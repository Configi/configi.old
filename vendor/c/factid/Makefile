factidSRC= vendor/c/factid/src/factidC.c
factidOBJ= vendor/c/factid/src/factidC.o
factidA= factidC.a
CLUA_MODS+= $(factidA)
CLUA_MODS:= $(filter-out factid.a,$(CLUA_MODS))
VENDOR_LUA+= factid
CLEAN+= clean_factid

$(factidA): $(factidOBJ) 
	$(ECHOT) [AR] $@
	$(AR) $(ARFLAGS) $@ $^ >/dev/null 2>&1
	$(RANLIB) $@

$(factidOBJ): $(factidSRC)
	$(ECHOT) [CC] $@
	$(CC) -o $@ $(INCLUDES) $(CCWARN) $(CFLAGS) $(CCOPT) -c $<

clean_factid:
	$(RM) $(RMFLAGS) $(factidA) $(factidOBJ) 

.PHONY: clean_factid

