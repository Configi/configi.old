_ENV = require "bin/tests/ENV"
function present(p)
  local r, t
  T.user["present policy"] = function()
    r, t = cfg("-m", "-f", p)
    T.equal(r, 0)
  end
  T.user["present check"] = function()
    T.is_not_nil(OK(t))
    r, t = cfg("-m", "-f", p)
    T.is_not_nil(PASS(t))
  end
end
present("test/user_present.lua")
function absent(p)
  local r, t
  T.policy = function()
    r, t = cfg("-m", "-f", p)
    T.equal(r, 0)
  end
  T.absent = function()
    T.is_not_nil(OK(t))
    r, t = cfg("-m", "-f", p)
    T.is_not_nil(PASS(t))
  end
end
absent("test/user_absent.lua")
T.summary()
