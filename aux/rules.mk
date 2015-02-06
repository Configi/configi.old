$(LUAC_T):
	$(ECHOT) [CC] $@
	$(CC) -o $@ -DMAKE_LUAC $(DEFINES) $(INCLUDES) $(CCWARN) $(CFLAGS) $(CCOPT) $(ONE).c $(DLDFLAGS)

$(LUAC2C_T): $(AUX_P)/luac2c.c
	$(ECHOT) [CC] $@
	cc -o $@ $(CCWARN) $(CFLAGS) $(CCOPT) $<

bootstrap: $(LUAC_T) $(LUAC2C_T)

deps: $(DEPS)

$(LUA_T): $(DEPS)
	$(ECHOT) [CC] $@
	$(CC) -o $@ -DMAKE_LUA $(DEFINES) $(LDEFINES) $(INCLUDES) $(CCWARN) $(CFLAGS) $(CCOPT) $(ONE).c $(DLDFLAGS) $(LDLIBS)

$(SRLUA_T): $(DEPS)
	$(ECHOT) [CC] $@
	$(CC) -o $@ -DMAKE_LUA $(DEFINES) $(LDEFINES) $(INCLUDES) $(CCWARN) $(CFLAGS) $(CCOPT) $(SRLUA).c $(DLDFLAGS) $(LDLIBS)

$(GLUE_T):
	$(ECHOT) [CC] $@
	$(CC) -o $@ $(GLUE_SRC).c

$(CFG_T): $(GLUE_T) $(SRLUA_T) $(LUA_T) $(CFG)
	$(ECHOT) [OK] $@
	$(GLUE) $(SRLUA_T) $(CFG) $@
	$(CHMOD) +x $@

interpreter: $(LUA_T) $(SRLUA_T) $(GLUE_T) $(CFG_T)

strip: $(LUA_T) $(SRLUA_T)
	$(STRIP) $(STRIPFLAGS) $^

compress: $(LUA_T)
	$(UPX) $(UPXFLAGS) $<

clean: $(CLEAN)
	$(ECHO) "Cleaning up..."
	$(RM) $(RMFLAGS) $(LUA_O) $(VLUA_O) $(VLUA_T) $(LUA_T) $(LUAC_T) $(LUAC2C_T) \
		$(SRLUA_T) $(GLUE_T) $(CFG_T) $(TESTLOG_F)
	$(RMRF) test/tmp
	$(ECHO) "Done!"

test_configi: $(LUA_T)
	bin/lua test/test.lua | tee $(TESTLOG_F)

test: test_configi $(TEST)
	$(ECHO) "Tests done."

.PHONY: all init bootstrap modules interpreter compress strip clean test test_lua
