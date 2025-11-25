vim.pack.add({
  "https://github.com/mason-org/mason.nvim",
  "https://github.com/mfussenegger/nvim-jdtls"
})

require("mason").setup({})

vim.lsp.enable({
  "lua_ls",
})

vim.diagnostic.config({
  underline = true,
  virtual_text = false,
  signs = false,
  update_in_insert = false,
  severity_sort = true,
})
