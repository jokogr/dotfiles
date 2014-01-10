set nocompatible
filetype off

set rtp+=~/.vim/bundle/vundle/
call vundle#rc()

Bundle 'gmarik/vundle'
Bundle 'w0ng/vim-hybrid'
Bundle 'bling/vim-airline'
Bundle 'kien/ctrlp.vim'
Bundle 'ervandew/supertab'
Bundle 'tpope/vim-commentary'

filetype plugin indent on

syntax on
colorscheme hybrid
set colorcolumn=+1

set mouse=a

let g:airline_powerline_fonts = 1
let g:airline#extensions#tabline#enabled = 1

" keyboard shortcuts
let mapleader = ','
nmap <leader>b :CtrlPBuffer<CR>
nmap <leader>p :CtrlP<CR>
nmap <leader>P :CtrlPClearCache<CR>:CtrlP<CR>

autocmd FileType c setlocal cindent softtabstop=4 sw=4 tabstop=4 et
