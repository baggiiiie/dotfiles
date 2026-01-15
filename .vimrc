set scrolloff=20

set nocompatible
set cursorline

set clipboard=unnamed
set shiftwidth=4
set tabstop=4
set expandtab

set backspace=indent,eol,start
set autoindent

" don't use ex mode, use q for formatting.
map Q gq
set number
set relativenumber
set showcmd
set showmode
syntax on

""" Search
set hlsearch
nmap <esc> :noh <CR>
set incsearch
set ignorecase
set smartcase
set showmatch
set colorcolumn=80
set noswapfile

nmap H g^
nmap L g$
vmap H g^
vmap L g$

map <C-a> <ESC>^
imap <C-a> <ESC>I
vmap <C-a> g^
xmap <C-a> g^
map <C-e> <ESC>$
imap <C-e> <ESC>A
vmap <C-e> g$
xmap <C-e> g$

imap <C-k> <ESC>C
nnoremap <CR> o<Esc>k
"" map zl 20zl " Scroll 20 characters to the right
"" map zh 20zh " Scroll 20 characters to the left


nmap zx :togglefold


let mapleader=" "
nmap <leader>( viwS(
nmap <leader>) viwS)
nmap <leader>" viwS"
nmap <leader>[ viwS[
nmap <leader>] viwS]
nmap <leader>{ viwS{
nmap <leader>} viwS}

noremap <leader>y "*y
noremap <leader>p "*p
" map <expr> M printf('`%c zz',getchar()) 
nnoremap <expr> ' "'" . nr2char(getchar()) . 'zz'
nnoremap <expr> ` "`" . nr2char(getchar()) . 'zz'


