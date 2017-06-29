_ENV = require "bin/tests/ENV"
function test(p)
  local r, o
  T.core["debug policy"] = function()
    r, o = cfg("-v", "-f", p)
    T.equal(r, 0)
  end
  T.core["debug check"] = function()
    o = table.concat(o.stderr, "\n")
    T.equal(string.find(o, "TESTDEBUG", 1, true), 70)
  end
end
test "test/core-debug.lua"
T.summary()
