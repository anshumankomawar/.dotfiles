if vim.g.loaded_compile_mode then
  return
end
vim.g.loaded_compile_mode = true

-- Highlights (lightweight, no require needed)
local function setup_highlights()
  local defs = {
    CompileCommand = { link = "Comment" },
    CompileInfo = { link = "Comment" },
    CompileHeaderKey = { link = "Function" },
    CompileError = { link = "DiagnosticError" },
    CompileWarning = { link = "DiagnosticWarn" },
    CompileNote = { link = "DiagnosticInfo" },
    CompileErrorFile = { link = "Directory" },
    CompileErrorLnum = { link = "Number" },
    CompileCursor = { link = "CursorLine" },
  }
  for k, v in pairs(defs) do
    vim.api.nvim_set_hl(0, k, vim.tbl_extend("keep", { default = true }, v))
  end
end

setup_highlights()
vim.api.nvim_create_autocmd("ColorScheme", { callback = setup_highlights })

-- <Plug> mappings (deferred require)
vim.keymap.set("n", "<Plug>(compile-goto-error)", function() require("compile-mode").goto_error() end)
vim.keymap.set("n", "<Plug>(compile-recompile)",  function() require("compile-mode").recompile() end)
vim.keymap.set("n", "<Plug>(compile-interrupt)",   function() require("compile-mode").interrupt() end)
vim.keymap.set("n", "<Plug>(compile-goto-file)",   function() require("compile-mode").goto_file() end)
vim.keymap.set("n", "<Plug>(compile-next-error)",  function() require("compile-mode").next_error() end)
vim.keymap.set("n", "<Plug>(compile-prev-error)",  function() require("compile-mode").prev_error() end)
vim.keymap.set("n", "<Plug>(compile-first-error)", function() require("compile-mode").first_error() end)
vim.keymap.set("n", "<Plug>(compile-close)",       function() require("compile-mode").close() end)
vim.keymap.set("n", "<Plug>(compile-quickfix)",    function() require("compile-mode").quickfix() end)

-- User commands (deferred require)
vim.api.nvim_create_user_command("Compile", function(args)
  local m = require("compile-mode")
  if args.args == "" then
    m.prompt()
  else
    m.compile(args.args)
  end
end, { nargs = "?", desc = "Run compile command" })

vim.api.nvim_create_user_command("Recompile", function()
  require("compile-mode").recompile()
end, { nargs = 0, desc = "Re-run last compile command" })

vim.api.nvim_create_user_command("NextError", function()
  require("compile-mode").next_error()
end, { nargs = 0, desc = "Jump to next compile error" })

vim.api.nvim_create_user_command("PrevError", function()
  require("compile-mode").prev_error()
end, { nargs = 0, desc = "Jump to previous compile error" })

vim.api.nvim_create_user_command("FirstError", function()
  require("compile-mode").first_error()
end, { nargs = 0, desc = "Jump to first compile error" })
