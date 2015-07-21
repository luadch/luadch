rem @echo off

set openssl_headers=C:\Programme\OpenSSL\include\
set openssl_libs=C:\Programme\OpenSSL\lib\MinGW

set root=%cd%
set build=%root%\build_mingw
set lib=%root%\lua\src
set include=%lib%
set hub=%root%\build_mingw\luadch


cd %openssl_libs%
copy ssleay32.a libssleay32.a

cd %root%\lua\src
echo Building lua.dll...
gcc -O2 -Wall -DLUA_BUILD_AS_DLL -DLUA_COMPAT_ALL -c *.c
gcc -shared -o lua.dll lapi.o lcode.o ldebug.o ldo.o ldump.o lfunc.o lgc.o llex.o lmem.o lobject.o lopcodes.o lparser.o lstate.o lstring.o ltable.o ltm.o lundump.o lvm.o lzio.o lauxlib.o lbaselib.o ldblib.o liolib.o lmathlib.o loslib.o ltablib.o lstrlib.o loadlib.o linit.o
strip --strip-unneeded lua.dll
xcopy lua.dll "%hub%\*.*" /y /f
del *.o

cd %root%\adclib 
echo Building adclib.dll...
g++ -O3  -Wall -c -I%include% *.cpp
g++ -shared -static-libgcc -static-libstdc++ -o adclib.dll *.o -L%lib% -llua
strip --strip-unneeded adclib.dll
xcopy adclib.dll "%hub%\lib\adclib\*.*" /y /f
del adclib.dll
del *.o

cd %root%\res
windres -i res.rc -o icon.o
xcopy icon.o "%root%\hub\*.*" /y /f
del *.o

cd %root%\hub
echo Building hub.exe...
gcc -O2 -DWINVER=0x0501 -Wall -c -I%include% *.c
gcc -o Luadch.exe *.o -L%lib% -llua
strip --strip-unneeded Luadch.exe
xcopy Luadch.exe "%hub%\*.*" /y /f
del *.exe
del *.o

cd %root%\slnunicode
echo Building unicode.dll...
gcc -O2 -Wall -c -I%include% slnunico.c slnudata.c
gcc -shared -o unicode.dll slnunico.o slnudata.o -L%lib% -llua
strip --strip-unneeded unicode.dll
xcopy unicode.dll "%hub%\lib\unicode\*.*" /y /f
del unicode.dll
del *.o

cd %root%\luasocket\src
echo Building socket.dll...
ren mime.c mime.c.not
ren unix.c unix.c.not
ren usocket.c usocket.c.not
gcc -O2 -DWINVER=0x0501 -DLUASOCKET_INET_PTON -DLUASO -c -I%include% *.c  
gcc -shared -o socket.dll *.o -lkernel32 -lws2_32 -L%lib% -llua
strip --strip-unneeded socket.dll
xcopy socket.dll "%hub%\lib\luasocket\socket\*.*" /y /f
ren mime.c.not mime.c

echo Building mime.dll...
gcc -O2 -c -I%include% mime.c
gcc -shared -o mime.dll mime.o -lkernel32 -lws2_32 -L%lib% -llua
strip --strip-unneeded mime.dll
xcopy mime.dll "%hub%\lib\luasocket\mime\*.*" /y /f
xcopy ltn12.lua "%hub%\lib\luasocket\lua\*.*" /y /f
xcopy mime.lua "%hub%\lib\luasocket\lua\*.*" /y /f
xcopy socket.lua "%hub%\lib\luasocket\lua\*.*" /y /f
xcopy ftp.lua "%hub%\lib\luasocket\lua\*.*" /y /f
xcopy http.lua "%hub%\lib\luasocket\lua\*.*" /y /f
xcopy smtp.lua "%hub%\lib\luasocket\lua\*.*" /y /f
xcopy tp.lua "%hub%\lib\luasocket\lua\*.*" /y /f
xcopy url.lua "%hub%\lib\luasocket\lua\*.*" /y /f
ren unix.c.not unix.c
ren usocket.c.not usocket.c
del socket.dll
del mime.dll
del *.o

cd %root%\luasec\src
echo Building ssl.dll...
ren usocket.c usocket.c.not
gcc -O2 -DWINVER=0x0501 -DLUASOCKET_INET_PTON -DLUASO -DOPENSSL_NO_HEARTBEATS -c -I%include% -I%openssl_headers% *.c  
gcc -shared -o ssl.dll *.o -L%openssl_libs% -leay32 -lssleay32 -lkernel32 -lws2_32 -L%lib% -llua 
strip --strip-unneeded ssl.dll
xcopy ssl.dll "%hub%\lib\luasec\ssl\*.*" /y /f
xcopy ssl.lua "%hub%\lib\luasec\lua\*.*" /y /f
ren usocket.c.not usocket.c
del ssl.dll
del *.o

echo Copy core...

xcopy %root%\core "%hub%\core\*.*" /y /f
xcopy %root%\scripts "%hub%\scripts\*.*" /y /f /e
xcopy %root%\examples\cfg "%hub%\cfg\*.*" /y /f
xcopy %root%\examples\certs "%hub%\certs\*.*" /y /f
xcopy %root%\examples\lang "%hub%\lang\*.*" /y /f
xcopy %root%\docs "%hub%\docs\*.*" /y /f

cd %hub%
mkdir log
cd %root%


echo Building done.

pause
