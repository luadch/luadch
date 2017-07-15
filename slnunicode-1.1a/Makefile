VERSION?=5.1.5
# put next to lua-5.1.5 or run with VERSION=xxx make ...
# then make -f slnunicode-1.1a/Makefile

unicode.so: slnunicode-1.1a/slnunico.c slnunicode-1.1a/slnudata.c
	gcc -Islnunicode-1.1a -Ilua-${VERSION}/src -shared -Wall -Os -fpic -o unicode.so slnunicode-1.1a/slnunico.c
	lua-${VERSION}/src/lua slnunicode-1.1a/unitest

clean:
	rm unicode.so
