vim.g.mapleader = " "

local opt = vim.opt
local keymap = vim.keymap.set

-- general
opt.swapfile = false
opt.autochdir = false
opt.autoread = true
opt.exrc = true
opt.errorbells = false
opt.visualbell = false
opt.backup = false
opt.updatetime = 50

-- undo
opt.undodir = vim.fn.stdpath("cache") .. "/nvim/undodir"
opt.undofile = true

-- completion
opt.completeopt = { "menuone", "menu", "fuzzy" }
opt.pumheight = 10

-- lines
opt.relativenumber = true
opt.nu = true
opt.wrap = false
opt.numberwidth = 1
opt.ruler = true

-- search
opt.path = ".,**"
opt.wildignore = "*.o,*.obj,*.pyc,*.class,node_modules/**,.git/**,target/**,build/**"
opt.wildmenu = true
opt.grepprg = "rg --vimgrep --hidden --smart-case"
opt.grepformat = "%f:%l:%c:%m"
opt.incsearch = true
opt.hlsearch = false
opt.shortmess:append("c")

-- display
opt.guicursor = "i:block"
opt.termguicolors = true
opt.showmatch = true
opt.splitright = true
opt.splitbelow = true
opt.ignorecase = true
opt.smartcase = true
opt.laststatus = 3
opt.cmdheight = 0
opt.scrolloff = 15
opt.signcolumn = "number"

-- perf
opt.hidden = true
opt.history = 100
opt.lazyredraw = true

-- indents
opt.expandtab = true
opt.shiftwidth = 2
opt.tabstop = 2
opt.smartindent = true

-- commands
vim.api.nvim_create_user_command("G", function(opts)
  vim.cmd("silent grep! " .. opts.args)
  vim.cmd("copen")
end, { nargs = "+" })

-- keymaps
keymap("t", "<ESC>", "<C-\\><C-n>", { noremap = true })
keymap("n", "<leader>h", "<cmd>wincmd h<CR>", { silent = true })
keymap("n", "<leader>j", "<cmd>wincmd j<CR>", { silent = true })
keymap("n", "<leader>k", "<cmd>wincmd k<CR>", { silent = true })
keymap("n", "<leader>l", "<cmd>wincmd l<CR>", { silent = true })
keymap("n", "<leader>fmt", "<cmd>Format<CR>")
keymap("n", "<leader>q", "<cmd>xa<CR>")
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

-- autocmds
vim.api.nvim_create_autocmd("FileType", {
  pattern = "markdown",
  callback = function()
    vim.opt_local.makeprg = "make -C %:p:h/.. 2>&1"
  end,
})
