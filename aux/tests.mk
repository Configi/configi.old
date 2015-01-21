ifeq ($(shell aux/test-strlcpy.sh $(CC) $(LD)), true)
DEFINES+= -DHAVE_STRLCPY
endif

ifeq ($(shell aux/test-mkostemp.sh $(CC) $(LD)), true)
DEFINES+= -DHAVE_MKOSTEMP
endif

ifeq ($(shell aux/test-F_CLOSEM.sh $(CC) $(LD)), true)
DEFINES+= -DHAVE_FCNTL_CLOSEM
endif
