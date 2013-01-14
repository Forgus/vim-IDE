"""""""""" Public """""""""""""""""""

" Starts IDE mode.
command! -nargs=0 -bar IDEOpen call s:IDEOpen()

" Stops IDE mode.
command! -nargs=0 -bar IDEClose call s:IDEClose()

" Rebuild the tags of the current buffer.
command! -nargs=0 -bar IDERebuildTags call s:IDEBuildTags(0)

" To make Vim init in IDE mode with all kind of files.
if !exists("g:IDEAlways")
  let g:IDEAlways = 0
endif


"""""""""" Mappings """""""""""""""""

" Jump to definitions mappings.
nmap <C-i> :vsp <CR>:exec("tag ".expand("<cword>"))<CR>
nmap <C-v> :sp <CR>:exec("tag ".expand("<cword>"))<CR>

" File outline window mapping.
nmap <silent> <F8> :TlistToggle<CR>

" Project explorer window mapping.
nmap <silent> <F7> :NERDTreeToggle<CR>


"""""""""" Internals """"""""""""""""

let g:IDEModeOn = 0

" Open the IDE windows
function! s:IDEOpen()

  if g:IDEModeOn == 1
    return 0
  endif

  " Show line numbers.
  setlocal number

  " Support QuickFix for Ggrep.
  autocmd QuickFixCmdPost *grep* cwindow

  " Tags and file output.
  call s:IDEAddTags()

  " Project explorer load and display.
  call s:IDEAddNERDTree()

  " Focus to opened file window.
  wincmd w

  let g:IDEModeOn = 1

endfunction


" Closes the IDE windows
function! s:IDEClose()

  " Get file type.
  let l:language = s:IDEGetFileLanguage()

  setlocal nonumber

  NERDTreeClose

  if bufwinnr(g:TagList_title) != -1
    TlistClose
  endif

  let g:IDEModeOn = 0

endfunction


" Function to build tags
function! s:IDEBuildTags(check_previous_file)

  let l:language = s:IDEGetFileLanguage()

  " Is ctags available?.
  let l:ctags_available = system('which ctags 2> /dev/null')
  let l:tags_command_path = s:IDEGetCtagsScript(l:language)

  " Only if ctags is available and if there is a tags command for this language.
  if l:ctags_available =~ '/' && filereadable(expand(l:tags_command_path))

    " Get project tags filename (the hash of the pwd + filetype).
    let l:tags_file = s:IDEGetTagsFileName(l:language)

    " Add project tags if they are not there yet.
    if a:check_previous_file == 0 || &tags !~ l:tags_file

      " Creating tags file if it doesn't exists.
      if a:check_previous_file == 0 || !filereadable(expand(l:tags_file))
        call s:IDERunCtagsCommand(l:tags_command_path, l:tags_file)
      endif

      " Adding the tags.
      execute "set tags+=" . l:tags_file

    endif

    return 1
  endif

  return 0
endfunction


" Load the tags of the specified language inside the project scope
function! s:IDEAddTags()

  if s:IDEBuildTags(1)
    call s:IDEAddTaglist()
  endif

endfunction


" Adds Taglist
function! s:IDEAddTaglist()

  " File outline (Tag list config & init).
  let g:Tlist_Auto_Open = 1
  let g:Tlist_Auto_Update = 1
  let g:Tlist_Use_Right_Window = 1
  let g:Tlist_Sort_Type = 'name'
  let g:Tlist_File_Fold_Auto_Close = 1
  let g:Tlist_Exit_OnlyWindow = 1
  let g:Tlist_GainFocus_On_ToggleOpen = 0
  TlistOpen

  " It seems that taglist ignores g:Tlist_GainFocus_On_ToggleOpen.
  wincmd w

endfunction


" Adds NERDTree
function! s:IDEAddNERDTree()

  let g:NERDChristmasTree = 1
  let g:NERDTreeStatusline = 'Project explorer'

  " Open tree navigation.
  NERDTree

  " Close vim if it's the last window.
  autocmd bufenter * if (winnr("$") == 1 && exists("b:NERDTreeType") && b:NERDTreeType == "primary") | q | endif

endfunction


" Returns the current buffer file type
function! s:IDEGetFileLanguage()
  return &filetype
endfunction


" Runs the ctags command
function! s:IDERunCtagsCommand(command_path, tags_file)
  execute system('sh ' . a:command_path . ' ' . a:tags_file)
endfunction


" Returns the path to the language ctags script
function! s:IDEGetCtagsScript(language)
  return '~/.vim/fttags/' . a:language . '.sh'
endfunction


" Gets the tags filename ([pwd + language] unique)
function! s:IDEGetTagsFileName(language)
  let l:shreturn = system('sh ~/.vim/script/get_project_hash.sh ' . a:language)
  return substitute(l:shreturn,"[^0-9a-zA-Z\/_\.\ \-\+]","","g")
endfunction

