testDEPS:= cwtest.lua cimicida.lua crc32.lua lib.lua factid.lua px.a factidC.a posix.sys.stat.a posix.pwd.a posix.grp.a posix.unistd.a posix.errno.a posix.sys.wait.a posix.poll.a posix.fcntl.a posix.stdlib.a posix.syslog.a posix.dirent.a posix.libgen.a
CLEAN+= clean_tests

tests: $(EXE)
	$(CP) vendor/lua/cwtest.lua .
	$(ECHOT) LN $@
	CC=$(TARGET_STCC) NM=$(TARGET_NM) $(LUA_T) $(LUASTATIC) test/tests.lua $(testDEPS) $(LUA_A) $(TARGET_FLAGS) $(PIE) $(TARGET_LDFLAGS) 2>&1 >/dev/null
	$(RM) $(RMFLAGS) bin/tests.lua.c cwtest.lua cimicida.lua crc32.lua lib.lua factid.lua

clean_tests:
	$(RM) $(RMFLAGS) bin/tests

.PHONY: clean_tests
