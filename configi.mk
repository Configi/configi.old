.PHONY: test clean_cwtest
cwtest.lua:
	$(ECHOT) CP cwtest.lua
	$(CP) vendor/lua/cwtest.lua .
test: development cwtest.lua
	$(ECHOT) RUN tests
	bin/tests.lua
clean_cwtest:
	$(RM) $(RMFLAGS) cwtest.lua
CLEAN+= clean_cwtest
