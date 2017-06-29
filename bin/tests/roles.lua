_ENV = require "bin/tests/ENV"
function test(p)
  local f = {}
  f = {
    "core-role",
    "core-role-attrib",
    "core-role-attrib-one",
    "core-role-handler",
    "core-role-handler-one",
    "core-role-modules",
    "core-role-modules-one",
    "core-role-one",
    "core-role-policy",
    "core-role-policy-one",
    "core-role-top",
  }
  T.core["roles policy"] = function()
    local r = cfg("-f", p)
    T.equal(r, 0)
  end
  for _, t in ipairs(f) do
    T.core["roles check"] = function()
      T.is_not_nil(stat.stat(dir..t))
      os.remove(dir..t)
    end
  end
end
test "test/core-roles/test.lua"
T.summary()
