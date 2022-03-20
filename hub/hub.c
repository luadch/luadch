/*

    hub.c by blastbeat

*/

#include <stdio.h>
#include <stdlib.h>
#include <signal.h>

#ifdef __unix__
#include <sys/types.h>
#include <sys/stat.h>
#include <fcntl.h>
#include <errno.h>
#include <unistd.h>
#include <syslog.h>
#include <string.h>
#endif
#ifdef _WIN32
#include <windows.h>
#endif

#include "lua.h"
#include "lualib.h"
#include "lauxlib.h"

static volatile sig_atomic_t do_exit = 0;
static int do_daemonization = 0;

static void log_error(const char *msg)
{
  FILE *file = NULL;
  file = fopen("exception.txt", "a+");
  if (file)
  {
    fprintf(file, "%s\n", msg);
    fclose(file);
  }
  fprintf(stderr, "%s\n", msg);
  fflush(stderr);
}

#ifdef _WIN32
static BOOL WINAPI signal_handler(DWORD event)
{
  // this runs in an extra thread
  do_exit = 1;
  sleep(10); // need to wait here, or windows will end the process after return TRUE
  return TRUE;
}
#endif
#ifdef __unix__
static void signal_handler(int sig)
{
  do_exit = 1;
  return;
}
#endif

static void handle_signals(void)
{
#ifdef _WIN32
  SetConsoleCtrlHandler(signal_handler, TRUE);
#endif
#ifdef __unix__
  struct sigaction sa;
  sigemptyset(&sa.sa_mask);
  sa.sa_handler = signal_handler;
  sa.sa_flags = 0;
  sigaction(SIGINT,  &sa, 0);
  sigaction(SIGTERM, &sa, 0);
  sigaction(SIGHUP,  &sa, 0);
  sigaction(SIGABRT, &sa, 0);
#endif
}

static int tablesize(lua_State *L)
{
  lua_pushnil(L);
  lua_Number i = 0;
  while (lua_next(L, 1) != 0)
  {
    lua_pop(L,1);
    i++;
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

static int doexit(lua_State *L)
{
  lua_pushboolean(L, (int)do_exit);
  return 1;
}

static void run_lua(void);

static int restart(lua_State *L)
{
  lua_close(L);
  atexit(run_lua);
  exit(EXIT_SUCCESS);
  return 0;
}

static void run_lua(void)
{
  lua_State *L = lua_open();
  if (!L)
  {
    log_error("cannot create Lua state: not enough memory");
    exit(EXIT_FAILURE);
  }
  luaL_openlibs(L);
  lua_register(L, "restartluadch", restart);
  lua_register(L, "cleantable", cleantable);
  lua_register(L, "tablesize", tablesize);
  lua_register(L, "doexit", doexit);
  int err = luaL_loadfile(L, "core/init.lua") || lua_pcall(L, 0, 0, 0);
  if (err)
  {
    log_error(lua_tostring(L, -1));
  }
  lua_close(L);
  exit(EXIT_SUCCESS);
}

static void daemonize(void)
{
  if (!do_daemonization)
  {
    return;
  }
#ifdef __unix__
  pid_t pid = fork();
  if (pid < 0)
  {
    exit(EXIT_FAILURE);
  }
  if (pid > 0)
  {
    exit(EXIT_SUCCESS);
  }
  umask(0);
  if (setsid() < 0)
  {
    exit(EXIT_FAILURE);
  }
  close(STDIN_FILENO);
  close(STDOUT_FILENO);
  close(STDERR_FILENO);
#else
  fprintf(stderr, "Daemonization is not implemented for your OS.\n");
  fflush(stderr);
#endif
}

static void print_help(void)
{
  fprintf(stderr,
  "usage: luadch [option]\n"
  "available options are:\n"
  "  -h       show this help\n"
  "  -d       execute luadch as background daemon\n");
  fflush(stderr);
  exit(EXIT_SUCCESS);
}

static void handle_args(int argc, char **argv)
{
  if (argc > 1 && argv[1][0] == '-')
  {
    switch(argv[1][1])
    {
      case 'h': print_help(); break;
      case 'd': do_daemonization = 1; break;
    }
  }
}

int main(int argc, char **argv)
{
  handle_signals();
  handle_args(argc, argv);
  daemonize();
  run_lua();
  return EXIT_SUCCESS;
}
