factidSRC= vendor/factid/src/factid.lua
factid_cSRC= vendor/factid/src/factid_c.c
factidOBJ= vendor/factid/factid.o
factid_cOBJ= vendor/factid/factid_c.o
factidC= vendor/factid/factid.c
factidLUAC= vendor/factid/factid.luac
factidA= vendor/factid/libfactid.a
DEPS+= $(factidA)
CLEAN+= clean_factid

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

.PHONY: clean_factid

