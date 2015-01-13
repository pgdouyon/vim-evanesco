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
    augroup evanesco
        autocmd!
        autocmd CursorMoved,InsertEnter * call <SID>evanesco_toggle_hl()
    augroup END
endfunction


function! s:evanesco_star()
    let s:save_shortmess = &shortmess
    set shortmess+=s
endfunction


function! s:evanesco_star_end()
    call s:evanesco()
    call s:evanesco_toggle_hl()
    let &shortmess = s:save_shortmess
endfunction


function! s:evanesco_toggle_hl()
    if s:evanesco
        let s:evanesco = 0
        let last_search = escape(@/, '\')
        let this_search = s:get_this_search()
        let search_dir = (v:searchforward ? "/" : "?")
        let offset = '\m\%('.search_dir.'[esb]\?[+-]\?[0-9]*\)\?$'
        let conjunctive_offset = '\m\%([/?][esb]\?[+-]\?[0-9]*\)\?$'
        let normal_search_executed = (this_search =~# '^\V'.last_search.offset)
        let conjunctive_search_executed = (this_search =~# '[/?]\V'.last_search.conjunctive_offset)
        if normal_search_executed || conjunctive_search_executed
            set hlsearch
            call s:clear_current_match()
            call s:highlight_current_match()
        endif
    else
        set nohlsearch
        call s:clear_current_match()
        autocmd! evanesco
    endif
endfunction


function! s:highlight_current_match()
    let prefix = '\c\%'.line('.').'l\%'.col('.').'c'
    let s:current_match = matchadd("IncSearch", prefix.@/)
    let s:current_match_window = winnr()
    let s:current_match_tab = tabpagenr()
endfunction


function! s:clear_current_match()
    silent! let save_tab = tabpagenr()
    silent! let save_win = tabpagewinnr(s:current_match_tab)
    silent! execute "tabnext " . s:current_match_tab
    silent! execute s:current_match_window . "wincmd w"
    silent! call matchdelete(s:current_match)
    silent! execute save_win . "wincmd w"
    silent! execute "tabnext " . save_tab
endfunction


function! s:get_this_search()
    let this_search = histget("search", -1)
    let search_dir = (v:searchforward ? "/" : "?")
    let used_last_pattern = (this_search =~# '^'.search_dir)
    if used_last_pattern
        let this_search = @/ . this_search
    endif
    return this_search
endfunction


nnoremap <Plug>Evanesco_/  :<C-U>call <SID>evanesco()<CR>/
nnoremap <Plug>Evanesco_?  :<C-U>call <SID>evanesco()<CR>?

nnoremap <silent> <Plug>Evanesco_n  :echo<CR>:call <SID>evanesco()<CR>n
nnoremap <silent> <Plug>Evanesco_N  :echo<CR>:call <SID>evanesco()<CR>N

nnoremap <silent> <Plug>Evanesco_*  :call <SID>evanesco_star()<CR>*N:call <SID>evanesco_star_end()<CR>
nnoremap <silent> <Plug>Evanesco_#  :call <SID>evanesco_star()<CR>#N:call <SID>evanesco_star_end()<CR>
nnoremap <silent> <Plug>Evanesco_g* :call <SID>evanesco_star()<CR>g*N:call <SID>evanesco_star_end()<CR>
nnoremap <silent> <Plug>Evanesco_g# :call <SID>evanesco_star()<CR>g#N:call <SID>evanesco_star_end()<CR>

for key in ['/', '?', 'n', 'N', '*', '#', 'g*', 'g#']
    execute printf("nmap %s <Plug>Evanesco_%s", key, key)
endfor

let &cpoptions = s:save_cpo
unlet s:save_cpo
