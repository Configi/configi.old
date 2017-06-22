local E = {}
E.T = require "u-test"
E.dofile = dofile
E.ipairs = ipairs
E.os = os
E.table = table
E.string = string
E.stat = require "posix.sys.stat"
E.lib = require "lib"
E.file = E.lib.file
E.cfg = E.lib.exec.cmd["bin/cfg-agent.lua"]
E.dir = "test/tmp/"
return E
