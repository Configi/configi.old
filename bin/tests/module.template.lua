_ENV = require "bin/tests/ENV"
function test(p)
  T.policy = function()
    T.equal(cfg("-f", p), 0)
  end
  T.functionality = function()
    local o = dir.."template_render_test.txt"
    T.equal(crc32(file.read_to_string("test/template_render.txt")), crc32(file.read_to_string(o)))
    os.remove(o)
  end
end
test("test/template_render.lua")
T.summary()
