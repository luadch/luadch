CFLAGS = -O3 -fpic -I$(LUAINCLUDE_DIR)
LFLAGS = -shared -fpic -L$(LUALIB_DIR) -llua
SO     = adclib.so
OBJS   = tiger.o adclib.o base32.o

copy: $(SO)
	cp $(SO) $(INSTALL_DIR)

$(SO): $(OBJS)
	$(CXX) $(LFLAGS) -o $(SO) $(OBJS)

$(OBJS):
	$(CXX) $(CFLAGS) -c $*.cpp

clean:
	rm -f *.o
	rm -f *.so
