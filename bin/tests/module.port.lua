_ENV = require"bin/tests/ENV"
function open(p)
  local r, t
  T.port["open policy"] = function()
    r, t = cfg("-m", "-f", p)
    T.equal(r, 0)
  end
  T.port["open pass"] = function()
    T.equal(PASS(t), 1)
  end
end
open("test/port_open.lua")
function refused(p)
  local r, t
  T.port["refused policy"] = function()
    r, t = cfg("-m", "-f", p)
    T.equal(r, 0)
  end
  T.port["refused pass"] = function()
    T.equal(PASS(t), 1)
  end
end
refused("test/port_closed.lua")
T.summary()
