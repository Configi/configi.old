.PHONY: test clean_u-test
u-test.lua:
	$(ECHOT) CP u-test.lua
	$(CP) vendor/lua/u-test.lua .
test/core-fact/httpd:
	$(ECHOT) CC $@
	$(CC) -o $@ -Ilib test/core-fact/httpd.c
	test/core-fact/httpd &
test: development u-test.lua test/core-fact/httpd
	$(ECHOT) RUN tests
	bin/tests.lua
clean_u-test:
	$(RM) $(RMFLAGS) u-test.lua
CLEAN+= clean_u-test
