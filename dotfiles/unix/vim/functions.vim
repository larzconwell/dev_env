" InitState sets up the states directories
function! InitState(dir) abort
    let dirs = {
        \ "backupdir": "backups",
        \ "viewdir": "views",
        \ "directory": "swaps",
        \ "undodir": "undos"
    \ }

    if exists("*mkdir") && !isdirectory(a:dir)
        call mkdir(a:dir)
    endif

    for [setting, dir] in items(dirs)
        let dir = a:dir . '/' . dir

        if exists("*mkdir") && !isdirectory(dir)
            call mkdir(dir)
        endif

        if !isdirectory(dir)
            echo "Warning: Unable to create directory: " . dir
            echo "Try: mkdir -p " . dir
        else
            exec "set " . setting . "=" . dir
        endif
    endfor
endfunction

" StripWhitespace strips trailing whitespace characters
function! StripWhitespace() abort
    if !&binary && &filetype != 'diff' && &filetype != 'markdown'
        normal mz
        normal Hmy

        let l:save_view = winsaveview()
        %s/\s\+$//e
        call winrestview(l:save_view)
        call histdel('search', -1)

        normal 'yz<CR>
        normal `z
    endif
endfunction
