_ENV = require "bin/tests/ENV"
function present(p)
  local r, t
  T.policy = function()
    r, t = cfg("-m", "-f", p)
    T.equal(r, 0)
  end
  T.present = function()
    T.is_not_nil(string.find(t.stderr[1], ".+%[ OK %].*"))
    r, t = cfg("-m", "-f", p)
    T.is_not_nil(string.find(t.stderr[1], ".+%[PASS%].*"))
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
    T.is_not_nil(string.find(t.stderr[1], ".+%[ OK %].*"))
    r, t = cfg("-m", "-f", p)
    T.is_not_nil(string.find(t.stderr[1], ".+%[PASS%].*"))
  end
end
absent("test/user_absent.lua")
T.summary()
