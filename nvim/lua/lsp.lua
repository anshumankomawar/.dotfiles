vim.pack.add({
  "https://github.com/mason-org/mason.nvim",
  "https://github.com/mfussenegger/nvim-jdtls",
  "https://github.com/ziglang/zig.vim",
})

vim.schedule(function()
  require("mason").setup({})
end)

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
vim.keymap.set("n", "gd", vim.lsp.buf.definition)
vim.keymap.set("n", "<leader>fmt", vim.lsp.buf.format)
vim.keymap.set("n", "vd", vim.diagnostic.open_float)

-- zig
vim.g.zig_fmt_parse_errors = 0
