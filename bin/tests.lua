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
  "module.git",
  "module.unarchive",
  "module.iptables",
  "module.make",
  "module.process",
  "module.mount",
  "module.portage",
  "module.apt",
  "module.ppa",
  "module.sticky",
  "module.port",
}
T["Configi Tests"] = function()
  for _, t in ipairs(tests) do
    T[t] = function()
      T.equal(cmd["bin/lua"]("bin/tests/"..t..".lua"), 0)
    end
  end
end
T.summary()
