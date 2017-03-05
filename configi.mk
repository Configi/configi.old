.PHONY: test clean_cwtest
test: dev
	$(CP) vendor/lua/cwtest.lua .
	bin/tests.lua
clean_cwtest:
	$(RM) $(RMFLAGS) cwtest.lua
CLEAN+= clean_cwtest
