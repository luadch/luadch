CFLAGS = -Wall -I$(LUAINCLUDE_DIR)
LFLAGS = -L$(LUALIB_DIR) $(LUAFLAG) -lm $(LINUXFLAG) -Wl,-rpath .
BIN    = luadch
OBJS   = hub.o

copy: $(BIN)
	cp $(BIN) $(INSTALL_DIR)

$(BIN): $(OBJS)
	$(CC) -o $(BIN) $(OBJS) $(LFLAGS)

$(OBJS):
	$(CC) $(CFLAGS) -c $*.c

clean:
	rm -f $(BIN)
	rm -f *.o
