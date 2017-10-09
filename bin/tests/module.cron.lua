_ENV = require "bin/tests/ENV"
local osfamily = require"factid".osfamily()
function test(p1, p2)
  if osfamily[1] == "openwrt" then
    cmd.touch("/etc/crontabs/root")
  end
  cmd.crontab("-r")
  cmd.crontab("-d")
  T.cron["present policy"] = function()
    T.equal(cfg("-f", p1), 0)
  end
  local _, o = cmd.crontab("-l")
  local t = table.filter(o.stdout, "^#[%C]+") -- Remove comments
  t[#t] = t[#t].."\n"
  T.cron["present check"] = function()
    T.equal(crc32(file.read_to_string("test/cron_present.out")), crc32(table.concat(t, "\n")))
  end
  T.cron["absent policy"] = function()
    T.equal(cfg("-f", p2), 0)
  end
  _, o = cmd.crontab("-l")
  t = table.filter(o.stdout, "^#[%C]+") -- Remove comments
  t[#t] = t[#t].."\n"
  T.cron["absent check"] = function()
    T.equal(crc32(file.read_to_string("test/cron_absent.out")), crc32(table.concat(t, "\n")))
  end
  cmd.crontab("-r")
  cmd.crontab("-d")
end
test("test/cron_present.lua", "test/cron_absent.lua")
T.summary()

