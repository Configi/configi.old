pxSRC= vendor/c/px/src/px.c
pxOBJ= vendor/c/px/src/px.o
pxdepsSRC = vendor/c/px/src/flopen.c vendor/c/px/src/closefrom.c
pxdepsOBJ= vendor/c/px/src/flopen.o vendor/c/px/src/closefrom.o
pxA= px.a
CLEAN+= clean_px

$(pxA): $(pxOBJ) $(pxdepsOBJ)
	$(ECHOT) [AR] $@
	$(AR) $(ARFLAGS) $@ $^ >/dev/null 2>&1
	$(RANLIB) $@

$(pxOBJ): $(pxSRC)
	$(ECHOT) [CC] $@
	$(CC) -o $@ $(pxDEFINES) $(INCLUDES) $(CCWARN) $(CFLAGS) $(CCOPT) -c $<

vendor/c/px/src/%.o: vendor/c/px/src/%.c
	$(ECHOT) [CC] $@
	$(CC) -o $@ $(DEFINES) $(INCLUDES) $(CCWARN) $(CFLAGS) $(CCOPT) -c $<

clean_px:
	$(RM) $(RMFLAGS) $(pxA) $(pxOBJ) $(pxdepsOBJ)

.PHONY: clean_px

