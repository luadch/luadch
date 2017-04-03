#!/bin/bash

ROOT=$PWD					# current directory
INSTALL_DIR=${ROOT}/build_gcc/luadch		# your install directory	
OPENSSL_HEADER_DIR=/usr/include/openssl		# open ssl header files
OPENSSL_LIB_DIR=/usr/lib			# open ssl libraries

# hopefully nothing to edit below

LUA_DIR=${ROOT}/lua/src	

mkdir -p ${INSTALL_DIR}/log
mkdir -p ${INSTALL_DIR}/lib/adclib
mkdir -p ${INSTALL_DIR}/lib/unicode
mkdir -p ${INSTALL_DIR}/lib/luasocket/socket
mkdir -p ${INSTALL_DIR}/lib/luasocket/mime
mkdir -p ${INSTALL_DIR}/lib/luasocket/lua
mkdir -p ${INSTALL_DIR}/lib/luasec/ssl
mkdir -p ${INSTALL_DIR}/lib/luasec/lua
mkdir -p ${INSTALL_DIR}/lib/basexx

echo Copy core...
rsync -av --exclude=".svn" ${ROOT}/core ${INSTALL_DIR}/
rsync -av --exclude=".svn" ${ROOT}/scripts ${INSTALL_DIR}/
rsync -av --exclude=".svn" ${ROOT}/examples/cfg ${INSTALL_DIR}/
rsync -av --exclude=".svn" ${ROOT}/examples/certs ${INSTALL_DIR}/
rsync -av --exclude=".svn" ${ROOT}/examples/lang ${INSTALL_DIR}/
rsync -av --exclude=".svn" ${ROOT}/docs ${INSTALL_DIR}/

cd ${ROOT}/lua/src

echo Building lua...
gcc -O3 -Wall -DLUA_USE_POSIX -DLUA_USE_DLOPEN -fpic -c *.c
gcc -shared -fpic -o liblua.so lapi.o lcode.o ldebug.o ldo.o ldump.o lfunc.o lgc.o llex.o lmem.o lobject.o lopcodes.o lparser.o lstate.o lstring.o ltable.o ltm.o lundump.o lvm.o lzio.o lauxlib.o lbaselib.o ldblib.o liolib.o lmathlib.o loslib.o ltablib.o lstrlib.o loadlib.o linit.o
cp liblua.so ${INSTALL_DIR}/

cd ${ROOT}/adclib 

echo Building adclib...
g++ -O3 -Wall -fpic -c -I$LUA_DIR *.cpp
g++ -shared -fpic -o adclib.so *.o -L$LUA_DIR -llua
cp adclib.so $INSTALL_DIR/lib/adclib/adclib.so
rm *.o
rm *.so

cd ${ROOT}/slnunicode

echo Building unicode...
gcc -O3 -Wall -fpic -c -I$LUA_DIR *.c
gcc -shared -fpic -o unicode.so *.o -L$LUA_DIR -llua
cp unicode.so $INSTALL_DIR/lib/unicode/unicode.so
rm *.o
rm *.so

cd ${ROOT}/luasocket/src

echo Building luasocket...
mv mime.c mime.c.not
mv wsocket.c wsocket.c.not
gcc -O3 -c -Wall -fpic -I$LUA_DIR *.c
gcc -shared -fpic -o socket.so *.o -L$LUA_DIR -llua
cp socket.so $INSTALL_DIR/lib/luasocket/socket/socket.so
mv mime.c.not mime.c
gcc -O3 -fpic -Wall -c -I$LUA_DIR *.c
gcc -shared -fpic -o mime.so *.o -L$LUA_DIR -llua
cp mime.so $INSTALL_DIR/lib/luasocket/mime/mime.so
cp *.lua $INSTALL_DIR/lib/luasocket/lua/
mv wsocket.c.not wsocket.c
rm *.so
rm *.o

cd ${ROOT}/luasec/src

echo Building luasec...
mv wsocket.c wsocket.c.not
gcc -O3 -c -Wall -fpic -DOPENSSL_NO_HEARTBEATS -I$LUA_DIR *.c
gcc -shared -fpic -o ssl.so *.o -L$LUA_DIR -llua -lssl -lcrypto
cp ssl.so $INSTALL_DIR/lib/luasec/ssl/ssl.so
cp *.lua $INSTALL_DIR/lib/luasec/lua/
mv wsocket.c.not wsocket.c
rm *.so
rm *.o

cd ${ROOT}/basexx

cp *.lua $INSTALL_DIR/lib/basexx/

cd ${ROOT}/hub

echo Building hub...
gcc -O3 -Wall -I$LUA_DIR -c *.c
gcc -o luadch *.o -L$LUA_DIR -L/opt/lib, -llua -lm -ldl -Wl,-rpath .
cp luadch $INSTALL_DIR/luadch
rm luadch
rm *.o

cd ${ROOT}/lua/src
rm *.o
rm *.so

cd ${INSTALL_DIR}/

