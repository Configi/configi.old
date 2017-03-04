.PHONY: test
test: dev
	$(CP) vendor/lua/cwtest.lua .
	bin/tests.lua
clean_cwtest:
	$(RM) cwtest.lua
CLEAN+= clean_cwtest
