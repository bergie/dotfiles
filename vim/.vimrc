set nocompatible
syntax enable
set encoding=utf-8
set enc=utf-8
set fileencoding=utf-8
set fileencodings=ucs-bom,utf8,prc
" Display incomplete commands
set showcmd
filetype plugin indent on

" Disable folding by default
set nofoldenable

"Reasonable line movement"
nnoremap j gj
nnoremap k gk
vnoremap j gj
vnoremap k gk

" In Normal mode, arrow keys switch windows
nnoremap <up> <C-w><up>
nnoremap <down> <C-w><down>
nnoremap <left> <C-w><left>
nnoremap <right> <C-w><right>
" In Insert mode, disable arrow keys
inoremap <up> <nop>
inoremap <down> <nop>
inoremap <left> <nop>
inoremap <right> <nop>

" Whitespace handling
set tabstop=2 shiftwidth=2  " Tab is two spaces
set expandtab               " Use spaces, not tabs
set backspace=indent,eol,start " Backspace through everything

" Indentation
set autoindent

" UI
set t_Co=256
set background=dark
" colors flowhub
colors zenburn
set number                  " Line numbering"
set guioptions-=m           " Remove menu in GUI
set guioptions-=T           " Remove toolbar in GUI
set showmode

" Style vertical splits
set fillchars+=vert:\ 

" Visualize tabs and linebreaks
set list
set listchars=tab:▸\ ,eol:¬

" Nicer visualization for linting errors and warnings
let g:ale_echo_msg_format = '[%linter%] %s [%severity%]'
let g:ale_sign_error = "◉"
let g:ale_sign_warning = '•'
highlight link ALEErrorSign    Error
highlight link ALEWarningSign  Warning

" Improve NerdTree looks
let NERDTreeMinimalUI = 1
let NERDTreeDirArrows = 1

" Improve Airline status bar
let g:airline_theme='zenburn'
let g:airline#parts#ffenc#skip_expected_string='utf-8[unix]'
let g:airline_powerline_fonts = 1

set ruler

" Keyboard mappings, Ctrl-X, C, V
vnoremap <C-X> "+x
vnoremap <C-C> "+y
map <C-V> "+gP

" jj for escape
imap jj <Esc>

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

" Open NerdTree on start-up if given a directory path
autocmd StdinReadPre * let s:std_in=1
autocmd VimEnter * if argc() == 1 && isdirectory(argv()[0]) && !exists("s:std_in") | exe 'NERDTree' argv()[0] | wincmd p | ene | endif
" Ctrl-N for opening/closing NerdTree
map <C-n> :NERDTreeToggle<CR>
" Close NerdTree automatically after opening a file
let NERDTreeQuitOnOpen = 1
" Show dotfiles by default
let NERDTreeShowHidden=1
