vim.pack.add({
  "https://github.com/mason-org/mason.nvim",
  "https://github.com/mfussenegger/nvim-jdtls",
  "https://github.com/ziglang/zig.vim",
})

require("mason").setup({})

vim.lsp.enable({
  "lua_ls",
  "zls",
  "ts_ls",
  "ruff",
  "ty",
})

vim.diagnostic.config({
  underline = true,
  virtual_text = false,
  virtual_lines = false,
  signs = false,
  update_in_insert = false,
  severity_sort = true,
})

-- keymaps
vim.keymap.set("n", "gd", vim.lsp.buf.definition, opts)
vim.keymap.set("n", "<leader>fmt", vim.lsp.buf.format, opts)
vim.keymap.set('n', 'vd', vim.diagnostic.open_float)

-- ZLS 
--
-- vim.g.zig_fmt_parse_errors = 0
-- vim.g.zig_fmt_autosave = 1

-- zig autocommands
-- vim.api.nvim_create_autocmd('BufWritePre',{
--   pattern = {"*.zig", "*.zon"},
--   callback = function(ev)
--     vim.lsp.buf.code_action({
--       context = { only = { "source.organizeImports" } },
--       apply = true,
--     })
--   end
-- })
--
-- vim.api.nvim_create_autocmd('BufWritePre',{
--   pattern = {"*.zig", "*.zon"},
--   callback = function(ev)
--     vim.lsp.buf.code_action({
--       context = { only = { "source.fixAll" } },
--       apply = true,
--     })
--   end
-- })
