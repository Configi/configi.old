cimicidaSRC= vendor/cimicida/src/cimicida.lua
cimicidaOBJ= vendor/cimicida/cimicida.o
cimicidaC= vendor/cimicida/cimicida.c
cimicidaLUAC= vendor/cimicida/cimicida.luac
cimicidaA= vendor/cimicida/libcimicida.a
DEPS+= $(cimicidaA)
CLEAN+= clean_cimicida

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

.PHONY: clean_cimicida
