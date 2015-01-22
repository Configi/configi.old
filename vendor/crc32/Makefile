crc32SRC= vendor/crc32/src/crc32.lua
crc32OBJ= vendor/crc32/crc32.o
crc32C= vendor/crc32/crc32.c
crc32LUAC= vendor/crc32/crc32.luac
crc32A= vendor/crc32/libcrc32.a
DEPS+= $(crc32A)
CLEAN+= clean_crc32

$(crc32A): $(crc32OBJ)
	$(ECHOT) [AR] $@
	$(AR) $(ARFLAGS) $@ $< >/dev/null 2>&1
	$(RANLIB) $@

$(crc32OBJ): $(crc32C) $(LINIT_T)
	$(ECHOT) [CC] $@
	$(CC) -o $@ $(DEFINES) $(INCLUDES) $(CCWARN) $(CFLAGS) $(CCOPT) -c $<

$(crc32C): $(crc32LUAC) $(LUAC2C_T)
	@$(LUAC2C_T) -n crc32 -o $@ $<

$(crc32LUAC): $(crc32SRC) $(LUAC_T)
	@$(LUAC) $(LUACFLAGS) -o $@ $<

clean_crc32:
	$(RM) $(RMFLAGS) $(crc32OBJ) $(crc32C) $(crc32LUAC) $(crc32A)

.PHONY: clean_crc32
