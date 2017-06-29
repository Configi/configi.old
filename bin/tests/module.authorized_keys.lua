_ENV = require "bin/tests/ENV"
function present(p)
  local r, t
  T.authorized_keys["present policy"] = function()
    r, t = cfg("-m", "-f", p)
    T.equal(r, 0)
  end
  T.authorized_keys["present ok"] = function()
    T.is_not_nil(OK(t))
  end
end
present("test/authorized_keys_present.lua")
function absent(p)
  local r, t
  T.authorized_keys["absent policy"] = function()
    r, t = cfg("-m", "-f", p)
    T.equal(r, 0)
  end
  T.authorized_keys["absent ok"] = function()
    T.is_not_nil(OK(t))
  end
  r, t = cfg("-m", "-f", p)
  T.authorized_keys["absent pass"] = function()
    T.is_not_nil(PASS(t))
  end
end
absent("test/authorized_keys_absent.lua")

