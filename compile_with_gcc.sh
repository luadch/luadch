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

echo
echo Building lua...
echo
cd ${ROOT}/lua/src
make INSTALL_DIR=$INSTALL_DIR

echo
echo Building adclib...
echo
cd ${ROOT}/adclib 
make LUAINCLUDE_DIR=$LUA_DIR LUALIB_DIR=$INSTALL_DIR INSTALL_DIR=$INSTALL_DIR/lib/adclib/adclib.so

echo
echo Building unicode...
echo
cd ${ROOT}/slnunicode
make LUAINCLUDE_DIR=$LUA_DIR LUALIB_DIR=$INSTALL_DIR INSTALL_DIR=$INSTALL_DIR/lib/unicode/unicode.so

echo
echo Building luasocket...
echo
cd ${ROOT}/luasocket/src
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

cd ${ROOT}/luasec-6.1
echo
echo Building luasec-6.1...
echo
make linux INC_PATH=-I$LUA_DIR LIB_PATH=-L$INSTALL_DIR
cp ./src/ssl.so $INSTALL_DIR/lib/luasec/ssl/ssl.so
cp ./src/*.lua $INSTALL_DIR/lib/luasec/lua/

cd ${ROOT}/basexx

cp *.lua $INSTALL_DIR/lib/basexx/

cd ${ROOT}/hub

echo Building hub...
gcc -O3 -Wall -I$LUA_DIR -c *.c
gcc -o luadch *.o -L$LUA_DIR -L/opt/lib, -llua -lm -ldl -Wl,-rpath .
cp luadch $INSTALL_DIR/luadch
rm luadch
rm *.o

cd ${INSTALL_DIR}/

