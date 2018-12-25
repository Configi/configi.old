.POSIX:
.SUFFIXES:
NULSTRING:=
CONFIGURE_P:= lib/configure
INCLUDES_P:= -Ilib/luajit/src
ifeq ($(CROSS),)
  CROSS:= $(NULSTRING)
endif
ifeq ($(CROSS_CC),)
  CROSS_CC:= $(HOST_CC)
endif
LD= ld
NM= nm
AR= ar
RANLIB= ranlib
STRIP= strip
CC= $(CROSS_CC)
TARGET_DYNCC:= $(CROSS)$(CC) -fPIC
TARGET_STCC:= $(CROSS)$(CC)
TARGET_LD= $(CROSS)$(LD)
TARGET_RANLIB= $(CROSS)$(RANLIB)
TARGET_AR= $(CROSS)$(AR)
TARGET_NM= $(CROSS)$(NM)
TARGET_STRIP= $(CROSS)$(STRIP)

# FLAGS when cross compiling
ifneq (,$(CROSS))
  TARGET_CCOPT:= -Os -fomit-frame-pointer -pipe
  TARGET_LDFLAGS= -Wl,--strip-all
endif

# Append -static-libgcc to CFLAGS if GCC is detected.
IS_CC:= $(shell $(CONFIGURE_P)/test-cc.sh $(TARGET_STCC))
ifeq ($(IS_CC), GCC)
  TARGET_CFLAGS+= -static-libgcc -lgcc_eh
endif

ifeq ($(shell $(CONFIGURE_P)/test-gcc47.sh $(TARGET_STCC)), true)
  ifeq ($(shell $(CONFIGURE_P)/test-binutils-plugins.sh $(CROSS)gcc-$(AR)), true)
    TARGET_RANLIB:= $(CROSS)gcc-$(RANLIB)
    TARGET_AR:= $(CROSS)gcc-$(AR)
    TARGET_NM:= $(CROSS)gcc-$(NM)
  endif
endif

ifeq ($(or $(MAKECMDGOALS),$(.DEFAULT_GOAL)), development)
  CCWARN:= -Wall -Wextra -Wredundant-decls -Wshadow -Wpointer-arith -Werror -Wfatal-errors
  TARGET_CFLAGS:= -U_FORTIFY_SOURCE -D_FORTIFY_SOURCE=2 -O1 -fno-omit-frame-pointer -ggdb
  CFLAGS:= -U_FORTIFY_SOURCE -D_FORTIFY_SOURCE=2 -O1 -fno-omit-frame-pointer -ggdb
  FOUND_ASAN:= $(shell $(CONFIGURE_P)/test-lasan.sh $(TARGET_STCC))
  ifeq ($(FOUND_ASAN), 0)
	CFLAGS+= -fsanitize=address
  endif
  FOUND_UBSAN:= $(shell $(CONFIGURE_P)/test-lubsan.sh $(TARGET_STCC))
  ifeq ($(FOUND_UBSAN), 0)
	CFLAGS+= -fsanitize=undefined
  endif
  TARGET_CCOPT:= $(NULSTRING)
  FOUND_LSAN:= $(shell $(CONFIGURE_P)/test-lsan.sh $(TARGET_STCC))
  ifeq ($(FOUND_LSAN), 0)
	CFLAGS+= -fsanitize=leak
  endif
  CCOPT:= $(NULSTRING)
  TARGET_LDFLAGS:= $(NULSTRING)
  LDFLAGS:= $(NULSTRING)
else
  DEFINES+= -DNDEBUG
endif

ifeq ($(STATIC), 1)
  PIE:= $(NULSTRING)
  TARGET_LDFLAGS+= -static
else
  ifneq ($(IS_CC), CLANG)
    PIE:= -fPIE -pie
  else
    PIE:= -fPIE -Wl,-pie
  endif
endif

TARGET_FLAGS:= $(DEFINES) $(INCLUDES_P) $(TARGET_CFLAGS) $(TARGET_CCOPT) $(CCWARN) $(CFLAGS_LRT)
FLAGS:= $(DEFINES) $(INCLUDES_P) $(CFLAGS) $(CCOPT) $(CCWARN)
