Manage passwords with Vim.

You will need Vim 7.3 or later.
This program was tested on FreeBSD & Arch Linux; it will *probably* also work on
other POSIX systems (OpenBSD, MacOSX, Other Linuxes, etc.). It will *not* work
on Windows.

Use `./pwbunny` to start the program or use `./gpwbunny` to use gVim. You can
optionally specify a file to open, i.e.: `./pwbunny my-passwords`. The default
is `passwords.pwbunny` in the directory `pwbunny` was  called from.  
See `pwbunny -h` for more commandline options.


Clipboard support
=================
Some functions need some way to access the clipboard. If Vim has `+clipboard`
we’ll use that. If it doesn’t, we try to use one of these commandline utilities:

- [xclip][xclip]
- [xcopy][xcopy]
- xsel (the original, no page) or the [newer xsel][xsel]


Clipboard support is useful but entirely *optional*.

You can also use the clipboard features over an ssh session with X11 forwarding,
please see the notes in the ‘Security’ section before enabling this.

You also need to enable both `ForwardX11` and `ForwardX11Trusted`; on the
commandline this can be done with the `-X` and `-Y` flags, i.e.:
`ssh -XY $server`

Or you can set these options for a host in your `~/.ssh/config`:

	Host myhost
		ForwardX11 yes
		ForwardX11Trusted yes

Security
========
- The file is encrypted with [blowfish][blf], which should be secure.

- Your system’s memory will contain the plaintext contents.

- We issue no warnings against unwise passwords (either as master password for
  the file, or passwords for the sites you add). It’s *your* responsibility to
  choose good passwords. You *should* use the built-in password generator.

- Using `ForwardX11Trusted` effectively gives the server complete control over
  the machine you’re connecting with, which may be a **serious** security
  problem. **Only** use this if you fully trust the server, and **do not** set
  these options globally!

- May not be safe against holy hand grenade attacks.


Keybinds
========
- `<Leader>a`  
Add a new entry. This is the recommended way to add a new entry.

- `<Leader>c`  
Copy the password of the entry under the cursor (which may still be in a closed
fold). This is especially useful if someone may be watching over your shoulder.  
By default, your clipboard will be automatically emptied after 10 seconds, this
timeout can be changed (or disabled) by setting `s:emptyclipboard` in
`pwbunny.vim`.

- `<Leader>u`  
Copy the username of the entry under the cursor (which may still be in a closed
fold); and after a user confirmation, also copy the password (as with
`<Leader>c`)

- `<Leader>C`  
Empty the clipboard.

- `<Leader>p`  
Generate a random password.

- `<Leader>P`  
Generate a random password & insert it at the cursor position.

- `<Leader>s`  
Sort all entries by title (the first line).

By default, Vim maps `<Leader>` to `\`.


Settings
========
- `s:defaultuser`  
Default username to use (default: unset).

- `s:site_from_clipboard`  
Use the clipboard contents as default site; it will try and get the domain part
from an URL (default: 1).

- `s:emptyclipboard = 10`  
Empty the clipboard after this many seconds after calling
`PwbunnyCopyPassword()`, set to 0 to disable (default: 10).

- `s:passwordlength = 15`  
Length of generated passwords (default: 15).

- `s:autosort = 1`  
Sort entries after adding a new one (default: 1).


File format
==========
The file format is extremely simple

- An entry *must* have at least 3 lines.

- An entry *must* be followed by 1 or more empty lines; except for the last
  entry, where an empty line is *optional*.

- The 1st line *must* be the title and *must* be present. THis line also doubles as the domain.

- The 2nd line *must* be the username, and *may* be blank.

- The 3rd line *must* be the password, and *may* be blank.

- An entry *may* have as many lines as desired. This is useful for storing
  notes, answers to ‘security questions’ (which should also be random), and
  other extra data (e.g. SSH fingerprints).


Changelog
=========

Latest source
-------------
- Add `-c` commandline option to find an entry, copy it to the clipboard, and
  exit immediately *(patch by yggdr)*.

- Add `<Leader>P` to insert a random password at the cursor position *(patch by
  yggdr)*.

- Add option `l:defaultuser` to set a default username.

- Add option `l:site_from_clipboard` use the clipboard contents as default site.

- Add option `l:autosort` to sort automatically sort entries after adding a new
  one.

- Add `gpwbunny` to use gVim.

- Fix a few minor bugs.


1.0, 20140510
-------------
- Initial release.


TODO
====
- Undo after `PwbunnySort()` removes all folds.

- The automatic password clearing doesn’t work properly if your terminal window
  is smaller that the timeout counter text displayed (74 characters).

- Write some tests (http://usevim.com/2012/10/17/vim-unit-tests/).

- A tool to regenerate passwords, and/or store when they were last changed,
  perhaps also integrate https://datalossdb.org and/or
  http://thepasswordproject.com/leaked_password_lists_and_dictionaries

- `gpwbunny` is not perfect, since it also relies on input from the terminal if
  the user enters a wrong password.

- Prepare for unexpected inquisitions.


Functions
=========
- `PwbunnyFold()`  
Remove & recreate all folds. This is called on startup.

- `PwbunnyMakePassword()`  
Generate a random password (mapped to `<Leader>p`).

- `PwbunnyAddEntry()`  
Add a new entry (mapped to `<Leader>a`).

- `PwbunnyGetSite()`  
Get title/sitename of the entry under the cursor.

- `PwbunnyGetUser()`  
Get username of the entry under the cursor.

- `PwbunnyGetPassword()`  
Get password of the entry under the cursor.

- `PwbunnyGetLine(n)`  
Get line number *n* of the entry under the cursor.

- `PwbunnyCopyPassword()`  
Copy the password of the entry under the cursor (mapped to `<Leader>c`).

- `PwbunnyCopyUserAndPassword()`
Copy the username of the entry under the cursor, and after a while go ahead and
copy the password (mapped to `<Leader>u`).

- `PwbunnyGetEntries()`  
Get a list of all entries as `[start, end]`.

- `PwbunnySort()`  
Sort *all* entries (mapped to `<Leader>s`).

- `PwbunnyEmptyClipboard()`  
Clear the clipboard.

- `PwbunnyCopyToClipboard(str)`  
Copy *str* to the clipboard.

- `PwbunnyGetClipboard()`  
Get contents of clipboard.

- `PwbunnyOpen()`  
Detect is the correct password was entered.

- `PwbunnyFindCopyClose(name)`
Find an entry by name, copy it to the clipboard, and exit.


[blf]: http://en.wikipedia.org/wiki/Blowfish_(cipher)
[xclip]: http://sourceforge.net/projects/xclip
[xsel]: http://www.vergenet.net/~conrad/software/xsel/
[xcopy]: http://www.chiark.greenend.org.uk/~sgtatham/utils/xcopy.html
