lustacheSRC= vendor/lustache/src/lustache.lua
lustacheSRCrenderer= vendor/lustache/src/lustacherenderer.lua
lustacheSRCscanner= vendor/lustache/src/lustachescanner.lua
lustacheSRCcontext= vendor/lustache/src/lustachecontext.lua
lustacheOBJ= vendor/lustache/lustache.o
lustacheOBJrenderer= vendor/lustache/lustacherenderer.o
lustacheOBJscanner= vendor/lustache/lustachescanner.o
lustacheOBJcontext= vendor/lustache/lustachecontext.o
lustacheC= vendor/lustache/lustache.c
lustacheCrenderer= vendor/lustache/lustacherenderer.c
lustacheCscanner= vendor/lustache/lustachescanner.c
lustacheCcontext= vendor/lustache/lustachecontext.c
lustacheLUAC= vendor/lustache/lustache.luac
lustacheLUACrenderer= vendor/lustache/lustacherenderer.luac
lustacheLUACscanner= vendor/lustache/lustachescanner.luac
lustacheLUACcontext= vendor/lustache/lustachecontext.luac
lustacheA= vendor/lustache/liblustache.a
DEPS+= $(lustacheA)
CLEAN+= clean_lustache

$(lustacheA): $(lustacheOBJ) $(lustacheOBJrenderer) $(lustacheOBJscanner) $(lustacheOBJcontext)
	$(ECHOT) [AR] $@
	$(AR) $(ARFLAGS) $@ $^ >/dev/null 2>&1
	$(RANLIB) $@

$(lustacheOBJ): $(lustacheC) $(LINIT_T)
	$(ECHOT) [CC] $@
	$(CC) -o $@ $(DEFINES) $(INCLUDES) $(CCWARN) $(CFLAGS) $(CCOPT) -c $<

$(lustacheOBJrenderer): $(lustacheCrenderer) $(LINIT_T)
	$(ECHOT) [CC] $@
	$(CC) -o $@ $(DEFINES) $(INCLUDES) $(CCWARN) $(CFLAGS) $(CCOPT) -c $<

$(lustacheOBJscanner): $(lustacheCscanner) $(LINIT_T)
	$(ECHOT) [CC] $@
	$(CC) -o $@ $(DEFINES) $(INCLUDES) $(CCWARN) $(CFLAGS) $(CCOPT) -c $<

$(lustacheOBJcontext): $(lustacheCcontext) $(LINIT_T)
	$(ECHOT) [CC] $@
	$(CC) -o $@ $(DEFINES) $(INCLUDES) $(CCWARN) $(CFLAGS) $(CCOPT) -c $<

$(lustacheC): $(lustacheLUAC) $(LUAC2C_T)
	@$(LUAC2C_T) -n lustache -o $@ $<

$(lustacheCrenderer): $(lustacheLUACrenderer) $(LUAC2C_T)
	@$(LUAC2C_T) -n lustacherenderer -o $@ $<

$(lustacheCscanner): $(lustacheLUACscanner) $(LUAC2C_T)
	@$(LUAC2C_T) -n lustachescanner -o $@ $<

$(lustacheCcontext): $(lustacheLUACcontext) $(LUAC2C_T)
	@$(LUAC2C_T) -n lustachecontext -o $@ $<

$(lustacheLUAC): $(lustacheSRC) $(LUAC_T)
	@$(LUAC) $(LUACFLAGS) -o $@ $<

$(lustacheLUACrenderer): $(lustacheSRCrenderer) $(LUAC_T)
	@$(LUAC) $(LUACFLAGS) -o $@ $<

$(lustacheLUACscanner): $(lustacheSRCscanner) $(LUAC_T)
	@$(LUAC) $(LUACFLAGS) -o $@ $<

$(lustacheLUACcontext): $(lustacheSRCcontext) $(LUAC_T)
	@$(LUAC) $(LUACFLAGS) -o $@ $<

clean_lustache:
	$(RM) $(RMFLAGS) $(lustacheOBJ) $(lustacheOBJrenderer) $(lustacheOBJscanner) $(lustacheOBJcontext) \
		             $(lustacheC) $(lustacheCrenderer) $(lustacheCscanner) $(lustacheCcontext) \
					 $(lustacheLUAC) $(lustacheLUACrenderer) $(lustacheLUACscanner) $(lustacheLUACcontext) \
					 $(lustacheA)

.PHONY: clean_lustache
