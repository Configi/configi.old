local U = require "u-test"
local T = {}
local file = require "cfg-modules.file"
local lib = require "lib"
local os, exec = lib.os, lib.exec
local touch = exec.ctx "touch"
_ENV = nil
local a = "tmp/cfg_test__file_absent"
touch(a)
file.absent(a)
U["file.absent"] = function()
  U.equal(nil, os.is_file(a))
end
return T
