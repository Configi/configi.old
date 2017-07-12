_ENV = require "bin/tests/ENV"
local osfamily = require"factid".osfamily()
if not osfamily == "gentoo" then
  T.portage.skip = true
end
function present(p)
  T.portage["present policy"] = function()
    T.equal(cfg("-f", p), 0)
  end
  T.portage["present check"] = function()
    T.is_not_nil(stat.stat("/usr/bin/spc"))
  end
end
present("test/portage_present.lua")
function absent(p)
  T.portage["absent policy"] = function()
    T.equal(cfg("-f", p), 0)
  end
  T.portage["absent check"] = function()
    T.is_nil(stat.stat("/usr/bin/spc"))
  end
end
absent("test/portage_absent.lua")
