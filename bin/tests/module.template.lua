_ENV = require "bin/tests/ENV"
function test(p)
  T.template["render policy"] = function()
    T.equal(cfg("-f", p), 0)
  end
  T.template["render check"] = function()
    local o = dir.."template_render_test.txt"
    T.equal(crc32(file.read_all("test/template_render.txt")), crc32(file.read_all(o)))
    os.remove(o)
  end
end
test("test/template_render.lua")
T.summary()
