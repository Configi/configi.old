package.path="vendor/lua/?.lua"
local T = require "u-test"
local exec = require"exec"
do
  local cfg = exec.ctx"bin/cfg"
  local a, b = cfg"tests/configi-basic-script.lua"
  T["Configi: Test if PID (number) is returned"] = function()
    T.is_number(a)
  end
  os.execute("rmdir /tmp/xxx")
end
do
  local cfg = exec.ctx"bin/cfg"
  local a, b = cfg("-v", "tests/configi-basic-script.lua")
  T["Configi: Test for expected STDOUT output (flag -v)"] = function()
    T.is_not_nil(string.find(b.stdout[1], "Start Configi run...", 1, true))
    T.is_not_nil(string.find(b.stdout[2], "-- Testing basic functionality...", 1, true))
    T.is_not_nil(string.find(b.stdout[3], "[REPAIRED] file.directory \"/tmp/xxx\"", 1, true))
    T.is_not_nil(string.find(b.stdout[6], "Finished run", 1, true))
  end
  os.execute("rmdir /tmp/xxx")
  os.execute("rmdir /tmp/yyy")
end
do
  local cfg = exec.ctx"bin/cfg"
  local a, b = cfg("-v", "-t", "tests/configi-basic-script.lua")
  T["Configi: Test for expected STDOUT output (flag -t)"] = function()
    T.is_not_nil(string.find(b.stdout[1], "Start Configi run...", 1, true))
    T.is_not_nil(string.find(b.stdout[2], "-- Testing basic functionality...", 1, true))
    T.is_not_nil(string.find(b.stdout[3], "[REPAIRED] file.directory \"/tmp/xxx\"", 1, true))
    T.is_not_nil(string.find(b.stdout[4], "-- AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA...", 1, true))
    T.is_not_nil(string.find(b.stdout[5], "[REPAIRED] file.directory \"/tmp/yyy\"", 1, true))
    T.is_not_nil(string.find(b.stdout[6], "Finished run", 1, true))
  end
  os.execute("rmdir /tmp/xxx")
  os.execute("rmdir /tmp/yyy")
end
T.summary()
