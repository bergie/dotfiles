set nocompatible

" UI
colors zenburn
syntax on
set number
set guioptions-=m
set guioptions-=T
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
set incsearch
set hlsearch
set showmatch

" Indentation
set autoindent

" Tab behaviour
set tabstop=4
set shiftwidth=4
set softtabstop=4
set expandtab

" Folding settings
set foldmethod=indent
set foldlevel=1

" Load additional modules
call pathogen#runtime_append_all_bundles()

" Language-specific configs
let coffee_compile_on_save = 1
