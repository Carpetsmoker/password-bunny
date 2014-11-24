include config.mk

install:
	install -d ${PREFIX}/share/pwbunny
	install -d ${PREFIX}/bin
	install -U pwbunny ${PREFIX}/bin
	install -U gpwbunny ${PREFIX}/bin
	install -U -m 644 pwbunny.vim ${PREFIX}/share/pwbunny
	install -U -m 644 parsejson.vim ${PREFIX}/share/pwbunny

uninstall: .IGNORE
	rm ${PREFIX}/bin/pwbunny
	rm ${PREFIX}/bin/gpwbunny
	rm ${PREFIX}/share/pwbunny/pwbunny.vim
	rm ${PREFIX}/share/pwbunny/parsejson.vim
	rmdir ${PREFIX}/share/pwbunny

.PHONY: install uninstall
