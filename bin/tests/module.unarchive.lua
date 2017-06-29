_ENV = require "bin/tests/ENV"
function unpack(p)
  local r, t
  T.unarchive["unpack policy"] = function()
    r, t = cfg("-m", "-f", p)
    T.equal(r, 0)
  end
  T.unarchive["unpack ok"] = function()
    T.is_not_nil(OK(t))
  end
  T.unarchive["unpack check"] = function()
    local f = dir.."unarchive_unpack.lua"
    T.is_not_nil(stat.stat(f))
    os.remove(f)
  end
end
unpack("test/unarchive_unpack.lua")
