local C = require("configi")
local type, tostring, pairs = type, tostring, pairs
local S = { }
_ENV = nil
local test_fail
test_fail = function(t)
  return function(p)
    C["test.test_fail :: " .. tostring(t)] = function()
      C.equal(0, 1, "Did not match")
      C.print("prints someting")
      if p then
        return C.pass
      end
    end
  end
end
local test
test = function(t)
  return function(p)
    C["test.test :: " .. tostring(t)] = function()
      C.equal(0, 0, "Did not match")
      C.print("prints someting")
      if p then
        return C.pass
      end
    end
  end
end
local register_table
register_table = function(t)
  return function(p)
    C["test.register_table :: " .. tostring(t)] = function()
      C.equal(0, 0, "Did not match")
      for k, v in pairs(p.register) do
        C.register(k, v)
      end
    end
  end
end
local register_value
register_value = function(t)
  return function(p)
    C["test.register_value :: " .. tostring(t)] = function()
      C.equal(0, 0, "Did not match")
      return C.register(p.register, "value")
    end
  end
end
S["test"] = test
S["test_fail"] = test_fail
S["register_table"] = register_table
S["register_value"] = register_value
return S
