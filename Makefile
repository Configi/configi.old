.PHONY: default
default: release
EXE:= cfg
SRC:=
SRC_DIR:= cfg-modules cfg-core
SRC_C:=
VENDOR:= cimicida crc32 sha2 lib tsort
VENDOR_DIR:=
VENDOR_C:= inotify posix factid px qhttp auxlib
MAKEFLAGS=
HOST_CC= cc
CROSS=
CROSS_CC=
CCOPT= -Os -mtune=generic -mmmx -msse -msse2 -fomit-frame-pointer -pipe
CFLAGS+= -ffunction-sections -fdata-sections -fno-asynchronous-unwind-tables -fno-unwind-tables
LDFLAGS= -Wl,--gc-sections -Wl,--strip-all -Wl,--relax -Wl,--sort-common
luaDEFINES:= -DLUA_COMPAT_BITLIB -DLUA_USE_POSIX
TARGET_CCOPT= $(CCOPT)
TARGET_CFLAGS= $(CFLAGS)
TARGET_LDFLAGS= $(LDFLAGS)
include configi.mk
include lib/tests.mk
include lib/std.mk
include lib/rules.mk
