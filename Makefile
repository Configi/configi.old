EXE= cfg
VENDOR_C= linotify luaposix factid px lpeg
VENDOR_LUA= cimicida crc32 sha2 lib
APP_SUBDIRS= module
APP_DEPS= module/make.lua module/cron.lua module/hostname.lua module/openrc.lua module/sha256.lua module/opkg.lua module/git.lua module/shell.lua module/textfile.lua module/iptables.lua module/authorized_keys.lua module/unarchive.lua module/portage.lua module/sysvinit.lua module/systemd.lua module/apk.lua module/user.lua module/yum.lua module/file.lua
APP_C=
APP_LUA= configi
MAKEFLAGS= --silent
CC= cc
LD= ld
RANLIB= ranlib
AR= ar
NM= nm
CCWARN= -Wall
CCOPT= -Os -mtune=generic -mmmx -msse -msse2 -fomit-frame-pointer -pipe
CFLAGS+= -ffunction-sections -fdata-sections -fno-asynchronous-unwind-tables -fno-unwind-tables
LDFLAGS= -Wl,--gc-sections -Wl,--strip-all -Wl,--relax -Wl,--sort-common
luaDEFINES:= -DLUA_COMPAT_BITLIB -DLUA_USE_POSIX
include aux/tests.mk
include aux/std.mk
include aux/configi.mk
include aux/vendor.mk
include aux/rules.mk
