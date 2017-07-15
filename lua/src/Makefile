CC     = gcc
CFLAGS = -O3 -DLUA_USE_POSIX -DLUA_USE_DLOPEN -fpic
LFLAGS = -shared -fpic
SO     = liblua.so
OBJS   = lapi.o lcode.o ldebug.o ldo.o ldump.o lfunc.o lgc.o llex.o lmem.o lobject.o lopcodes.o lparser.o lstate.o lstring.o ltable.o ltm.o lundump.o lvm.o lzio.o lauxlib.o lbaselib.o ldblib.o liolib.o lmathlib.o loslib.o ltablib.o lstrlib.o loadlib.o linit.o

$(SO): $(OBJS)
	$(CC) $(LFLAGS) -o $(SO) $(OBJS)
	cp $(SO) $(INSTALL_DIR)

$(OBJS):
	$(CC) $(CFLAGS) -c $*.c

clean:
	rm *.o
	rm *.so
