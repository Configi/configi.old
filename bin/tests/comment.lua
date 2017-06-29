_ENV = require "bin/tests/ENV"
function test(p)
  local r, t
  T.core["comment policy"] = function()
    r, t = cfg("-v", "-f", p)
    T.equal(r, 0)
  end
  T.core["comment check"] = function()
    t = table.concat(t.stderr, "\n")
    T.equal(string.find(t, "TEST COMMENT", 1, true), 51)
  end
end
test "test/core-comment.lua"
T.summary()
