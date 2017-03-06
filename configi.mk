.PHONY: test clean_cwtest
cwtest.lua:
	$(ECHOT) CP cwtest
	$(CP) vendor/lua/cwtest.lua .
test: dev cwtest.lua
	$(ECHOT) RUN tests
	bin/tests.lua
clean_cwtest:
	$(RM) $(RMFLAGS) cwtest.lua
CLEAN+= clean_cwtest
