testsDEPS:= cwtest.lua cimicida.lua crc32.lua lib.lua factid.lua
testsDEPS_A:= px.a factidC.a posix.sys.stat.a posix.pwd.a posix.grp.a posix.unistd.a posix.errno.a posix.sys.wait.a posix.poll.a posix.fcntl.a posix.stdlib.a posix.syslog.a posix.dirent.a posix.libgen.a
CLEAN+= clean_tests

bin/tests: $(EXE_T)
	for f in $(testsDEPS); do $(CP) vendor/lua/$$f .;done
	$(ECHOT) LN $@
	CC=$(TARGET_STCC) NM=$(TARGET_NM) $(LUA_T) $(LUASTATIC) bin/tests.lua $(testsDEPS) $(testsDEPS_A) $(LUA_A) \
		 $(TARGET_FLAGS) $(PIE) $(TARGET_LDFLAGS) 2>&1 >/dev/null
	$(RM) $(RMFLAGS) bin/tests.lua.c $(testsDEPS)

clean_tests:
	$(RM) $(RMFLAGS) bin/tests

.PHONY: clean_tests
