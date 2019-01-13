package.path="vendor/lua/?.lua"
local T = require "u-test"
local exec = require"exec"
do
  local cfg = exec.ctx"bin/cfg"
  local a, b = cfg"tests/configi-basic-script.lua"
  T["Configi: Test if PID (number) is returned"] = function()
    T.is_number(a)
  end
  T["Configi: Test for expected STDOUT output"] = function()
    T.is_number(string.find(b.stdout[1], "[REPAIRED] file.directory \"/tmp/xxx\"", 1, true))
  end
  os.execute("rmdir /tmp/xxx")
end
do
  local cfg = exec.ctx"bin/cfg"
  local a, b = cfg("-v", "tests/configi-basic-script.lua")
  T["Configi: Test for expected STDOUT output (flag -v)"] = function()
    T.is_not_nil(string.find(b.stdout[1], "Start Configi run...", 1, true))
    T.is_not_nil(string.find(b.stdout[2], "[REPAIRED] file.directory \"/tmp/xxx\"", 1, true))
    T.is_not_nil(string.find(b.stdout[3], "Finished run", 1, true))
  end
  os.execute("rmdir /tmp/xxx")
end
T.summary()
