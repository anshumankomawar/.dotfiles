-- Oil
vim.pack.add({
  "https://github.com/stevearc/oil.nvim",
})

-- Hardtime
vim.pack.add({
  "https://github.com/m4xshen/hardtime.nvim",
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
          { "label",     "label_description", gap = 1 },
          { "kind_icon", "kind" }
        },
      }
    },
  },
  signature = { enabled = true }
})

-- Git
vim.pack.add({
  "https://github.com/tpope/vim-fugitive",
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
  { src = "https://github.com/ThePrimeagen/harpoon/", branch = "harpoon2", name = "harpoon" },
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

-- treesitter support
vim.pack.add({
  "https://github.com/nvim-treesitter/nvim-treesitter",
})

---@diagnostic disable-next-line: missing-fields
require("nvim-treesitter.configs").setup({
  auto_install = true,
  highlight = {
    enable = true,
  }
})

---------------------------------------------------------
vim.pack.add({
  { src = 'https://github.com/ibhagwan/fzf-lua', version = "main" },
  -- 'https://github.com/elanmed/fzf-lua-frecency.nvim',
})

require 'fzf-lua'.setup({
  fzf_colors = {
    false,
    -- ["fg"] = { "fg", "Normal" },
    -- ["fg+"] = { "fg", "Normal" },
    -- ["fg"] = { "fg", "Normal" },
    -- ["bg"] = { "bg", "Normal" },
    -- ["bg+"] = { "bg", "CursorLine" },
    -- ["fg+"] = { "Normal" },
    -- ["hl"] = { "fg", "FzfLuaFzfMatch" },
    -- ["separator"] = { "bg", "Normal" },
    -- ["hl+"] = { "fg", "FzfLuaFzfMatch" },
    -- ["info"] = { "fg", "Normal" },
    -- ["prompt"] = { "fg", "Normal" },
    -- ["pointer"] = "-1",
    -- ["marker"] = "-1",
    -- ["spinner"] = { "fg", "Normal" },
    -- ["header"] = { "fg", "Normal" },
    ["gutter"] = "-1",
  },
  winopts = {
    split = "belowright 10new",
    title = false,
    title_flags = false,
    preview = {
      hidden = true,
    },
    on_create = function()
      vim.schedule(function()
        local info = require("fzf-lua").get_info()
        local picker = info and info.cmd or "fzf"
        local cwd = info and info.cwd or vim.fn.getcwd()
        cwd = vim.fn.fnamemodify(cwd, ":~:.")

        vim.wo.statusline = string.format(
          "%s: %s ",
          picker,
          cwd
        )
      end)
    end,
  },
  files = {
    -- file icons are distracting
    file_icons = "mini",
    -- git icons are nice
    git_icons = false,
    -- but don't mess up my anchored search
    _fzf_nth_devicons = true,
  },
  buffers = {
    file_icons = false,
    git_icons = true,
    -- no nth_devicons as we'll do that
    -- manually since we also use
    -- with-nth
  },
  fzf_args = "--pointer=",
  fzf_opts = {
    ["--no-separator"] = "",
    -- ["--prompt"] = "",
    ["--pointer"] = " ",
    ["--layout"] = "default",
  },
});

vim.keymap.set('n', '<leader>ff', require("fzf-lua").files, opts)
vim.keymap.set('n', '<leader>fg', require("fzf-lua").live_grep, opts)
