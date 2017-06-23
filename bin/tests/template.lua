_ENV = require "bin/tests/ENV"
function test(p)
  T.policy = function()
    T.equal(cfg("-f", p), 0)
  end
  T.functionality = function()
    T.equal(cmd.rm("-f", dir.."FILE-1.0"), 0)
  end
end
test "test/core-template.lua"
