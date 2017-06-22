_ENV = require "bin/tests/ENV"
function test(p)
  local r, o = cfg{"-f", p}
  T.policy = function()
    T.equal(r, 0)
  end
  T.functionality = function()
    T.is_not_nil(stat.stat(dir.."i-deadbeef"))
    os.remove(dir.."i-deadbeef")
  end
end
test "test/core-fact.lua"
