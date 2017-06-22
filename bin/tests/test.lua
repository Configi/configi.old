_ENV = require "bin/tests/ENV"
function test(p)
  local temp = dir.."core-test.txt"
  file.write_all(temp, "test")
  T.policy = function()
    T.equal(cfg{"-t", "-f", p}, 0)
  end
  T.functionality = function()
    T.equal(file.read_to_string(temp), "test")
    os.remove(temp)
  end
end
test "test/core-test.lua"
