vim.pack.add({
  "https://github.com/stevearc/oil.nvim",
  "https://github.com/dmtrKovalenko/fff.nvim",
  { src = "https://github.com/saghen/blink.cmp", version = vim.version.range("^1") },
  "https://github.com/tpope/vim-fugitive",
  { src = "https://github.com/ThePrimeagen/harpoon/", branch = "harpoon2", name = "harpoon" },
  "https://github.com/nvim-lua/plenary.nvim",
  "https://github.com/nvim-treesitter/nvim-treesitter",
})

vim.cmd.packadd('minibuffer.nvim')

vim.api.nvim_create_autocmd('PackChanged', {
  callback = function(event)
    if event.data.updated then
      require('fff.download').download_or_build_binary()
    end
  end,
})

-- the plugin will automatically lazy load
vim.g.fff = {
  lazy_sync = true, -- start syncing only when the picker is open
  debug = {
    enabled = true,
    show_scores = true,
  },
}

vim.keymap.set(
  'n',
  'ff',
  function() require('fff').find_files() end,
  { desc = 'FFFind files' }
)
vim.keymap.set(
  'n',
  'fg',
  function() require('minibuffer.examples.live-grep')() end,
  { desc = 'Minibuffer live grep' }
)

local minibuffer = require("minibuffer")
vim.ui.select = require("minibuffer.builtin.ui_select")
vim.ui.input = require("minibuffer.builtin.ui_input")

local picker_ui = require("fff.picker_ui")
picker_ui.open = require("minibuffer.integrations.fff")

-- vim.keymap.set("n", "<M-;>", require("minibuffer.builtin.cmdline"))
-- vim.keymap.set("n", "<M-.>", function()
--   minibuffer.resume(true)
-- end)

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
  columns = {
    "permissions",
    "size",
    "mtime",
  },
  delete_to_trash = true,
  skip_confirm_for_simple_edits = true,
  prompt_save_on_select_new_entry = false,
  lsp_file_methods = {
    enabled = true,
    timeout_ms = 1000,
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

require('blink.cmp').setup({
  completion = {
    menu = {
      draw = {
        columns = {
          { "label",     "label_description", gap = 1 },
          { "kind" }
        },
      }
    },
  },
  signature = { enabled = false }
})

local harpoon = require("harpoon")
harpoon:setup()

vim.keymap.set("n", "<leader>H", function() harpoon:list():add() end, { desc = "Harpoon File" })
vim.keymap.set("n", "<leader>e", require("minibuffer.integrations.harpoon"), { desc = "Harpoon Quick Menu" })

for i = 1, 5 do
  vim.keymap.set("n", "<leader>" .. i, function()
    harpoon:list():select(i)
  end, { desc = "Harpoon to File " .. i })
end

---@diagnostic disable-next-line: missing-fields
require("nvim-treesitter.configs").setup({
  auto_install = true,
  highlight = {
    enable = true,
  }
})
