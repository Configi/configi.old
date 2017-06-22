_ENV = require "bin/tests/ENV"
function test(p)
  T.policy = function()
    T.equal(cfg{"-f", p}, 0)
  end
  T.functionality = function()
    T.is_nil(stat.stat(dir.."core-context"))
    T.is_not_nil(stat.stat(dir.."core-context-true"))
    os.remove(dir.."core-context-true")
  end
end
test "test/core-context.lua"
