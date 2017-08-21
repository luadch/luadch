/*

    hub.c by blastbeat

*/

#include <stdio.h>
#include <stdlib.h>

#include "lua.h"
#include "lualib.h"
#include "lauxlib.h"

int pass = 0;
int debug = 1;

void help(void);
void execute(void);
void onerror(const char *msg);
static int restart(lua_State *L);
static int cleantable(lua_State *L);
static int tablesize(lua_State *L);

static int tablesize(lua_State *L) {
  lua_pushnil(L);
  lua_Number i = 0;
  while (lua_next(L, 1) != 0) {
    lua_pop(L,1);
    i = i + 1;
  }
  lua_pushnumber(L, i);
  return 1;
}

static int cleantable(lua_State *L) {
  lua_pushnil(L);
  while (lua_next(L, 1) != 0) {
    lua_pop(L, 1);
    lua_pushnil(L);
    lua_rawset(L, 1);
    lua_pushnil(L);
  }
  return 0;
}

static int restart(lua_State *L) {
  lua_close(L);
  atexit(execute);
  exit(EXIT_SUCCESS);
  return EXIT_SUCCESS;
}

void onerror(const char *msg) {
  FILE *file;
  file = fopen("exception.txt", "a+");
  if (NULL != file) {
    fprintf(file, "%s\n", msg);
    fclose(file);
  }
  fprintf(stderr, "%s\n", msg);
  fflush(stderr);
}

void execute(void) {
  int error;
  lua_State *L = lua_open();
  if (NULL == L) {
    onerror("cannot create state: not enough memory");
    exit(EXIT_FAILURE);
  }
  luaL_openlibs(L);
  if (debug == 0 && pass == 0) {
    pass = 1;
    lua_pushboolean(L, 0);
    lua_setglobal(L, "DEBUG");
  }
  else if (pass == 0) {
    lua_pushboolean(L, 1);
    lua_setglobal(L, "DEBUG");
  }
  lua_register(L, "restartluadch", restart);
  lua_register(L, "cleantable", cleantable);
  lua_register(L, "tablesize", tablesize);
  error = luaL_loadfile(L, "core/init.lua") || lua_pcall(L, 0, 0, 0);
  if (error)
    onerror(lua_tostring(L, -1));
  lua_close(L);
  exit(EXIT_SUCCESS);
}

void help(void) {
  fprintf(stderr,
  "usage: luadch [options]\n"
  "available options are:\n"
  "  -r       execute luadch in release mode (no debug messages from hub to screen and event.log)\n");
  fflush(stderr);
  exit(EXIT_SUCCESS);
}

int main(int argc, char **argv) {
  if (argc > 1 && argv[1][0] == '-') {
    switch(argv[1][1]) {
      case 'h': help();
        break;
      case 'r': debug = 0;
        break;
    }
  }
  execute();
  return EXIT_SUCCESS;
}
