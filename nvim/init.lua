vim.loader.enable()

require("vim._core.ui2").enable({
  enable = true,
  msg = { target = "cmd" },
})

require("colors")
require("keymaps")
require("plugins")
require("lsp")
