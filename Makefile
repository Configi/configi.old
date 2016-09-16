EXE:= cfg
SRC:= configi
SRC_DIR:= module
SRC_C:=
VENDOR:= cimicida crc32 sha2 lib
VENDOR_DIR:= moonscript moonscript/parse moonscript/compile moonscript/transform
VENDOR_C:= linotify luaposix factid px lpeg
MAKEFLAGS= --silent
CC= cc
LD= ld
RANLIB= ranlib
AR= ar
NM= nm
CCOPT= -Os -mtune=generic -mmmx -msse -msse2 -fomit-frame-pointer -pipe
CFLAGS+= -ffunction-sections -fdata-sections -fno-asynchronous-unwind-tables -fno-unwind-tables
LDFLAGS= -Wl,--gc-sections -Wl,--strip-all -Wl,--relax -Wl,--sort-common
luaDEFINES:= -DLUA_COMPAT_BITLIB -DLUA_USE_POSIX
include aux/tests.mk
include aux/std.mk
include aux/configi.mk
include aux/rules.mk
