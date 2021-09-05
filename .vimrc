"================================================
" Notes to self
"================================================
" Install Ctags `brew install ctags`
" Install theme
" Install Vundle and plugins (:PluginInstall)
"
"================================================




set nocompatible                                        "Use the latest vim settings/options
so ~/.vim/plugins.vim
syntax enable

set backspace=indent,eol,start                          "Make backspace work like every other editor
let mapleader = ','                                     "The default leader is \, but a comma is better





"============== Plugins ===================="

"/
"/ CtrlP
"/
"let g:ctrlp_custom_ignore = 'node_modules\DS_Store\|git'
let g:ctrlp_custom_ignore = { 'dir': 'build$\|node_modules$\|.git$' }
let g:ctrlp_match_window = 'top,order:ttb,min:1,max:30,results:30'

"/
"/ NERDTree
"/
let NERDTreeHijackNetrw = 0




"============== Search ===================="
set hlsearch                                            "Highlight search
set incsearch                                           "Takes you to the search location





"============== Split management ===================="
set splitbelow                                          "Makes sure new horizontal splits are created below
set splitright                                          "Makes sure new vertical splits are created to the right

"Mapping for splits to use e.g ctrl+l to switch between vertical splits
nmap <C-J> <C-W><C-J>
nmap <C-K> <C-W><C-K>
nmap <C-H> <C-W><C-H>
nmap <C-L> <C-W><C-L>





"============== Visuals ===================="
colorscheme atom-dark-256
set t_CO=256                                            "Use 256 colors. This is useful for Terminal vim
set guifont=JetBrains_Mono:h16
set nonumber                                            "Remove line numbers. Use number to reactivate it
set linespace=15                                        "Set the line height but only works on GUI vim
"set macligatures                                       "Pretty symbols when available

set guioptions-=l                                       "Hide scrollbar for the left
set guioptions-=L
set guioptions-=r                                       "Hide scrollbar for the right
set guioptions-=R





"Fake custom left padding
set foldcolumn=2
hi LineNr guibg=bg ctermbg=bg
hi FoldColumn guibg=bg ctermbg=bg

"Hide the vertical split
hi VertSplit ctermfg=bg ctermbg=bg guibg=bg guifg=bg





"============== Mappings ===================="

"Make it easy to edit the Vimrc file
nmap <Leader>ev :tabedit ~/.vimrc<cr>

"Highlight removal command
nmap <Leader><space> :nohlsearch<cr>

"Make NERDTree easier to toggle
nmap <c-B> :NERDTreeToggle<cr>

"Search symbols, may require 'sudo apt-get install exuberant-ctags' or 'brew install ctags'
nmap <c-R> :CtrlPBufTag<cr>

"Go to recent files
nmap <c-E> :CtrlPMRUFiles<cr>





"============== Auto-Commands ===================="

augroup autosourcing
        autocmd!
        "Automatically source the vimrc file on save
        autocmd BufWritePost .vimrc source %
augroup END
