_ENV = require "bin/tests/ENV"
function present(p)
  T.policy = function()
    T.equal(cfg("-f", p), 0)
  end
  T.present = function()
    T.is_not_nil(os.is_file("/sbin/mtr"))
  end
end
present("test/yum_present.lua")
function absent(p)
  T.policy = function()
    T.equal(cfg("-f", p), 0)
  end
  T.absent = function()
    T.is_nil(os.is_file("/sbin/mtr"))
  end
end
absent("test/yum_absent.lua")
function add_repo(p)
  T.policy = function()
    T.equal(cfg("-f", p), 0)
  end
  T.added = function()
    T.is_not_nil(os.is_file("/etc/yum.repos.d/OpenResty.repo"))
    os.remove("/etc/yum.repos.d/OpenResty.repo")
  end
end
add_repo("test/yum_add_repo.lua")
function groups(p)
  T.policy = function()
    T.equal(cfg("-f", p), 0)
  end
end
groups("test/yum_groups.lua")
T.summary()
