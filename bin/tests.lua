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
  "module.hostname",
  "module.cron",
  "module.template",
  "module.edit",
  "module.shell",
  "module.yum",
  "module.user",
  "module.hash",
  "module.systemd",
  "module.file",
  "module.authorized_keys",
}
function T.Configi()
  for _, t in ipairs(tests) do
    T[t] = function()
      T.equal(cmd["bin/lua"]("bin/tests/"..t..".lua"), 0)
    end
  end
end
T.summary()
