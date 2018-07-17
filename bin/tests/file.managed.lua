local U = require "u-test"
local T = {}
local file = require "cfg-modules.file"
local lib = require "lib"
local F = lib.file
local os = lib.os
_ENV = nil
local f = "tmp/____configi_test"
file.managed("____configi_test")
U["file.managed"] = function()
  U.equal(f, os.is_file(f))
  U.equal(F.read_all(f), "Contents of the file \"tmp/____configi_test\"\n")
end
os.execute("rm -f tmp/____configi_test")
return T
