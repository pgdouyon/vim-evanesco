"==============================================================================
"File:        evanesco.vim
"Description: Automatically clears search highlight on CursorMoved
"Maintainer:  Pierre-Guy Douyon <pgdouyon@alum.mit.edu>
"License:     MIT <../LICENSE>
"==============================================================================

let s:save_cpo = &cpoptions
set cpoptions&vim

let s:paused = 0
let s:has_current_match = 0
let s:should_highlight = 0

function! evanesco#evanesco()
    if s:pattern_not_found()
        let v:errmsg = ""
    endif
    let s:should_highlight = 1
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


function! evanesco#evanesco_next_end()
    call s:register_autocmds()
    call s:enable_highlighting()
    let s:should_highlight = 0
endfunction


function! evanesco#evanesco_star()
    let s:save_shortmess = &shortmess
    let s:save_winview = winsaveview()
    set shortmess+=s
endfunction


function! evanesco#evanesco_visual_star()
    let save_yank_register_info = ['0', getreg('0'), getregtype('0')]
    let save_unnamed_register_info = ['"', getreg('"'), getregtype('"')]
    normal! gvy
    let search_term = '\V' . escape(@@, '\')
    call evanesco#evanesco_star()
    call call("setreg", save_yank_register_info)
    call call("setreg", save_unnamed_register_info)
    return search_term
endfunction


function! evanesco#evanesco_star_end()
    let &shortmess = s:save_shortmess
    let s:save_winview.lnum = line(".")
    let s:save_winview.col = col(".") - 1
    let s:save_winview.coladd = 0
    call winrestview(s:save_winview)
    call s:register_autocmds()
    call s:enable_highlighting()
    let s:should_highlight = 0
endfunction


function! s:evanesco_toggle_hl()
    if s:paused
        return
    endif

    if s:should_highlight
        let s:should_highlight = 0
        if !s:pattern_not_found() && s:search_executed()
            call s:enable_highlighting()
        endif
    else
        call s:disable_highlighting()
        call s:unregister_autocmds()
    endif
endfunction


function! s:search_executed()
    let [search_term, offset] = s:last_search()
    let match_at_cursor = s:match_at_cursor(search_term, offset)
    return (search_term ==# @/) && search(match_at_cursor, 'cnw')
endfunction


function! s:last_search()
    let last_search = histget("search", -1)
    let search_dir = (v:searchforward ? "/" : "?")
    let used_last_pattern = (last_search =~# '^'.search_dir)
    let is_conjunctive = (last_search =~# '\\\@<![/?];[/?]')
    if used_last_pattern
        return [@/, last_search[1:]]
    endif

    if is_conjunctive
        let search_query = matchstr(last_search, '\%(.*\\\@<![/?];\)\zs.*')
        let search_dir = search_query[0]
        let last_search = search_query[1:]
    endif
    let offset_regex = '\\\@<!'.search_dir.'[esb]\?[+-]\?[0-9]*'
    let search_term = matchstr(last_search, '^.\{-\}\ze\%('.offset_regex.'\)\?$')
    let offset = matchstr(last_search, offset_regex.'$')[1:]
    return [search_term, offset]
endfunction


function! s:match_at_cursor(search_term, offset)
    if s:is_linewise_offset(a:offset)
        return s:linewise_match_at_cursor(a:search_term, a:offset)
    else
        return s:characterwise_match_at_cursor(a:search_term, a:offset)
    endif
endfunction


function! s:is_linewise_offset(offset)
    return !empty(a:offset) && (a:offset[0] !~# '[esb]')
endfunction


function! s:linewise_match_at_cursor(search_term, offset)
    let cursor_line = line(".")
    let offset_lines = matchstr(a:offset, '\d\+')
    let offset_lines = !empty(offset_lines) ? str2nr(offset_lines) : 1
    let nomagic = &magic ? '' : '\M'
    if (a:offset =~ '^-')
        return '\m\%#' . repeat('.*\n', offset_lines) . '.*\zs' . nomagic . a:search_term
    else
        return a:search_term . '\ze\m' . repeat('.*\n', offset_lines) . '\%#'
    endif
endfunction


function! s:characterwise_match_at_cursor(search_term, offset)
    let cursor_column = s:offset_cursor_column(a:search_term, a:offset)
    if cursor_column <= 0
        let offset = (0 - cursor_column)
        return '\%#' . repeat('\_.', offset) . '\zs' . a:search_term
    elseif cursor_column >= strchars(a:search_term)
        let offset = cursor_column - strchars(a:search_term)
        return a:search_term . '\ze' . repeat('\_.', offset) . '\%#'
    endif
    let start = a:search_term[0 : cursor_column - 1]
    let end = a:search_term[cursor_column : -1]
    return start . '\%#' . end
endfunction


function! s:offset_cursor_column(search_term, offset)
    let default_offset = (a:offset =~ '[-+]') ? 1 : 0
    let offset_chars = matchstr(a:offset, '\d\+')
    let offset_chars = !empty(offset_chars) ? str2nr(offset_chars) : default_offset
    let start_column = (a:offset =~ 'e') ? strchars(a:search_term) - 1 : 0
    if (a:offset =~ '-')
        return (start_column - offset_chars)
    else
        return (start_column + offset_chars)
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
    let [search_term, offset] = s:last_search()
    let match_at_cursor = s:match_at_cursor(search_term, offset)
    let w:evanesco_current_match = matchadd("IncSearch", '\c'.match_at_cursor, 999)
    let s:has_current_match = 1
endfunction


function! s:clear_current_match()
    if s:has_current_match
        let [current_match_tabnr, current_match_winnr] = s:find_current_match_window()
        if (current_match_tabnr > 0) && (current_match_winnr > 0)
            let save_tab = tabpagenr()
            let save_win = tabpagewinnr(current_match_tabnr)
            execute "tabnext" current_match_tabnr
            execute current_match_winnr "wincmd w"
            call matchdelete(w:evanesco_current_match)
            unlet w:evanesco_current_match
            execute save_win "wincmd w"
            execute "tabnext" save_tab
        endif
        let s:has_current_match = 0
    endif
endfunction


function! s:find_current_match_window()
    for winnr in range(1, winnr("$"))
        if !empty(getwinvar(winnr, "evanesco_current_match"))
            return [tabpagenr(), winnr]
        endif
    endfor

    for tabnr in range(1, tabpagenr("$"))
        for winnr in range(1, tabpagewinnr(tabnr, "$"))
            if !empty(gettabwinvar(tabnr, winnr, "evanesco_current_match"))
                return [tabnr, winnr]
            endif
        endfor
    endfor

    return [-1, -1]
endfunction


function! evanesco#pause()
    let s:paused = 1
    let s:should_highlight = 1
endfunction


function! evanesco#resume()
    let s:paused = 0
endfunction

let &cpoptions = s:save_cpo
unlet s:save_cpo
