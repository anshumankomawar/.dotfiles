vim.pack.add({
  "https://github.com/stevearc/oil.nvim",
})

-- Hardtime
vim.pack.add({
  "https://github.com/m4xshen/hardtime.nvim",
  "https://github.com/MunifTanjim/nui.nvim"
})

require("hardtime").setup({});

-- Oil
function _G.get_oil_winbar()
  local bufnr = vim.api.nvim_win_get_buf(vim.g.statusline_winid)
  local dir = require("oil").get_current_dir(bufnr)
  if dir then
    return vim.fn.fnamemodify(dir, ":~")
  else
    -- If there is no current directory (e.g. over ssh), just show the buffer name
    return vim.api.nvim_buf_get_name(0)
  end
end

require("oil").setup({
  default_file_explorer = true,
  columns = {
    "icon",
    "permissions",
    "size",
    "mtime",
  },
  delete_to_trash = true,
  skip_confirm_for_simple_edits = true,
  prompt_save_on_select_new_entry = false,
  lsp_file_methods = {
    -- Enable or disable LSP file operations
    enabled = true,
    -- Time to wait for LSP file operations to complete before skipping
    timeout_ms = 1000,
    -- Set to true to autosave buffers that are updated with LSP willRenameFiles
    -- Set to "unmodified" to only save unmodified buffers
    autosave_changes = false,
  },
  watch_for_changes = true, 
  win_options = {
    winbar = "%!v:lua.get_oil_winbar()",
  },
})

vim.keymap.set("n", "<leader>.", function()
  if vim.bo.filetype == 'oil' then
    require("oil.actions").close.callback()
  else
    vim.cmd('Oil')
  end
end)


-- Blink
vim.pack.add({
  { src = "https://github.com/saghen/blink.cmp", version = vim.version.range("^1") },
  "https://github.com/onsails/lspkind.nvim"
})

require('blink.cmp').setup({
  completion = {
    menu = {
      draw = {
        columns = {
          { "label", "label_description", gap = 1 },
          { "kind_icon", "kind" }
        },
      }
    },
  },
  signature = { enabled = true }
})


-- Git
vim.pack.add({
  "https://github.com/tpope/vim-fugitive" ,
  "https://github.com/lewis6991/gitsigns.nvim",
})

require('gitsigns').setup({ signcolumn = false })

-- Icons
vim.pack.add({
  "https://github.com/echasnovski/mini.icons",
  "https://github.com/nvim-tree/nvim-web-devicons",
})

package.preload["nvim-web-devicons"] = function()
  require("mini.icons").mock_nvim_web_devicons()
  return package.loaded["nvim-web-devicons"]
end

require("mini.icons").setup({
  extension = {
    ['properties'] = { glyph = '󰬷', hl = 'MiniIconsBlue' },
    ['java'] = { glyph = '󰬷', hl = 'MiniIconsRed' },
    ['xml'] = { glyph = '󰗀', hl = 'MiniIconsRed' },
  },
  file = {
    ['build.xml'] = { glyph = '󰗀', hl = 'MiniIconsRed' },
  },
})

-- harpoon
vim.pack.add({
  {src="https://github.com/ThePrimeagen/harpoon/", branch="harpoon2", name="harpoon"}, 
  "https://github.com/nvim-lua/plenary.nvim",
})

local harpoon = require("harpoon")
local mark = require("harpoon.mark")
local ui = require("harpoon.ui")

vim.keymap.set("n", "<leader>H", mark.add_file, { desc = "Harpoon File" })
vim.keymap.set("n", "<leader>e", ui.toggle_quick_menu, { desc = "Harpoon Quick Menu" })

for i = 1, 5 do
  vim.keymap.set("n", "<leader>" .. i, function()
    ui.nav_file(i)
  end, { desc = "Harpoon to File " .. i })
end

-- fzf
vim.pack.add({
  'https://github.com/ibhagwan/fzf-lua',
  -- version = "1.*"
  -- 'https://github.com/elanmed/fzf-lua-frecency.nvim'
})
local utils = {}

-- From fzf-lua utils - the invisible unicode separator
utils.nbsp = "\xe2\x80\x82" -- "\u{2002}"

-- From fzf-lua utils - string split function
function utils.strsplit(inputstr, sep)
  local t = {}
  local s, m, r = inputstr, nil, nil
  repeat
    m, r = s:match("^(.-)" .. sep .. "(.*)$")
    s = r and r or s
    table.insert(t, m or s)
  until not m
  return t
end

-- ANSI escape sequences
utils.ansi_escseq = {
  clear = "\027[0m",
}

-- Function to get ansi coloring from highlight group (simplified)
function utils.ansi_from_hl(hl, s)
  if not hl or #hl == 0 or vim.fn.hlexists(hl) ~= 1 then
    return s, nil
  end
  -- Simplified version - just return the string for now
  -- You can expand this if you need actual color support
  return s, ""
end

-- Path utilities
local path = {}

function path.tail(filepath)
  return vim.fn.fnamemodify(filepath, ":t")
end

function path.parent(filepath)
  local parent = vim.fn.fnamemodify(filepath, ":h")
  return parent ~= "." and parent or nil
end

function path.remove_trailing(filepath)
  return filepath:gsub("/$", "")
end

function path.join(parts)
  return table.concat(parts, "/")
end

local fzf_lua = require("fzf-lua")

-- require('fzf-lua-frecency').frecency({
--     cwd_only = true,
-- })

require("fzf-lua").setup({
  "hide",
  hls = { border = "NonText" },
  formatters    = {
    path = {
      filename_first_aligned = {
        -- <Tab> is used as the invisible space between the parent and the file part
        enrich = function(o, v)
          o.fzf_opts = vim.tbl_extend("keep", o.fzf_opts or {}, { ["--tabstop"] = 1 })
          if tonumber(v) == 2 then
            -- https://github.com/ibhagwan/fzf-lua/pull/1255
            o.fzf_opts = vim.tbl_extend("keep", o.fzf_opts or {}, {
              ["--ellipsis"] = " ",
              ["--no-hscroll"] = true,
            })
          end
          return o
        end,
        -- underscore `_to` returns a custom to function when options could
        -- affect the transformation, here we create a different function
        -- base on the dir part highlight group.
        -- We use a string function with hardcoded values as non-scope vars
        -- (globals or file-locals) are stored by ref and will be nil in the
        -- `string.dump` (from `config.bytecode`), we use the 3rd function
        -- argument `m` to pass module imports (path, utils, etc).
        _to = function(o, v)
          local _, hl_dir = utils.ansi_from_hl(o.hls.dir_part, "foo")
          local _, hl_file = utils.ansi_from_hl(o.hls.file_part, "foo")
          local v2 = tonumber(v) ~= 2 and "" or [[, "\xc2\xa0" .. string.rep(" ", 200) .. s]]
          return ([[
            return function(s, _, m)
              local _path, _utils = m.path, m.utils
              local _hl_dir = "%s"
              local _hl_file = "%s"
              local tail = _path.tail(s)
              local parent = _path.parent(s)
              if #_hl_file > 0 then
                tail = _hl_file .. tail .. _utils.ansi_escseq.clear
              end
              if parent then
                parent = _path.remove_trailing(parent)
                if #_hl_dir > 0 then
                  parent = _hl_dir .. parent .. _utils.ansi_escseq.clear
                end
                local padding = string.rep(" ", math.max(1, 80 - #tail))
                return tail .. padding .. parent %s
              else
                return tail %s
              end
            end
          ]]):format(hl_dir or "", hl_file or "", v2, v2)
        end,
        from = function(s, _)
          s = s:gsub("\xc2\xa0     .*$", "") -- gsub v2 postfix
          local parts = utils.strsplit(s, utils.nbsp)
          local last = parts[#parts]
          -- Lines from grep, lsp, tags are formatted <file>:<line>:<col>:<text>
          -- the pattern below makes sure tab doesn't come from the line text
          local filename, rest = last:match("^([^:]-)\t(.+)$")
          if filename and rest then
            local parent
            if utils.__IS_WINDOWS and path.is_absolute(rest) then
              parent = rest:sub(1, 2) .. (#rest > 2 and rest:sub(3):match("^[^:]+") or "")
            else
              parent = rest:match("^[^:]+")
            end
            local fullpath = path.join({ parent, filename })
            -- overwrite last part with restored fullpath + rest of line
            parts[#parts] = fullpath .. rest:sub(#parent + 1)
            return table.concat(parts, utils.nbsp)
          else
            return s
          end
        end
      },
    },
  },

  -- Global ignore patterns (replaces your complex fd_opts/rg_opts setup)
  file_ignore_patterns = {
    -- Version control
    "%.git",

    -- Dependencies
    "node_modules",
    "vendor",
    "%.bundle",
    "%.gradle",
    "%.settings",

    -- Build outputs
    "dist",
    -- "build", 
    "target",
    "%.next",
    "env",
    "%.bemol",
    "%.brazil",
    "logs",

    -- Cache and temporary files
    "__pycache__",
    "%.pytest_cache",
    "%.cargo",
    "%.dart_tool",
    "%.pub%-cache",

    -- Virtual environments
    "%.venv",
    "venv",
    "%.env",

    -- Coverage reports
    "coverage",
    "%.coverage",
    "%.nyc_output",

    -- Cloud/Infrastructure
    "cdk%.out",
    "%.aws%-sam",
    "%.terraform",

    -- IDE/Editor files
    "%.vscode",
    "%.idea",
  },

  defaults = {
    file_icons = "mini",
    git_icons = false,
  },

  winopts = {
    fullscreen = true,
    border = "none",
    preview = {
      layout = "horizontal",
      horizontal = "right:50%,noborder",
      border = "none",
    },
    on_create = function()
      vim.cmd("set guicursor+=a:blinkon0")
    end,
  },

  files = {
    cwd_prompt = false,
    no_ignore = true,
    path_shorten = false,
    formatter = "path.filename_first",
    winopts = {
      fullscreen= false,
      -- split = "botright 10new",
      path_shorten = false,
      list = true,
      height = 0.2,        -- Very thin
      width = 1.0,
      row = 1.0,
      col = 0,
      -- height = 0.3,        -- Very thin
      -- width = 0.6,
      -- row = 0.2,
      border = "none",
      backdrop = 80,
      preview = { hidden = "hidden" },
    },
    fzf_opts = {
      ['--layout'] = 'reverse',
    },
  },

  fzf_colors = {
    false,
    ["fg"] = { "fg", "Normal" },
    ["bg"] = { "bg", "Normal" },
    ["bg+"] = { "bg", "CursorLine" },
    ["fg+"] = { "fg", "Normal" },
    ["hl"] = { "fg", "FzfLuaFzfMatch" },
    ["hl+"] = { "fg", "FzfLuaFzfMatch" },
    ["info"] = { "fg", "Normal" },
    ["prompt"] = { "fg", "Normal" },
    ["pointer"] = "-1",
    ["marker"] = "-1",
    ["spinner"] = { "fg", "Normal" },
    ["header"] = { "fg", "Normal" },
    ["gutter"] = "-1",
  },
  fzf_args = '--pointer=',

  fzf_opts = {
    ['--no-separator'] = '',
    ['--no-info'] = '',
    ['--no-bold'] = '',
    ['--prompt'] = " Find File: ",
  },

  grep = {
    prompt = ' Grep Files: ',
    input_prompt = 'Grep For❯ ',
    no_header = true,
    no_header_i = true,
    winopts = {
      -- fullscreen = false,
      -- path_shorten = false,
      -- height = 0.2,
      -- list = true,
      -- width = 1.0,
      -- row = 1.0,
      -- col = 0,
      fullscreen= false,
      split = "botright 10new",
      path_shorten = false,
      list = true,
      border = "none",
      preview = { hidden = "hidden" },
    },
  },

  live_grep = {
    stderr = false,
  },
})

-- Keymaps
local opts = { noremap = true, silent = true }

vim.keymap.set('n', '<leader>ff', fzf_lua.files, opts)
-- vim.keymap.set('n', '<leader>ff', fzf_lua.frequency, opts)
vim.keymap.set('n', '<leader>fr', fzf_lua.oldfiles, opts)
vim.keymap.set('n', '<leader>fg', fzf_lua.live_grep, opts)
vim.keymap.set('n', '<leader>sw', fzf_lua.grep_cword, opts)
vim.keymap.set('n', '<leader>sW', fzf_lua.grep_cWORD, opts)
vim.keymap.set('v', '<leader>sg', fzf_lua.grep_visual, opts)
vim.keymap.set('n', '<leader>sb', fzf_lua.lgrep_curbuf, opts)
vim.keymap.set('n', '<leader>bb', fzf_lua.buffers, opts)
vim.keymap.set('n', '<leader>gs', fzf_lua.git_status, opts)
vim.keymap.set('n', '<leader>gc', fzf_lua.git_commits, opts)
vim.keymap.set('n', '<leader>gb', fzf_lua.git_branches, opts)
-- vim.keymap.set('n', '<leader>ls', fzf_lua.lsp_document_symbols, opts)
-- vim.keymap.set('n', '<leader>lS', fzf_lua.lsp_workspace_symbols, opts)
-- vim.keymap.set('n', '<leader>lr', fzf_lua.lsp_references, opts)
-- vim.keymap.set('n', '<leader>ld', fzf_lua.lsp_definitions, opts)
-- vim.keymap.set('n', '<leader>lt', fzf_lua.lsp_typedefs, opts)
-- vim.keymap.set('n', '<leader>li', fzf_lua.lsp_implementations, opts)
-- vim.keymap.set('n', '<leader>la', fzf_lua.lsp_code_actions, opts)
-- vim.keymap.set('n', '<leader>lD', fzf_lua.diagnostics_document, opts)
-- vim.keymap.set('n', '<leader>lW', fzf_lua.diagnostics_workspace, opts)
-- vim.keymap.set('n', '<leader>hh', fzf_lua.help_tags, opts)
-- vim.keymap.set('n', '<leader>hm', fzf_lua.man_pages, opts)
vim.keymap.set('n', '<leader>:', fzf_lua.commands, opts)
-- vim.keymap.set('n', '<leader>hk', fzf_lua.keymaps, opts)
vim.keymap.set('n', '<leader>sr', fzf_lua.resume, opts)
vim.keymap.set('n', '<leader>qq', fzf_lua.quickfix, opts)
vim.keymap.set('n', '<leader>ql', fzf_lua.loclist, opts)


-- treesitter support
vim.pack.add {
  "https://github.com/nvim-treesitter/nvim-treesitter",
  "https://github.com/nvim-treesitter/nvim-treesitter-textobjects",
  "https://github.com/windwp/nvim-ts-autotag",
  "https://github.com/Wansmer/treesj",
}

---@diagnostic disable-next-line: missing-fields
require("nvim-treesitter.configs").setup {
  auto_install = true,
  highlight = {
    enable = true,
  }
}

local swap = require("nvim-treesitter.textobjects.swap")
vim.keymap.set("n", "{", function() swap.swap_previous("@parameter.inner") end)
vim.keymap.set("n", "}", function() swap.swap_next("@parameter.inner") end)
---@diagnostic disable-next-line: missing-fields
require("nvim-treesitter.configs").setup {
  textobjects = {
    select = {
      enable = true,
      lookahead = true,
      keymaps = {
        ["af"] = "@function.outer",
        ["if"] = "@function.inner",
        ["ac"] = "@class.outer",
        ["ic"] = { query = "@class.inner", desc = "Select inner part of a class region" },
        ["as"] = { query = "@local.scope", query_group = "locals", desc = "Select language scope" },
      },
      include_surrounding_whitespace = true,
    },
    move = {
      enable = true,
      goto_next_start = { ["]f"] = "@function.outer", ["]c"] = "@class.outer" },
      goto_next_end = { ["]F"] = "@function.outer", ["]C"] = "@class.outer" },
      goto_previous_start = { ["[f"] = "@function.outer", ["[c"] = "@class.outer" },
      goto_previous_end = { ["[F"] = "@function.outer", ["[C"] = "@class.outer" },
    },
  },
}
local tsj = require("treesj")

tsj.setup {
  max_join_length = 1000000,
  use_default_keymaps = false,
}

vim.keymap.set("n", "gs", function() tsj.toggle() end, { desc = "Toggle split/join" })
vim.keymap.set("n", "gS", function() tsj.toggle { split = { recursive = true } } end, { desc = "Toggle split/join (recursive)" })

require("nvim-ts-autotag").setup {}
