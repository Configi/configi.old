.POSIX:
.SUFFIXES:
LIB= cimicida px configi factid
VENDOR= luaposix linotify crc32
MODULES= unarchive authorized_keys cron file hostname shell textfile user git \
	portage openrc \
	yum systemd \
	apk opkg sysvinit
CC= gcc
LD= ld
RANLIB= ranlib
AR= ar
STRIP= strip
LUAC= bin/luac
GLUE= bin/glue
DEFINES= -DLUA_COMPAT_BITLIB
CCOPT=
CCWARN= -Wall
CFLAGS= -Os -mtune=generic -mmmx -msse -msse2 -fomit-frame-pointer -pipe -fno-stack-protector
CFLAGS+= -ffunction-sections -fdata-sections -fno-asynchronous-unwind-tables -fno-unwind-tables
LDFLAGS= -Wl,--gc-sections -Wl,--strip-all -Wl,--relax -Wl,--sort-common

# FLAGS when compiling for an OpenWRT target.
ifneq (,$(findstring openwrt,$(CC)))
CFLAGS= -Os -fomit-frame-pointer -pipe
CFLAGS+= -ffunction-sections -fdata-sections -fno-asynchronous-unwind-tables -fno-unwind-tables
LDFLAGS= -Wl,--gc-sections -Wl,--strip-all
DEFINES+= -DHAVE_UCLIBC
endif

# Append -static-libgcc to CFLAGS if GCC is detected.
ifeq ($(shell aux/test-cc.sh $(CC)), GCC)
CFLAGS+=-static-libgcc
endif

# Test for GCC LTO capability.
ifeq ($(shell aux/test-gcc47.sh $(CC)), GCC47)
ifeq ($(shell aux/test-binutils-plugins.sh gcc-ar), TRUE)
CFLAGS += -fwhole-program -flto -fuse-linker-plugin
LDFLAGS+= -fwhole-program -flto
RANLIB= gcc-ranlib
AR= gcc-ar
endif
endif

# Linux only for now
DEFINES+= -DLUA_USE_LINUX
DLDFLAGS:= -Wl,-E -ldl -lpthread -lm -lcrypt -lrt $(LDFLAGS)

all: init bootstrap deps interpreter
include aux/std.mk
include aux/tests.mk
include $(eval _d:=lib/$(LIB) $(_d)) $(call _lget,$(LIB))
include $(eval _d:=vendor/$(VENDOR) $(_d)) $(call _vget,$(VENDOR))
include aux/modules.mk
include aux/rules.mk
