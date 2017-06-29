_ENV = require "bin/tests/ENV"
function test(p)
  local r, t
  T.hash["sha2 policy"] = function()
    r, t = cfg("-m", "-f", p)
    T.equal(r, 0)
  end
  T.hash["sha2 check"] = function()
    T.is_not_nil(PASS(t))
  end
end
test("test/hash_digest.lua")
