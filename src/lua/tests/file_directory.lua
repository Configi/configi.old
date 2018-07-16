local U = require "u-test"
local T = {}
local file = require "cfg-modules.file"
local lib = require "lib"
local os, exec = lib.os, lib.exec
local rmdir = exec.ctx "rmdir"
_ENV = nil
local a = "tmp/cfg_test__file_directory"
file.directory(a)
U["file.directory"] = function()
  U.equal(a, os.is_dir(a))
end
return T
