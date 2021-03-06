set nocompatible

call plug#begin('~/.vim/plugged')

Plug 'w0ng/vim-hybrid'
Plug 'junegunn/vim-emoji'
Plug 'junegunn/fzf', { 'dir': '~/.fzf', 'do': 'yes \| ./install --bin' }
Plug 'junegunn/fzf.vim'
Plug 'tpope/vim-commentary'
Plug 'lervag/vimtex'
Plug 'mileszs/ack.vim'
Plug 'tpope/vim-surround'
Plug 'tpope/vim-repeat'
Plug 'junegunn/vim-easy-align'
Plug 'junegunn/goyo.vim'
Plug 'neomake/neomake'
Plug 'LnL7/vim-nix'

" Browsing
Plug 'Yggdroot/indentLine', { 'on': 'IndentLinesEnable' }
autocmd! User indentLine doautocmd indentLine Syntax

Plug 'justinmk/vim-gtfo'

" Git
Plug 'tpope/vim-fugitive'
Plug 'gregsexton/gitv', { 'on': 'Gitv' }
if v:version >= 703
  Plug 'mhinz/vim-signify'
endif

" Lang
Plug 'pangloss/vim-javascript'
Plug 'plasticboy/vim-markdown'

Plug 'lambdalisue/suda.vim'

call plug#end()

filetype plugin indent on

syntax on
set guifont=Source\ Code\ Pro\ for\ Powerline\ Regular\ 13
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

set statusline=%<[%n]\ %F\ %m%r%y\ %{exists('g:loaded_fugitive')?fugitive#statusline():''}\ %=%-14.(%l,%c%V%)\ %P

silent! if emoji#available()
  let s:ft_emoji = map({
    \ 'javascript': 'monkey',
    \ 'markdown': 'book'
    \ }, 'emoji#for(v:val)')

  function! S_filetype()
    if empty(&filetype)
      return emoji#for('grey_question')
    else
      return get(s:ft_emoji, &filetype, '['.&filetype.']')
    endif
  endfunction

  function! S_modified()
    if &modified
      return emoji#for('kiss').' '
    elseif !&modifiable
      return emoji#for('construction').' '
    else
      return ''
    endif
  endfunction

  function! S_fugitive()
    if !exists('g:loaded_fugitive')
      return ''
    endif
    let head = fugitive#head()
    if empty(head)
      return ''
    else
      return head == 'master' ? emoji#for('crown') : emoji#for('dango').'='.head
    endif
  endfunction

  let s:braille = split('"⠉⠒⠤⣀', '\zs')
  function! Braille()
    let len = len(s:braille)
    let [cur, max] = [line('.'), line('$')]
    let pos  = min([len * (cur - 1) / max([1, max - 1]), len - 1])
    return s:braille[pos]
  endfunction

  hi def link User1 TablineFill
  let s:cherry = emoji#for('cherry_blossom')
  function! MyStatusLine()
    let mod = '%{S_modified()}'
    let ro  = "%{&readonly ? emoji#for('lock') . ' ' : ''}"
    let ft  = '%{S_filetype()}'
    let fug = ' %{S_fugitive()}'
    let sep = ' %= '
    let pos = ' %l,%c%V '
    let pct = ' %P '

    return s:cherry.' [%n] %F %<'.mod.ro.ft.fug.sep.pos.'%{Braille()}%*'.pct.s:cherry
  endfunction

  " Note that the "%!" expression is evaluated in the context of the
  " current window and buffer, while %{} items are evaluated in the
  " context of the window that the statusline belongs to.
  set statusline=%!MyStatusLine()
endif

highlight ExtraWhitespace ctermbg=LightRed guibg=LightRed
au BufNewFile,BufRead,InsertLeave * silent! match ExtraWhitespace /\s\+$/
au InsertEnter * silent! match ExtraWhitespace /\s\+\%#\@<!$/

if executable('rg')
  let g:ackprg = 'rg --vimgrep'
endif

" indentLine
let g:indentLine_enabled = 0

" vimtex
let g:tex_flavor = 'latex'
let g:vimtex_view_method = 'zathura'

" neomake
let g:neomake_javascript_enabled_makers = ['eslint']

" vim-easy-align options
xmap ga <Plug>(EasyAlign)
nmap ga <Plug>(EasyAlign)

" vim-gtfo
let g:gtfo#terminals = { 'unix' : 'urxvtc -cd' }

" vim-markdown options
let g:vim_markdown_initial_foldlevel = &foldlevelstart

" keyboard shortcuts
let mapleader      = ' '
let maplocalleader = ' '

nmap     <leader>b :Buffers<CR>
nmap     <leader>f :Files<CR>
nnoremap <leader>c :cclose<bar>lclose<cr>
inoremap <C-d>     <C-^>

" Allow saving of files as sudo when I forgot to start vim using sudo.
"cmap w!! w !sudo tee > /dev/null %
cmap w!! w suda://%

autocmd FileType groovy setlocal shiftwidth=4 tabstop=8 softtabstop=4 expandtab

if filereadable(expand("~/.vimrc.local"))
  source ~/.vimrc.local
endif
