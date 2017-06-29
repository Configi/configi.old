_ENV = require "bin/tests/ENV"
function test(p1, p2)
  T.core["handler policy"] = function()
    T.equal(cfg("-f", p1), 0)
  end
  local xf = dir.."core-handler2-xfile"
  local f = dir.."core-handler2-file"
  T.core["handler check"] = function()
    T.equal(cfg("-g", "testhandle", "-f", p2), 0)
    T.is_nil(stat.stat(xf))
    T.is_not_nil(stat.stat(f))
  end
  os.remove(f)
end
test("test/core-handler.lua",
  "test/core-handler2.lua")
T.summary()
