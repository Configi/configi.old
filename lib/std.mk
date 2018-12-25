EXE_T:= bin/$(EXE)
MAIN:= $(EXE_T).lua
LUASTATIC:= bin/luastatic.lua
LUA_T:= bin/lua
LIBLUAJIT_A:= lib/luajit/src/libluajit.a
ECHO:= @printf '%s\n'
ECHON:= @printf '%s'
ECHOT:= @printf '%s\t  %s\n'
INSTALL:= @install
PREFIX?= /usr/local
CP:= cp
CPR:= cp -R
STRIPFLAGS:= --strip-all
RM:= rm
RMFLAGS:= -f
RMRF:= rm -rf
VENDOR_P:= vendor/lua
SRC_P:= src/lua
VENDOR_LUA:= $(addsuffix /*.lua,$(VENDOR_DIR))
SRC_LUA:= $(addsuffix /*.lua,$(SRC_DIR))
SRC_CHECK:= $(foreach m, $(SRC_DIR), src/lua/$m/*.lua)
VENDOR_DIRS:= $(sort $(foreach f, $(VENDOR_DIR), $(firstword $(subst /, ,$f))))
SRC_DIRS:= $(sort $(foreach f, $(SRC_DIR), $(firstword $(subst /, ,$f))))
_rest= $(wordlist 2,$(words $(1)),$(1))
_lget= $(firstword src/c/$(1))/Makefile $(if $(_rest),$(call _lget,$(_rest)),)
_vget= $(firstword vendor/c/$(1))/Makefile $(if $(_rest),$(call _vget,$(_rest)),)
VENDOR_TOP+= $(foreach m, $(VENDOR), $m.lua)
SRC_TOP+= $(foreach m, $(SRC), $m.lua)
SRC_FNL:= $(wildcard bin/*.fnl)
SRC_FNL+= $(wildcard src/lua/*.fnl)
SRC_FNL+= $(wildcard vendor/lua/*.fnl)
SRC_FNL+= $(foreach m, $(SRC_DIR), $(wildcard src/lua/$m/*.fnl))
SRC_FNL+= $(foreach m, $(VENDOR_DIR), $(wildcard vendor/lua/$m/*.fnl))
COMPILED_FNL:= $(foreach m, $(SRC_FNL), $(addsuffix .lua, $(basename $m)))
BUILD_DEPS= has-$(TARGET_STCC) has-$(TARGET_RANLIB) has-$(TARGET_NM) has-$(TARGET_AR) has-$(TARGET_STRIP)

release: $(EXE_T)

ifneq ($(COMPILED_FNL),)
  include lib/fennel.mk
endif

print-%: ; @echo $*=$($*)

vprint-%:
	@echo '$*=$($*)'
	@echo ' origin = $(origin $*)'
	@echo ' flavor = $(flavor $*)'
	@echo ' value = $(value $*)'

has-%:
	@command -v "${*}" >/dev/null 2>&1 || { \
		echo "Missing build-time dependency: ${*}"; \
		exit -1; \
	}

.PHONY: development release new clean install print-% vprint-% has-%
