vim.pack.add({
  "https://github.com/stevearc/oil.nvim",
  "https://github.com/dmtrKovalenko/fff.nvim",
  "https://github.com/tpope/vim-fugitive",
  "https://github.com/nvim-lua/plenary.nvim",
  "https://github.com/nvim-treesitter/nvim-treesitter",
  "https://github.com/mason-org/mason.nvim",
  "https://github.com/neovim/nvim-lspconfig",
  "https://github.com/mfussenegger/nvim-jdtls",
  "https://github.com/ziglang/zig.vim",
})

vim.cmd.packadd("minibuffer.nvim")
vim.cmd.packadd('nvim.undotree')
vim.cmd.packadd('nvim.difftool')

vim.g.mapleader = " "
vim.o.cmdheight = 0

require("vim._core.ui2").enable({
  enable = true,
  msg = { targets = "msg" },
})

vim.opt.number = true
vim.opt.relativenumber = true
vim.opt.ignorecase = true
vim.opt.smartcase = true
vim.opt.completeopt = { "menu", "menuone", "fuzzy", "noinsert" }
vim.opt.swapfile = false
vim.opt.termguicolors = true
vim.opt.pumheight = 10
vim.opt.wildoptions:append { "fuzzy" }
vim.opt.wildignore = "*.o,*.obj,*.pyc,*.class,node_modules/**,.git/**,target/**,build/**"
vim.opt.path:append { "**" }
vim.opt.smoothscroll = true
vim.opt.grepprg = "rg --vimgrep --no-messages --smart-case"
vim.opt.grepformat = "%f:%l:%c:%m"
vim.opt.undofile = true
vim.opt.undodir = vim.fn.stdpath("cache") .. "/nvim/undodir"
vim.opt.linebreak = true
vim.opt.numberwidth = 1
vim.opt.guicursor = "i:block"
vim.opt.laststatus = 3
vim.opt.cmdheight = 0
vim.opt.scrolloff = 15
vim.opt.signcolumn = "number"
vim.opt.splitright = true
vim.opt.splitbelow = true
vim.opt.shiftwidth = 2
vim.opt.tabstop = 2
vim.opt.smartindent = true
vim.opt.incsearch = true
vim.opt.hlsearch = false
vim.opt.showmatch = true

local keymap = vim.keymap.set
keymap("t", "<ESC>", "<C-\\><C-n>", { noremap = true })

keymap("n", "<leader>h", "<cmd>wincmd h<CR>", { silent = true })
keymap("n", "<leader>j", "<cmd>wincmd j<CR>", { silent = true })
keymap("n", "<leader>k", "<cmd>wincmd k<CR>", { silent = true })
keymap("n", "<leader>l", "<cmd>wincmd l<CR>", { silent = true })

keymap("n", "grd", vim.lsp.buf.definition)
keymap("n", "<leader>=", "<cmd>resize +1<CR>", { silent = true })
keymap("n", "<leader>-", "<cmd>resize -1<CR>", { silent = true })

keymap("v", "<C-c>", '"+y')
keymap("v", "J", ":m '>+1<CR>gv=gv")
keymap("v", "K", ":m '<-2<CR>gv=gv")
keymap("n", "J", "mzJ`z")
keymap("n", "<C-d>", "<C-d>zz")
keymap("n", "<C-u>", "<C-u>zz")
keymap("n", "n", "nzzzv")
keymap("n", "N", "Nzzzv")
keymap("x", "<leader>p", [["_dP]])
keymap({ "n", "v" }, "<leader>y", [["+y]])
keymap("n", "<leader>Y", [["+Y]])
keymap("n", "<leader>s", [[:%s/\<<C-r><C-w>\>/<C-r><C-w>/gI<Left><Left><Left>]])

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
elseif theme == "gruvbox" then
  vim.pack.add({ "https://github.com/ellisonleao/gruvbox.nvim" })
  require("gruvbox").setup({ contrast = "hard" })
elseif theme == "zenwritten" then
  vim.pack.add({ "https://github.com/zenbones-theme/zenbones.nvim", "https://github.com/rktjmp/lush.nvim" })
  vim.opt.background = "dark"
end

vim.cmd.colorscheme(theme)
vim.api.nvim_set_hl(0, "Winbar", { link = "Normal" })
vim.api.nvim_set_hl(0, "WinbarNC", { link = "Normal" })

-- Experimental MiniBuffer
vim.ui.select = require("minibuffer.builtin.ui_select")
vim.ui.input = require("minibuffer.builtin.ui_input")

vim.g.fff = { lazy_sync = true, debug = { enabled = true, show_scores = true } }
require("fff.picker_ui").open = require("minibuffer.integrations.fff")

keymap("n", "ff", function() require("fff").find_files() end)
keymap("n", "fg", function() require("minibuffer.examples.live-grep")() end)

vim.cmd.packadd("compile.nvim")
local compile = require("compile-mode")
compile.setup({ height = 10 })
keymap("n", "cc", function() compile.recompile() end)
keymap("n", "cC", function() compile.prompt() end)
keymap("n", "ce", function() compile.first_error() end)
keymap("n", "]e", function() compile.next_error() end)
keymap("n", "[e", function() compile.prev_error() end)

function _G.get_oil_winbar()
  local bufnr = vim.api.nvim_win_get_buf(vim.g.statusline_winid)
  local dir = require("oil").get_current_dir(bufnr)
  if dir then return vim.fn.fnamemodify(dir, ":~") else return vim.api.nvim_buf_get_name(0) end
end

require("oil").setup({
  default_file_explorer = true,
  columns = { "permissions", "size", "mtime" },
  delete_to_trash = true,
  skip_confirm_for_simple_edits = true,
  prompt_save_on_select_new_entry = false,
  lsp_file_methods = { enabled = true, timeout_ms = 1000, autosave_changes = false },
  win_options = { winbar = "%!v:lua.get_oil_winbar()" },
})

keymap("n", "<leader>.", function()
  if vim.bo.filetype == "oil" then require("oil.actions").close.callback() else vim.cmd("Oil") end
end)

vim.api.nvim_create_autocmd('FileType', {
    callback = function()
      pcall(vim.treesitter.start)
      vim.bo.indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
    end,
})

vim.api.nvim_create_autocmd('LspAttach', {
    callback = function(args)
        local client = assert(vim.lsp.get_client_by_id(args.data.client_id))
        if client:supports_method('textDocument/completion') then
            vim.o.complete = 'o,.,w,b,u'
            vim.o.completeopt = 'menu,menuone,popup,noinsert'
            vim.lsp.completion.enable(true, client.id, args.buf)
        end
    end
})

vim.lsp.config('lua_ls', {
  settings = {
    Lua = {
      runtime = { version = "Lua 5.4" },
      diagnostics = { globals = { "vim" } },
      workspace = { library = { vim.env.VIMRUNTIME }, checkThirdParty = false },
    },
  },
})
vim.lsp.config('zls', {
  settings = {
    zls = { enable_build_on_save = false, semantic_tokens = "partial" },
  },
})
vim.lsp.config('ts_ls', { init_options = { hostInfo = "neovim" } })
vim.lsp.enable({ "lua_ls", "zls", "ts_ls", "ruff", "ty", "gopls" })

vim.diagnostic.config({
  underline = true,
  virtual_text = false,
  virtual_lines = false,
  signs = false,
  update_in_insert = false,
  severity_sort = true,
})

vim.g.zig_fmt_parse_errors = 0
