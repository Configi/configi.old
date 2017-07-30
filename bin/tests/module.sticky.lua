_ENV = require"bin/tests/ENV"
function set(p)
  local r, t
  T.sticky["set policy"] = function()
    r, t = cfg("-m", "-f", p)
    T.equal(r, 0)
  end
  T.sticky["set pass"] = function()
    T.equal(PASS(t), 1)
  end
end
set("test/sticky_set.lua")
function check(p)
  local r, t
  file.mkdir("test/tmp/sticky_set")
  cmd.chmod("0777", "test/tmp/sticky_set")
  T.sticky["set policy check"] = function()
    r, t = cfg("-m", "-f", p)
    T.equal(r, 0)
  end
  T.sticky["set check"] = function()
    T.equal(OK(t), 1)
  end
  os.remove("test/tmp/sticky_set")
end
check("test/sticky_set.lua")
T.summary()
