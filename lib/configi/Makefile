configiSRC= lib/configi/src/configi.lua
configiOBJ= lib/configi/configi.o
configiC= lib/configi/configi.c
configiLUAC= lib/configi/configi.luac
configiA= lib/configi/libconfigi.a
DEPS+= $(configiA)
CLEAN+= clean_configi

$(configiA): $(configiOBJ)
	$(ECHOT) [AR] $@
	$(AR) $(ARFLAGS) $@ $< >/dev/null 2>&1
	$(RANLIB) $@

$(configiOBJ): $(configiC) $(LINIT_T)
	$(ECHOT) [CC] $@
	$(CC) -o $@ $(DEFINES) $(INCLUDES) $(CCWARN) $(CFLAGS) $(CCOPT) -c $<

$(configiC): $(configiLUAC) $(LUAC2C_T)
	@$(LUAC2C_T) -n configi -o $@ $<

$(configiLUAC): $(configiSRC) $(LUAC_T)
	@$(LUAC) $(LUACFLAGS) -o $@ $<

clean_configi:
	$(RM) $(RMFLAGS) $(configiOBJ) $(configiC) $(configiLUAC) $(configiA)

.PHONY: clean_configi
