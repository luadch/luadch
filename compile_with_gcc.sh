#!/bin/bash

# current directory
ROOT=$PWD

# your install directory
INSTALL_DIR=${ROOT}/build_gcc

# open ssl header files
OPENSSL_HEADER_DIR=/usr/include/openssl

# open ssl libraries
OPENSSL_LIB_DIR=/usr/lib

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
rsync -a --exclude=".svn" ${ROOT}/core ${INSTALL_DIR}/
rsync -a --exclude=".svn" ${ROOT}/scripts ${INSTALL_DIR}/
rsync -a --exclude=".svn" ${ROOT}/examples/cfg ${INSTALL_DIR}/
rsync -a --exclude=".svn" ${ROOT}/examples/certs ${INSTALL_DIR}/
rsync -a --exclude=".svn" ${ROOT}/examples/lang ${INSTALL_DIR}/
rsync -a --exclude=".svn" ${ROOT}/docs ${INSTALL_DIR}/

echo Building lua...
cd ${ROOT}/lua/src
make INSTALL_DIR=$INSTALL_DIR
make clean

echo Building adclib...
cd ${ROOT}/adclib 
make LUAINCLUDE_DIR=$LUA_DIR LUALIB_DIR=$INSTALL_DIR INSTALL_DIR=$INSTALL_DIR/lib/adclib/adclib.so
make clean

echo Building unicode...
cd ${ROOT}/slnunicode
make LUAINCLUDE_DIR=$LUA_DIR LUALIB_DIR=$INSTALL_DIR INSTALL_DIR=$INSTALL_DIR/lib/unicode/unicode.so
make clean

echo Building luasocket...
cd ${ROOT}/luasocket/src
mv mime.c mime.c.not
mv wsocket.c wsocket.c.not
gcc -O3 -c -Wall -fpic -I$LUA_DIR *.c
gcc -shared -fpic -o socket.so *.o -L$INSTALL_DIR -llua
cp socket.so $INSTALL_DIR/lib/luasocket/socket/socket.so
mv mime.c.not mime.c
gcc -O3 -fpic -Wall -c -I$LUA_DIR *.c
gcc -shared -fpic -o mime.so *.o -L$INSTALL_DIR -llua
cp mime.so $INSTALL_DIR/lib/luasocket/mime/mime.so
cp *.lua $INSTALL_DIR/lib/luasocket/lua/
mv wsocket.c.not wsocket.c
rm *.so
rm *.o

echo Building luasec-6.1...
cd ${ROOT}/luasec-6.1
make linux INC_PATH=-I$LUA_DIR LIB_PATH=-L$INSTALL_DIR
cp ./src/ssl.so $INSTALL_DIR/lib/luasec/ssl/ssl.so
cp ./src/*.lua $INSTALL_DIR/lib/luasec/lua/
make clean

echo Building basexx...
cd ${ROOT}/basexx
make LUAINCLUDE_DIR=$LUA_DIR LUALIB_DIR=$INSTALL_DIR INSTALL_DIR=$INSTALL_DIR/lib/basexx/
make clean

echo Building hub...
cd ${ROOT}/hub
make LUAINCLUDE_DIR=$LUA_DIR LUALIB_DIR=$INSTALL_DIR INSTALL_DIR=$INSTALL_DIR
make clean

