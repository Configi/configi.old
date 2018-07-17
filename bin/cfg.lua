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
U["file.directory"] = function()
  local a = "tmp/cfg_test__file_directory"
  U["- run"] = function()
    r, t = T"file.directory"
    U.equal(0, r)
  end
  U["- directory created"] = function()
    U.is_true(table.find(t.output, OK))
    U.equal(a, os.is_dir(a))
  end
  U["- if directory exists"] = function()
    r, t = T"file.directory"
    U.is_true(table.find(t.output, SKIP))
  end
  U["- tear down"] = function()
    U.equal(0, rmdir(a))
  end
end
U["file.absent"] = function()
  local a = "tmp/cfg_test__file_absent"
  U["- run"] = function()
    r, t = T"file.absent"
    U.equal(0, r)
  end
  U["- file already absent"] = function()
    U.is_true(table.find(t.output, SKIP))
    U.equal(nil, os.is_file(a))
  end
  U["- removing file"] = function()
    os.execute("touch " .. a)
    r, t = T"file.absent"
    U.equal(0, r)
    U.is_true(table.find(t.output, OK))
  end
end
os.execute "rmdir tmp"
U.summary()
