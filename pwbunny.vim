"
" pwbunny: Manage passwords with Vim
"
" TODO:
" - Add a help window
" - Also add extra whitespace to fold
" - Write docs
"


nnoremap <Leader>a :call AddEntry()<CR>
nnoremap <Leader>c :call CopyPassword()<CR>
nnoremap <Leader>p :echo MakePassword()<CR>

set foldopen=""
set foldclose="all"
set foldtext=getline(v:foldstart)
set fillchars=""

fun! Pwbunny()
	normal zE
	normal 1G

	let l:i = 0
	while l:i < line("$")
		if search("^$", "W") <= l:i
			execute l:i + 1 . "," . line("$"). "fold"
			break
		endif

		execute l:i + 1 . "," . line(".") . "fold"
		let l:i = line(".")
	endwhile

	normal zc
	normal 1G
endfun


fun! MakePassword()
	return system("head -c100 /dev/urandom | strings -n1 | tr -d '[:space:]' | head -c15")
endfun


fun! AddEntry()
	let l:site = input("Site: ")
	if l:site == ""
		echoerr "Site is required"
	endif

	let l:user = input("User: ")
	let l:pass = input("Password (enter for random): ")
	if l:pass == ""
		let l:pass = MakePassword()
	endif

	call append("$", "")
	let l:start = line("$")
	call append("$", l:site)
	call append("$", l:user)
	call append("$", l:pass)
	execute l:start . "," . line("$") . "fold"

	execute "w"
endfun


fun! CopyPassword()
	if search("^$", "Wb") > 0 
		normal j
	endif
	normal zojj
	let l:pass = getline(".")
	normal zc

	let l:pass = substitute(l:pass, "\n$", "", "")
	echo l:pass
	call system("echo " . shellescape(l:pass) .  "| xclip")
	echo "Okay"
endfun


call Pwbunny()
