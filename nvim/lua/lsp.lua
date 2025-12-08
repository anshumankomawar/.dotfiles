vim.pack.add({
  "https://github.com/mason-org/mason.nvim",
  -- java
  "https://github.com/mfussenegger/nvim-jdtls",
  -- zig
  "https://github.com/ziglang/zig.vim",
})

require("mason").setup({})

vim.lsp.enable({
  "lua_ls",
  "zls",
  "ts_ls",
})

vim.diagnostic.config({
  underline = true,
  virtual_text = true,
  virtual_lines = false,
  signs = false,
  update_in_insert = false,
  severity_sort = true,
})

-- keymaps
vim.keymap.set("n", "gd", vim.lsp.buf.definition, opts)

-- ZLS 
--
vim.g.zig_fmt_parse_errors = 0
vim.g.zig_fmt_autosave = 1

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
