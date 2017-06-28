_ENV = require "bin/tests/ENV"
function test(p)
  local f = dir.."_test_configi.log"
  T.policy = function()
    T.equal(cfg{"-ltest/tmp/_test_configi.log", "-f", p}, 0)
  end
  T.functionality = function()
    T.is_not_nil(stat.stat(f))
    os.remove(f)
  end
end
test "test/core-log.lua"
T.summary()
