$(LIBLUAJIT_A):
	$(MAKE) -C lib/luajit/src \
                TARGET_CFLAGS="$(TARGET_CFLAGS) -DLUAJIT_ENABLE_LUA52COMPAT" \
                TARGET_LD="$(TARGET_LD)" \
                TARGET_LDFLAGS="$(TARGET_LDFLAGS)" \
                TARGET_STCC="$(TARGET_STCC)" \
                TARGET_DYNCC="$(TARGET_DYNCC)" \
                TARGET_CC="$(TARGET_DYNCC)" \
                TARGET_AR="$(TARGET_AR) rcs" \
                libluajit.a "LJCORE_O=ljamalg.o"
$(LUA_T): $(LIBLUAJIT_A)
	$(ECHOT) CC $@
	$(MAKE) -C lib/luajit/src \
		BUILDMODE="static" \
                TARGET_FLAGS="-O2 -mtune=generic -mmmx -msse -msse2 -fomit-frame-pointer -pipe" \
		TARGET_LDFLAGS="-Wl,--strip-all" \
                TARGET_LD="$(HOST_CC)" \
	        luajit
	$(ECHOT) MV $@
	mv lib/luajit/src/luajit bin/lua

$(VENDOR_TOP):
	$(ECHOT) CP VENDOR
	for f in $(VENDOR); do $(CP) $(VENDOR_P)/$$f.lua .; done

$(SRC_TOP):
	$(ECHOT) CP SRC
	for f in $(SRC); do $(CP) $(SRC_P)/$$f.lua .; done

$(SRC_LUA):
	$(ECHOT) CP SRC_DIR
	for d in $(SRC_DIRS); do [ -d $$d ] || $(CPR) $(SRC_P)/$$d .; done

$(VENDOR_LUA):
	$(ECHOT) CP VENDOR_DIR
	for d in $(VENDOR_DIRS); do [ -d $$d ] || $(CPR) $(VENDOR_P)/$$d .; done

$(EXE_T): $(BUILD_DEPS) $(LIBLUAJIT_A) $(LUA_T) $(COMPILED_FNL) $(VENDOR_TOP) $(SRC_TOP) $(SRC_LUA) $(VENDOR_LUA)
	$(ECHOT) LN $(EXE_T)
	CC=$(TARGET_STCC) NM=$(TARGET_NM) $(LUA_T) $(LUASTATIC) $(MAIN) \
	   $(SRC_LUA) $(VENDOR_LUA) $(VENDOR_TOP) $(SRC_TOP) $(LIBLUAJIT_A) \
	   $(TARGET_FLAGS) $(PIE) $(TARGET_LDFLAGS) 2>&1 >/dev/null
	$(RM) $(RMFLAGS) $(MAIN).c $(VENDOR_TOP) $(SRC_TOP)
	$(RMRF) $(VENDOR_DIRS) $(SRC_DIRS)

development: $(LUA_T) $(COMPILED_FNL) $(VENDOR_LUA) $(VENDOR_TOP)
	for f in $(SRC); do $(CP) $(SRC_P)/$$f.lua .; done
	$(RMRF) $(SRC_DIRS)
	for d in $(SRC_DIRS); do $(CPR) $(SRC_P)/$$d .; done
	$(ECHOT) RUN luacheck
	-bin/luacheck.lua src/lua/*.lua $(COMPILED_FNL) $(SRC_CHECK) --exclude-files 'vendor/lua/*'
	$(RM) $(RMFLAGS) luacov.stats.out

clean: $(CLEAN)
	$(ECHO) "Cleaning up..."
	$(RM) $(RMFLAGS) $(MAIN).c $(LUA_T) $(EXE_T) \
	   $(LIBLUAJIT_A) $(COMPILED_FNL) $(VENDOR_TOP) $(SRC_TOP)
	$(RMRF) $(SRC_DIRS) $(VENDOR_DIRS)
	$(RMRF) *.a bin/*.dSYM luacheck luacov luacov.report.out luacov.stats.out
	$(MAKE) -C lib/luajit/src clean
	$(ECHO) "Done!"

install: $(EXE_T)
	$(ECHO) "Installing..."
	$(INSTALL) -d $(DESTDIR)$(PREFIX)/bin
	$(INSTALL) -c $(EXE_T) $(DESTDIR)$(PREFIX)/$(EXE_T)
	$(ECHO) "Done!"

new:
	$(RMRF) vendor/lua/* vendor/c/* src/lua/* src/c/* Makefile
	$(CP) lib/Makefile.pristine Makefile

