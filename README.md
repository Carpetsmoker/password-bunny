Manage passwords with Vim.

Use `./pwbunny filename` to start the program.

You will need Vim 7.3 or later.
This program was tested on FreeBSD 9, and Ubuntu 12; it will *probably* also
work on other POSIX systems (Other Linux systems, OpenBSD, MacOSX, etc.).  
It will *not* work on Windows.


Clipboard support
-----------------
Some functions (`<Leader>c`, `<Leader>C`, and `<Leader>u`) need some way to
access the clipboard. If Vim has `+clipboard` we'll use that. If it doesn't, we
try to use one of these commandline utilities:

- [xclip][xclip]
- [xcopy][xcopy]
- xsel (the original, no page) or the [newer xsel][xsel]


Clipboard support is *optional*.


Keybinds
--------
- `<Leader>a`  
Add a new entry, this is the recommended way to add a new entry.

- `<Leader>c`  
Copy the password of the entry under the cursor (which may still be in a closed
fold). This is useful if someone may be watching over your shoulder.  
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

- `<Leader>s`  
Sort all entries by title (the 1st line).

By default, Vim maps `<Leader>` to `\`.


File format
-----------
The file format is extremely simple

- An entry *must* have at least 3 lines.
- An entry *must* be followed by 1 or more empty lines; except for the last
  entry, where an empty line is *optional*.
- The 1st line *must* be the title, which also doubles as the URL.
- The 2nd line *must* be the username.
- The 3rd line *must* be the password.
- An entry *may* have as many lines as desired. This is useful for storing notes
  and extra data (eg. SSH fingerprints).


Security
--------
- The file is encrypted with [blowfish][blf], which should be secure.
- Your system's memory will containt the plaintext contents.
- We issue no warnings against unwise passwords (either as master password for
  the file, or passwords for the sites you add). It's *your* responsibility to
  choose good passwords. You *should* use the built-in password generator.
- May not be safe against holy hand grenade attacks.


TODO
----
- Undo after `PwbunnySort()` removes all folds
- Make `\c` & `\u` work over ssh sessions
- Prepare for unexpected inquisitions


Functions
---------
- `PwbunnyFold()`  
Remove & recreate all folds. This is called on startup

- `PwbunnyMakePassword()`  
Generate a random password (mapped to `<Leader>p`)

- `PwbunnyAddEntry()`  
Add a new entry (mapped to `<Leader>a`)

- `PwbunnyGetSite()`  
Get title/sitename of the entry under the cursor

- `PwbunnyGetUser()`  
Get username of the entry under the cursor

- `PwbunnyGetPassword()`  
Get password of the entry under the cursor

- `PwbunnyGetLine(n)`  
Get line number *n* of the entry under the cursor

- `PwbunnyCopyPassword()`  
Copy the password of the entry under the cursor (mapped to `<Leader>c`)

- `PwbunnyCopyUserAndPassword()`
Copy the username of the entry under the cursor, and after a while go ahead and
copy the password (mapped to `<Leader>u`)

- `PwbunnyGetEntries()`  
Get a list of all entries as `[start, end]`

- `PwbunnySort()`  
Sort *all* entries (mapped to `<Leader>s`)

- `PwbunnyEmptyClipboard()`  
Clear the clipboard

- `PwbunnyCopyToClipboard(str)`  
Copy *str* to the clipboard

- `PwbunnyOpen()`  
Detect is the correct password was entered


[blf]: http://en.wikipedia.org/wiki/Blowfish_(cipher)
[xclip]: http://sourceforge.net/projects/xclip
[xsel]: http://www.vergenet.net/~conrad/software/xsel/
[xcopy]: http://www.chiark.greenend.org.uk/~sgtatham/utils/xcopy.html
