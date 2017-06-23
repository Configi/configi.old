_ENV = require "bin/tests/ENV"
function test(p)
  T.policy = function()
    T.equal(cfg("-f", p), 0)
  end
  T.functionality = function()
    T.is_not_nil(stat.stat(dir.."core-user-modules"))
    os.remove(dir.."core-user-modules")
  end
end
test "test/core-user-modules/test.lua"
