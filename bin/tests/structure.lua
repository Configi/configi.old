_ENV = require "bin/tests/ENV"
function test(p)
  T.policy = function()
    T.equal(cfg{"-f", p}, 0)
  end
  T.attributes = function()
    T.is_not_nil(stat.stat(dir.."core-structure-attributes"))
    os.remove(dir.."core-structure-attributes")
  end
  T.includes = function()
    T.is_not_nil(stat.stat(dir.."core-structure-policies"))
    os.remove(dir.."core-structure-policies")
  end
  T.handlers = function()
    T.is_not_nil(stat.stat(dir.."core-structure-handlers"))
    os.remove(dir.."core-structure-handlers")
  end
  T.files = function()
    T.is_not_nil(stat.stat(dir.."copied-under-files"))
    os.remove(dir.."copied-under-files")
  end
  T.templates = function()
    T.is_not_nil(stat.stat(dir.."template_render_test.txt"))
    local t = file.read_to_string(dir.."template_render_test.txt")
    local m1, m2 = string.match(t, "^(Joe spends 6)\n(\n)")
    T.equal(m1, "Joe spends 6")
    T.equal(m2, "\n")
    os.remove(dir.."template_render_test.txt")
  end
  T["roles files"] = function()
    T.is_not_nil(stat.stat(dir.."core-structure-role-copy"))
    T.is_not_nil(stat.stat(dir.."core-structure-override-role-copy"))
    t = file.read_to_string(dir.."core-structure-override-role-copy")
    m1 = string.match(t, "^(1)")
    T.equal(m1, "1")
    os.remove(dir.."core-structure-role-copy")
    os.remove(dir.."core-structure-override-role-copy")
  end
  T["roles template"] = function()
    T.is_not_nil(stat.stat(dir.."core-structure-role-template"))
    t = file.read_to_string(dir.."core-structure-role-template")
    m1 = string.match(t, "^(Joe spends 6)")
    T.equal(m1, "Joe spends 6")
    T.is_not_nil(stat.stat(dir.."core-structure-override-role-template"))
    t = file.read_to_string(dir.."core-structure-override-role-template")
    m1 = string.match(t, "^(1 Joe spends 6)")
    T.equal(m1, "1 Joe spends 6")
    os.remove(dir.."core-structure-role-template")
    os.remove(dir.."core-structure-override-role-template")
  end
end
test "test/core-structure/test.lua"
T.summary()
