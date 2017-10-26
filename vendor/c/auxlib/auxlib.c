#include <string.h>
#include <errno.h>
#include <stdio.h>
#include <stdlib.h>

#include <lua.h>
#include <lauxlib.h>
#include <lualib.h>

/*
 * lclonetable
 */
#include <lobject.h>
#include <ltable.h>
#include <lgc.h>
#include <lstate.h>
#define black2gray(x)	resetbit(x->marked, BLACKBIT)
#define linkgclist(o,p)	((o)->gclist = (p), (p) = obj2gco(o))

/*
 * lcleartable
 */
#define gnodelast(h)    gnode(h, cast(size_t, sizenode(h)))
#define dummynode               (&dummynode_)
static const Node dummynode_ = {
	{NILCONSTANT},  /* value */
	{{NILCONSTANT, 0}}  /* key */
};

static int
lcleartable(lua_State *L) {
	luaL_checktype(L, 1, LUA_TTABLE);
	Table *h = (Table *)lua_topointer(L, 1);
	unsigned int i;
	for (i = 0; i < h->sizearray; i++)
		setnilvalue(&h->array[i]);
	if (h->node != dummynode) {
		Node *n, *limit = gnodelast(h);
		for (n = gnode(h, 0); n < limit; n++)   //traverse hash part
			setnilvalue(gval(n));
	}
	return 0;
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

void
auxI_assertion_failed(const char *file, int line, const char *diag, const char *cond)
{
	fprintf(stderr, "Assertion failed on %s line %d: %s\n", file, line, cond);
	fprintf(stderr, "Diagnostic: %s\n", diag);
	(void)fflush(stderr);
	abort();
}

/*
 * From: https://boringssl.googlesource.com/boringssl/+/ad1907fe73334d6c696c8539646c21b11178f20f
 * Tested with GCC and clang at -O3
 */

void
auxL_bzero(void *ptr, size_t len)
{
	memset(ptr, 0, len);
	__asm__ __volatile__("" : : "r"(ptr) : "memory");
}

int
auxL_assert_bzero(char *buf, size_t len)
{
	int z = 0;
	size_t i;
	for (i = 0; i < len; ++i)
		z |= buf[i];
	return z != 0;
}

char
*auxL_strncpy(char *dest, const char *src, size_t n)
{
	size_t len = strlen(src);
	if (len != 0) {
		if (len > n) {
			len = n;
		}
		memmove(dest, src, len);
		if (len < n) {
			auxL_bzero(dest + len, n - len);
		}
	}
	return dest;
}

char
*auxL_strnmove(char *dest, const char *src, size_t n)
{
	if (n > 0) {
		size_t len = strlen(src);
		if (len != 0) {
			if (len + 1 > n) {
				len = n - 1;
			}
			memmove(dest, src, len);
			dest[len] = '\0';
		}
	}
	return dest;
}

int
luaX_pusherror(lua_State *L, char *error)
{
	lua_pushnil(L);
	if (errno) {
		lua_pushfstring(L, LUA_QS" : "LUA_QS, error, strerror(errno));
		lua_pushinteger(L, errno);
		return 3;
	} else {
		lua_pushstring(L, error);
		return 2;
	}
}

static int
luaX_assert(lua_State *L)
{
	const char *msg;
	msg = 0;
	int fargs = lua_gettop(L);
	if (fargs >= 2) {
		msg = lua_tolstring(L, 2, 0);
	}
	if (lua_toboolean(L, 1)) {
		return fargs;
	} else {
		luaL_checkany(L, 1);
		lua_remove(L, 1);
		lua_Debug info;
		lua_getstack(L, 1, &info);
		const char *failed = "Assertion failed";
		if (!msg) {
			msg = "false";
		}
		const char *name;
		name = 0;
		lua_getinfo(L, "Snl", &info);
		if (info.name) {
			name = info.name;
		} else {
			name = "?";
		}
		lua_pushfstring(L, "%s:<%s.lua:%d:%s:%s> %s", \
				failed, info.source, info.currentline, info.namewhat, name,  msg);
		return lua_error(L);
	}
}

static const
luaL_Reg auxlib_funcs[] =
{
	{"assert", luaX_assert},
	{"table_copy", lclonetable},
	{"table_clear", lcleartable},
	{NULL, NULL}
};

int
luaopen_auxlib(lua_State *L)
{
	luaL_newlib(L, auxlib_funcs);
	return 1;
}
