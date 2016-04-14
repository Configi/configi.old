factid_cSRC= vendor/c/factid_c/src/factid_c.c
factid_cOBJ= vendor/c/factid_c/src/factid_c.o
factid_cA= factid_c.a
CLEAN+= clean_factid

$(factid_cA): $(factid_cOBJ) 
	$(ECHOT) [AR] $@
	$(AR) $(ARFLAGS) $@ $^ >/dev/null 2>&1
	$(RANLIB) $@

$(factid_cOBJ): $(factid_cSRC)
	$(ECHOT) [CC] $@
	$(CC) -o $@ $(INCLUDES) $(CCWARN) $(CFLAGS) $(CCOPT) -c $<

clean_factid:
	$(RM) $(RMFLAGS) $(factid_cA) $(factid_cOBJ) 

.PHONY: clean_factid

