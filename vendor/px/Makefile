pxSRC= vendor/px/src/px.lua
px_cSRC= vendor/px/src/px_c.c
px_auxSRC = vendor/px/src/flopen.c vendor/px/src/closefrom.c

pxOBJ= vendor/px/px.o
px_cOBJ= vendor/px/px_c.o
px_auxOBJ= vendor/px/flopen.o vendor/px/closefrom.o
pxLUAC= vendor/px/px.luac
pxC= vendor/px/px.c
pxA= vendor/px/libpx.a
DEPS+= $(pxA)
CLEAN+= clean_px
TEST+= test_px

$(pxA): $(pxOBJ) $(px_cOBJ) $(px_auxOBJ)
	$(ECHOT) [AR] $@
	$(AR) $(ARFLAGS) $@ $^ >/dev/null 2>&1
	$(RANLIB) $@

$(pxOBJ): $(pxC) $(LINIT_T)
	$(ECHOT) [CC] $@
	$(CC) -o $@ $(DEFINES) $(INCLUDES) $(CCWARN) $(CFLAGS) $(CCOPT) -c $<

$(px_cOBJ): $(px_cSRC) $(LINIT_T)
	$(ECHOT) [CC] $@
	$(CC) -o $@ $(pxDEFINES) $(INCLUDES) $(CCWARN) $(CFLAGS) $(CCOPT) -c $<

$(pxC): $(pxLUAC) $(LUAC2C_T)
	@$(LUAC2C_T) -n px -o $@ $<

$(pxLUAC): $(pxSRC) $(LUAC_T)
	@$(LUAC) $(LUACFLAGS) -o $@ $<

vendor/px/%.o: vendor/px/src/%.c $(LINIT_T)
	$(ECHOT) [CC] $@
	$(CC) -o $@ $(DEFINES) $(INCLUDES) $(CCWARN) $(CFLAGS) $(CCOPT) $(SOCFLAGS) -c $<

clean_px:
	$(RM) $(RMFLAGS) $(pxOBJ) $(pxC) $(pxLUAC) $(pxA) $(px_cOBJ) $(px_auxOBJ) $(px_cA)

test_px: $(LUA_T)
	pushd px/test; LUA_PATH="../../cwtest/?.lua" ../../lua test.lua ;popd

.PHONY: clean_px test_px

