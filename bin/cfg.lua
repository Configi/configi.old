local OK, SKIP = "REPAIR", "PASS"
local U = require"u-test"
local lib = require"lib"
local exec, table = lib.exec, lib.table
local rmdir = exec.ctx"rmdir"
local r, t
local T = function(t)
  return exec.popen("bin/lua " .. "bin/tests/" .. t .. ".lua")
end
os.execute "mkdir tmp"
U["file.directory"]= function()
  local a = "tmp/cfg_test__file_directory"
  U["  - run"] = function()
    r, t = T"file.directory"
    U.equal(0, r)
  end
  U["  - output"] = function()
    U.is_true(table.find(t.output, OK))
  end
  U["  - op"] = function()
    U.equal(a, os.is_dir(a))
  end
  U["  - if compliant"] = function()
    r, t = T"file.directory"
    U.is_true(table.find(t.output, SKIP))
  end
  U["  - tear down"] = function()
    U.equal(0, rmdir(a))
  end
end
os.execute "rmdir tmp"
U.summary()
