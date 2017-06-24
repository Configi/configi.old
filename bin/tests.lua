#!bin/lua
local T = require "u-test"
local L = require "lib"
local cmd = L.exec.cmd
local tests = {
  "lua",
  "embedded",
  "roles",
  "structure",
  "log",
  "fact",
  "test",
  "context",
  "comment",
  "require",
  "user-modules",
  "template",
  "each",
}
for _, t in ipairs(tests) do
  T[t] = function()
    T.equal(cmd["bin/lua"]("bin/tests/"..t..".lua"), 0)
  end
end
T.summary()
