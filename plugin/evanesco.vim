"==============================================================================
"File:        evanesco.vim
"Description: Automatically clears search highlight on CursorMoved
"Maintainer:  Pierre-Guy Douyon <pgdouyon@alum.mit.edu>
"License:     MIT <../LICENSE>
"==============================================================================

" ======================================================================
" Configuration and Defaults
" ======================================================================

let s:save_cpo = &cpoptions
set cpoptions&vim

if !exists("g:loaded_evanesco")
    " only executed once, at startup
    set nohlsearch
endif
let g:loaded_evanesco = 1

nnoremap <silent> <Plug>Evanesco_/ :<C-U>call evanesco#evanesco('/')<CR>
nnoremap <silent> <Plug>Evanesco_? :<C-U>call evanesco#evanesco('?')<CR>

nnoremap <silent> <Plug>Evanesco_n  :<C-U>call evanesco#evanesco_next_init()<CR>n:call evanesco#evanesco_next_end()<CR>
nnoremap <silent> <Plug>Evanesco_N  :<C-U>call evanesco#evanesco_next_init()<CR>N:call evanesco#evanesco_next_end()<CR>

nnoremap <silent> <Plug>Evanesco_*  :<C-U>call evanesco#evanesco_star_init()<CR>:keepjumps normal! *N<CR>:call evanesco#evanesco_star_end()<CR>
nnoremap <silent> <Plug>Evanesco_#  :<C-U>call evanesco#evanesco_star_init()<CR>:keepjumps normal! #N<CR>:call evanesco#evanesco_star_end()<CR>
nnoremap <silent> <Plug>Evanesco_g* :<C-U>call evanesco#evanesco_star_init()<CR>:keepjumps normal! g*N<CR>:call evanesco#evanesco_star_end()<CR>
nnoremap <silent> <Plug>Evanesco_g# :<C-U>call evanesco#evanesco_star_init()<CR>:keepjumps normal! g#N<CR>:call evanesco#evanesco_star_end()<CR>
nnoremap <silent> <Plug>Evanesco_gd :<C-U>call evanesco#evanesco_star_init()<CR>gd:call evanesco#evanesco_star_end()<CR>
nnoremap <silent> <Plug>Evanesco_gD :<C-U>call evanesco#evanesco_star_init()<CR>gD:call evanesco#evanesco_star_end()<CR>

xnoremap <silent> <Plug>Evanesco_*  <Esc>:<C-U>call evanesco#evanesco_visual_star('/')<CR>
xnoremap <silent> <Plug>Evanesco_#  <Esc>:<C-U>call evanesco#evanesco_visual_star('?')<CR>

" hack used to call evanesco#evanesco_star_end from feedkeys without causing
" command to echo or be saved in command history
nnoremap <silent> <Plug>Evanesco_visual_search_end :<C-U>call evanesco#evanesco_star_end()<CR>:echo<CR>

for key in ['/', '?', 'n', 'N', '*', '#', 'g*', 'g#', 'gd', 'gD']
    if !hasmapto(printf("<Plug>Evanesco_%s", key), "n")
        execute printf("nmap %s <Plug>Evanesco_%s", key, key)
    endif
endfor
if !hasmapto("<Plug>Evanesco_*", "v")
    xmap * <Plug>Evanesco_*
endif
if !hasmapto("<Plug>Evanesco_#", "v")
    xmap # <Plug>Evanesco_#
endif

let &cpoptions = s:save_cpo
unlet s:save_cpo
