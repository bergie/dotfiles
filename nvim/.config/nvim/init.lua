vim.opt.relativenumber = true
vim.opt.termguicolors = true
vim.opt.showmode = true

vim.opt.undofile = true
vim.opt.backup = false
vim.opt.writebackup = false

vim.opt.expandtab = true
vim.opt.tabstop = 4
vim.opt.shiftwidth = 0

vim.opt.scrolloff = 3

local opts = { noremap = true, silent = true }

vim.keymap.set("i", "jj", "<ESC>", opts)

-- In Normal mode, arrow keys switch windows
vim.keymap.set("n", "<up>", "<C-w><up>", opts)
vim.keymap.set("n", "<down>", "<C-w><down>", opts)
vim.keymap.set("n", "<left>", "<C-w><left>", opts)
vim.keymap.set("n", "<right>", "<C-w><right>", opts)
-- In Insert mode, disable arrow keys
vim.keymap.set("i", "<up>", "<nop>", opts)
vim.keymap.set("i", "<down>", "<nop>", opts)
vim.keymap.set("i", "<left>", "<nop>", opts)
vim.keymap.set("i", "<right>", "<nop>", opts)

vim.cmd([[colorscheme tokyonight]])
