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
Bundle 'LaTeX-Box-Team/LaTeX-Box'

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

" Allow saving of files as sudo when I forgot to start vim using sudo.
cmap w!! w !sudo tee > /dev/null %

autocmd FileType c,cpp setlocal cindent softtabstop=4 sw=4 tabstop=4 et tw=80
