_ENV = require "bin/tests/ENV"
function test(p)
  cmd.mkdir("-p", dir.."core-each.xxx")
  cmd.mkdir("-p", dir.."core-each.yyy")
  T.policy = function()
    T.equal(cfg("-f", p), 0)
  end
  T.functionality = function()
    T.is_nil(stat.stat(dir.."core-each.xxx"))
    T.is_nil(stat.stat(dir.."core-each.yyy"))
  end
end
test "test/core-each.lua"
T.summary()
