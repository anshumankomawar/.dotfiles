local theme = "gruber-darker"

if theme == "gruvbox-material" then
  vim.pack.add({ "https://github.com/sainnhe/gruvbox-material" })
  vim.g.gruvbox_material_foreground = "material"
  vim.g.gruvbox_material_background = "hard"
  vim.g.gruvbox_material_enable_bold = 0
  vim.g.gruvbox_material_transparent_background = 0
  vim.g.gruvbox_material_diagnostic_virtual_text = "colored"
  vim.g.gruvbox_material_diagnostic_line_highlight = 1
  vim.g.gruvbox_material_dim_inactive_windows = 0
  vim.g.gruvbox_material_statusline_style = "mix"
  vim.opt.background = "dark"

elseif theme == "gruber-darker" then
  vim.pack.add({ "https://github.com/blazkowolf/gruber-darker.nvim" })

elseif theme == "zenwritten" then
  vim.pack.add({ "https://github.com/zenbones-theme/zenbones.nvim", "https://github.com/rktjmp/lush.nvim" })
  vim.opt.background = "dark"
end

vim.cmd.colorscheme(theme)

vim.api.nvim_set_hl(0, "Winbar", { link = "Normal" })
vim.api.nvim_set_hl(0, "WinbarNC", { link = "Normal" })
