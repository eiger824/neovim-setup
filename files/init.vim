" @file    init.vim
" @brief   Current neovim init script
" @author  Santiago Pagola
" @version 1.2
" @date    2020-01-29
"
call plug#begin("~/.local/share/nvim/plugged")
Plug 'junegunn/fzf'
Plug 'junegunn/fzf.vim'
Plug 'itchyny/lightline.vim'
Plug 'autozimu/LanguageClient-neovim', {
    \ 'branch': 'next',
    \ 'do': 'bash install.sh',
    \ }
Plug 'Shougo/deoplete.nvim', { 'do': ':UpdateRemotePlugins' }
Plug 'tpope/vim-surround'
Plug 'derekwyatt/vim-fswitch'
Plug 'airblade/vim-gitgutter'
Plug 'rafi/awesome-vim-colorschemes'
Plug 'mihaifm/bufstop'
Plug 'mtdl9/vim-log-highlighting'
Plug 'jremmen/vim-ripgrep'
Plug 'tpope/vim-fugitive'
Plug 'vim-scripts/DoxygenToolkit.vim'
Plug 'skywind3000/asyncrun.vim'
Plug 'vim-scripts/ZoomWin'
call plug#end()

" Leader: always first
let mapleader=","

" Check if /tmp/$USER exists, create if not
if !isdirectory("/tmp/".$USER)
    echo "Creating /tmp/".$USER
    call mkdir("/tmp/".$USER, "p")
else
    echo "/tmp/".$USER." found"
endif

"*********************************************
"********** LanguageClient-Neovim ************
"*********************************************
let g:LanguageClient_serverCommands = {
    \ 'c': ['ccls', '--log-file=/tmp/$USER/cc.log', '--init={"cache": {"directory": "/tmp/$USER/ccls-cache"}}'],
    \ 'cpp': ['ccls', '--log-file=/tmp/$USER/cc.log', '--init={"cache": {"directory": "/tmp/$USER/ccls-cache"}}'],
    \ }

let g:LanguageClient_loadSettings = 1 " Use an absolute configuration path if you want system-wide settings
let g:LanguageClient_settingsPath = '~/.config/nvim/settings.json'
" https://github.com/autozimu/LanguageClient-neovim/issues/379 LSP snippet is
" not supported
let g:LanguageClient_hasSnippetSupport = 0
:nmap <leader>gg :call LanguageClient_contextMenu()<CR>
nnoremap <leader>f :call LanguageClient#textDocument_definition()<CR>
nnoremap <leader>r :call LanguageClient#textDocument_references({'includeDeclaration': v:false})<CR>
noremap <leader>C :call LanguageClient#findLocations({'method':'$ccls/call'})<CR>
"nn <silent> K :call LanguageClient#textDocument_hover()<CR>
nnoremap <silent> K :call LanguageClient#textDocument_hover()<CR>
let g:LanguageClient_hoverPreview = 'Always'
set completefunc=LanguageClient#complete

" ASYNCRUN Plugin
let g:asyncrun_open = 30

" DEOPLETE
let g:deoplete#enable_at_startup = 1
" <TAB>: completion.
inoremap <expr><TAB>  pumvisible() ? "\<C-n>" : "\<TAB>"

" ASYNCRUN Plugin
" let g:asyncrun_open = 30
let g:asyncrun_wrapper = 'ZDOTDIR=~ '
let g:asyncrun_shell = '/usr/bin/zsh'
let g:asyncrun_shellflag = '-d -f'

if has("nvim")
  " Make escape work in the Neovim terminal.
  tnoremap jk  <C-\><C-n>

  " Make navigation into and out of Neovim terminal splits nicer.
  tnoremap <C-h> <C-\><C-N><C-w>h
  tnoremap <C-j> <C-\><C-N><C-w>j
  tnoremap <C-k> <C-\><C-N><C-w>k
  tnoremap <C-l> <C-\><C-N><C-w>l

  " Prefer Neovim terminal insert mode to normal mode.
  autocmd BufEnter term://* startinsert
endif

" LIGHTLINE Plugin
set laststatus=2
let g:lightline = {
      \ 'active': {
      \   'left': [ [ 'mode', 'paste' ],
      \             [ 'gitbranch', 'readonly', 'filename', 'modified' ] ]
      \ },
      \ 'component_function': {
      \   'gitbranch': 'FugitiveHead'
      \ },
      \ }

" vim color
"colorscheme onedark
colorscheme gruvbox
" colorscheme stellarized
" colorscheme wombat256mod

" Use whitespaces
set tabstop=4
set softtabstop=4
set shiftwidth=4
set expandtab

set showcmd
set number
set cursorline

set incsearch
set hlsearch

" Function parameter indentation
set cinoptions=:0,l1,t0,g0,(0

" if hidden is not set, TextEdit might fail.
set hidden

" Some servers have issues with backup files, see #649
set nobackup
set nowritebackup

" Better display for messages
set cmdheight=2

" You will have bad experience for diagnostic messages when it's default 4000.
set updatetime=100

" don't give |ins-completion-menu| messages.
set shortmess+=c

" always show signcolumns
set signcolumn=yes

set colorcolumn=121
 "choose any desired cterm/gui color, red usually is noticed :)
highlight ColorColumn ctermbg=red guibg=red

" Clipboard integration
set clipboard+=unnamedplus

" Time for keymaps
"*********************************************
"**************** Key Maps *******************
"*********************************************
inoremap '' ''<Left>
inoremap <> <><Left>
inoremap <leader><leader> <esc>A
inoremap <z <><Left>
inoremap cC ""<Left>
inoremap jk <esc>:w<cr>
inoremap nN \n
inoremap kk <esc>A {<cr>}<esc>O
inoremap kK <esc>A {<cr>};<esc>O
inoremap ( ()<Left>
inoremap [ []<Left>
inoremap { {}<Left>
inoremap <leader>. <esc>:call ToggleBlockLineCommentRuntime()<cr>$hhi

nnoremap <leader><TAB> :AsyncRun -mode=term 
nnoremap <leader>c :call ToggleLineComment()<cr>
nnoremap <leader><leader> :call AutoHighlightToggle()<cr>
nnoremap <leader>R :LanguageClientStop<cr>:echo "Sleeping 1 s"<cr>:sleep 1<cr>:LanguageClientStart<cr>
nnoremap ; :FZF<cr>
nnoremap <C-h> <C-w><Left>
nnoremap <C-j> <C-w><Down>
nnoremap <C-k> <C-w><Up>
nnoremap <C-l> <C-w><Right>
nnoremap <C-m> <C-w>s
nnoremap <C-n> <C-w>v
nnoremap <C-w>h <C-w>s
nnoremap <F5> :FSHere<cr>
nnoremap <leader>5 mzgg=G`z
nnoremap <leader><space> :nohlsearch<cr>
nnoremap <leader>B :bd
nnoremap <leader>a <esc>ggvG
nnoremap <leader>b :BufstopFast<cr>
nnoremap <leader>e :call feedkeys(":edit " . expand('%:p:h') . "/")<cr>
nnoremap <leader>g :GitGutterPreviewHunk<cr>
nnoremap <leader>h 30h
nnoremap <leader>j 30j
nnoremap <leader>k 30k
nnoremap <leader>l 30l
nnoremap <leader>s :%s/\<<C-r><C-w>\>//gc<Left><Left><Left>
nnoremap <leader>v :so $HOME/.config/nvim/init.vim<cr>
nnoremap <leader>w :%s/\s\+$//g<cr>
nnoremap <space> :b#<cr>
nnoremap <leader>gs :Gstatus<cr>
nnoremap <leader>gb :Gblame<cr>
nnoremap DD :1,$d<cr>
nnoremap QQ :qall!<cr>
nnoremap S :w<cr>
nnoremap e $
nnoremap qq :q<cr>
nnoremap s <NOP>
nnoremap se :wq<cr>
nnoremap z =$;
nnoremap <leader>F :call GGrepAllTerrain()<cr>
nnoremap <leader>. *``
nnoremap <C-C> :call BlockCommentInteractive()<cr>
nnoremap <C-U> :call BlockUncomment()<cr>

vnoremap <leader>f zf
vnoremap <leader>u zo
vnoremap <C-C> :call VisualBlockComment()<cr>

if filereadable("/home/".$USER."/init-specific.vim")
    source /home/$USER/init-specific.vim
else
    echo "Didn't find specific /home/".$USER."/init-specific.vim file"
endif

"*********************************
"***** Functions + Commands ******
"*********************************
command! -bang -nargs=* GGrep
  \ call fzf#vim#grep(
  \   'git grep --line-number --color=always -w '.shellescape(<q-args>).' .', 0,
  \   fzf#vim#with_preview({'dir': systemlist('git rev-parse --show-toplevel')[0]}), <bang>0)

function! GGrepAllTerrain()
    if (empty(expand('<cword>')))
        :call feedkeys(":GGrep ")
    else
        :call feedkeys(":GGrep " . expand('<cword>'))
    endif
    :call feedkeys("\<CR>")
endfunction

" Highlight all instances of word under cursor, when idle.
" Useful when studying strange source code.
" Type z/ to toggle highlighting on/off.
function! AutoHighlightToggle()
  let @/ = ''
  if exists('#auto_highlight')
    au! auto_highlight
    augroup! auto_highlight
    "setl updatetime=4000
    echo 'Highlight current word: off'
    return 0
  else
    augroup auto_highlight
      au!
      au CursorHold * let @/ = '\V\<'.escape(expand('<cword>'), '\').'\>'
    augroup end
    "setl updatetime=500
    echo 'Highlight current word: ON'
    return 1
  endif
endfunction

function! BlockComment(line1, line2)
    let format = GetFileExtension()
    if format == "//"
        call append(a:line1 - 1, "/*")
        call append(a:line2 + 1, "*/")
    elseif format == "#"
        let current = a:line1
        while current <= a:line2
            call setline(current, "# ". getline(current))
            let current = current + 1
        endwhile
    endif
endfunction

function! BlockCommentInteractive()
    "Get first line from line number line1
    let init = 1
    let end = line('$')
    let correct = 0
    while correct == 0
        call inputsave()
        let line1 = input('Starting line?: ')
        call inputrestore()
        if line1 > 0 && line1 < end
            let correct = 1
        endif
    endwhile

    let correct = 0
    while correct == 0
        call inputsave()
        let line2 = input('End line?: ')
        call inputrestore()
        if line2 > 0 && line2 < end && line1 <= line2
            let correct = 1
        endif
    endwhile
    call BlockComment(line1, line2)
endfunction

function! BlockUncomment()
    let init_line = line('^')
    let last_line = line('$')
    " Get current line number
    let current_line = line('.')
    let line = current_line
    " Loop upwards looking for the /* sequence
    " Search() will return the line number
    let position = search('\/\*', 'b', 'W')
    " Search now downwards for the */ sequence
    let position2 = search('\*\/', 'W')
    " Last check: if there is a whole file comment
    " and the first line is actually the start of the
    " comment. It happens that if no /* or */ are found,
    " that the initial and end lines are returned from
    " the search() command
    if position == init_line && position2 == last_line
        let found = match(getline(init_line), "/*")
        echo "found: " . string(found)
        if found == 0
            exe position . 'd'
            let updated_position2 = position2 - 1
            exe updated_position2 . 'd'
        endif
    else
        "  		if position == position2
        "  			echo 'Not found'
        "  		else
        exe position . 'd'
        let updated_position2 = position2 - 1
        exe updated_position2 . 'd'
        "  		endif
    endif
endfunction

fun! VisualBlockComment() range
    let line_start = getpos("'<")[1]
    let line_end = getpos("'>")[1]
    call BlockComment(line_start, line_end) 
endfun

function Prompt(str)
	call inputsave()
	let ans = input(a:str)
	call inputrestore()
	return ans
endfunction

function AddField(linr, str)
	call append(a:linr, a:str)
" 	execute ":w"
" 	execute ":edit " . expand("%:p")
endfunction

fun! ContextBlock() range
    let lineStart = getpos("'<")[1]
    let lineEnd = getpos("'>")[1]
    call append(lineStart, "{")
    call append(lineEnd+1, "}")
endfun!

function! InitHeader()
    call inputsave()
    let symbol = input('Enter symbol to define: ')
    call inputrestore()

    call setline(line('.'), "#ifndef " . symbol)
    call setline(line('.') + 1, "#define " . symbol)
    call append(line('$'), "")
    call append(line('$'), "")
    call append(line('$'), "")
    call append(line('$'), "#endif /* " . symbol . " */")

    execute "normal! 3ji"

endfunction

function! GetFileExtension()
    let current_filename = expand("%")
    """"""""""""""""""""""""""""""""""""""""""""""""""""""""
    " Check for file format, since comment mark will depend
    " on that
    """"""""""""""""""""""""""""""""""""""""""""""""""""""""
    let format = split(current_filename, '\.')[-1]
    if format == "c" || format == "h" ||
                \ format == "cpp" || format == "hpp" || format == "cc" || format == "cxx" ||
                \ format == "tpp" || format == "tcc" ||
                \ format == "java" ||
                \ format == "dts" || format == "l" || format == "y" || format == "cu" || format == "cl"
        return "//"
    elseif format == "sh" || format == "bash" || format == "bb" || format == "bbappend" ||
                \ format == "conf" || format == "cfg" || format == "bashrc" || format == "bash_aliases" ||
                \ format == "config" ||
                \ format == "ovpn"
        return "#"
    elseif format == "vim" || format == "vimrc"
        return '"'
    elseif format == "bashrc" || format == "bash_aliases"
        return "#"
    else
        return '#'
    endif
endfunction

function! ToggleLineComment()
    " Get current line
    let current_filename = expand("%")
    let line = getline('.')
    let pattern = GetFileExtension()
    " Check if line starts with pattern: recommended format
    let comment = substitute(line, '^\s*' . fnameescape(pattern) . '\s*', "", "")

    if comment == line  "  No comment was found  "
        call setline(line('.'), pattern . " " . line)
    else  "  Comment was found  "
        call setline(line('.'), comment)
        " Indent current line
        execute "normal! =$"
    endif
endfunction

function! ToggleBlockLineComment(wholeline)
    let open_pattern = GetFileExtension()
    " Check if C/C++/Java/DTS file for /**/ type comments
    if open_pattern == "//"
        let open_pattern = "/*"
    endif
    let close_pattern = join(reverse(split(open_pattern, '\zs')), '')
    if a:wholeline == 0
        " Get current line
        let line = getline('.')

        let comment1 = substitute(line, fnameescape(open_pattern) . '\s*', "", "")
        let comment2 = substitute(comment1, '\s*' . fnameescape(close_pattern), "", "")
        if line == comment2  " No comment was found  "
            call setline(line('.'), open_pattern . " " . line . " ". close_pattern)
        else  " Comment was found "
            call setline(line('.'), comment2)
            execute "normal! =$"
        endif
    elseif a:wholeline == 1
        call VisualToggleBlockLineCommentRuntime()
    endif
endfunction


function! ToggleBlockLineCommentRuntime()
    let open_pattern = GetFileExtension()
    if open_pattern == "//"
        let open_pattern = "/*"
    endif
    let close_pattern = join(reverse(split(open_pattern, '\zs')), '')
    let line = getline('.')
    let comment1 = substitute(line, fnameescape(open_pattern) . '\s*', "", "")
    let comment2 = substitute(comment1, '\s*' . fnameescape(close_pattern), "", "")
    if line == comment2  " No comment was found  "
        call setline(line('.'), getline('.') . " " . open_pattern . "  " . close_pattern)
    else
        call setline(line('.'), comment2)
    endif
endfunction

fun! VisualToggleBlockLineCommentRuntime() range
    let open_pattern = GetFileExtension()
    " Check if C/C++/Java/DTS file for /**/ type comments
    if open_pattern == "//"
        let open_pattern = "/*"
    else
        echo "WARNING: individual word comment in same line not supported for current language, skipping..."
        return
    endif
    let close_pattern = join(reverse(split(open_pattern, '\zs')), '')
    let [line_start, column_start] = getpos("'<")[1:2]
    let [line_end, column_end] = getpos("'>")[1:2]
    " TODO: investigate if a function already does this
    if line_start != line_end
        return
    endif
    let current_line_str = getline('.')
    let column_start -= 1
    let column_end -= 2
    let final_line_str = current_line_str
    let final_line = split(final_line_str, '\zs')
    let current_line = split(current_line_str, '\zs')
    let offset = 2
    call insert(final_line, open_pattern, column_start)
    call insert(final_line, close_pattern, column_end + offset)
    call setline(line('.'), join(final_line, ''))
endfun


function! LineLength(inputStr, maxAllowedLineLength)

    let maxLineLength = a:maxAllowedLineLength

    let splitList = split(a:inputStr, ' ')
    let returnList = []

    let index = 0
    let currentLength = 0
    let currentSentence = ""

    while index < len(splitList)
        let currentSentence = currentSentence . splitList[index] . " "
        let currentLength = len(currentSentence)
        if currentLength == maxLineLength
            call add(returnList, currentSentence)
            " Reset the sentence
            let currentSentence = ""
        elseif currentLength > maxLineLength
            " Cut out the last word and put it into currentSentence
            let tmp = split(currentSentence, ' ')
            let currentSentence = tmp[-1] . ' '
            call add(returnList, join(tmp[0:-2], ' '))
        endif
        let index += 1
    endwhile
    " Last check: add what remains in currentSentence
    call add (returnList, currentSentence)
    let a = 0
    while a < len(returnList)
        let a+=1
    endwhile
    return returnList
endfunction

function! ToggleVisualWrap(type)
    let colInit  = 1
    let colEnd   = len(getline('.'))

    let posStart = getpos("'<")
    let posEnd   = getpos("'>")

    let colStart = posStart[2]
    let colStop = posEnd[2]

    echo "Pos start: " colStart ", pos End: " colStop
    echo "Pos init: " colInit ", pos End: " colEnd
    if colStop == colEnd
        execute "normal! dA" . a:type . "<esc>pA" . a:type . "<esc>"
    elseif colInit == colStart
        echo "This case"
"         execute "normal! di" . a:type . "<esc>pli" . a:type . "<esc>"
execute "normal! dd"
    endif
    " If selection is inside line (most normal case)
    if colStart > colInit && colEnd < colEnd
        execute "normal! di" . a:type . "<esc>pli" . a:type . "<esc>"
    endif
endfunction!
