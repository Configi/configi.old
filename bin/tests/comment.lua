_ENV = require "bin/tests/ENV"
function test(p)
  local r, o
  T.policy = function()
    r, o = cfg{"-v", "-f", p}
    T.equal(r, 0)
    o = table.concat(o.stderr, "\n")
  end
  T.functionality = function()
    T.equal(string.find(o, "TEST COMMENT", 1, true), 51)
  end
end
test "test/core-comment.lua"
