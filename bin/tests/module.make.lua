_ENV = require "bin/tests/ENV"
function install(p)
  local r, t
  T.make["install policy"] = function()
    r, t = cfg("-m", "-f", p)
    T.equal(r, 0)
  end
  T.make["install check"] = function()
    T.is_not_nil(stat.stat(dir.."root/bin/exe"))
  end
  cmd.rm("-r", "-f", "test/tmp/root")
  cmd.rm("-r", "-f", "test/tmp/make_install")
end
install("test/make_install.lua")
T.summary()
