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
let s:try_set_hlsearch = 0

function! evanesco#evanesco()
    if s:pattern_not_found()
        let v:errmsg = ""
    endif
    let s:try_set_hlsearch = 1
    call s:set_nohlsearch()
    call s:register_autocmds()
endfunction


function! s:pattern_not_found()
    return (v:errmsg =~# '^E486')
endfunction


function! s:register_autocmds()
    augroup evanesco_hl
        autocmd!
        autocmd CursorMoved,InsertEnter * call <SID>toggle_hlsearch()
    augroup END
endfunction


function! s:unregister_autocmds()
    autocmd! evanesco_hl
    augroup! evanesco_hl
endfunction


function! evanesco#evanesco_next_end()
    call s:register_autocmds()
    call s:set_hlsearch()
    let s:try_set_hlsearch = 0
endfunction


function! evanesco#evanesco_star()
    let s:save_shortmess = &shortmess
    let s:save_winview = winsaveview()
    set shortmess+=s
endfunction


function! evanesco#evanesco_visual_star(search_type)
    let save_yank_register_info = ['0', getreg('0'), getregtype('0')]
    let save_unnamed_register_info = ['"', getreg('"'), getregtype('"')]
    normal! gvy
    let escape_chars = '\' . a:search_type
    let search_term = '\V' . s:remove_null_bytes(escape(@@, escape_chars))
    call evanesco#evanesco_star()
    call call("setreg", save_yank_register_info)
    call call("setreg", save_unnamed_register_info)
    return search_term
endfunction


function! s:remove_null_bytes(string)
    return substitute(a:string, '\%x00', '\\n', 'g')
endfunction


function! evanesco#evanesco_star_end()
    let &shortmess = s:save_shortmess
    let s:save_winview.lnum = line(".")
    let s:save_winview.col = col(".") - 1
    let s:save_winview.coladd = 0
    call winrestview(s:save_winview)
    call s:register_autocmds()
    call s:set_hlsearch()
    let s:try_set_hlsearch = 0
endfunction


" there are 3 scenarios where the cursor can move after a search is attempted:
"   1) search was successfully executed and cursor moves to next match
"   2) search was exectued but failed with a 'pattern not found' error
"   3) search was aborted by pressing <Esc> or <C-C> at the search prompt
" only want to enable highlighting for scenario 1 and ignore 2/3 entirely
function! s:toggle_hlsearch()
    if s:paused
        return
    endif

    if s:try_set_hlsearch
        let s:try_set_hlsearch = 0
        if !s:pattern_not_found() && s:search_executed()
            call s:set_hlsearch()
        endif
    else
        call s:set_nohlsearch()
        call s:unregister_autocmds()
    endif
endfunction


function! s:search_executed()
    let [search_pattern, offset] = s:last_search_attempt()
    let match_at_cursor = s:match_at_cursor(search_pattern, offset)
    return (search_pattern ==# @/) && search(match_at_cursor, 'cnw')
endfunction


" extracts pattern and offset from last search attempt
function! s:last_search_attempt()
    let last_search_attempt = histget("search", -1)
    let search_dir = (v:searchforward ? "/" : "?")
    let reused_latest_pattern = (last_search_attempt[0] ==# search_dir)
    if reused_latest_pattern
        return [@/, last_search_attempt[1:]]
    endif

    let is_conjunctive_search = (last_search_attempt =~# '\\\@<![/?];[/?]')
    if is_conjunctive_search
        let search_query = matchstr(last_search_attempt, '\%(.*\\\@<![/?];\)\zs.*')
        let search_dir = search_query[0]
        let last_search_attempt = search_query[1:]
    endif
    let offset_regex = '\\\@<!'.search_dir.'[esb]\?[+-]\?[0-9]*'
    let search_pattern = matchstr(last_search_attempt, '^.\{-\}\ze\%('.offset_regex.'\)\?$')
    let offset = matchstr(last_search_attempt, offset_regex.'$')[1:]
    return [search_pattern, offset]
endfunction


" Returns a pattern string to match the search_pattern+offset at the current
" cursor position
function! s:match_at_cursor(search_pattern, offset)
    let search_pattern = s:sanitize_search_pattern(a:search_pattern)
    if empty(a:offset)
        return '\%#' . search_pattern
    endif
    if s:is_linewise_offset(a:offset)
        return s:linewise_match_at_cursor(search_pattern, a:offset)
    else
        return s:characterwise_match_at_cursor(search_pattern, a:offset)
    endif
endfunction


function! s:sanitize_search_pattern(search_pattern)
    let star_replacement = &magic ? '\\*' : '*'
    let equals_replacement = '\%(=\)'
    let sanitized = substitute(a:search_pattern, '\V\^*', star_replacement, '')
    return substitute(sanitized, '\V\^=', equals_replacement, '')
endfunction


function! s:is_linewise_offset(offset)
    return a:offset[0] !~# '[esb]'
endfunction


function! s:linewise_match_at_cursor(search_pattern, offset)
    let cursor_line = line(".")
    let offset_lines = matchstr(a:offset, '\d\+')
    let offset_lines = !empty(offset_lines) ? str2nr(offset_lines) : 1
    let nomagic = &magic ? '' : '\M'
    if (a:offset =~ '^-')
        return '\m\%#' . repeat('.*\n', offset_lines) . '.*\zs' . nomagic . a:search_pattern
    else
        return a:search_pattern . '\ze\m' . repeat('.*\n', offset_lines) . '\%#'
    endif
endfunction


function! s:characterwise_match_at_cursor(search_pattern, offset)
    let cursor_column = s:offset_cursor_column(a:search_pattern, a:offset)
    if cursor_column <= 0
        let offset = (0 - cursor_column)
        return '\%#' . repeat('\_.', offset) . '\zs' . a:search_pattern
    elseif cursor_column >= strchars(a:search_pattern)
        let offset = cursor_column - strchars(a:search_pattern)
        return a:search_pattern . '\ze' . repeat('\_.', offset) . '\%#'
    endif
    let byteidx = byteidx(a:search_pattern, cursor_column)
    let start = a:search_pattern[0 : byteidx - 1]
    let end = a:search_pattern[byteidx : -1]
    return start . '\%#' . s:sanitize_search_pattern(end)
endfunction


function! s:offset_cursor_column(search_pattern, offset)
    let default_offset = (a:offset =~ '[-+]') ? 1 : 0
    let offset_chars = matchstr(a:offset, '\d\+')
    let offset_chars = !empty(offset_chars) ? str2nr(offset_chars) : default_offset
    let start_column = (a:offset =~ 'e') ? strchars(a:search_pattern) - 1 : 0
    if (a:offset =~ '-')
        return (start_column - offset_chars)
    else
        return (start_column + offset_chars)
    endif
endfunction


function! s:set_hlsearch()
    set hlsearch
    call s:highlight_current_match()
    if (&foldopen =~# 'search') || (&foldopen =~# 'all')
        normal! zv
    endif
endfunction


function! s:set_nohlsearch()
    set nohlsearch
    call s:clear_current_match()
endfunction


function! s:highlight_current_match()
    call s:clear_current_match()
    let [search_pattern, offset] = s:last_search_attempt()
    let match_at_cursor = s:match_at_cursor(search_pattern, offset)
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

            try
                call matchdelete(w:evanesco_current_match)
            catch /E803/
                " suppress errors for matches that have already been deleted
            endtry
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
    let s:try_set_hlsearch = 1
endfunction


function! evanesco#resume()
    let s:paused = 0
endfunction

let &cpoptions = s:save_cpo
unlet s:save_cpo
