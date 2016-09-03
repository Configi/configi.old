testDEPS:= cwtest.lua cimicida.lua crc32.lua lib.lua factid.lua px.a factidC.a posix.sys.stat.a posix.pwd.a posix.grp.a posix.unistd.a posix.errno.a posix.sys.wait.a posix.poll.a posix.fcntl.a posix.stdlib.a posix.syslog.a posix.dirent.a
CLEAN+= clean_tests

tests: $(LUA_A) $(CLUA_MODS)
	$(CP) vendor/lua/cwtest.lua .
	$(ECHOT) [LN] $@
	$(LUA_T) $(LUASTATIC) test/tests.lua $(testDEPS) $(LUA_A) $(INCLUDES) $(CCWARN) $(CFLAGS) $(CCOPT) $(LDFLAGS)
	$(RM) $(RMFLAGS) cwtest.lua

clean_tests:
	$(RM) $(RMFLAGS) tests test/tests.lua.c

.PHONY: clean_tests
