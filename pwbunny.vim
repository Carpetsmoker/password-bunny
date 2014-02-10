"
" password bunny: Manage passwords with Vim
"
" http://code.arp242.net/password-bunny
"
" Copyright © 2014 Martin Tournoij <martin@arp242.net>
" See below for full copyright
"


"""
""" Keybinds
"""

nnoremap <Leader>a :call PwbunnyAddEntry()<CR>
nnoremap <Leader>c :call PwbunnyCopyPassword()<CR>
nnoremap <Leader>p :echo PwbunnyMakePassword()<CR>
nnoremap <Leader>s :call PwbunnySort()<CR>


"""
""" Settings
"""

" Empty the clipboard after this many seconds after calling PwbunnyCopyPassword
" Set to 0 to disable
let s:emptyclipboard = 10

" Length of generated passwords
let s:passwordlength = 15

" Only open fold explicitly (with zo)
setlocal foldopen=

" Close folds as soon as we move out of them
setlocal foldclose=all

" Display less info on closed folds
setlocal foldtext=getline(v:foldstart)
setlocal fillchars=""

" Default is zip (insecure!)
if !has('cryptv')
	echoerr "Your Vim doesn't support encrypting files -- DO NOT USE THIS PROGRAM BEFORE FIXING THIS!"
endif
setlocal cryptmethod=blowfish

" VimInfo file isn't encrypted, and may possible leak data
setlocal viminfo=

" Make sure we keep the backup & swap file in the same directory, they're
" encrypted, but we don't want then dangeling around in tmp dirs
setlocal backupdir=.
setlocal dir=.

" We disabled swap on startup (-n), re-enable it (it will now be created in the
" correct directory, instead of whatever is in ~/.vimrc)
setlocal updatecount=200


"""
""" Functions
"""

" Make folds
fun! PwbunnyFold()
	normal zE
	for e in PwbunnyGetEntries()
		execute e[0] . "," . e[1] . "fold"
	endfor
	normal zc
endfun


" Generate a random password
fun! PwbunnyMakePassword()
	return system("head -c100 /dev/urandom | strings -n1 | tr -d '[:space:]' | head -c" . s:passwordlength)
endfun


" Add a new entry
fun! PwbunnyAddEntry()
	let l:site = input("Site: ")
	if l:site == ""
		echoerr "Site is required"
		return
	endif

	let l:user = input("User: ")
	let l:pass = input("Password (enter for random): ")
	if l:pass == ""
		let l:pass = PwbunnyMakePassword()
	endif

	if line("$") > 1
		let l:first = 0
		call append("$", "")
	else
		let l:first = 1
	endif
	let l:start = line("$")
	call append("$", l:site)
	call append("$", l:user)
	call append("$", l:pass)
	if l:first
		normal dd
	endif

	call PwbunnyFold()
	execute "w"
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
	let l:folded = foldclosed(".")
	if search("^$", "Wb") > 0 
		normal j
	endif
	normal zo

	let l:i = 1
	while l:i < a:n
		normal j
		let l:i += 1
	endwhile
	
	let l:val = getline(".")

	if l:folded > -1
		normal zc
	endif	

	let l:val = substitute(l:val, "\n$", "", "")
	return l:val
endfun


" Copy passwordt with xclip
fun! PwbunnyCopyPassword()
	call system("echo " . shellescape(PwbunnyGetPassword()) .  " | xclip")

	if s:emptyclipboard > 0
		let l:i = 0

		while  l:i < s:emptyclipboard
			echon "\rClipboard will be emptied in " . (s:emptyclipboard - l:i) . " seconds  "
			execute "sleep 1"
			let l:i += 1
		endwhile

		call PwbunnyEmptyClipboard()
	endif
	echo "Okay"
endfun


" Clear the clipboard
fun! PwbunnyEmptyClipboard()
	call system("echo '' | xclip")
endfun


" Sort entries
fun! PwbunnySort()
	let l:names = []
	for e in PwbunnyGetEntries()
		call cursor(e[0], 0)
		call add(l:names, [PwbunnyGetSite(), e[0], e[1]])
	endfor

	fun! s:sort(a, b)
		return a:a[0] == a:b[0] ? 0 : a:a[0] > a:b[0] ? 1 : -1
	endfun
	call sort(l:names, "s:sort")

	let l:new = []
	for e in l:names
		let l:new += getline(e[1], e[2])
	endfor

	normal 1G99909D
	call append(".", l:new)
	normal dd
	call PwbunnyFold()
endfun


" Get list of all entries, as [startline, endline]
fun! PwbunnyGetEntries()
	let l:ret = []

	normal 1G
	while 1
		let l:start = line(".")

		let [l:emptyline, l:col] = searchpos("^$", "W")
		let [l:nemptyline, l:col] = searchpos("^[^$]", "W")

		" Last entry
		if l:emptyline == 0 || l:nemptyline == 0
			call add(l:ret, [l:start, line("$")])
			break
		endif

		call add(l:ret, [l:start, l:nemptyline - 1])
	endwhile

	normal 1G
	return l:ret
endfun


" Let's go!
call PwbunnyFold()


" The MIT License (MIT)
"
" Copyright © 2014 Martin Tournoij
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
