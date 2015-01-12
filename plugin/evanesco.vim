"==============================================================================
"File:        evanesco.vim
"Description: Automatically clears search highlight on CursorMoved
"Maintainer:  Pierre-Guy Douyon <pgdouyon@alum.mit.edu>
"Version:     1.0.0
"Last Change: 2015-01-11
"License:     MIT <../LICENSE>
"==============================================================================

" ======================================================================
" Configuration and Defaults
" ======================================================================

if exists("g:loaded_evanesco")
    finish
endif
let g:loaded_evanesco = 1

let s:save_cpo = &cpoptions
set cpoptions&vim

let s:evanesco = 0

function! s:evanesco()
    let s:evanesco = 1
endfunction


function! s:evanesco_star()
    let s:save_shortmess = &shortmess
    set shortmess+=s
endfunction


function! s:evanesco_star_end()
    set hlsearch
    let &shortmess = s:save_shortmess
endfunction


function! s:evanesco_toggle_hl()
    if s:evanesco
        let s:evanesco = 0
        set hlsearch
    else
        set nohlsearch
    endif
endfunction


nnoremap <Plug>Evanesco_/  :<C-U>call <SID>evanesco()<CR>/
nnoremap <Plug>Evanesco_?  :<C-U>call <SID>evanesco()<CR>?

nnoremap <silent> <Plug>Evanesco_n  :echo<CR>n:set hlsearch<CR>
nnoremap <silent> <Plug>Evanesco_N  :echo<CR>N:set hlsearch<CR>

nnoremap <silent> <Plug>Evanesco_*  :call <SID>evanesco_star()<CR>*N:call <SID>evanesco_star_end()<CR>
nnoremap <silent> <Plug>Evanesco_#  :call <SID>evanesco_star()<CR>#N:call <SID>evanesco_star_end()<CR>
nnoremap <silent> <Plug>Evanesco_g* :call <SID>evanesco_star()<CR>g*N:call <SID>evanesco_star_end()<CR>
nnoremap <silent> <Plug>Evanesco_g# :call <SID>evanesco_star()<CR>g#N:call <SID>evanesco_star_end()<CR>

for key in ['/', '?', 'n', 'N', '*', '#', 'g*', 'g#']
    execute printf("nmap %s <Plug>Evanesco_%s", key, key)
endfor

augroup evanesco
    autocmd!
    autocmd CursorMoved,InsertEnter * call <SID>evanesco_toggle_hl()
augroup END

let &cpoptions = s:save_cpo
unlet s:save_cpo
