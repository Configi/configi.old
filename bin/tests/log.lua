_ENV = require "bin/tests/ENV"
function test(p)
  local f = dir.."_test_configi.log"
  T.core["log policy"] = function()
    T.equal(cfg("-l", "test/tmp/_test_configi.log", "-f", p), 0)
  end
  T.core["log check"] = function()
    T.is_not_nil(stat.stat(f))
    os.remove(f)
  end
end
test "test/core-log.lua"
T.summary()
