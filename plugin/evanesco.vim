"==============================================================================
"File:        evanesco.vim
"Description: Automatically clears search highlight on CursorMoved
"Maintainer:  Pierre-Guy Douyon <pgdouyon@alum.mit.edu>
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

nnoremap <Plug>Evanesco_/ :<C-U>call evanesco#evanesco()<CR>/
nnoremap <Plug>Evanesco_? :<C-U>call evanesco#evanesco()<CR>?

nnoremap <silent> <Plug>Evanesco_n  :echo<CR>n:call evanesco#evanesco_next_end()<CR>
nnoremap <silent> <Plug>Evanesco_N  :echo<CR>N:call evanesco#evanesco_next_end()<CR>

nnoremap <silent> <Plug>Evanesco_*  :call evanesco#evanesco_star()<CR>:keepjumps normal! *N<CR>:call evanesco#evanesco_star_end()<CR>
nnoremap <silent> <Plug>Evanesco_#  :call evanesco#evanesco_star()<CR>:keepjumps normal! #N<CR>:call evanesco#evanesco_star_end()<CR>
nnoremap <silent> <Plug>Evanesco_g* :call evanesco#evanesco_star()<CR>:keepjumps normal! g*N<CR>:call evanesco#evanesco_star_end()<CR>
nnoremap <silent> <Plug>Evanesco_g# :call evanesco#evanesco_star()<CR>:keepjumps normal! g#N<CR>:call evanesco#evanesco_star_end()<CR>
nnoremap <silent> <Plug>Evanesco_gd :call evanesco#evanesco_star()<CR>gd:call evanesco#evanesco_star_end()<CR>
nnoremap <silent> <Plug>Evanesco_gD :call evanesco#evanesco_star()<CR>gD:call evanesco#evanesco_star_end()<CR>

xnoremap <silent> <Plug>Evanesco_*  <Esc>/<C-R>=evanesco#evanesco_visual_star('/')<CR><CR><C-O>:call evanesco#evanesco_star_end()<CR>
xnoremap <silent> <Plug>Evanesco_#  <Esc>?<C-R>=evanesco#evanesco_visual_star('?')<CR><CR><C-O>:call evanesco#evanesco_star_end()<CR>

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

augroup evanesco
    autocmd!
    autocmd CmdWinEnter * call evanesco#pause()
    autocmd CmdWinLeave * call evanesco#resume()
augroup END

let &cpoptions = s:save_cpo
unlet s:save_cpo
