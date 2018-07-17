local OK, SKIP = "REPAIR", "PASS"
local U = require"u-test"
local lib = require"lib"
local file, os, exec, table = lib.file, lib.os, lib.exec, lib.table
local rmdir = exec.ctx"rmdir"
local rm = exec.ctx"rm"
local T = function(t)
  return exec.popen("bin/lua " .. "bin/tests/" .. t .. ".lua")
end
local r, t
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
U["exec.simple"] = function()
  local a = "tmp/touch"
  U["- run"] = function()
    r, t = T"exec.simple"
    U.equal(0, r)
  end
  U["- if executed"] = function()
    U.is_true(table.find(t.output, OK))
    U.equal(a, os.is_file(a))
  end
  U["- expected file exists"] = function()
    r, t = T"exec.simple"
    U.equal(0, r)
    U.is_true(table.find(t.output, SKIP))
  end
  U["- tear down"] = function()
    U.equal(0, rm(a))
  end
end
U["file.managed"] = function()
  local f = "tmp/____configi_test"
  U[" - run"] = function()
    r, t = T"file.managed"
    U.equal(0, r)
  end
  U[" - plain"] = function()
    U.is_true(table.find(t.output, OK))
    U.equal(f, os.is_file(f))
    U.equal(file.read_all(f), "Contents of the file \"tmp/____configi_test\"\n")
  end
  U[" - tear down"] = function()
    U.equal(0, rm("-f", f))
  end
end
os.execute "rmdir tmp"
U.summary()
