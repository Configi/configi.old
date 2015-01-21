factidSRC= lib/factid/src/factid.lua
factid_cSRC= lib/factid/src/factid_c.c
factidOBJ= lib/factid/factid.o
factid_cOBJ= lib/factid/factid_c.o
factidC= lib/factid/factid.c
factidLUAC= lib/factid/factid.luac
factidA= lib/factid/libfactid.a
DEPS+= $(factidA)
CLEAN+= clean_factid
TEST+= test_factid

$(factidA): $(factidOBJ) $(factid_cOBJ)
	$(ECHOT) [AR] $@
	$(AR) $(ARFLAGS) $@ $^ >/dev/null 2>&1
	$(RANLIB) $@

$(factidOBJ): $(factidC) $(LINIT_T)
	$(ECHOT) [CC] $@
	$(CC) -o $@ $(DEFINES) $(INCLUDES) $(CCWARN) $(CFLAGS) $(CCOPT) -c $<

$(factid_cOBJ): $(factid_cSRC) $(LINIT_T)
	$(ECHOT) [CC] $@
	$(CC) -o $@ $(DEFINES) $(INCLUDES) $(CCWARN) $(CFLAGS) $(CCOPT) -c $<

$(factidC): $(factidLUAC) $(LUAC2C_T)
	@$(LUAC2C_T) -n factid -o $@ $<

$(factidLUAC): $(factidSRC) $(LUAC_T)
	@$(LUAC) $(LUACFLAGS) -o $@ $<

clean_factid:
	$(RM) $(RMFLAGS) $(factidOBJ) $(factidC) $(factidLUAC) $(factidA) $(factid_cOBJ) $(factid_auxOBJ) $(factid_cA)

test_factid: $(LUA_T)
	pushd lib/factid/test; MODULE_PATH="../../../vendor/cwtest/?.lua" ../../../bin/lua test.lua ;popd


.PHONY: clean_factid test_factid

