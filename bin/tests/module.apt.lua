_ENV = require "bin/tests/ENV"
local osfamily = require"factid".osfamily()
if not osfamily[1] == "debian" then
  T.apt.skip = true
end
function present(p)
  T.apt["present policy"] = function()
    T.equal(cfg("-f", p), 0)
  end
  T.apt["present check"] = function()
    T.is_not_nil(stat.stat("/usr/bin/mtr"))
  end
end
present("test/apt_present.lua")
function absent(p)
  T.apt["absent policy"] = function()
    T.equal(cfg("-f", p), 0)
  end
  T.apt["absent check"] = function()
    T.is_nil(stat.stat("/usr/bin/mtr"))
  end
end
absent("test/apt_absent.lua")
