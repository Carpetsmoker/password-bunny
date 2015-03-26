" password bunny: Manage passwords with Vim
"
" http://code.arp242.net/password-bunny
"
" Copyright © 2014-2015 Martin Tournoij <martin@arp242.net>
" See below for full copyright
"

scriptencoding utf-8

"""
""" Keybinds
"""

nnoremap <Leader>a :call PwbunnyAddEntry()<CR>
nnoremap <Leader>g :call PwbunnyGoto(PwbunnyGetSite())<CR>
nnoremap <Leader>c :call PwbunnyCopyPassword()<CR>
nnoremap <Leader>u :call PwbunnyCopyUserAndPassword()<CR>
nnoremap <Leader>C :call PwbunnyEmptyClipboard()<CR>
nnoremap <Leader>p :echo PwbunnyMakePassword()<CR>
nnoremap <Leader>P :put=PwbunnyMakePassword()<CR>
nnoremap <Leader>s :call PwbunnySort()<CR>
nnoremap <Leader>e :echo 'Score: ' . PwbunnyEstimatePassword(PwbunnyGetSite(), PwbunnyGetUser(), PwbunnyGetPassword(), 1)<CR>
nnoremap <Leader>E :call PwbunnyEstimateAllPasswords()<CR>


"""
""" Settings
"""

" Default username to use
let s:defaultuser = 'martin@arp242.net'

" Use the clipboard contents as default site
let s:site_from_clipboard = 1

" Empty the clipboard after this many seconds after calling
" PwbunnyCopyPassword(), set to 0 to disable
let s:emptyclipboard = 10

" Length of generated passwords
let s:passwordlength = 15

" Minimal password score. 4 is recommended, 3 is acceptable, 2 or lower is
" strongly discouraged
let s:min_password_strength = 4

" Sort entries after adding a new one
let s:autosort = 1

" Start private mode by default
let s:private = 0

" Try and see if we can access the clipboard
" You could set this manually for a better startup time if you're using a
" commandline utility`
let s:copymethod = has('clipboard') && has('xterm_clipboard')

if s:copymethod ==# '0'
	if system('which xclip > /dev/null && echo -n 0 || echo -n 1') ==# '0'
		let s:copymethod = 'xclip'
	elseif system('which xcopy > /dev/null && echo -n 0 || echo -n 1') ==# '0'
		let s:copymethod = 'xcopy'
	elseif system('which pbcopy > /dev/null && echo -n 0 || echo -n 1') ==# '0'
		let s:copymethod = 'pbcopy'
	elseif system('which xsel > /dev/null && echo -n 0 || echo -n 1') ==# '0'
		let s:copymethod = 'xsel'

		" Newer xsel, which is an `improved' version, but has incompatible
		" switches..! (why do people do this sort of thing...!?!?)
		if system('xsel --version > /dev/null && echo -n 0 || echo -n 1') ==# '0'
			let s:copymethod = 'xsel-new'
		endif
	endif
endif

setlocal foldmethod=expr
setlocal foldexpr=getline(v:lnum)=~'^\\s*$'&&getline(v:lnum+1)=~'\\S'?'<1':1

" Only open fold explicitly (with zo or insert commands)
setlocal foldopen=

" Close folds as soon as we move out of them
setlocal foldclose=all

" Display less info on closed folds
setlocal foldtext=getline(v:foldstart)
setlocal fillchars=""


"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
""" You probably don't want to change the settings below this """
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""


" Default is zip (insecure!)
if !has('cryptv')
	echoerr "Your Vim doesn't support encrypting files -- DO NOT USE THIS PROGRAM BEFORE FIXING THIS!"
endif
setlocal cryptmethod=blowfish2

" VimInfo file isn't encrypted, and may possible leak data
setlocal viminfo=

" Don't create temp files for shell commands
set noshelltemp

" Disallow autocmd, shell commands, and write commands in the vimrc file
set secure

" Make sure we keep the backup & swap file in the same directory, they're
" encrypted, but we don't want them dangling around in tmp dirs
setlocal backupdir=.
setlocal dir=.
setlocal noundofile

" We disabled swap on startup (-n), re-enable it (it will now be created in the
" correct directory, instead of whatever is in ~/.vimrc)
setlocal updatecount=200


"""
""" Functions
"""

" Find an entry, copy it to the clipboard, and exit Pwbunny
fun! PwbunnyFindCopyClose(name)
	let l:sstr = "/^\\n" . a:name
	try
		execute l:sstr
	" Try again, but skip group names
	catch /^Vim\%((\a\+)\)\=:E385/
		let l:sstr = '/^\n^\w\+: ' . a:name
		echo l:sstr
		try
			execute l:sstr
		catch /^Vim\%((\a\+)\)\=:E385/
			" TODO: ideally, I'd like to exit with status 2, and do this in the
			" shell script... exiting Vim with an exit status other than 0 or 1
			" doesn't seem possible, though...
			try
				echohl ErrorMsg | echo 'Entry not found' | echohl None
				call input('press enter to exit')
			finally
				execute ':q'
			endtry
		endtry
	endtry

	normal! j
	try
		call PwbunnyCopyPassword()
	finally
		execute ':q'
	endtry
endfun


" Generate a random password
fun! PwbunnyMakePassword()
	if !exists('s:passwordlength')
		let s:passwordlength = 15
	endif

	" http://arp242.net/weblog/Generate_passwords_from_the_commandline.html
	return system('strings -n 1 < /dev/urandom | tr -d "[:space:]" | head -c ' . s:passwordlength)
endfun


" Try and extract only the domain part from an URL
fun! PwbunnyExtractDomain(url, only_toplevel)
	let l:domain = a:url

	" Strip spaces and stuff
	let l:domain = substitute(l:domain, '\r', '', 'g')
	let l:domain = substitute(l:domain, '^\s*\|\s*$', '', 'g')
	"let l:domain = strpart(l:domain, 0, 30)
	let l:domain = substitute(l:domain, '^\s*\|\s*$', '', 'g')

	" Get just the domain part
	let l:domain = substitute(l:domain, '^\w*://', '', '')
	let l:domain = substitute(l:domain, '/.*', '', '')

	return l:domain
endfun


" Add a new entry
fun! PwbunnyAddEntry()
	if exists('s:site_from_clipboard') && s:site_from_clipboard
		let l:defaultsite = PwbunnyExtractDomain(PwbunnyGetClipboard(), 1)

		if l:defaultsite !=# ''
			let l:site = input('Site (enter for ' . l:defaultsite . '): ')
		else
			let l:site = input('Site: ')
		endif
		if l:site ==# ''
			let l:site = l:defaultsite
		endif
	else
		let l:site = input('Site: ')
	endif

	if l:site ==# ''
		echoerr 'Site is required'
		return
	endif

	if exists('s:defaultuser') && s:defaultuser !=# ''
		let l:user = input('User (enter for ' . s:defaultuser . '): ')
		if l:user ==# ''
			let l:user = s:defaultuser
		endif
	else
		let l:user = input('User: ')
	endif

	let l:pass = input('Password (enter for random): ')
	if l:pass ==# ''
		let l:pass = PwbunnyMakePassword()
	endif

	if line('$') > 1
		let l:first = 0
		call append('$', '')
	else
		let l:first = 1
	endif
	let l:start = line('$')
	call append('$', l:site)
	call append('$', l:user)
	call append('$', l:pass)
	call append('$', '')
	if l:first
		normal! dd
	endif

	if exists('s:autosort') && s:autosort
		call PwbunnySort()
	endif
	silent execute 'w'

	let l:score = PwbunnyEstimatePassword(l:site, l:user, l:pass, 0)
	if l:score >= 0 && l:score < s:min_password_strength
		echoerr 'Warning: The score for this password is ' . l:score . ' which is lower than the configured minimum score of ' . s:min_password_strength . ' (but we''ve saved your password anyway).'
	endif
endfun


" Get the site of the current entry
fun! PwbunnyGetSite()
	return PwbunnyGetLine(1)
endfun


" Get the username of the current entry
fun! PwbunnyGetUser()
	return PwbunnyGetLine(2)
endfun


" Get the password of the current entry
fun! PwbunnyGetPassword()
	return PwbunnyGetLine(3)
endfun


" Get line number n of an entry
fun! PwbunnyGetLine(n)
	let l:folded = foldclosed('.')

	if search('^$', 'Wb') ==# 0
		normal! 1G
	else
		normal! j
	endif

	if l:folded > -1
		normal! zo
	endif

	let l:i = 1
	while l:i < a:n
		normal! j
		let l:i += 1
	endwhile

	let l:val = getline('.')

	if l:folded > -1
		normal! zc
	endif

	let l:val = substitute(l:val, "\n$", '', '')
	return l:val
endfun


" Copy username to clipboard
fun! PwbunnyCopyUserAndPassword()
	if !PwbunnyCopyToClipboard(PwbunnyGetUser())
		return
	endif

	let l:pw = input('User copied; copy password (Esc or ^C for no)? ', 'yes')
	if l:pw ==? 'yes'
		call PwbunnyCopyPassword()
	endif
endfun


" Copy password to clipboard
fun! PwbunnyCopyPassword()
	if !PwbunnyCopyToClipboard(PwbunnyGetPassword())
		return
	endif

	if exists('s:emptyclipboard') && s:emptyclipboard > 0
		let l:i = 0
		let l:wait = s:emptyclipboard * 10

		" This will cause problems if the terminal window is too small (<65
		" chars), should be very rare, but just in case
		let l:oldmore = &more
		set nomore

		try
			" If we sleep in steps of 1s, pasting has a delay of 1s
			while l:i < l:wait
				echon "\rClipboard will be emptied in " . ((l:wait - l:i) / 10) . 's (^C to cancel, Enter to empty now)'
				execute 'sleep 100m'
				let l:char = getchar(0)
				if l:char ==# 10 || l:char ==# 13
					break
				endif
				let l:i += 1
			endwhile
		finally
			let &more = l:oldmore
		endtry

		call PwbunnyEmptyClipboard()
	endif
endfun


" Clear the clipboard
fun! PwbunnyEmptyClipboard()
	" Using an empty clipboard doesn't seem to work with:
	" let @* = a:str
	if !PwbunnyCopyToClipboard(' ')
		return
	endif
	
	echo 'Clipboard cleared'
endfun


" Sort entries
fun! PwbunnySort()
	let l:names = []
	for e in PwbunnyGetEntries()
		call cursor(e[0], 0)
		call add(l:names, [PwbunnyGetSite(), e[0], e[1]])
	endfor

	fun! s:sort(a, b)
		return a:a[0] ==# a:b[0] ? 0 : a:a[0] > a:b[0] ? 1 : -1
	endfun
	call sort(l:names, 's:sort')

	let l:new = []
	for e in l:names
		let l:new += getline(e[1], e[2])

		" Add a newline to the last entry, if it isn't there (see Issue #1)
		if e[2] ==# line('$') && getline(e[2]) !=# ''
			let l:new += ['']
		endif
	endfor

	normal! 1Gd100%
	call append('.', l:new)

	if getline(1) ==# ''
		normal! 1Gdd
	endif
endfun


" Get list of all entries, as [startline, endline]
fun! PwbunnyGetEntries()
	let l:cursor_save = getpos('.')
	let l:ret = []
	normal! 1G

	while 1
		let l:start = line('.')
		let l:end = foldclosedend('.')
		call add(l:ret, [l:start, l:end])

		if l:end ==# line('$')
			break
		endif

		execute 'normal ' . (l:end + 1) . 'G'
	endwhile

	call setpos('.', l:cursor_save)
	return l:ret
endfun


" Copy str to clipboard
fun! PwbunnyCopyToClipboard(str)
	fun! s:esc(s)
		return shellescape(escape(a:s, '\'))
	endfun

	if s:copymethod ==# '1'
		let @* = a:str
	elseif s:copymethod ==? 'xclip'
		call system('echo -n ' . s:esc(a:str) . ' | xclip')
	elseif s:copymethod ==? 'xcopy'
		call system('echo -n ' . s:esc(a:str) . ' | xcopy')
	elseif s:copymethod ==? 'pbcopy'
		call system('echo -n ' . s:esc(a:str) . ' | pbcopy')
	elseif s:copymethod ==? 'xsel'
		call system('echo -n ' . s:esc(a:str) . ' | xsel -c')
	elseif s:copymethod ==? 'xsel-new'
		call system('echo -n ' . s:esc(a:str) . ' | xsel -i')
	else
		echoerr "Can't access clipboard; please see the `Clipboard support' in the README file"
		return 0
	endif

	return 1
endfun


" Get clipboard contents
" TODO: We could also use xprop -root
fun! PwbunnyGetClipboard()
	if s:copymethod ==# '1'
		let l:contents = @*
	elseif s:copymethod ==? 'xclip'
		let l:contents = system('xclip -o')
	elseif s:copymethod ==? 'xcopy'
		let l:contents = system('xcopy -r')
	elseif s:copymethod ==? 'pbcopy'
		let l:contents = system('pbpaste -Prefer txt')
	elseif s:copymethod ==? 'xsel'
		let l:contents = system('xsel')
	elseif s:copymethod ==? 'xsel-new'
		let l:contents = system('xsel')
	else
		echoerr "Can't access clipboard; please see the `Clipboard support' in the README file"
		return -1
	endif

	if v:shell_error > 0
		return ''
	else
		return l:contents
	endif
endfun


" Try to open domain in browser
fun! PwbunnyGoto(site)
	let l:site = a:site
	if l:site !~? '^https\?:\/\/'
		let l:site = 'https://' . l:site
	endif

	call netrw#BrowseX(l:site, netrw#CheckIfRemote())
endfun


" Estimate strenght of a password
fun! PwbunnyEstimatePassword(site, user, password, warn)
	" TODO: Maybe split weak list more? Not sure how zxcvbn handles this...

	let l:method = 'none'

	if has('python') || has('python3')
		try
			python import vim, zxcvbn
			let l:method = 'python'
		catch
		endtry
	endif

	if !l:method && has('ruby')
		try
			ruby require 'zxcvbn'
			let l:method = 'ruby'
		catch
		endtry
	endif

	let l:score = -1 " Not required, but makes vint happy
	if l:method ==? 'python'
		python import vim, zxcvbn
		python score = zxcvbn.password_strength(vim.eval('a:password'), [vim.eval('a:site'), vim.eval('a:user')])['score']
		python vim.command('let l:score = %s' % score)
	elseif l:method ==? 'ruby'
		ruby require 'zxcvbn'
		ruby VIM.command("let l:score = #{Zxcvbn.test(VIM.evaluate('a:password'), [VIM.evaluate('a:site'), VIM.evaluate('a:user')]).score}")
	else
		if a:warn
			echoerr 'This requires either Python or Ruby support, and the zxcvbn module for this language (see README)'
		endif
		return -1
	endif

	return l:score
endfun


fun! PwbunnyEstimateAllPasswords()
	let l:bad = []
	for e in PwbunnyGetEntries()
		call cursor(e[0], 0)
		let l:site = PwbunnyGetSite()
		let l:score = PwbunnyEstimatePassword(l:site, PwbunnyGetUser(), PwbunnyGetPassword(), 1)
		" Unsupported, no sense in going on
		if l:score ==# -1 | break | endif

		if l:score < s:min_password_strength
			call add(l:bad, l:score . '    ' . l:site)
		endif
	endfor

	call sort(l:bad)
	if len(l:bad) ==# 0
		echo 'All your passwords have a minimum score of ' . s:min_password_strength . '.'
	else
		echo 'The following passwords have a score lower than ' . s:min_password_strength . ':'
		for b in l:bad
			echo l:b
		endfor
	endif
endfun


" Enable 'private mode'
fun! PwbunnySetPrivate()
	setlocal foldtext=
endfun


" If there are less than 3 + (bytes / 100) newlines, we assume the password
" is incorrect, and we're displaying a bunch of gibberish. Quit, and try
" again
fun! PwbunnyOpen()
	fun! s:seems_okay()
		return !(getline(1) !=# '' && line('$') < 3 + (line2byte(line('$')) / 100))
	endfun

	" gVim
	if has('gui_running')
		while 1
			if s:seems_okay()
				normal! zc
				if s:private | call PwbunnySetPrivate() | endif
				break
			endif

			set key=
			edit
		endwhile
	" From terminal, exit and let the shell script show a message
	" advantage over re-setting key is that we can ^C out of this, which is not
	" possible with the above (maybe we can hack that, though? Would be cool)
	else
		if !s:seems_okay()
			" User pressed ^C
			if strpart(getline('.'), 0, 12) ==# 'VimCrypt~03!'
				quit!
			else
				cquit!
			endif
		else
			normal! zc
		endif
	endif
endfun


" Let's go!
call PwbunnyOpen()


" The MIT License (MIT)
"
" Copyright © 2014-2015 Martin Tournoij
"
" Permission is hereby granted, free of charge, to any person obtaining a copy
" of this software and associated documentation files (the "Software"), to
" deal in the Software without restriction, including without limitation the
" rights to use, copy, modify, merge, publish, distribute, sublicense, and/or
" sell copies of the Software, and to permit persons to whom the Software is
" furnished to do so, subject to the following conditions:
"
" The above copyright notice and this permission notice shall be included in
" all copies or substantial portions of the Software.
"
" The software is provided "as is", without warranty of any kind, express or
" implied, including but not limited to the warranties of merchantability,
" fitness for a particular purpose and noninfringement. In no event shall the
" authors or copyright holders be liable for any claim, damages or other
" liability, whether in an action of contract, tort or otherwise, arising
" from, out of or in connection with the software or the use or other dealings
" in the software.
