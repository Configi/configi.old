/* activate system definitions in lprefix.h */
#include "lprefix.h"
#include <assert.h>
#include <ctype.h>
#include <errno.h>
#include <float.h>
#include <limits.h>
#include <locale.h>
#include <math.h>
#include <setjmp.h>
#include <signal.h>
#include <stdarg.h>
#include <stddef.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>

/* setup for luaconf.h */
#define LUA_CORE
#define LUA_LIB
#define lvm_c
#include "luaconf.h"
#include "glue.h"
#define _PATH_MAX PATH_MAX

/* do not export internal symbols */
#undef LUAI_FUNC
#undef LUAI_DDEC
#undef LUAI_DDEF
#define LUAI_FUNC	static
#define LUAI_DDEC	static
#define LUAI_DDEF	static

/* core -- used by all */
#include "lapi.c"
#include "lcode.c"
#include "lctype.c"
#include "ldebug.c"
#include "ldo.c"
#include "ldump.c"
#include "lfunc.c"
#include "lgc.c"
#include "llex.c"
#include "lmem.c"
#include "lobject.c"
#include "lopcodes.c"
#include "lparser.c"
#include "lstate.c"
#include "lstring.c"
#include "ltable.c"
#include "ltm.c"
#include "lundump.c"
#include "lvm.c"
#include "lzio.c"

/* auxiliary library -- used by all */
#include "lauxlib.c"

/* standard library  -- not used by luac */
#include "lbaselib.c"
#if defined(LUA_COMPAT_BITLIB)
#include "lbitlib.h"
#include "lbitlib.c"
#endif
#include "lcorolib.c"
#ifndef NDEBUG
#include "ldblib.c"
#endif
#include "liolib.c"
#include "lmathlib.c"
#include "loadlib.c"
#include "loslib.c"
#include "lstrlib.c"
#include "ltablib.c"
/* #include "lutf8lib.c" */
#include "linit.c"

typedef struct
{
 FILE *f;
 size_t size;
 char buff[512];
} State;

static const char *myget(lua_State *L, void *data, size_t *size)
{
 State* s=data;
 size_t n;
 (void)L;
 n=(sizeof(s->buff)<=s->size)? sizeof(s->buff) : s->size;
 n=fread(s->buff,1,n,s->f);
 s->size-=n;
 *size=n;
 return (n>0) ? s->buff : NULL;
}

#define cannot(x) luaL_error(L,"cannot %s %s: %s",x,name,strerror(errno))

static void load(lua_State *L, const char *name)
{
 Glue t;
 State S;
 FILE *f=fopen(name,"rb");
 int c;
 if (f==NULL) cannot("open");
 if (fseek(f,-sizeof(t),SEEK_END)!=0) cannot("seek");
 if (fread(&t,sizeof(t),1,f)!=1) cannot("read");
 if (memcmp(t.sig,GLUESIG,GLUELEN)!=0) luaL_error(L,"no Lua program found in %s",name);
 if (fseek(f,t.size1,SEEK_SET)!=0) cannot("seek");
 S.f=f; S.size=t.size2;
 c=getc(f);
 if (c=='#')
  while (--S.size>0 && c!='\n') c=getc(f);
 else
  ungetc(c,f);
#if LUA_VERSION_NUM <= 501
 if (lua_load(L,myget,&S,"=")!=0) lua_error(L);
#else
 if (lua_load(L,myget,&S,"=",NULL)!=0) lua_error(L);
#endif
 fclose(f);
}

static int pmain(lua_State *L)
{
 int argc=lua_tointeger(L,1);
 char** argv=lua_touserdata(L,2);
 int i;
 lua_gc(L,LUA_GCSTOP,0);
 luaL_openlibs(L);
 lua_gc(L,LUA_GCRESTART,0);
 load(L,argv[0]);
 lua_createtable(L,argc,0);
 for (i=0; i<argc; i++)
 {
  lua_pushstring(L,argv[i]);
  lua_rawseti(L,-2,i);
 }
 lua_setglobal(L,"arg");
 luaL_checkstack(L,argc-1,"too many arguments to script");
 for (i=1; i<argc; i++)
 {
  lua_pushstring(L,argv[i]);
 }
 lua_call(L,argc-1,0);
 return 0;
}

static void fatal(const char* progname, const char* message)
{
#ifdef _WIN32
 MessageBox(NULL,message,progname,MB_ICONERROR | MB_OK);
#else
 fprintf(stderr,"%s: %s\n",progname,message);
#endif
 exit(EXIT_FAILURE);
}

char* getprog() {
  int nsize = _PATH_MAX + 1;
  char* progdir = malloc(nsize * sizeof(char));
  char *lb;
  int n = 0;
#if defined(__CYGWIN__)
  char win_buff[_PATH_MAX + 1];
  GetModuleFileNameA(NULL, win_buff, nsize);
  cygwin_conv_path(CCP_WIN_A_TO_POSIX, win_buff, progdir, nsize);
  n = strlen(progdir);
#elif defined(_WIN32)
  n = GetModuleFileNameA(NULL, progdir, nsize);
#elif defined(__linux__)
  n = readlink("/proc/self/exe", progdir, nsize);
  if (n > 0) progdir[n] = 0;
#elif defined(__sun)
  pid_t pid = getpid();
  char linkname[256];
  sprintf(linkname, "/proc/%d/path/a.out", pid);
  n = readlink(linkname, progdir, nsize);
  if (n > 0) progdir[n] = 0;
#elif defined(__FreeBSD__)
  int mib[4];
  mib[0] = CTL_KERN;
  mib[1] = KERN_PROC;
  mib[2] = KERN_PROC_PATHNAME;
  mib[3] = -1;
  size_t cb = nsize;
  sysctl(mib, 4, progdir, &cb, NULL, 0);
  n = cb;
#elif defined(__BSD__)
  n = readlink("/proc/curproc/file", progdir, nsize);
  if (n > 0) progdir[n] = 0;
#elif defined(__APPLE__)
  uint32_t nsize_apple = nsize;
  if (_NSGetExecutablePath(progdir, &nsize_apple) == 0)
    n = strlen(progdir);
#else
  // FALLBACK
  // Use 'lsof' ... should work on most UNIX systems (incl. OSX)
  // lsof will list open files, this captures the 1st file listed (usually the executable)
  int pid;
  FILE* fd;
  char cmd[80];
  pid = getpid();

  sprintf(cmd, "lsof -p %d | awk '{if ($5==\"REG\") { print $9 ; exit}}' 2> /dev/null", pid);
  fd = popen(cmd, "r");
  n = fread(progdir, 1, nsize, fd);
  pclose(fd);

  // remove newline
  if (n > 1) progdir[--n] = '\0';
#endif
  if (n == 0 || n == nsize || (lb = strrchr(progdir, (int)LUA_DIRSEP[0])) == NULL)
    return NULL;
  return (progdir);
}

int main(int argc, char *argv[])
{
 lua_State *L;
 argv[0] = getprog();

 if (argv[0]==NULL) fatal("srlua","cannot locate this executable");
 L=luaL_newstate();
 if (L==NULL) fatal(argv[0],"not enough memory for state");
 lua_pushcfunction(L,&pmain);
 lua_pushinteger(L,argc);
 lua_pushlightuserdata(L,argv);
 if (lua_pcall(L,2,0,0)!=0) fatal(argv[0],lua_tostring(L,-1));
 lua_close(L);
 return EXIT_SUCCESS;
}
