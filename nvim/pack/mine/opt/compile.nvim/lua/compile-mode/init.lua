local M = {}

---@alias compile.ParserFn fun(line: string): compile.Error|nil
---@alias compile.WatchPattern string

local config = {
  height = 15,
  auto_scroll = true,
  error_threshold = "info", -- "error", "warning", or "info"
}

---@type compile.ParserFn[]
local parsers = {}

---@type compile.WatchPattern[]
local watch_patterns = {}

local state = {
  last_cmd = nil,
  job_id = nil,
  buf = nil,
  win = nil,
  exit_code = nil,
  errors = {},
  error_idx = 0,
  start_time = nil,
  cwd = nil,
  seen_boundary = false,
}

local ns = vim.api.nvim_create_namespace("compile-mode")

local function long_timestamp()
  return os.date("%a %b %d %H:%M:%S")
end


---@class compile.Error
---@field lnum integer line in the compile buffer (0-indexed)
---@field file string
---@field row integer
---@field col integer
---@field level "error"|"warning"|"info"
---@field text string

--- Built-in parser for common formats.
--- Supports: gcc/clang, rustc, go, python tracebacks, typescript, lua, java
---@param line string
---@return compile.Error|nil
local function builtin_parser(line)
  local file, row, col, text

  -- file:line:col: message (gcc, clang, rustc, go, typescript, etc.)
  file, row, col, text = line:match("^%s*([^:]+):(%d+):(%d+):%s*(.*)")
  if file and row then
    goto matched
  end

  -- file:line: message (no column)
  file, row, text = line:match("^%s*([^:]+):(%d+):%s*(.*)")
  if file and row then
    col = "1"
    goto matched
  end

  -- Python: File "path", line N
  file, row = line:match('^%s*File "([^"]+)",%s+line (%d+)')
  if file and row then
    col = "1"
    text = ""
    goto matched
  end

  -- Rust panics: thread 'main' panicked at file:line:col
  file, row, col = line:match("panicked at ([^:]+):(%d+):(%d+)")
  if file and row then
    text = "panic"
    goto matched
  end

  do return nil end

  ::matched::
  -- Skip things that look like file paths but aren't
  if file:match("^/bin/") or file:match("^/usr/bin/") or file:match("^%d+$") then
    return nil
  end

  local level = "info"
  local lower = line:lower()
  if lower:match("error") or lower:match("^e%[") then
    level = "error"
  elseif lower:match("warning") or lower:match("^w%[") then
    level = "warning"
  end

  return {
    lnum = 0, -- set by caller
    file = file,
    row = tonumber(row),
    col = tonumber(col) or 1,
    level = level,
    text = text or "",
  }
end

--- Try all registered parsers, then the built-in one.
---@param line string
---@return compile.Error|nil
local function parse_error(line)
  for _, parser in ipairs(parsers) do
    local err = parser(line)
    if err then
      return err
    end
  end
  return builtin_parser(line)
end

--- Parse make directory changes: "Entering directory 'path'"
---@param line string
---@return string|nil
local function parse_directory(line)
  return line:match("Entering directory [`'](.+)'")
end

---@param buf integer
---@param line_idx integer 0-indexed
---@param err compile.Error
local function highlight_error_line(buf, line_idx, err)
  local line = vim.api.nvim_buf_get_lines(buf, line_idx, line_idx + 1, false)[1]
  if not line then
    return
  end

  local hl_group
  if err.level == "error" then
    hl_group = "CompileError"
  elseif err.level == "warning" then
    hl_group = "CompileWarning"
  else
    hl_group = "CompileNote"
  end

  -- Highlight file:line:col portion
  local file_pattern = vim.pesc(err.file) .. ":%d+"
  local s, e = line:find(file_pattern)
  if s then
    vim.api.nvim_buf_set_extmark(buf, ns, line_idx, s - 1, {
      end_col = e,
      hl_group = "CompileErrorFile",
    })
  end

  -- Highlight the error/warning keyword
  local kw_start, kw_end = line:lower():find("error")
  if not kw_start then
    kw_start, kw_end = line:lower():find("warning")
  end
  if kw_start then
    vim.api.nvim_buf_set_extmark(buf, ns, line_idx, kw_start - 1, {
      end_col = kw_end,
      hl_group = hl_group,
    })
  end

  -- Sign column indicator
  vim.api.nvim_buf_set_extmark(buf, ns, line_idx, 0, {
    sign_text = err.level == "error" and "E " or err.level == "warning" and "W " or "I ",
    sign_hl_group = hl_group,
  })
end

local function resolve_file(file)
  -- Absolute path
  if file:sub(1, 1) == "/" then
    return file
  end
  -- Resolve relative to tracked cwd
  local base = state.cwd or vim.fn.getcwd()
  local resolved = base .. "/" .. file
  if vim.fn.filereadable(resolved) == 1 then
    return resolved
  end
  -- Fallback: try as-is
  if vim.fn.filereadable(file) == 1 then
    return file
  end
  return nil
end

local function jump_to_error(err)
  if not err then
    return
  end
  local file = resolve_file(err.file)
  if not file then
    vim.notify("[compile] file not found: " .. err.file, vim.log.levels.WARN)
    return
  end

  -- Find a non-compile window
  local target_win = nil
  for _, win in ipairs(vim.api.nvim_list_wins()) do
    if vim.api.nvim_win_get_buf(win) ~= state.buf then
      local cfg = vim.api.nvim_win_get_config(win)
      if not cfg.relative or cfg.relative == "" then
        target_win = win
        break
      end
    end
  end
  if target_win then
    vim.api.nvim_set_current_win(target_win)
  end

  vim.cmd("edit " .. vim.fn.fnameescape(file))
  pcall(vim.api.nvim_win_set_cursor, 0, { err.row, math.max(0, err.col - 1) })
  vim.cmd("normal! zz")
end

local function highlight_error_cursor()
  if not state.buf or not vim.api.nvim_buf_is_valid(state.buf) then
    return
  end
  -- Clear old cursor highlights
  local marks = vim.api.nvim_buf_get_extmarks(state.buf, ns, 0, -1, { details = true })
  for _, mark in ipairs(marks) do
    if mark[4] and mark[4].line_hl_group == "CompileCursor" then
      vim.api.nvim_buf_del_extmark(state.buf, ns, mark[1])
    end
  end
  -- Set new one
  local err = state.errors[state.error_idx]
  if err and err.lnum < vim.api.nvim_buf_line_count(state.buf) then
    pcall(vim.api.nvim_buf_set_extmark, state.buf, ns, err.lnum, 0, {
      line_hl_group = "CompileCursor",
    })
    -- Scroll compile window to the error
    if state.win and vim.api.nvim_win_is_valid(state.win) then
      pcall(vim.api.nvim_win_set_cursor, state.win, { err.lnum + 1, 0 })
    end
  end
end

function M.goto_error()
  local cursor_lnum = vim.api.nvim_win_get_cursor(0)[1] - 1
  for i, err in ipairs(state.errors) do
    if err.lnum == cursor_lnum then
      state.error_idx = i
      highlight_error_cursor()
      jump_to_error(err)
      return
    end
  end
end

function M.goto_file()
  local file = vim.fn.expand("<cfile>")
  local resolved = resolve_file(file)
  if resolved then
    vim.cmd("wincmd p")
    vim.cmd("edit " .. vim.fn.fnameescape(resolved))
  end
end

function M.close()
  if state.win and vim.api.nvim_win_is_valid(state.win) then
    vim.api.nvim_win_close(state.win, false)
    state.win = nil
  end
end

function M.quickfix()
  local qf = {}
  for _, err in ipairs(state.errors) do
    local file = resolve_file(err.file)
    qf[#qf + 1] = {
      filename = file or err.file,
      lnum = err.row,
      col = err.col,
      text = err.text,
    }
  end
  if #qf > 0 then
    vim.fn.setqflist({}, " ", { title = "Compile Errors", items = qf })
    vim.cmd("copen")
  end
end

local level_rank = { error = 3, warning = 2, info = 1 }

local function meets_threshold(err)
  local threshold = level_rank[config.error_threshold] or 1
  return (level_rank[err.level] or 1) >= threshold
end

function M.first_error()
  for i, err in ipairs(state.errors) do
    if meets_threshold(err) then
      state.error_idx = i
      highlight_error_cursor()
      jump_to_error(err)
      return
    end
  end
  vim.notify("[compile] no errors", vim.log.levels.INFO)
end

function M.next_error()
  if #state.errors == 0 then
    vim.notify("[compile] no errors", vim.log.levels.INFO)
    return
  end
  local start = state.error_idx
  for _ = 1, #state.errors do
    start = start + 1
    if start > #state.errors then
      start = 1
    end
    if meets_threshold(state.errors[start]) then
      state.error_idx = start
      highlight_error_cursor()
      jump_to_error(state.errors[state.error_idx])
      return
    end
  end
  vim.notify("[compile] no matching errors", vim.log.levels.INFO)
end

function M.prev_error()
  if #state.errors == 0 then
    vim.notify("[compile] no errors", vim.log.levels.INFO)
    return
  end
  local start = state.error_idx
  for _ = 1, #state.errors do
    start = start - 1
    if start < 1 then
      start = #state.errors
    end
    if meets_threshold(state.errors[start]) then
      state.error_idx = start
      highlight_error_cursor()
      jump_to_error(state.errors[state.error_idx])
      return
    end
  end
  vim.notify("[compile] no matching errors", vim.log.levels.INFO)
end

local function get_or_create_buf()
  if state.buf and vim.api.nvim_buf_is_valid(state.buf) then
    return state.buf
  end
  state.buf = vim.api.nvim_create_buf(false, true)
  vim.bo[state.buf].buftype = "nofile"
  vim.bo[state.buf].bufhidden = "hide"
  vim.bo[state.buf].swapfile = false
  vim.bo[state.buf].filetype = "compile"
  vim.api.nvim_buf_set_name(state.buf, "*compilation*")

  local buf = state.buf

  -- Buffer-local defaults (only set if user hasn't mapped the <Plug>)
  local defaults = {
    { "<CR>",         "<Plug>(compile-goto-error)" },
    { "<LeftMouse>",  "<LeftMouse><Plug>(compile-goto-error)" },
    { "r",            "<Plug>(compile-recompile)" },
    { "<C-c>",        "<Plug>(compile-interrupt)" },
    { "gf",           "<Plug>(compile-goto-file)" },
    { "]e",           "<Plug>(compile-next-error)" },
    { "[e",           "<Plug>(compile-prev-error)" },
    { "ge",           "<Plug>(compile-first-error)" },
    { "q",            "<Plug>(compile-close)" },
    { "<C-q>",        "<Plug>(compile-quickfix)" },
  }

  for _, map in ipairs(defaults) do
    if vim.fn.hasmapto(map[2], "n") == 0 then
      vim.keymap.set("n", map[1], map[2], { buffer = buf, nowait = true, silent = true })
    end
  end

  vim.api.nvim_create_autocmd("BufDelete", {
    buffer = buf,
    callback = function()
      M.kill()
      state.buf = nil
      state.win = nil
    end,
  })

  return state.buf
end

local function open_win(buf)
  if state.win and vim.api.nvim_win_is_valid(state.win) then
    vim.api.nvim_win_set_buf(state.win, buf)
    return state.win
  end
  vim.cmd("botright split")
  state.win = vim.api.nvim_get_current_win()
  vim.api.nvim_win_set_buf(state.win, buf)
  vim.api.nvim_win_set_height(state.win, config.height)
  vim.wo[state.win].winfixheight = true
  vim.wo[state.win].wrap = false
  vim.wo[state.win].cursorline = true
  vim.cmd("wincmd p")
  return state.win
end

function M.kill()
  if state.job_id and state.job_id > 0 then
    pcall(vim.fn.jobstop, state.job_id)
    state.job_id = nil
  end
end

function M.interrupt()
  if not state.job_id then
    return
  end
  M.kill()
  if state.buf and vim.api.nvim_buf_is_valid(state.buf) then
    vim.bo[state.buf].modifiable = true
    local count = vim.api.nvim_buf_line_count(state.buf)
    vim.api.nvim_buf_set_lines(state.buf, count, count, false, {
      "",
      "Compilation interrupted at " .. long_timestamp(),
    })
    local footer = vim.api.nvim_buf_line_count(state.buf) - 1
    vim.api.nvim_buf_set_extmark(state.buf, ns, footer, 0, { line_hl_group = "CompileError" })
    vim.bo[state.buf].modifiable = false
  end
end

---@param cmd string
function M.compile(cmd)
  M.kill()

  state.last_cmd = cmd
  state.last_cwd = vim.fn.getcwd()
  state.exit_code = nil
  state.errors = {}
  state.error_idx = 0
  state.cwd = state.last_cwd
  state.start_time = vim.uv.hrtime()
  state.seen_boundary = false

  local buf = get_or_create_buf()

  -- Clear buffer
  vim.bo[buf].modifiable = true
  local time_str = long_timestamp()
  local cwd_display = (state.cwd or vim.fn.getcwd()):gsub("^" .. vim.env.HOME, "~")
  local branch = vim.fn.system("git -C " .. vim.fn.shellescape(state.cwd) .. " rev-parse --abbrev-ref HEAD 2>/dev/null"):gsub("%s+$", "")
  if vim.v.shell_error ~= 0 then
    branch = nil
  end

  local header_lines = {
    "directory : " .. cwd_display .. (branch and " (" .. branch .. ")" or ""),
    "command   : " .. cmd,
    "started   : " .. time_str,
    "",
  }
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, header_lines)
  vim.api.nvim_buf_clear_namespace(buf, ns, 0, -1)
  for i = 0, 2 do
    local line = header_lines[i + 1]
    local colon = line:find(":")
    if colon then
      vim.api.nvim_buf_set_extmark(buf, ns, i, 0, {
        end_col = colon,
        hl_group = "CompileHeaderKey",
      })
      vim.api.nvim_buf_set_extmark(buf, ns, i, colon, {
        end_col = #line,
        hl_group = "Normal",
      })
    end
  end
  vim.bo[buf].modifiable = false

  open_win(buf)

  local function is_watch_boundary(line)
    for _, pat in ipairs(watch_patterns) do
      if line:match(pat) then
        return true
      end
    end
    return false
  end

  -- Header is 4 lines: directory, command, started, blank
  local header_end = 4

  local function clear_output()
    vim.bo[buf].modifiable = true
    vim.api.nvim_buf_set_lines(buf, header_end, -1, false, {})
    vim.api.nvim_buf_clear_namespace(buf, ns, header_end, -1)
    state.errors = {}
    state.error_idx = 0
    vim.bo[buf].modifiable = false
  end

  local function append(data)
    if not data or not vim.api.nvim_buf_is_valid(buf) then
      return
    end
    -- jobstart sends a trailing "" to signal end of chunk — drop it
    while #data > 0 and data[#data] == "" do
      data[#data] = nil
    end
    if #data == 0 then
      return
    end
    vim.bo[buf].modifiable = true

    -- Process line by line so we can clear mid-batch
    for _, line in ipairs(data) do
      local clean = line:gsub("\27%[[%d;]*[A-Za-z]", ""):gsub("\27%([A-Z0-9]", ""):gsub("\r", "")

      if clean ~= "" and state.job_id then
        if is_watch_boundary(clean) then
          if state.seen_boundary then
            -- Second+ boundary with no output between — clean build, clear old output
            clear_output()
            vim.bo[buf].modifiable = true
          end
          state.seen_boundary = true
        elseif state.seen_boundary then
          -- First real output after a boundary — new cycle, clear old output
          clear_output()
          vim.bo[buf].modifiable = true
          state.seen_boundary = false
        end
      end

      -- Write line to buffer
      local lnum = vim.api.nvim_buf_line_count(buf)
      vim.api.nvim_buf_set_lines(buf, lnum, lnum, false, { line })

      -- Parse non-empty lines
      if clean ~= "" then
        local dir = parse_directory(clean)
        if dir then
          state.cwd = dir
        end

        local err = parse_error(clean)
        if err then
          err.lnum = lnum
          state.errors[#state.errors + 1] = err
          highlight_error_line(buf, lnum, err)
        end
      end
    end

    vim.bo[buf].modifiable = false

    -- Auto-scroll: to first error if any, otherwise to bottom
    if state.win and vim.api.nvim_win_is_valid(state.win) then
      if #state.errors > 0 then
        state.error_idx = 1
        highlight_error_cursor()
      elseif config.auto_scroll then
        local count = vim.api.nvim_buf_line_count(buf)
        pcall(vim.api.nvim_win_set_cursor, state.win, { count, 0 })
      end
    end
  end

  state.job_id = vim.fn.jobstart(cmd, {
    on_stdout = function(_, data)
      vim.schedule(function() append(data) end)
    end,
    on_stderr = function(_, data)
      vim.schedule(function() append(data) end)
    end,
    on_exit = function(id, code)
      local end_time = vim.uv.hrtime()
      -- Ignore if this job was replaced by a new one
      if state.job_id ~= id then
        return
      end
      state.exit_code = code
      state.job_id = nil
      vim.schedule(function()
        local time_end = long_timestamp()
        local duration = ""
        if state.start_time then
          local dt = (end_time - state.start_time) / 1e9
          if dt >= 60 then
            duration = string.format(", duration %dm %.2fs", math.floor(dt / 60), dt % 60)
          else
            duration = string.format(", duration %.2fs", dt)
          end
        end

        local status
        if code == 0 then
          status = "Compilation finished"
        elseif code == 139 then
          status = "Compilation segmentation fault (core dumped)"
        elseif code == 143 then
          status = "Compilation terminated"
        else
          status = "Compilation exited abnormally with code " .. code
        end

        local counts = { error = 0, warning = 0, info = 0 }
        for _, err in ipairs(state.errors) do
          counts[err.level] = counts[err.level] + 1
        end
        local parts = {}
        if counts.error > 0 then
          parts[#parts + 1] = counts.error .. " error" .. (counts.error > 1 and "s" or "")
        end
        if counts.warning > 0 then
          parts[#parts + 1] = counts.warning .. " warning" .. (counts.warning > 1 and "s" or "")
        end
        if counts.info > 0 then
          parts[#parts + 1] = counts.info .. " note" .. (counts.info > 1 and "s" or "")
        end
        local err_summary = ""
        if #parts > 0 then
          err_summary = " [" .. table.concat(parts, ", ") .. "]"
        end

        vim.bo[buf].modifiable = true
        local count = vim.api.nvim_buf_line_count(buf)
        vim.api.nvim_buf_set_lines(buf, count, count, false, {
          "",
          status .. " at " .. time_end .. duration .. err_summary,
        })
        local footer_line = vim.api.nvim_buf_line_count(buf) - 1
        local hl = code == 0 and "CompileInfo" or "CompileError"
        vim.api.nvim_buf_set_extmark(buf, ns, footer_line, 0, { line_hl_group = hl })
        vim.bo[buf].modifiable = false

        -- Auto-scroll to first error
        if #state.errors > 0 and state.win and vim.api.nvim_win_is_valid(state.win) then
          state.error_idx = 1
          highlight_error_cursor()
          pcall(vim.api.nvim_win_set_cursor, state.win, { state.errors[1].lnum + 1, 0 })
        end
      end)
    end,
    stdout_buffered = false,
    stderr_buffered = false,
  })

  if state.job_id <= 0 then
    append({ "failed to start: " .. cmd })
    state.job_id = nil
  end
end

function M.prompt()
  vim.ui.input({ prompt = "Compile: ", default = state.last_cmd or "" }, function(cmd)
    if cmd and cmd ~= "" then
      M.compile(cmd)
    end
  end)
end

function M.recompile()
  if state.last_cmd then
    -- Recompile in the original directory
    local saved_cwd = state.last_cwd
    M.compile(state.last_cmd)
    state.last_cwd = saved_cwd
    state.cwd = saved_cwd
  else
    M.prompt()
  end
end

--- Register a custom error parser. Runs before built-in parsers.
---@param fn compile.ParserFn
function M.add_parser(fn)
  parsers[#parsers + 1] = fn
end

--- Register a cycle end pattern for watch mode.
---@param pattern compile.WatchPattern
function M.add_watch_pattern(pattern)
  watch_patterns[#watch_patterns + 1] = pattern
end

---@param opts { height: integer|nil, auto_scroll: boolean|nil, error_threshold: string|nil }|nil
function M.setup(opts)
  config = vim.tbl_extend("force", config, opts or {})

  -- Built-in watch boundary patterns
  watch_patterns = {
    "^Build Summary:",          -- zig
    "^Watching for file",       -- tsc --watch
    "^%[Finished",              -- cargo watch
    "^BUILD SUCCESSFUL",        -- gradle
    "^BUILD FAILED",            -- gradle
    "^Waiting for changes",     -- gradle --continuous
  }
end

return M
