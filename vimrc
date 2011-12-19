set nocompatible
syntax enable
set encoding=utf-8
" Display incomplete commands
set showcmd
filetype plugin indent on

" Whitespace handling
set tabstop=2 shiftwidth=2  " Tab is two spaces
set expandtab               " Use spaces, not tabs
set backspace=indent,eol,start " Backspace through everything

" Indentation
set autoindent

" UI
"set t_Co=256
colors zenburn
set number                  " Line numbering"
set guioptions-=m           " Remove menu in GUI
set guioptions-=T           " Remove toolbar in GUI
set showmode

set ruler

" Keyboard mappings, Ctrl-X, C, V
vnoremap <C-X> "+x
vnoremap <C-C> "+y
map <C-V> "+gP

" Always be in the directory of the file
"set autochdir We use rooter now

" Backups in one place
set backup
set backupdir=~/.vim/backup
set directory=~/.vim/tmp

" Nicer searching
set incsearch               " Incremental searching
set hlsearch                " Highlight matches
set showmatch               " Show match numbers
set ignorecase              " Search case-insensitive
set smartcase               " ...except when something is capitalized

" File navigation
let mapleader=","           " Use comma as <leader>

" Search files in project with ,f
map <leader>f :CommandTFlush<cr>\|:CommandT<cr>
" Search files in directory with ,F
map <leader>F :CommandTFlush<cr>\|:CommandT %%<cr>

" Load additional modules
call pathogen#runtime_append_all_bundles()

" Language-specific configs
let coffee_compile_on_save = 1
