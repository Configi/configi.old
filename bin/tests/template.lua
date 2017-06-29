_ENV = require "bin/tests/ENV"
function test(p)
  T.core["template policy"] = function()
    T.equal(cfg("-f", p), 0)
  end
  T.core["template check"] = function()
    T.equal(cmd.rm("-f", dir.."FILE-1.0"), 0)
  end
end
test "test/core-template.lua"
T.summary()
