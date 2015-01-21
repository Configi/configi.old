cimicidaSRC= lib/cimicida/src/cimicida.lua
cimicidaOBJ= lib/cimicida/cimicida.o
cimicidaC= lib/cimicida/cimicida.c
cimicidaLUAC= lib/cimicida/cimicida.luac
cimicidaA= lib/cimicida/libcimicida.a
DEPS+= $(cimicidaA)
CLEAN+= clean_cimicida
TEST+= test_cimicida

$(cimicidaA): $(cimicidaOBJ)
	$(ECHOT) [AR] $@
	$(AR) $(ARFLAGS) $@ $< >/dev/null 2>&1
	$(RANLIB) $@

$(cimicidaOBJ): $(cimicidaC) $(LINIT_T)
	$(ECHOT) [CC] $@
	$(CC) -o $@ $(DEFINES) $(INCLUDES) $(CCWARN) $(CFLAGS) $(CCOPT) -c $<

$(cimicidaC): $(cimicidaLUAC) $(LUAC2C_T)
	@$(LUAC2C_T) -n cimicida -o $@ $<

$(cimicidaLUAC): $(cimicidaSRC) $(LUAC_T)
	@$(LUAC) $(LUACFLAGS) -o $@ $<

clean_cimicida:
	$(RM) $(RMFLAGS) $(cimicidaOBJ) $(cimicidaC) $(cimicidaLUAC) $(cimicidaA)

test_cimicida: $(LUA_T)
	pushd lib/cimicida/test; MODULE_PATH="../../../vendor/cwtest/?.lua" ../../../bin/lua test.lua ;popd

.PHONY: clean_cimicida test_cimicida
