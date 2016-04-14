linotifySRC= vendor/c/linotify/linotify.c
linotifyOBJ= vendor/c/linotify/linotify.o
linotifyA= inotify.a
CLUA_MODS+= $(linotifyA)
CLUA_MODS:= $(filter-out linotify.a,$(CLUA_MODS))
CLEAN+= clean_linotify
CCWARN=

$(linotifyA): $(linotifyOBJ)
	$(ECHOT) [AR] $@
	$(AR) $(ARFLAGS) $@ $< >/dev/null 2>&1
	$(RANLIB) $@

$(linotifyOBJ): $(linotifySRC) $(LINIT_T)
	$(ECHOT) [CC] $@
	$(CC) -o $@ $(INCLUDES) -Ivendor/c/linotify $(CCWARN) $(CFLAGS) $(CCOPT) -c $<

clean_linotify:
	$(RM) $(RMFLAGS) $(linotifyOBJ) $(linotifyA)

.PHONY: clean_linotify
