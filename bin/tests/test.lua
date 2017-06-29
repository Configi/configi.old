_ENV = require "bin/tests/ENV"
function test(p)
  local temp = dir.."core-test.txt"
  file.write(temp, "test")
  T.core["test policy"] = function()
    T.equal(cfg{"-t", "-f", p}, 0)
  end
  T.core["test check"] = function()
    T.equal(file.read(temp), "test")
    os.remove(temp)
  end
end
test "test/core-test.lua"
T.summary()
