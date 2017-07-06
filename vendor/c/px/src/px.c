/***
 luaposix extensions and some unix utilities.
@module lib
*/

#define _LARGEFILE_SOURCE       1
#define _FILE_OFFSET_BITS 64

#include <errno.h>
#include <unistd.h>
#include <fcntl.h>
#include <string.h>

#include "lua.h"
#include "lauxlib.h"
#include "lualib.h"

/*
 * lclonetable
 */
#include <lobject.h>
#include <ltable.h>
#include <lgc.h>
#include <lstate.h>
#define black2gray(x)	resetbit(x->marked, BLACKBIT)
#define linkgclist(o,p)	((o)->gclist = (p), (p) = obj2gco(o))

#include "flopen.h"
#include "closefrom.h"

static int pusherror(lua_State *L, const char *error)
{
        lua_pushnil(L);
        lua_pushstring(L, error);
        return 2;
}

static int pusherrno(lua_State *L, char *error)
{
        lua_pushnil(L);
        lua_pushfstring(L, LUA_QS" : "LUA_QS, error, strerror(errno));
        lua_pushinteger(L, errno);
        return 3;
}

/*
 * From:
 * http://lua-users.org/lists/lua-l/2017-07/msg00075.html
 * https://gist.github.com/cloudwu/a48200653b6597de0446ddb7139f62e3
 */
static void
barrierback(lua_State *L, Table *t)
{
	if (isblack(t)) {
		global_State *g = G(L);
		black2gray(t);  /* make table gray (again) */
		linkgclist(t, g->grayagain);
	}
}

static int
lclonetable(lua_State *L)
{
	luaL_checktype(L, 1, LUA_TTABLE);
	luaL_checktype(L, 2, LUA_TTABLE);
	Table * to = (Table *)lua_topointer(L, 1);
	const Table * from = lua_topointer(L, 2);
	void *ud;
	lua_Alloc alloc = lua_getallocf(L, &ud);
	if (from->lsizenode != to->lsizenode) {
		if (isdummy(from)) {
			// free to->node
			if (!isdummy(to))
				alloc(ud, to->node, sizenode(to) * sizeof(Node), 0);
			to->node = from->node;
		} else {
			unsigned int size = sizenode(from) * sizeof(Node);
			Node *node = alloc(ud, NULL, 0, size);
			if (node == NULL)
				luaL_error(L, "Out of memory");
			memcpy(node, from->node, size);
			// free to->node
			if (!isdummy(to))
				alloc(ud, to->node, sizenode(to) * sizeof(Node), 0);
			to->node = node;
		}
		to->lsizenode = from->lsizenode;
	} else if (!isdummy(from)) {
		unsigned int size = sizenode(from) * sizeof(Node);
		if (isdummy(to)) {
			Node *node = alloc(ud, NULL, 0, size);
			if (node == NULL)
				luaL_error(L, "Out of memory");
			to->node = node;
		}
		memcpy(to->node, from->node, size);
	}
	if (from->lastfree) {
		int lastfree = from->lastfree - from->node;
		to->lastfree = to->node + lastfree;
	} else {
		to->lastfree = NULL;
	}
	if (from->sizearray != to->sizearray) {
		if (from->sizearray) {
			TValue *array = alloc(ud, NULL, 0, from->sizearray * sizeof(TValue));
			if (array == NULL)
				luaL_error(L, "Out of memory");
			alloc(ud, to->array, to->sizearray * sizeof(TValue), 0);
			to->array = array;
		} else {
			alloc(ud, to->array, to->sizearray * sizeof(TValue), 0);
			to->array = NULL;
		}
		to->sizearray = from->sizearray;
	}
	memcpy(to->array, from->array, from->sizearray * sizeof(TValue));
	barrierback(L,to);
	lua_settop(L, 1);
	return 1;
}

/***
chroot(2) wrapper.
@function chroot
@tparam string path or directory to chroot into.
@treturn bool true if successful; otherwise nil
*/
static int
Cchroot(lua_State *L)
{
	const char *path = luaL_checkstring(L, 1);
	if (chroot(path) == -1) {
		return pusherrno(L, "chroot(2) error");
	}
	lua_pushboolean(L, 1);
	return 1;
}

/***
close(2) a file descriptor.
@function fdclose
@tparam int fd file descriptor to close
@treturn bool true if successful; otherwise nil
*/
static int
Cfdclose (lua_State *L)
{
	FILE *f = *(FILE**)luaL_checkudata(L, 1, LUA_FILEHANDLE);
	int res = close(fileno(f));
	if (res == -1) {
		return pusherrno(L, "close(2) error");
	}
	lua_pushboolean(L, 1);
	return 1;
}

typedef luaL_Stream LStream;
static
LStream *newfile (lua_State *L)
{
	LStream *p = (LStream *)lua_newuserdata(L, sizeof(LStream));
	p->closef = NULL;
	luaL_setmetatable(L, LUA_FILEHANDLE);
	p->f = NULL;
	p->closef = &Cfdclose;
	return p;
}

/***
Wrapper to flopen(3) -- Reliably open and lock a file.
@function flopen
@tparam string file to open and lock
@treturn int a new file handle, or, in case of errors, nil plus an error message
*/
static int
Cflopen(lua_State *L)
{
	const char *path = luaL_checkstring(L, 1);
	int flags = luaL_optinteger(L, 2, O_NONBLOCK | O_RDWR);
	mode_t mode = luaL_optinteger(L, 3, 0700);
	int fd = flopen(path, flags, mode);
	LStream *p = newfile(L);
	if (fd == -1) {
		return pusherrno(L, "open(2) error");
	}
	p->f = fdopen(fd, "rwe");
	return (p->f == NULL) ? luaL_fileresult(L, 0, NULL) : 1;
}

/***
Wrapper to fdopen(3).
@function fdopen
@tparam string file to open
@treturn int a new file handle, or, in case of errors, nil plus an error message
*/
static int
Cfdopen (lua_State *L)
{
	int fd = luaL_checkinteger(L, 1);
  	const char *mode = luaL_optstring(L, 2, "re");
	LStream *p = newfile(L);
	p->f = fdopen(fd, mode);
	return (p->f == NULL) ? luaL_fileresult(L, 0, NULL) : 1;
}

/***
Wrapper to closefrom(2) -- delete open file descriptors.
@function closefrom
@tparam int fd file descriptors greater or equal to this is deleted
@treturn bool true always
*/
static int
Cclosefrom (lua_State *L)
{
	int fd = luaL_optinteger(L, 2, 3);
	closefrom(fd);
	lua_pushboolean(L, 1);
	return 1;
}

/* Derived from luaposix runexec(). Modified to take in the environment. */
/***
Execute a program using execve(2)
@function execve
@tparam string path of executable
@tparam table argt arguments (table can include index 0)
@tparam table arge environment
@return nil or
@treturn string error message
*/
static int
Cexecve(lua_State *L)
{
	char **argv;
	char **env;
	const char *path = luaL_checkstring(L, 1);
	int n;
	int i;
	if (lua_type(L, 2) != LUA_TTABLE) {
		return pusherror(L, "bad argument #2 to 'execve' (table expected)");
	}

	n = lua_rawlen(L, 2);
	argv = lua_newuserdata(L, (n + 2) * sizeof(char*));
	argv[0] = (char*) path;
	lua_pushinteger(L, 0);
	lua_gettable(L, 2);

	if (lua_type(L, -1) == LUA_TSTRING) {
		argv[0] = (char*)lua_tostring(L, -1);
	} else {
		lua_pop(L, 1);
	}

	for (i=1; i<=n; i++) {
		lua_pushinteger(L, i);
		lua_gettable(L, 2);
		argv[i] = (char*)lua_tostring(L, -1);
	}

	argv[n+1] = NULL;

	if (lua_type(L, 3) == LUA_TTABLE) {
		int e = lua_rawlen(L, 3);
		env = lua_newuserdata(L, (e + 2) * sizeof(char*));
		for (i=0; i<=e; i++) {
			lua_pushinteger(L, i + 1);
			lua_gettable(L, 3);
			env[i] = (char*)lua_tostring(L, -1);
		}
		env[e+1] = NULL;
		execve(path, argv, env);
	} else {
		execv(path, argv);
	}
	return pusherror(L, path);
}

static const
luaL_Reg syslib[] =
{
	{"chroot", Cchroot},
	{"fdclose", Cfdclose},
	{"flopen", Cflopen},
	{"closefrom", Cclosefrom},
	{"fdopen", Cfdopen},
	{"execve", Cexecve},
	{"t_copy", lclonetable},
	{NULL, NULL}
};

int
luaopen_px(lua_State *L)
{
	luaL_newlib(L, syslib);
	return 1;
}
