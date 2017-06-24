local E = {}
E.T = require "u-test"
E.factid = require "factid"
E.dofile = dofile
E.ipairs = ipairs
E.os = os
E.table = table
E.string = string
E.stat = require "posix.sys.stat"
E.lib = require "lib"
E.cmd = E.lib.exec.cmd
E.cfg = E.cmd["bin/cfg-agent.lua"]
E.file = E.lib.file
E.dir = "test/tmp/"
return E
