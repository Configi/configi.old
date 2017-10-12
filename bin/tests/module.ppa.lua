_ENV = require "bin/tests/ENV"
local osfamily = require"factid".osfamily()
if not osfamily[1] == "ubuntu" then
  T.ppa.skip = true
end
function present(p)
  T.ppa["present policy"] = function()
    T.equal(cfg("-f", p), 0)
  end
  T.ppa["present check"] = function()
    T.is_not_nil(stat.stat("/etc/apt/sources.list.d/stefansundin-ubuntu-truecrypt-xenial.list"))
    T.is_not_nil(stat.stat("/etc/apt/trusted.gpg.d/stefansundin_ubuntu_truecrypt.gpg"))
  end
end
present("test/ppa_present.lua")
function absent(p)
  T.ppa["absent policy"] = function()
    T.equal(cfg("-f", p), 0)
  end
  T.ppa["absent check"] = function()
    T.is_nil(stat.stat("/etc/apt/sources.list.d/stefansundin-ubuntu-truecrypt-xenial.list"))
    T.is_nil(stat.stat("/etc/apt/trusted.gpg.d/stefansundin_ubuntu_truecrypt.gpg"))
  end
end
absent("test/ppa_absent.lua")
