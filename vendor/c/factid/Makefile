factidSRC= vendor/c/factid/src/factidC.c
factidOBJ= vendor/c/factid/src/factidC.o
factidA= factidC.a
C_MODULES+= $(factidA)
C_MODULES:= $(filter-out factid.a,$(C_MODULES))
VENDOR+= factid
CLEAN+= clean_factid

$(factidA): $(factidOBJ)
	$(ECHOT) [AR] $@
	$(AR) $(ARFLAGS) $@ $^ >/dev/null 2>&1
	$(RANLIB) $@

$(factidOBJ): $(factidSRC)
	$(ECHOT) [CC] $@
	$(CC) -o $@ $(INCLUDES) $(CCWARN) $(CFLAGS) $(CCOPT) -c $<

clean_factid:
	$(RM) $(RMFLAGS) $(factidA) $(factidOBJ)

.PHONY: clean_factid

