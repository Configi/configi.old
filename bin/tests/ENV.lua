local E = {}
E.T = require "u-test"
E.factid = require "factid"
E.dofile = dofile
E.ipairs = ipairs
E.pairs = pairs
E.require = require
E.os = os
E.table = table
E.string = string
E.stat = require "posix.sys.stat"
E.lib = require "lib"
E.crc32 = require "plc.checksum".crc32
E.cmd = E.lib.exec.cmd
E.cfg = E.cmd["bin/cfg-agent.lua"]
E.file = E.lib.file
E.path = E.lib.path
E.util = E.lib.util
E.OK = function(t)
  return string.find(t.stderr[1], ".+%[%sOK%s%].*")
end
E.PASS = function(t)
  return string.find(t.stderr[1], ".+%[PASS%].*")
end
E.dir = "test/tmp/"
return E
