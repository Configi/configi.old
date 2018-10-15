.DEFAULT_GOAL= release
EXE:= cfg
SRC:=
SRC_DIR:= files
SRC_C:=
VENDOR:= u-test cimicida lib inspect configi argparse
VENDOR_DIR:= cfg-modules plc moor moonscript moonscript/parse moonscript/transform moonscript/compile
VENDOR_C:= lfs posix px auxlib array qhttp linenoise lpeg lsocket
MAKEFLAGS= --silent
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
include lib/tests.mk
include lib/std.mk
include lib/rules.mk
test:
	cp vendor/lua/cfg-modules/*.lua cfg-modules
	bin/luacheck.lua --no-max-line-length bin/cfg.lua
	bin/luacheck.lua --no-max-line-length vendor/lua/configi.lua
	bin/luacheck.lua --no-max-line-length vendor/lua/cfg-modules/*.lua
	bin/lua bin/cfg.lua
