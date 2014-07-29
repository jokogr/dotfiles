set nocompatible
filetype off

set rtp+=~/.vim/bundle/Vundle.vim
call vundle#begin()

Plugin 'https://git.joko.gr/joko/vundle-vim.git'
Plugin 'w0ng/vim-hybrid'
Plugin 'bling/vim-airline'
Plugin 'kien/ctrlp.vim'
Plugin 'ervandew/supertab'
Plugin 'tpope/vim-commentary'
Plugin 'LaTeX-Box-Team/LaTeX-Box'
Plugin 'mileszs/ack.vim'
Plugin 'tpope/vim-surround'
Plugin 'tpope/vim-repeat'

call vundle#end()
filetype plugin indent on

syntax on
colorscheme hybrid
set colorcolumn=+1

set mouse=a

let g:airline_powerline_fonts = 1
let g:airline#extensions#tabline#enabled = 1

let g:ackprg = 'ag --nogroup --nocolor --column'

let g:tex_flavor='latex'
let g:LatexBox_latexmk_options
                        \ = "-pdflatex='pdflatex -synctex=1 \%O \%S'"

" keyboard shortcuts
let mapleader = ','
nmap <leader>b :CtrlPBuffer<CR>
nmap <leader>p :CtrlP<CR>
nmap <leader>P :CtrlPClearCache<CR>:CtrlP<CR>

" Allow saving of files as sudo when I forgot to start vim using sudo.
cmap w!! w !sudo tee > /dev/null %

autocmd FileType c,cpp setlocal cindent softtabstop=4 sw=4 tabstop=4 et tw=80
autocmd FileType html,tex setlocal sts=2 sw=2 ts=2 noet
