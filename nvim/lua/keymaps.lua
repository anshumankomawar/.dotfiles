local keymap = vim.keymap.set
local opt = vim.opt
local s = { silent = true }

vim.g.mapleader = " "

--- defaults
opt.swapfile = false  -- don't use swapfile
opt.autochdir = false -- auto change current working dir
opt.autoread = true
opt.exrc = true
opt.errorbells = false                                   -- don't use error bells
opt.visualbell = false
opt.backup = false                                       -- don't store file backups
opt.updatetime = 50                                      -- neovim refresh rate (ms)
--- undo
opt.undodir = vim.fn.stdpath('cache') .. '/nvim/undodir' -- path to undo directory
opt.undofile = true                                      -- keep undofile
--- pmenu
opt.completeopt = { "menuone", "menu", "fuzzy" }
opt.pumheight = 10
--- lines
opt.relativenumber = true
opt.nu = true    -- show line numbers
opt.wrap = false -- don't wrap lines
opt.numberwidth = 1
opt.ruler = true
--- search
opt.path = ".,**"
opt.wildignore = "*.o,*.obj,*.pyc,*.class,node_modules/**,.git/**,target/**,build/**"
opt.wildmenu = true
opt.grepprg = "rg --vimgrep --hidden --smart-case"
opt.grepformat = "%f:%l:%c:%m"
vim.api.nvim_create_user_command('G', function(opts)
  vim.cmd("silent grep! " .. opts.args)
  vim.cmd("copen")
end, { nargs = '+' })
opt.incsearch = true -- use incremental search
opt.hlsearch = false -- don't highlight search result
opt.shortmess:append('c')
-- graphics
opt.guicursor = "i:block"
opt.termguicolors = true
opt.showmatch = true
opt.splitright = true
opt.splitbelow = true
opt.ignorecase = true
opt.smartcase = true
-- opt.signcolumn = "yes"
opt.laststatus = 3
opt.statusline = "%<%f %h%m%r%=%{%v:lua.require('patch').get_status()%}       %-14.(%l,%c%V%) %P"
opt.cmdheight = 0
opt.scrolloff = 8
-- opt.signcolumn = 'no'
-- perf
opt.hidden = true
opt.history = 100
opt.lazyredraw = true
-- indents
opt.expandtab = true   -- use spaces instead of tabs
opt.shiftwidth = 2     -- shift 4 spaces when tab
opt.tabstop = 2        -- 1 tab == 4 spaces
opt.smartindent = true -- autoindent new lines

keymap("n", "<leader>pu", '<cmd>lua vim.pack.update()<CR>')
keymap('t', '<ESC>', '<C-\\><C-n>', { noremap = true })
keymap('n', '<leader>h', ':wincmd h<CR>', { noremap = true, silent = true })
keymap('n', '<leader>j', ':wincmd j<CR>', { noremap = true, silent = true })
keymap('n', '<leader>k', ':wincmd k<CR>', { noremap = true, silent = true })
keymap('n', '<leader>l', ':wincmd l<CR>', { noremap = true, silent = true })
keymap('n', '<S-Tab>', ':tabprevious<CR>', { noremap = true })
keymap('n', '<leader>t', ':tabnew<CR>', { noremap = true })
keymap('n', '<Leader>+', ':vertical resize +5<CR>', { noremap = true, silent = true })
keymap('n', '<leader>fmt', ':Format<CR>', { noremap = true })
keymap('n', '<leader>q', ':xa<CR>', { noremap = true })
keymap('v', '<C-c>', '"*y', { noremap = true })

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

require("vim._extui").enable {
  enable = true,
  msg = {
    target = 'cmd',
    timeout = 4000
  }
}
