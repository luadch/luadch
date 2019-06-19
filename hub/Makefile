CFLAGS = -Wall -I$(LUAINCLUDE_DIR)
LFLAGS = -L$(LUALIB_DIR) $(LUAFLAG) -L../adclib -ladc -lm $(LINUXFLAG) -Wl,-rpath .
BIN    = luadch
OBJS   = hub.o

copy: $(BIN)
	cp $(BIN) $(INSTALL_DIR)

$(BIN): $(OBJS)
	g++ $(OBJS) $(LFLAGS) -o $(BIN)

$(OBJS):
	g++ $(CFLAGS) -c $*.c

clean:
	rm -f $(BIN)
	rm -f *.o
