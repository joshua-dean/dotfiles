""" [Pathogen]
execute pathogen#infect()

""" [vim-plug]
call plug#begin()
Plug 'sillybun/vim-repl'
call plug#end()
" REPLToggle bind
nnoremap <leader>r :REPLToggle<Cr>

""" [General Settings]
syntax on
filetype plugin indent on
set indentexpr=""
set number
set relativenumber


""" [Commands]
" Python Main Block
command! MainBlock execute "normal! Goif __name__ == \"__main__\":<Esc>opass<Esc>"
command! MB MainBlock

" Aliases for [vim-argwrap](https://git.foosoft.net/alex/vim-argwrap)
command! AW ArgWrap

" Expand DocStr
command! DocStrWrap execute "normal! F\"a<Return><Esc>f\"i<Return><Esc>"
command! DSW DocStrWrap

" Copy all
command! CPA execute "normal! maggVG\"+y`a<Esc>"

" Delete all
command! DA execute "normal! ggVGd"

" Paste
command! P execute "normal! \"+p"

" Paste inside quotes
command! PIQ execute "normal! T\"dt\"\"+P"

" Yank inside quotes
command! YIQ execute "normal! T\"vt\"\"+y"

