set nocompatible

call plug#begin('~/.vim/plugged')

Plug 'w0ng/vim-hybrid'
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

" Git
Plug 'tpope/vim-fugitive'
Plug 'gregsexton/gitv', { 'on': 'Gitv' }
if v:version >= 703
  Plug 'mhinz/vim-signify'
endif

call plug#end()

filetype plugin indent on

syntax on
colorscheme hybrid
set background=dark

set textwidth=0
if exists('&colorcolumn')
  set colorcolumn=80
endif

set mouse=a

set autoindent
set smartindent
set tabstop=2
set shiftwidth=2
set expandtab smarttab
set foldlevelstart=99

set formatoptions+=1
if has('patch-7.3.541')
  set formatoptions+=j
endif
if has('patch-7.4.338')
  let &showbreak = '↳ '
  set breakindent
  set breakindentopt=sbr
endif

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

if filereadable(expand("~/.vimrc.local"))
  source ~/.vimrc.local
endif
