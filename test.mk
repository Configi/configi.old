.PHONY: test clean_cwtest
cwtest.lua:
	$(ECHOT) CP cwtest.lua
	$(CP) vendor/lua/cwtest.lua .
test/core-fact/httpd:
	$(ECHOT) CC $@
	$(CC) -o $@ -Ilib test/core-fact/httpd.c
	test/core-fact/httpd &
test: development cwtest.lua test/core-fact/httpd
	$(ECHOT) RUN tests
	bin/tests.lua
clean_cwtest:
	$(RM) $(RMFLAGS) cwtest.lua
CLEAN+= clean_cwtest
