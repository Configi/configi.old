_ENV = require "bin/tests/ENV"
if not path.bin "yum" then
  T.yum.skip = true
end
function present(p)
  T.yum["present policy"] = function()
    T.equal(cfg("-f", p), 0)
  end
  T.yum["present check"] = function()
    T.is_not_nil(os.is_file("/sbin/mtr"))
  end
end
present("test/yum_present.lua")
function absent(p)
  T.yum["absent policy"] = function()
    T.equal(cfg("-f", p), 0)
  end
  T.yum["absent check"] = function()
    T.is_nil(os.is_file("/sbin/mtr"))
  end
end
absent("test/yum_absent.lua")
function add_repo(p)
  T.yum["add_repo policy"] = function()
    T.equal(cfg("-f", p), 0)
  end
  T.yum["add_repo check"] = function()
    T.is_not_nil(os.is_file("/etc/yum.repos.d/OpenResty.repo"))
    os.remove("/etc/yum.repos.d/OpenResty.repo")
  end
end
add_repo("test/yum_add_repo.lua")
function groups(p)
  T.yum["groups policy"] = function()
    T.equal(cfg("-f", p), 0)
  end
end
groups("test/yum_groups.lua")
T.summary()
