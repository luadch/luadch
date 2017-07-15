CC     = gcc
CFLAGS = -Wall -I$(LUAINCLUDE_DIR)
LFLAGS = -L$(LUALIB_DIR) -L/opt/lib, -llua -lm -ldl -Wl,-rpath .
BIN    = luadch
OBJS   = hub.o

copy: $(BIN)
	cp $(BIN) $(INSTALL_DIR)

$(BIN): $(OBJS)
	$(CC) -o $(BIN) $(OBJS) $(LFLAGS)

$(OBJS):
	$(CC) $(CFLAGS) -c $*.c

clean:
	rm $(BIN)
	rm *.o
