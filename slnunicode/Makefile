CC     = gcc
CFLAGS = -O3 -fpic -I$(LUAINCLUDE_DIR)
LFLAGS = -shared -fpic -L$(LUALIB_DIR) -llua
SO     = unicode.so
OBJS   = slnudata.o slnunico.o

copy: $(SO)
	cp $(SO) $(INSTALL_DIR)

$(SO): $(OBJS)
	$(CC) $(LFLAGS) -o $(SO) $(OBJS)

$(OBJS):
	$(CC) $(CFLAGS) -c $*.c

clean:
	rm *.o
	rm *.so
