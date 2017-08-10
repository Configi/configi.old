sendSRC= vendor/c/send/send.c
sendOBJ= vendor/c/send/send.o
sendA= send.a
sendSO= send.so
CLEAN+= clean_send

$(sendA): $(sendOBJ)
	$(ECHOT) AR $@
	$(TARGET_AR) $(ARFLAGS) $@ $< >/dev/null 2>&1
	$(TARGET_RANLIB) $@

$(sendOBJ): $(sendSRC)
	$(ECHOT) CC $@
	$(TARGET_DYNCC) -o $@ -Ivendor/c/send -Ivendor/c/auxlib $(TARGET_FLAGS) -c $<

$(sendSO): $(sendOBJ) vendor/c/auxlib/auxlib.o
	$(ECHOT) CC $@
	$(TARGET_DYNCC) -shared -o $@ $^

clean_send:
	$(RM) $(RMFLAGS) $(sendOBJ) $(sendA) $(sendSO)

.PHONY: clean_send
