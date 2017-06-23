_ENV = require "bin/tests/ENV"
function test(p1, p2)
  local r, o
  T.policy = function()
    r, o = cfg{"-m", "-f", p1}
  end
  T.ordering = function()
    T.is_not_nil(string.find(o.stderr[1], "%C+%c%C+%c%C+%c#1st"))
    T.is_not_nil(string.find(o.stderr[2], "%C+%c%C+%c%C+%c#2nd"))
    T.is_not_nil(string.find(o.stderr[3], "%C+%c%C+%c%C+%c#2nd"))
    T.is_not_nil(string.find(o.stderr[4], "%C+%c%C+%c%C+%c#3rd"))
    T.is_not_nil(string.find(o.stderr[5], "%C+%c%C+%c%C+%c#3rd"))
    T.is_not_nil(string.find(o.stderr[6], "%C+%c%C+%c%C+%c#4th"))
    T.is_not_nil(string.find(o.stderr[7], "%C+%c%C+%c%C+%c#4th"))
    T.is_not_nil(string.find(o.stderr[8], "%C+%c%C+%c%C+%c#nodeps"))
    T.is_not_nil(string.find(o.stderr[9], "%C+%c%C+%c%C+%c#nodeps"))
    T.is_not_nil(string.find(o.stderr[10], "%C+%c%C+%c%C+%c#delete%-nodeps"))
    T.is_not_nil(string.find(o.stderr[11], "%C+%c%C+%c%C+%c#delete%-nodeps"))
    T.is_not_nil(string.find(o.stderr[12], "%C+%c%C+%c%C+%c#last"))
    T.is_not_nil(string.find(o.stderr[13], "%C+%c%C+%c%C+%c#last"))
    T.is_not_nil(string.find(o.stderr[14], "%C+%c%C+%c%C+%c#delete%-last"))
    T.is_not_nil(string.find(o.stderr[15], "%C+%c%C+%c%C+%c#delete%-last"))
    os.remove(dir.."core-require-first")
    os.remove(dir.."core-require-another")
    os.remove(dir.."core-require")
  end
  T.policy = function()
    r, o = cfg{"-m", "-f", p2}
  end
  T.nodeps = function()
    T.is_not_nil(string.find(o.stderr[1], "%C+%c%C+%c%C+%c#nodeps"))
    T.is_not_nil(string.find(o.stderr[2], "%C+%c%C+%c%C+%c#nodeps"))
    T.is_not_nil(string.find(o.stderr[3], "%C+%c%C+%c%C+%c#2nd"))
    T.is_not_nil(string.find(o.stderr[4], "%C+%c%C+%c%C+%c#2nd"))
    T.is_not_nil(string.find(o.stderr[5], "%C+%c%C+%c%C+%c#3rd"))
    T.is_not_nil(string.find(o.stderr[6], "%C+%c%C+%c%C+%c#3rd"))
    T.is_not_nil(string.find(o.stderr[7], "%C+%c%C+%c%C+%c#4th"))
    T.is_not_nil(string.find(o.stderr[8], "%C+%c%C+%c%C+%c#4th"))
    os.remove(dir.."core-require-nodeps")
    os.remove(dir.."core-require-last")
  end
end
test("test/core-require.lua",
  "test/core-require-nodeps.lua")
