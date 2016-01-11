set nocompatible

call plug#begin('~/.vim/plugged')

Plug 'w0ng/vim-hybrid'
Plug 'bling/vim-airline'
Plug 'junegunn/fzf', { 'dir': '~/.fzf', 'do': 'yes \| ./install --bin' }
Plug 'junegunn/fzf.vim'
Plug 'ervandew/supertab'
Plug 'tpope/vim-commentary'
Plug 'LaTeX-Box-Team/LaTeX-Box'
Plug 'mileszs/ack.vim'
Plug 'tpope/vim-surround'
Plug 'tpope/vim-repeat'
Plug 'junegunn/vim-easy-align'
Plug 'plasticboy/vim-markdown'
Plug 'junegunn/goyo.vim'

call plug#end()

filetype plugin indent on

syntax on
colorscheme hybrid
set background=dark
set colorcolumn=+1

set mouse=a

let g:airline_powerline_fonts = 1
let g:airline#extensions#tabline#enabled = 1

set foldlevelstart=99

let g:ackprg = 'ag --nogroup --nocolor --column'

" LaTeX-BoX options

let g:tex_flavor='latex'
let g:LatexBox_latexmk_options
                        \ = "-pdflatex='pdflatex -synctex=1 \%O \%S'"

" vim-easy-align options
xmap ga <Plug>(EasyAlign)
nmap ga <Plug>(EasyAlign)

" vim-markdown options
let g:vim_markdown_initial_foldlevel = &foldlevelstart

" keyboard shortcuts
let mapleader = ','
nmap <leader>b :Buffers<CR>
nmap <leader>f :Files<CR>

" Allow saving of files as sudo when I forgot to start vim using sudo.
cmap w!! w !sudo tee > /dev/null %

autocmd FileType c,cpp setlocal cindent softtabstop=4 sw=4 tabstop=4 et tw=80
autocmd FileType html,tex setlocal sts=2 sw=2 ts=2 noet

if filereadable(expand("~/.vimrc.local"))
  source ~/.vimrc.local
endif
