px_cSRC= vendor/c/px/src/px_c.c
px_cOBJ= vendor/c/px/src/px_c.o
px_depsSRC = vendor/c/px/src/flopen.c vendor/c/px/src/closefrom.c
px_depsOBJ= vendor/c/px/src/flopen.o vendor/c/px/src/closefrom.o
px_cA= px_c.a
CLUA_MODS+= $(px_cA)
CLUA_MODS:= $(filter-out px.a,$(CLUA_MODS))
VENDOR_LUA+= px
CLEAN+= clean_px

$(px_cA): $(px_cOBJ) $(px_depsOBJ)
	$(ECHOT) [AR] $@
	$(AR) $(ARFLAGS) $@ $^ >/dev/null 2>&1
	$(RANLIB) $@

$(px_cOBJ): $(px_cSRC)
	$(ECHOT) [CC] $@
	$(CC) -o $@ $(pxDEFINES) $(INCLUDES) $(CCWARN) $(CFLAGS) $(CCOPT) -c $<

vendor/c/px/src/%.o: vendor/c/px/src/%.c
	$(ECHOT) [CC] $@
	$(CC) -o $@ $(DEFINES) $(INCLUDES) $(CCWARN) $(CFLAGS) $(CCOPT) -c $<

clean_px:
	$(RM) $(RMFLAGS) $(pxA) $(px_cOBJ) $(px_depsOBJ)

.PHONY: clean_px

