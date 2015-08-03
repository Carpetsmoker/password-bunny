PREFIX?=${HOME}/local

install:
	install -dm755 ${PREFIX}/share/pwbunny
	install -dm755 ${PREFIX}/share/pixmaps
	install -dm755 ${PREFIX}/share/applications
	install -dm755 ${PREFIX}/bin
	install -m755 pwbunny ${PREFIX}/bin
	install -m755 gpwbunny ${PREFIX}/bin
	install -m644 pwbunny.vim ${PREFIX}/share/pwbunny
	install -m644 pwbunny.png ${PREFIX}/share/pixmaps/pwbunny.png
	install -m644 pwbunny.desktop ${PREFIX}/share/applications/pwbunny.desktop
	install -m644 gpwbunny.desktop ${PREFIX}/share/applications/gpwbunny.desktop

uninstall: .IGNORE
	rm ${PREFIX}/bin/pwbunny
	rm ${PREFIX}/bin/gpwbunny
	rm ${PREFIX}/share/pwbunny/pwbunny.vim
	rm ${PREFIX}/share/pixmaps/pwbunny.png
	rm ${PREFIX}/share/applications/pwbunny.desktop
	rm ${PREFIX}/share/applications/gpwbunny.desktop
	rmdir ${PREFIX}/share/pwbunny

.PHONY: install uninstall
