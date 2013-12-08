set nocompatible
syntax enable
set encoding=utf-8
set enc=utf-8
set fileencoding=utf-8
set fileencodings=ucs-bom,utf8,prc
" Display incomplete commands
set showcmd
filetype plugin indent on

"Reasonable line movement"
nnoremap j gj
nnoremap k gk
vnoremap j gj
vnoremap k gk

" In Normal mode, Arrow keys switch windows
nnoremap <up> <C-w><up>
nnoremap <down> <C-w><down>
nnoremap <left> <C-w><left>
nnoremap <right> <C-w><right>
" Disable arrow keys
inoremap <up> <nop>
inoremap <down> <nop>
inoremap <left> <nop>
inoremap <right> <nop>

" Load additional modules
call pathogen#infect()

" Whitespace handling
set tabstop=2 shiftwidth=2  " Tab is two spaces
set expandtab               " Use spaces, not tabs
set backspace=indent,eol,start " Backspace through everything

" Indentation
set autoindent

" UI
set t_Co=256
set background=dark
" colorscheme solarized
colors zenburn
set number                  " Line numbering"
set guioptions-=m           " Remove menu in GUI
set guioptions-=T           " Remove toolbar in GUI
set showmode

" Visualize tabs and linebreaks
set list
set listchars=tab:▸\ ,eol:¬

set ruler

" Keyboard mappings, Ctrl-X, C, V
vnoremap <C-X> "+x
vnoremap <C-C> "+y
map <C-V> "+gP

" Always be in the directory of the file
"set autochdir We use rooter now

" Backups in one place
set nobackup
set nowritebackup
set noswapfile

" Nicer searching
set incsearch               " Incremental searching
set hlsearch                " Highlight matches
set showmatch               " Show match numbers
set ignorecase              " Search case-insensitive
set smartcase               " ...except when something is capitalized

" File navigation
let mapleader=","           " Use comma as <leader>

" Switch between relative and absolute line numbers depending on mode
set relativenumber
autocmd InsertEnter * :set number
autocmd InsertLeave * :set relativenumber

" Language-specific configs
let coffee_compile_on_save = 1
