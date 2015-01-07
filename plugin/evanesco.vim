"==============================================================================
"File:        evanesco.vim
"Description: Automatically clears search highlight on CursorMoved
"Maintainer:  Pierre-Guy Douyon <pgdouyon@alum.mit.edu>
"Version:     1.0.0
"Last Change: 2015-01-06
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

let s:evanesco_active = 0
let s:saved_cmappings = []

function! s:evanesco(direction)
    let s:evanesco_active = 1
    let s:save_cursor = getpos(".")
    let s:save_search = @/
    let s:save_cpo = &cpo
    let s:save_tvb = &t_vb
    let s:save_vb = &vb
    set cpoptions-=B
    set t_vb=
    set vb
    set nohlsearch
    for key in ['<CR>', '<C-J>', '<C-C>', '<Esc>']
        let name = tolower(substitute(key, '[<>-]', '', 'g'))
        let old_map = maparg(key, "c", 0, 1)
        let rhs = (has_key(old_map, "rhs") ? old_map.rhs : "")
        execute "silent! cunmap " . key
        execute printf('cnoremap <silent> %s %s<Esc><Esc>:<C-U>call <SID>evanesco_finish("\%s", "%d")<CR>',
            \ key, rhs, key, a:direction)
        if !empty(old_map)
            call add(s:saved_cmappings, old_map)
        endif
    endfor
endfunction


function! s:evanesco_finish(key, direction)
    if s:evanesco_active
        let &cpo = s:save_cpo
        let &t_vb = s:save_tvb
        let &vb = s:save_vb
        call s:delete_evanesco_mappings()
        call s:restore_mappings()
        let s:evanesco_active = 0
        let is_cr = (a:key =~? '<CR>\|<C-J>')
        if is_cr
            let s:evanesco_forward = a:direction
            let s:evanesco_canceled = 0
            set hlsearch
        else
            let s:evanesco_canceled = 1
            call setpos(".", s:save_cursor)
            let @/ = s:save_search
        endif
    endif
endfunction


function! s:delete_evanesco_mappings()
    for key in ['<CR>', '<C-J>', '<C-C>', '<Esc>']
        execute "silent! cunmap " . key
    endfor
endfunction


function! s:restore_mappings()
    for mapping in s:saved_cmappings
        let map_cmd = (mapping.noremap ? "cnoremap" : "cmap")
        let silent = (mapping.silent ? "<silent>" : "")
        let buffer = (mapping.buffer ? "<buffer>" : "")
        let nowait = (mapping.nowait ? "<nowait>" : "")
        let expr = (mapping.expr ? "<expr>" : "")
        execute map_cmd silent buffer nowait expr mapping.lhs mapping.rhs
    endfor
endfunction


" ===========================================================================
" v:searchforward is reset to 1 whenever writing to the search register (@/).
" Evanesco writes to the search register on canceled searches to preserve the
" original search term, resulting in inconsistent movement directions for n/N
" when used after a canceled search.
"
" This function calculates the correct direction that an `n` or `N` command
" should move following a canceled search.
" ===========================================================================
function! s:evanesco_next(mode, next)
    " Echo clears 'search hit BOTTOM' message
    echo
    if !exists("s:evanesco_canceled")
        return (a:next ? "n" : "N")
    endif

    let hlsearch = (a:mode ==? "n" ? ":set hlsearch\<CR>" : "")
    if s:evanesco_canceled
        let forward = (a:next && s:evanesco_forward) || (!a:next && !s:evanesco_forward)
        let next = (forward ? "n" : "N")
    else
        let next = (a:next ? "n" : "N")
    endif
    return next . hlsearch
endfunction

nnoremap <Plug>Evanesco_/  :<C-U>call <SID>evanesco(1)<CR>/
nnoremap <Plug>Evanesco_?  :<C-U>call <SID>evanesco(0)<CR>?
nmap / <Plug>Evanesco_/
nmap ? <Plug>Evanesco_?

nnoremap <silent> <Plug>Evanesco_*  *N:set hlsearch<CR>
nnoremap <silent> <Plug>Evanesco_#  #N:set hlsearch<CR>
nnoremap <silent> <Plug>Evanesco_g* g*N:set hlsearch<CR>
nnoremap <silent> <Plug>Evanesco_g# g#N:set hlsearch<CR>

nnoremap <silent><expr> <Plug>Evanesco_n <SID>evanesco_next("n", 1)
nnoremap <silent><expr> <Plug>Evanesco_N <SID>evanesco_next("n", 0)

for key in ['/', '?', 'n', 'N', '*', '#', 'g*', 'g#']
    execute printf("nmap %s <Plug>Evanesco_%s", key, key)
endfor

augroup evanesco
    autocmd!
    autocmd CursorMoved,InsertEnter * set nohlsearch
augroup END

let &cpoptions = s:save_cpo
unlet s:save_cpo
