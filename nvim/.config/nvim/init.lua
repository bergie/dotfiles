vim.opt.relativenumber = true
vim.opt.termguicolors = true

local opts = { noremap = true, silent = true }

vim.keymap.set("i", "jj", "<ESC>", opts)

require("zenburn").setup()
