rem @echo off

set openssl_headers=C:\Programme\OpenSSL\include\
set openssl_libs=C:\Programme\OpenSSL\lib\MinGW

set openssl_headers=g:\__home\var\openssl-1.0.2k\include\
set openssl_libs=g:\__home\var\openssl-1.0.2k\

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
::g++ -shared -static-libgcc -static-libstdc++ -static -lwinpthread -o adclib.dll *.o -L%lib% -llua
g++ *.o  %hub%\lua.dll  -static-libgcc -static-libstdc++ -static -lwinpthread -shared -o adclib.dll
::g++ -shared -static-libgcc -static-libstdc++ -o adclib.dll *.o -L%lib% -llua
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

cd %root%\slnunicode-1.1a
echo Building unicode.dll...
gcc -O2 -Wall -c -I%include% slnunico.c slnudata.c
gcc -shared -o unicode.dll slnunico.o slnudata.o -L%lib% -llua
strip --strip-unneeded unicode.dll
xcopy unicode.dll "%hub%\lib\unicode\*.*" /y /f
del unicode.dll
del *.o

cd %root%\luasocket\src
ren mime.c mime.c.not
ren unix.c unix.c.not
ren unixtcp.c unixtcp.c.not
ren unixudp.c unixudp.c.not
ren usocket.c usocket.c.not
ren unixdgram.c unixdgram.c.not
ren unixstream.c unixstream.c.not
ren serial.c serial.c.not
gcc -DLUASOCKET_INET_PTON -DWINVER=0x0501 -DLUASO -w -fno-common -fvisibility=hidden  -c -I%include% *.c  
::gcc %build%\lua.dll -shared -o socket.dll *.o -lkernel32 -lws2_32
gcc *.o %lib%\lua.dll -shared -Wl,-s -lws2_32 -o socket.dll
strip --strip-unneeded socket.dll
xcopy socket.dll "%hub%\lib\luasocket\socket\*.*" /y /f
xcopy *.lua "%hub%\lib\luasocket\lua\*.*" /y /f
ren mime.c.not mime.c
ren unix.c.not unix.c
ren usocket.c.not usocket.c
ren unixtcp.c.not unixtcp.c 
ren unixudp.c.not unixudp.c
ren unixdgram.c.not unixdgram.c
ren unixstream.c.not unixstream.c
ren serial.c.not serial.c 
del *.dll
del *.o

echo Building ssl.dll...
cd %root%\luasec\src\luasocket
ren usocket.c usocket.c.not
cd %root%\luasec\src
gcc -DLUASEC_INET_NTOP -DWINVER=0x0501 -DLUASO -w -c -I%include% -I%openssl_headers% -I%root%\luasec\src *.c 
gcc *.o %lib%\lua.dll %hub%\lib\luasocket\socket\socket.dll -shared -L%openssl_libs% -lssl -lcrypto -lkernel32 -lgdi32 -lws2_32 -static-libgcc -o ssl.dll
strip --strip-unneeded ssl.dll
xcopy ssl.dll "%hub%\lib\luasec\ssl\*.*" /y /f
xcopy *.lua "%hub%\lib\luasec\lua\*.*" /y /f
cd %root%\luasec\src\luasocket
ren usocket.c.not usocket.c
del *.dll
del *.o
cd %root%\luasec\src\
del *.dll
del *.o

cd %root%\basexx
echo Copy core...
xcopy basexx.lua "%hub%\lib\basexx\*.*" /y /f
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
