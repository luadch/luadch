/*

    hub.c by blastbeat

*/

#include <stdio.h>
#include <stdlib.h>

#ifdef __unix__

#include <sys/types.h>
#include <sys/stat.h>
#include <fcntl.h>
#include <errno.h>
#include <unistd.h>
#include <syslog.h>
#include <string.h>

#endif

#include "lua.h"
#include "lualib.h"
#include "lauxlib.h"

static int pass_count = 0;
static int do_daemonization = 0;

static void daemonize(void);
static void help(void);
static void execute(void);
static void onerror(const char *msg);
static void handle_args(int argc, char **argv);

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

static int cleantable(lua_State *L)
{
  lua_pushnil(L);
  while (lua_next(L, 1) != 0)
  {
    lua_pop(L, 1);
    lua_pushnil(L);
    lua_rawset(L, 1);
    lua_pushnil(L);
  }
  return 0;
}

static int restart(lua_State *L)
{
  lua_close(L);
  atexit(execute);
  exit(EXIT_SUCCESS);
  return EXIT_SUCCESS;
}

void onerror(const char *msg)
{
  FILE *file;
  file = fopen("exception.txt", "a+");
  if (NULL != file) {
    fprintf(file, "%s\n", msg);
    fclose(file);
  }
  fprintf(stderr, "%s\n", msg);
  fflush(stderr);
}

void daemonize(void)
{
#ifdef __unix__

  pid_t pid = fork();
  if (pid < 0) exit(EXIT_FAILURE);
  if (pid > 0) exit(EXIT_SUCCESS);
  umask(0);
  if (setsid() < 0) exit(EXIT_FAILURE);
  close(STDIN_FILENO);
  close(STDOUT_FILENO);
  close(STDERR_FILENO);

#else

  fprintf(stderr, "Daemonization is not implemented on your OS yet.\n");

#endif
}

void execute(void)
{
  int error;
  lua_State *L = lua_open();
  if (NULL == L)
  {
    onerror("cannot create state: not enough memory");
    exit(EXIT_FAILURE);
  }
  luaL_openlibs(L);
  if (pass_count == 0)
  {
    lua_pushboolean(L, 1);
    lua_setglobal(L, "DEBUG");
  }
  if (do_daemonization) daemonize();
  lua_register(L, "restartluadch", restart);
  lua_register(L, "cleantable", cleantable);
  lua_register(L, "tablesize", tablesize);
  error = luaL_loadfile(L, "core/init.lua") || lua_pcall(L, 0, 0, 0);
  if (error) onerror(lua_tostring(L, -1));
  lua_close(L);
  exit(EXIT_SUCCESS);
}

void help(void)
{
  fprintf(stderr,
  "usage: luadch [option]\n"
  "available options are:\n"
  "  -h       show this help\n"
  "  -d       execute luadch as background daemon\n");
  fflush(stderr);
  exit(EXIT_SUCCESS);
}

void handle_args(int argc, char **argv)
{
  if (argc > 1 && argv[1][0] == '-')
  {
    switch(argv[1][1])
    {
      case 'h': help();
        break;
      case 'd': do_daemonization = 1;
        break;
    }
  }
}

int main(int argc, char **argv)
{
  handle_args(argc, argv);
  execute();
  return EXIT_SUCCESS;
}
