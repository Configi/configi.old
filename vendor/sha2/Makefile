sha2SRC= vendor/sha2/src/sha2.lua
sha2OBJ= vendor/sha2/sha2.o
sha2C= vendor/sha2/sha2.c
sha2LUAC= vendor/sha2/sha2.luac
sha2A= vendor/sha2/libsha2.a
DEPS+= $(sha2A)
CLEAN+= clean_sha2

$(sha2A): $(sha2OBJ)
	$(ECHOT) [AR] $@
	$(AR) $(ARFLAGS) $@ $< >/dev/null 2>&1
	$(RANLIB) $@

$(sha2OBJ): $(sha2C) $(LINIT_T)
	$(ECHOT) [CC] $@
	$(CC) -o $@ $(DEFINES) $(INCLUDES) $(CCWARN) $(CFLAGS) $(CCOPT) -c $<

$(sha2C): $(sha2LUAC) $(LUAC2C_T)
	@$(LUAC2C_T) -n sha2 -o $@ $<

$(sha2LUAC): $(sha2SRC) $(LUAC_T)
	@$(LUAC) $(LUACFLAGS) -o $@ $<

clean_sha2:
	$(RM) $(RMFLAGS) $(sha2OBJ) $(sha2C) $(sha2LUAC) $(sha2A)

.PHONY: clean_sha2
