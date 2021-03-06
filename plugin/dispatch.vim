" Location:     plugin/dispatch.vim
" Maintainer:   Tim Pope <http://tpo.pe/>
" Version:      1.5
" GetLatestVimScripts: 4504 1 :AutoInstall: dispatch.vim

if exists("g:loaded_dispatch") || v:version < 700 || &compatible
  finish
endif
let g:loaded_dispatch = 1

command! -bang -nargs=* -range=-1 -complete=customlist,dispatch#command_complete Dispatch
      \ execute dispatch#compile_command(<bang>0, <q-args>,
      \   <count> < 0 || <line1> == <line2> ? <count> : 0)

command! -bang -nargs=* -range=-1 -complete=customlist,dispatch#command_complete FocusDispatch
      \ execute dispatch#focus_command(<bang>0, <q-args>,
      \   <count> < 0 || <line1> == <line2> ? <count> : 0)

command! -bang -nargs=* -range=-1 -complete=customlist,dispatch#make_complete Make
      \ execute dispatch#compile_command(<bang>0, '_ ' . <q-args>,
      \   <count> < 0 || <line1> == <line2> ? <count> : 0)

command! -bang -nargs=* -complete=customlist,dispatch#command_complete Spawn
      \ execute dispatch#spawn_command(<bang>0, <q-args>)

command! -bang -nargs=* -complete=customlist,dispatch#command_complete Start
      \ execute dispatch#start_command(<bang>0, <q-args>)

command! -bang -bar Copen call dispatch#copen(<bang>0)

command! -bang -bar -nargs=* AbortDispatch
      \ execute dispatch#abort_command(<bang>0, <q-args>)

function! s:map(mode, lhs, rhs, ...) abort
  let flags = (a:0 ? a:1 : '') . (a:rhs =~# '^<Plug>' ? '' : '<script>')
  let head = a:lhs
  let tail = ''
  let keys = get(g:, a:mode.'remap', {})
  if type(keys) != type({})
    return
  endif
  while !empty(head)
    if has_key(keys, head)
      let head = keys[head]
      if empty(head)
        return
      endif
      break
    endif
    let tail = matchstr(head, '<[^<>]*>$\|.$') . tail
    let head = substitute(head, '<[^<>]*>$\|.$', '', '')
  endwhile
  exe a:mode.'map' flags head.tail a:rhs
endfunction

nmap <script> <SID>:.    :<C-R>=getcmdline() =~ ',' ? "\0250" : ""<CR>
call s:map('n', 'm<CR>', '<SID>:.Make<CR>')
call s:map('n', 'm<Space>', '<SID>:.Make<Space>')
call s:map('n', 'm!', '<SID>:.Make!')
call s:map('n', 'd<CR>', '<SID>:.Dispatch<CR>')
call s:map('n', 'd<Space>', '<SID>:.Dispatch<Space>')
call s:map('n', 'd!', '<SID>:.Dispatch!')

function! DispatchComplete(id) abort
  return dispatch#complete(a:id)
endfunction

function! s:hijack_netrw_maps() abort
  let rhs = maparg('d', 'n')
  if len(rhs)
    exe 'nnoremap <buffer> <silent> d' rhs
    exe 'nnoremap <buffer> <silent> dd' rhs
  endif
endfunction

if !exists('g:dispatch_handlers')
  let g:dispatch_handlers = [
        \ 'tmux',
        \ 'screen',
        \ 'windows',
        \ 'iterm',
        \ 'x11',
        \ 'headless',
        \ ]
endif

augroup dispatch
  autocmd!
  autocmd FileType qf
        \ if &buftype ==# 'quickfix' && empty(getloclist(winnr())) && get(w:, 'quickfix_title') =~# '^:noautocmd cgetfile\>\|^:\d*Dispatch\>' |
        \   call dispatch#quickfix_init() |
        \ endif
  autocmd FileType netrw call s:hijack_netrw_maps()
augroup END
