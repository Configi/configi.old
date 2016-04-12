px_cSRC= app/c/px_c/src/px_c.c
px_cOBJ= app/c/px_c/src/px_c.o
px_depsSRC = app/c/px_c/src/flopen.c app/c/px_c/src/closefrom.c
px_depsOBJ= app/c/px_c/src/flopen.o app/c/px_c/src/closefrom.o
px_cA= px_c.a
CLEAN+= clean_px

$(px_cA): $(px_cOBJ) $(px_depsOBJ)
	$(ECHOT) [AR] $@
	$(AR) $(ARFLAGS) $@ $^ >/dev/null 2>&1
	$(RANLIB) $@

$(px_cOBJ): $(px_cSRC)
	$(ECHOT) [CC] $@
	$(CC) -o $@ $(pxDEFINES) $(INCLUDES) $(CCWARN) $(CFLAGS) $(CCOPT) -c $<

app/c/px_c/src/%.o: app/c/px_c/src/%.c
	$(ECHOT) [CC] $@
	$(CC) -o $@ $(DEFINES) $(INCLUDES) $(CCWARN) $(CFLAGS) $(CCOPT) -c $<

clean_px:
	$(RM) $(RMFLAGS) $(pxA) $(px_cOBJ) $(px_depsOBJ)

.PHONY: clean_px

