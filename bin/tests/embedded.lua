_ENV = require "bin/tests/ENV"
function test(p)
  local r, o
  T.core["embedded policy"] = function()
    r, o = cfg("-x", "-m", "-e", p)
    T.equal(r, 0)
  end
  T.core["embedded check ordering"] = function()
    T.is_not_nil(string.find(o.stderr[1], "[%g%s^#]+"))
    T.is_not_nil(string.find(o.stderr[2], "[%g%s^#]+"))
    T.is_not_nil(string.find(o.stderr[3], "[%g%s^#]+"))
    T.is_not_nil(string.find(o.stderr[4], "[%g%s^#]+"))
    T.is_not_nil(string.find(o.stderr[5], "[%g%s^#]+#test includes"))
    T.is_not_nil(string.find(o.stderr[6], "[%g%s^#]+#test includes"))
    T.is_not_nil(string.find(o.stderr[7], "[%g%s^#]+#test handlers"))
    T.is_not_nil(string.find(o.stderr[8], "[%g%s^#]+#test handlers"))
  end
  T.core["embedded check structure"] = function()
    T.is_not_nil(stat.stat(dir.."core-embedded-structure"))
  end
  T.core["embedded check handlers"] = function()
    T.is_not_nil(stat.stat(dir.."core-embedded-handlers"))
  end
  T.core["embedded check"] = function()
    T.is_not_nil(stat.stat(dir.."core-embedded.txt"))
    local st = stat.stat(dir.."core-embedded.txt")
    T.equal(util.octal(st.st_mode), 100777)
    os.remove(dir.."core-embedded-structure")
    os.remove(dir.."core-embedded-handlers")
    os.remove(dir.."core-embedded.txt")
  end
end
test "init.lua"
T.summary()
