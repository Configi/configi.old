FNLC= bin/fennelc.lua
FNLC_T= bin/fennelc
CLEAN+= clean_fennel

$(FNLC_T):
	$(ECHOT) CC $@
	$(CP) vendor/lua/fennel.lua .
	CC=$(HOST_CC) NM=$(NM) $(LUA_T) $(LUASTATIC) $(FNLC) fennel.lua $(LIBLUAJIT_A) $(FLAGS) $(LDFLAGS) 2>&1 >/dev/null
	$(RM) $(RMFLAGS) fennel.lua $(FNL).c

%.lua: $(FNLC_T) %.fnl
	$(FNLC) $*.fnl $@

clean_fennel:
	$(RM) $(RMFLAGS) $(COMPILED_FNL) $(FNLC_T) cimicida.lua
