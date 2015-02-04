policySRC= lib/policy/src/policy.lua
policyOBJ= lib/policy/policy.o
policyC= lib/policy/policy.c
policyLUAC= lib/policy/policy.luac
policyA= lib/policy/libpolicy.a
DEPS+= $(policyA)
CLEAN+= clean_policy

$(policyA): $(policyOBJ)
	$(ECHOT) [AR] $@
	$(AR) $(ARFLAGS) $@ $< >/dev/null 2>&1
	$(RANLIB) $@

$(policyOBJ): $(policyC) $(LINIT_T)
	$(ECHOT) [CC] $@
	$(CC) -o $@ $(DEFINES) $(INCLUDES) $(CCWARN) $(CFLAGS) $(CCOPT) -c $<

$(policyC): $(policyLUAC) $(LUAC2C_T)
	@$(LUAC2C_T) -n policy -o $@ $<

$(policyLUAC): $(policySRC) $(LUAC_T)
	@$(LUAC) $(LUACFLAGS) -o $@ $<

clean_policy:
	$(RM) $(RMFLAGS) $(policyOBJ) $(policyC) $(policyLUAC) $(policyA) $(policySRC)

.PHONY: clean_policy
