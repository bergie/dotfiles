vim.opt.relativenumber = true

local opts = { noremap = true, silent = true }

vim.keymap.set("i", "jj", "<ESC>", opts)
