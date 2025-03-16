" Most of my Neovim usage is via vscode,
" which takes care of many common settings

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

""" [vim-argwrap]
" Upstream: https://git.foosoft.net/alex/vim-argwrap
" Fork: https://github.com/joshua-dean/vim-argwrap

" Don't wrap for triple quotes (feature from my fork)
let g:argwrap_tail_comma_braces = '[({'

command! AW ArgWrap

""" [Commands]
" Python Main Block
command! MainBlock execute "normal! Goif __name__ == \"__main__\":<Esc>opass<Esc>"
command! MB MainBlock

" "Empty" Main Block - no "pass". Leaves cursor at start of first line in the main block
command! EmptyMainBlock execute "normal! Goif __name__ == \"__main__\":<Esc>o<Esc>"
command! EMB EmptyMainBlock

" Expand DocStr
command! DocStrWrap execute "normal! F\"a<Return><Esc>f\"i<Return><Esc>"
command! DSW DocStrWrap

" Duplicate and Comment Line
command! DuplicateAndComment execute "normal! yypkI# <Esc>"
command! DAC DuplicateAndComment

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

" Capitalize Booleans (usually when pasting from an external source)
command! CapTrue execute "%s/true/True/g"
command! CapFalse execute "%s/false/False/g"
command! CapBool execute "CapTrue" | execute "CapFalse"
command! CB CapBool

" Coerce `null` to `None` (usually when pasting from an external source)
command CoerceNull execute "%s/null/None/g"
command CN CoerceNull

" Wrap in print (python)
command! WIP execute "normal! ^iprint(<Esc>A)<Esc>"
" Unwrap in print (python) - puts whatever it wrapped on a separate line
" not working correctly rn TODO debug this
" command! UWIP execute "normal! ^iprint(<Enter><Esc>o)"


" 'Best Effort' Split (python, LeetCode)
" Given multiple valid assignment statements on a line, break them into their own lines. e.g.
" a = [3, 4, 5], b = [3, 4, 5]
" goes to
" a = [3, 4, 5]
" b = [3, 4, 5]
" This is tricky as commas enclosed by brackets/parentheses shouldn't get expanded
" Restricting this to a single line so it doesn't go sicko mode on me
command! BES execute "s/\\v(, )(\\w+ =)/\r    \\2/g"

""" [LeetCode Parsing Commands]
" These are to parse examples/test cases I copy-pasta from LeetCode problems
" Eventually I'll do this with the GraphQL API, but this is good enough for now
" Prefixed all of these with "LCP" - "LeetCode Parse"

" Parse "Example" and "Explanation" strings - just remove them
command! LCPEx execute "%s/\\v(Example|Explanation).*//g"

" Parse "Input" strings - remove prefix and add 4-space indent
command! LCPIn execute "%s/Input: /    /g"

" Parse "Output" strings - remove prefix and assign to `exp_out`
command! LCPOut execute "%s/Output: /    exp_out = /g"

" Split multiple declarations on the same line into their own lines
" e.g. "m = 3, n = 2" -> "m = 3\rn = 2"
" Captures leading whitespace to use as an indent on the new line
command! LCPSplitMultDec execute "%s/\\v^( *)(.*)%(, )(\\w+ = .*)/\\1\\2\r\\1\\3/g"
command! LCPSMD LCPSplitMultDec

" Commands that achieve valid syntax
" This won't necessarily work if the question has multi-line explanations,
" but it will get close
function LCPValidSyntax()
    silent! execute "LCPEx"
    silent! execute "LCPIn"
    silent! execute "LCPOut"
    silent! execute "LCPSMD"
    silent! execute "CB"
    silent! execute "CN"
endfunction

" Clear blank lines after the main block
command! LCPClearAfterMainBlock execute "%s/\\v(^.+\"__main__\":)%([ \\r\\n]*)(^ +)/\\1\r\\2/g"
command! LCPCAMB LCPClearAfterMainBlock

" Clear all but one blank line after each `exp_out = ...`
command! LCPClearAfterExpOut execute "%s/\\v(^.+exp_out = .+$)%([ \\r\\n]*)(^ +)/\\1\r\r\\2/g"
command! LCPCAEO LCPClearAfterExpOut

" Commands that format things to look nicer, after syntax parsing
command! LCPFormat execute "LCPCAMB" | execute "LCPCAEO"

" Full parsing
command! LCP execute "call LCPValidSyntax()" | execute "LCPFormat"

" Paste and Parse
command! LCPP execute "normal! \"+P" | execute "LCP"

" LC Main Block - Create an empty main block, then paste and parse
command! LCMB execute "EMB" | execute "LCPP"

""" [LeetCode Utils]
" Other LeetCode utilities

" Select all lines of code from the first valid up to (but not including) the main block
" This should just be the actual solution code, for pasting into the browser
" '=' have to be escaped otherwise `vscode-neovim` has a fit, so I just shortened the second pattern
command! LCSelect execute "normal! gg/\"\"\"/<CR>jV/if __name__/<CR>k"
command! LCS LCSelect

" Select and copy all lines of code
command! LCCopy execute "LCSelect" | execute "normal! \"+y"
command! LCC LCCopy

