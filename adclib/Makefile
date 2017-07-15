CC     = g++
CFLAGS = -O3 -fpic -I$(LUAINCLUDE_DIR)
LFLAGS = -shared -fpic -L$(LUALIB_DIR) -llua
SO     = adclib.so
OBJS   = tiger.o adclib.o base32.o

copy: $(SO)
	cp $(SO) $(INSTALL_DIR)

$(SO): $(OBJS)
	$(CC) $(LFLAGS) -o $(SO) $(OBJS)
	cp $(SO) $(INSTALL_DIR)

$(OBJS):
	$(CC) $(CFLAGS) -c $*.cpp

clean:
	rm *.o
	rm *.so
