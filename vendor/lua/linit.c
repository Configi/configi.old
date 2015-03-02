/*
** $Id: linit.c,v 1.32.1.1 2013/04/12 18:48:47 roberto Exp $
** Initialization of libraries for lua.c and other clients
** See Copyright Notice in lua.h
*/

#define linit_c
#define LUA_LIB

#include "lprefix.h"
#include "lua.h"
#include "lualib.h"
#include "lauxlib.h"
#ifdef lib_policy
  int luaopen_policy (lua_State *L);
#endif
#ifdef lib_cimicida
  int luaopen_cimicida (lua_State *L);
#endif
#ifdef lib_configi
  int luaopen_configi (lua_State *L);
#endif
#ifdef lib_factid
  int luaopen_factid (lua_State *L);
  int luaopen_factid_c (lua_State *L);
#endif
#ifdef lib_crc32
  int luaopen_crc32 (lua_State *L);
#endif
#ifdef lib_sha2
  int luaopen_sha2 (lua_State *L);
#endif
#ifdef lib_linotify
  int luaopen_inotify (lua_State *L);
#endif
#ifdef lib_px
  int luaopen_px (lua_State *L);
  int luaopen_px_c (lua_State *L);
#endif
#ifdef lib_luaposix
int luaopen_posix(lua_State *L);
int luaopen_posix_bit32(lua_State *L);
int luaopen_posix_ctype(lua_State *L);
int luaopen_posix_dirent(lua_State *L);
int luaopen_posix_errno(lua_State *L);
int luaopen_posix_fcntl(lua_State *L);
int luaopen_posix_fnmatch(lua_State *L);
int luaopen_posix_getopt(lua_State *L);
int luaopen_posix_glob(lua_State *L);
int luaopen_posix_grp(lua_State *L);
int luaopen_posix_libgen(lua_State *L);
int luaopen_posix_poll(lua_State *L);
int luaopen_posix_pwd(lua_State *L);
int luaopen_posix_sched(lua_State *L);
int luaopen_posix_signal(lua_State *L);
int luaopen_posix_stdio(lua_State *L);
int luaopen_posix_stdlib(lua_State *L);
int luaopen_posix_syslog(lua_State *L);
/* int luaopen_posix_termio(lua_State *L); */
int luaopen_posix_time(lua_State *L);
int luaopen_posix_unistd(lua_State *L);
int luaopen_posix_utime(lua_State *L);
int luaopen_posix_sys_msg(lua_State *L);
int luaopen_posix_sys_resource(lua_State *L);
int luaopen_posix_sys_socket(lua_State *L);
int luaopen_posix_sys_stat(lua_State *L);
int luaopen_posix_sys_statvfs(lua_State *L);
int luaopen_posix_sys_time(lua_State *L);
int luaopen_posix_sys_times(lua_State *L);
int luaopen_posix_sys_utsname(lua_State *L);
int luaopen_posix_sys_wait(lua_State *L);
#endif
#ifdef module_unarchive
int luaopen_module_unarchive(lua_State *L);
#endif
#ifdef module_authorized_keys
int luaopen_module_authorized_keys(lua_State *L);
#endif
#ifdef module_cron
int luaopen_module_cron(lua_State *L);
#endif
#ifdef module_file
int luaopen_module_file(lua_State *L);
#endif
#ifdef module_hostname
int luaopen_module_hostname(lua_State *L);
#endif
#ifdef module_openrc
int luaopen_module_openrc(lua_State *L);
#endif
#ifdef module_opkg
int luaopen_module_opkg(lua_State *L);
#endif
#ifdef module_portage
int luaopen_module_portage(lua_State *L);
#endif
#ifdef module_shell
int luaopen_module_shell(lua_State *L);
#endif
#ifdef module_systemd
int luaopen_module_systemd(lua_State *L);
#endif
#ifdef module_sysvinit
int luaopen_module_sysvinit(lua_State *L);
#endif
#ifdef module_textfile
int luaopen_module_textfile(lua_State *L);
#endif
#ifdef module_user
int luaopen_module_user(lua_State *L);
#endif
#ifdef module_yum
int luaopen_module_yum(lua_State *L);
#endif
#ifdef module_apk
int luaopen_module_apk(lua_State *L);
#endif
#ifdef module_git
int luaopen_module_git(lua_State *L);
#endif
#ifdef module_sha256
int luaopen_module_sha256(lua_State *L);
#endif
#ifdef module_iptables
int luaopen_module_iptables(lua_State *L);
#endif
#ifdef module_make
int luaopen_module_make(lua_State *L);
#endif

/*
** these libs are loaded by lua.c and are readily available to any Lua
** program
*/
static const luaL_Reg loadedlibs[] = {
  {"_G", luaopen_base},
  {LUA_LOADLIBNAME, luaopen_package},
  {LUA_COLIBNAME, luaopen_coroutine},
  {LUA_TABLIBNAME, luaopen_table},
  {LUA_IOLIBNAME, luaopen_io},
  {LUA_OSLIBNAME, luaopen_os},
  {LUA_STRLIBNAME, luaopen_string},
/*  {LUA_UTF8LIBNAME, luaopen_utf8}, */
  {LUA_MATHLIBNAME, luaopen_math},
#ifdef DEBUG
  {LUA_DBLIBNAME, luaopen_debug},
#endif
  {NULL, NULL}
};


/*
** these libs are preloaded and must be required before used
*/
static const luaL_Reg preloadedlibs[] = {
#ifdef lib_policy
  {"policy", luaopen_policy},
#endif
#ifdef lib_cimicida
  {"cimicida", luaopen_cimicida},
#endif
#ifdef lib_configi
  {"configi", luaopen_configi},
#endif
#ifdef lib_factid
  {"factid", luaopen_factid},
  {"factid_c", luaopen_factid_c},
#endif
#ifdef lib_crc32
  {"crc32", luaopen_crc32},
#endif
#ifdef lib_sha2
  {"sha2", luaopen_sha2},
#endif
#ifdef lib_linotify
  {"inotify", luaopen_inotify},
#endif
#ifdef lib_lunix
  {"unix", luaopen_unix},
#endif
#ifdef lib_px
  {"px", luaopen_px},
  {"px_c", luaopen_px_c},
#endif
#ifdef lib_luaposix
  {"posix.ctype", luaopen_posix_ctype},
  {"posix.dirent", luaopen_posix_dirent},
  {"posix.errno", luaopen_posix_errno},
  {"posix.fcntl", luaopen_posix_fcntl},
  {"posix.fnmatch", luaopen_posix_fnmatch},
  {"posix.getopt", luaopen_posix_getopt},
  {"posix.glob", luaopen_posix_glob},
  {"posix.grp", luaopen_posix_grp},
  {"posix.libgen", luaopen_posix_libgen},
  {"posix.poll", luaopen_posix_poll},
  {"posix.pwd", luaopen_posix_pwd},
  {"posix.sched", luaopen_posix_sched},
  {"posix.signal", luaopen_posix_signal},
  {"posix.stdio", luaopen_posix_stdio},
  {"posix.stdlib", luaopen_posix_stdlib},
  {"posix.syslog", luaopen_posix_syslog},
/*  {"posix.c.termio", luaopen_posix_termio}, */
  {"posix.time", luaopen_posix_time},
  {"posix.unistd", luaopen_posix_unistd},
  {"posix.utime", luaopen_posix_utime},
  {"posix.sys.msg", luaopen_posix_sys_msg},
  {"posix.sys.resource", luaopen_posix_sys_resource},
  {"posix.sys.socket", luaopen_posix_sys_socket},
  {"posix.sys.stat", luaopen_posix_sys_stat},
  {"posix.sys.statvfs", luaopen_posix_sys_statvfs},
  {"posix.sys.time", luaopen_posix_sys_time},
  {"posix.sys.times", luaopen_posix_sys_times},
  {"posix.sys.utsname", luaopen_posix_sys_utsname},
  {"posix.sys.wait", luaopen_posix_sys_wait},
  {"posix", luaopen_posix},
#endif
#ifdef module_unarchive
  {"module.unarchive", luaopen_module_unarchive},
#endif
#ifdef module_authorized_keys
  {"module.authorized_keys", luaopen_module_authorized_keys},
#endif
#ifdef module_cron
  {"module.cron", luaopen_module_cron},
#endif
#ifdef module_file
  {"module.file", luaopen_module_file},
#endif
#ifdef module_hostname
  {"module.hostname", luaopen_module_hostname},
#endif
#ifdef module_openrc
  {"module.openrc", luaopen_module_openrc},
#endif
#ifdef module_opkg
  {"module.opkg", luaopen_module_opkg},
#endif
#ifdef module_portage
  {"module.portage", luaopen_module_portage},
#endif
#ifdef module_shell
  {"module.shell", luaopen_module_shell},
#endif
#ifdef module_systemd
  {"module.systemd", luaopen_module_systemd},
#endif
#ifdef module_sysvinit
  {"module.sysvinit", luaopen_module_sysvinit},
#endif
#ifdef module_textfile
  {"module.textfile", luaopen_module_textfile},
#endif
#ifdef module_user
  {"module.user", luaopen_module_user},
#endif
#ifdef module_yum
  {"module.yum", luaopen_module_yum},
#endif
#ifdef module_apk
  {"module.apk", luaopen_module_apk},
#endif
#ifdef module_git
  {"module.git", luaopen_module_git},
#endif
#ifdef module_sha256
  {"module.sha256", luaopen_module_sha256},
#endif
#ifdef module_iptables
  {"module.iptables", luaopen_module_iptables},
#endif
#ifdef module_make
  {"module.make", luaopen_module_make},
#endif
#if defined(LUA_COMPAT_BITLIB)
  {"bit32", luaopen_bit32},
#endif
  {NULL, NULL}
};

LUALIB_API void luaL_openlibs (lua_State *L) {
  const luaL_Reg *lib;
  /* "require" functions from 'loadedlibs' and set results to global table */
  for (lib = loadedlibs; lib->func; lib++) {
    luaL_requiref(L, lib->name, lib->func, 1);
    lua_pop(L, 1);  /* remove lib */
  }
  /* add open functions from 'preloadedlibs' into 'package.preload' table */
  luaL_getsubtable(L, LUA_REGISTRYINDEX, "_PRELOAD");
  for (lib = preloadedlibs; lib->func; lib++) {
    lua_pushcfunction(L, lib->func);
    lua_setfield(L, -2, lib->name);
  }
  lua_pop(L, 1);  /* remove _PRELOAD table */
}



