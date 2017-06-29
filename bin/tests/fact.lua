_ENV = require "bin/tests/ENV"
function test(p)
  local r, o
  T.core["fact policy"] = function()
    r, o = cfg("-f", p)
    T.equal(r, 0)
  end
  T.core["fact check"] = function()
    T.is_not_nil(stat.stat(dir.."i-deadbeef"))
    os.remove(dir.."i-deadbeef")
  end
end
test "test/core-fact.lua"
T.summary()
