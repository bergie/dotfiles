set nocompatible

" UI
colors zenburn
syntax on
set number
set guioptions-=m
set guioptions-=T
set showmode

set ruler

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
