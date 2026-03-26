-- PackChanged hooks must be defined before vim.pack.add
vim.api.nvim_create_autocmd("PackChanged", {
  callback = function(event)
    local name = event.data.spec.name
    if name == "fff.nvim" and event.data.updated then
      require("fff.download").download_or_build_binary()
    end
    if name == "nvim-treesitter" and event.data.kind == "update" then
      if not event.data.active then vim.cmd.packadd("nvim-treesitter") end
      vim.cmd("TSUpdate")
    end
  end,
})

vim.pack.add({
  "https://github.com/stevearc/oil.nvim",
  "https://github.com/dmtrKovalenko/fff.nvim",
  { src = "https://github.com/saghen/blink.cmp", version = vim.version.range("^1") },
  "https://github.com/tpope/vim-fugitive",
  { src = "https://github.com/ThePrimeagen/harpoon/", branch = "harpoon2", name = "harpoon" },
  "https://github.com/nvim-lua/plenary.nvim",
  "https://github.com/nvim-treesitter/nvim-treesitter",
})

vim.cmd.packadd("minibuffer.nvim")

-- minibuffer
vim.ui.select = require("minibuffer.builtin.ui_select")
vim.ui.input = require("minibuffer.builtin.ui_input")

-- fff
vim.g.fff = {
  lazy_sync = true,
  debug = { enabled = true, show_scores = true },
}

local picker_ui = require("fff.picker_ui")
picker_ui.open = require("minibuffer.integrations.fff")

vim.keymap.set("n", "ff", function() require("fff").find_files() end, { desc = "Find files" })
vim.keymap.set("n", "fg", function() require("minibuffer.examples.live-grep")() end, { desc = "Live grep" })

-- oil
function _G.get_oil_winbar()
  local bufnr = vim.api.nvim_win_get_buf(vim.g.statusline_winid)
  local dir = require("oil").get_current_dir(bufnr)
  if dir then
    return vim.fn.fnamemodify(dir, ":~")
  else
    return vim.api.nvim_buf_get_name(0)
  end
end

require("oil").setup({
  default_file_explorer = true,
  columns = { "permissions", "size", "mtime" },
  delete_to_trash = true,
  skip_confirm_for_simple_edits = true,
  prompt_save_on_select_new_entry = false,
  lsp_file_methods = { enabled = true, timeout_ms = 1000, autosave_changes = false },
  watch_for_changes = true,
  win_options = { winbar = "%!v:lua.get_oil_winbar()" },
})

vim.keymap.set("n", "<leader>.", function()
  if vim.bo.filetype == "oil" then
    require("oil.actions").close.callback()
  else
    vim.cmd("Oil")
  end
end)

-- blink.cmp
vim.schedule(function()
  require("blink.cmp").setup({
    completion = {
      menu = {
        draw = {
          columns = {
            { "label", "label_description", gap = 1 },
            { "kind" },
          },
        },
      },
    },
    signature = { enabled = false },
  })
end)

-- harpoon
local harpoon = require("harpoon")
harpoon:setup()

vim.keymap.set("n", "<leader>H", function() harpoon:list():add() end, { desc = "Harpoon add" })
vim.keymap.set("n", "<leader>e", function() harpoon.ui:toggle_quick_menu(harpoon:list()) end, { desc = "Harpoon menu" })

for i = 1, 5 do
  vim.keymap.set("n", "<leader>" .. i, function() harpoon:list():select(i) end, { desc = "Harpoon " .. i })
end

-- treesitter
---@diagnostic disable-next-line: missing-fields
require("nvim-treesitter.configs").setup({
  auto_install = true,
  highlight = { enable = true },
})
