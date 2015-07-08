"==============================================================================
"File:        evanesco.vim
"Description: Automatically clears search highlight on CursorMoved
"Maintainer:  Pierre-Guy Douyon <pgdouyon@alum.mit.edu>
"Version:     1.0.0
"Last Change: 2015-01-23
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

let s:evanesco_should_highlight = 0

function! s:evanesco()
    if s:pattern_not_found()
        let v:errmsg = ""
    endif
    let s:evanesco_should_highlight = 1
    call s:disable_highlighting()
    call s:register_autocmds()
endfunction


function! s:pattern_not_found()
    return (v:errmsg =~# '^E486')
endfunction


function! s:register_autocmds()
    augroup evanesco_hl
        autocmd!
        autocmd CursorMoved,InsertEnter * call <SID>evanesco_toggle_hl()
    augroup END
endfunction


function! s:unregister_autocmds()
    autocmd! evanesco_hl
    augroup! evanesco_hl
endfunction


function! s:evanesco_next_end()
    call s:register_autocmds()
    call s:enable_highlighting()
    let s:evanesco_should_highlight = 0
endfunction


function! s:evanesco_star()
    let s:save_shortmess = &shortmess
    let s:save_winview = winsaveview()
    set shortmess+=s
endfunction


function! s:evanesco_visual_star()
    let save_yank_register_info = ['0', getreg('0'), getregtype('0')]
    let save_unnamed_register_info = ['"', getreg('"'), getregtype('"')]
    let s:save_shortmess = &shortmess
    let s:save_winview = winsaveview()
    set shortmess+=s
    normal! gvy
    let search_term = '\V' . escape(@@, '\')
    call call("setreg", save_yank_register_info)
    call call("setreg", save_unnamed_register_info)
    return search_term
endfunction


function! s:evanesco_star_end()
    let &shortmess = s:save_shortmess
    let s:save_winview.lnum = line(".")
    let s:save_winview.col = col(".") - 1
    let s:save_winview.coladd = 0
    call winrestview(s:save_winview)
    call s:register_autocmds()
    call s:enable_highlighting()
    let s:evanesco_should_highlight = 0
endfunction


function! s:evanesco_toggle_hl()
    if s:evanesco_should_highlight
        let s:evanesco_should_highlight = 0
        let last_search = escape(@/, '\')
        let this_search = s:get_this_search()
        let search_dir = (v:searchforward ? "/" : "?")
        let offset = '\m\%('.search_dir.'[esb]\?[+-]\?[0-9]*\)\?$'
        let conjunctive_offset = '\m\%([/?][esb]\?[+-]\?[0-9]*\)\?$'
        let normal_search_executed = (this_search =~# '^\V'.last_search.offset)
        let conjunctive_search_executed = (this_search =~# ';[/?]\V'.last_search.conjunctive_offset)
        if !s:pattern_not_found() && (normal_search_executed || conjunctive_search_executed)
            call s:enable_highlighting()
        endif
    else
        call s:disable_highlighting()
        call s:unregister_autocmds()
    endif
endfunction


function! s:enable_highlighting()
    set hlsearch
    call s:highlight_current_match()
endfunction


function! s:disable_highlighting()
    set nohlsearch
    call s:clear_current_match()
endfunction


function! s:highlight_current_match()
    call s:clear_current_match()
    let prefix = '\c\%'.line('.').'l\%'.col('.').'c'
    let w:evanesco_current_match = matchadd("IncSearch", prefix.@/, 999)
    let s:current_match_window = winnr()
    let s:current_match_tab = tabpagenr()
endfunction


function! s:clear_current_match()
    if exists("s:current_match_window")
        let save_tab = tabpagenr()
        let save_win = tabpagewinnr(s:current_match_tab)
        execute "tabnext " . s:current_match_tab
        execute s:current_match_window . "wincmd w"
        if exists("w:evanesco_current_match")
            call matchdelete(w:evanesco_current_match)
            unlet w:evanesco_current_match
        endif
        execute save_win . "wincmd w"
        execute "tabnext " . save_tab
        unlet s:current_match_window
        unlet s:current_match_tab
    endif
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

nnoremap <silent> <Plug>Evanesco_n  :echo<CR>n:call <SID>evanesco_next_end()<CR>
nnoremap <silent> <Plug>Evanesco_N  :echo<CR>N:call <SID>evanesco_next_end()<CR>

nnoremap <silent> <Plug>Evanesco_*  :call <SID>evanesco_star()<CR>*N:call <SID>evanesco_star_end()<CR>
nnoremap <silent> <Plug>Evanesco_#  :call <SID>evanesco_star()<CR>#N:call <SID>evanesco_star_end()<CR>
nnoremap <silent> <Plug>Evanesco_g* :call <SID>evanesco_star()<CR>g*N:call <SID>evanesco_star_end()<CR>
nnoremap <silent> <Plug>Evanesco_g# :call <SID>evanesco_star()<CR>g#N:call <SID>evanesco_star_end()<CR>

xnoremap <silent> <Plug>Evanesco_*  <Esc>/<C-R>=<SID>evanesco_visual_star()<CR><CR>N:call <SID>evanesco_star_end()<CR>
xnoremap <silent> <Plug>Evanesco_#  <Esc>?<C-R>=<SID>evanesco_visual_star()<CR><CR>N:call <SID>evanesco_star_end()<CR>

for key in ['/', '?', 'n', 'N', '*', '#', 'g*', 'g#']
    execute printf("nmap %s <Plug>Evanesco_%s", key, key)
endfor
xmap * <Plug>Evanesco_*
xmap # <Plug>Evanesco_#

augroup evanesco
    autocmd!
    autocmd CmdWinEnter [/?] let s:evanesco_should_highlight = 0
    autocmd CmdWinLeave [/?] call <SID>evanesco()
augroup END

let &cpoptions = s:save_cpo
unlet s:save_cpo
