package.path="vendor/lua/?.lua"
local T = require "u-test"
do
  local lua = dofile("tests/lua-script.lua")
  T["Sequence"] = function()
    T.equal(lua.sequence(), "12345")
  end
  T["ipairs()"] = function()
    T.equal(lua.ipairsnil(), "123")
  end
  T["For loop"] = function()
    T.equal(lua.forloopnil(), "123")
  end
  T["next()"] = function()
    T.equal(lua.nextsequence(), "1235")
  end
  T["Multiple return"] = function()
    T.equal(lua.multiplereturn(), "145")
  end
  T["Update table 1"] = function()
    T.equal(lua.updatetable1(), "12345")
  end
  T["Update table 2"] = function()
    T.equal(lua.updatetable2(), "12345")
  end
  T["Mixed table 1"] = function()
    T.equal(lua.mixedtable1(), "012")
  end
  T["Mixed table 2"] = function()
    T.equal(lua.mixedtable2(), "123")
  end
end

