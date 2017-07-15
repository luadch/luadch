#!/bin/sh

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
rsync -a ${ROOT}/core ${INSTALL_DIR}/
rsync -a ${ROOT}/scripts ${INSTALL_DIR}/
rsync -a ${ROOT}/examples/cfg ${INSTALL_DIR}/
rsync -a ${ROOT}/examples/certs ${INSTALL_DIR}/
rsync -a ${ROOT}/examples/lang ${INSTALL_DIR}/
rsync -a ${ROOT}/docs ${INSTALL_DIR}/

echo Building lua...
cd ${ROOT}/lua/src
make INSTALL_DIR=$INSTALL_DIR
#make clean

echo Building adclib...
cd ${ROOT}/adclib 
make LUAINCLUDE_DIR=$LUA_DIR LUALIB_DIR=$INSTALL_DIR INSTALL_DIR=$INSTALL_DIR/lib/adclib/adclib.so
#make clean

echo Building slnunicode-1.1a...
cd ${ROOT}/slnunicode-1.1a
make LUAINCLUDE_DIR=$LUA_DIR LUALIB_DIR=$INSTALL_DIR INSTALL_DIR=$INSTALL_DIR/lib/unicode/unicode.so
#make clean

echo Building luasocket-3.0...
cd ${ROOT}/luasocket-3.0/
make LUAINC_linux=$LUA_DIR
cp ./src/socket*.so $INSTALL_DIR/lib/luasocket/socket/socket.so
cp ./src/mime*.so $INSTALL_DIR/lib/luasocket/mime/mime.so
cp ./src/*.lua $INSTALL_DIR/lib/luasocket/lua/

echo Building luasec-6.1...
cd ${ROOT}/luasec-6.1
make linux INC_PATH=-I$LUA_DIR LIB_PATH=-L$INSTALL_DIR
cp ./src/ssl.so $INSTALL_DIR/lib/luasec/ssl/ssl.so
cp ./src/*.lua $INSTALL_DIR/lib/luasec/lua/
#make clean

echo Building basexx...
cd ${ROOT}/basexx
make LUAINCLUDE_DIR=$LUA_DIR LUALIB_DIR=$INSTALL_DIR INSTALL_DIR=$INSTALL_DIR/lib/basexx/
#make clean

echo Building hub...
cd ${ROOT}/hub
make LUAINCLUDE_DIR=$LUA_DIR LUALIB_DIR=$INSTALL_DIR INSTALL_DIR=$INSTALL_DIR
#make clean

