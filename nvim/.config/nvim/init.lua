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

vim.opt.ignorecase = true
vim.opt.smartcase = true

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

-- LSP functionality
vim.lsp.config['vtsls'] = {
  cmd = { 'vtsls', '--stdio' },
  filetypes = { 'javascript', 'typescript' },
  root_markers = { 'package-lock.json', 'yarn.lock', 'pnpm-lock.yaml', 'bun.lockb', 'bun.lock' },
}
vim.lsp.enable('vtsls')
vim.diagnostic.config({
    virtual_lines = {
        current_line = true,
    },
})
vim.api.nvim_create_autocmd('LspAttach', {
  callback = function(args)
    local bufnr = args.buf
    local map = function(mode, lhs, rhs, desc)
      vim.keymap.set(mode, lhs, rhs, { buffer = bufnr, desc = desc })
    end

    map('n', 'K', vim.lsp.buf.hover, 'LSP Hover')
    map('n', 'gd', vim.lsp.buf.definition, 'Go to definition')
    map('n', 'gi', vim.lsp.buf.implementation, 'Go to implementation')
    map('n', 'gr', vim.lsp.buf.references, 'References')
  end,
})
