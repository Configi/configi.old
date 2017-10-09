_ENV = require "bin/tests/ENV"
if not path.bin("systemctl") then
  T.systemd.skip = true
end
function started(p)
  local r, t
  T.systemd["started policy"] = function()
    r, t = cfg("-m", "-f", p)
    T.equal(r, 0)
  end
  T.systemd["started ok"] = function()
    T.is_not_nil(string.find(t.stderr[1], ".+%[%sOK%s%].*"))
  end
end
started("test/systemd_started.lua")
function restarted(p)
  local r, t, o, pgrep
  local o, pgrep = cmd.pgrep("nscd")
  local first = pgrep.stdout[1]
  T.systemd["restarted policy"] = function()
    r, t = cfg("-m", "-f", p)
    T.equal(r, 0)
  end
  T.systemd["restarted ok"] = function()
    T.is_not_nil(string.find(t.stderr[1], ".+%[%sOK%s%].*"))
  end
  T.systemd["restarted check"] = function()
    o, pgrep = cmd.pgrep("nscd")
    local second = pgrep.stdout[1]
    if first == second then
      o = nil
    end
    T.equal(o, 0)
  end
end
restarted("test/systemd_restart.lua")
if not factid.osfamily()[1] == "debian" then
  function reloaded(p)
    local r, t
    T.systemd["reloaded policy"] = function()
      r, t = cfg("-m", "-f", p)
      T.equal(r, 0)
    end
    T.systemd["reloaded ok"] = function()
      T.is_not_nil(string.find(t.stderr[1], ".+%[%sOK%s%].*"))
    end
  end
  reloaded("test/systemd_reload.lua")
end
function stopped(p)
  local r, t
  T.systemd["stopped policy"] = function()
    r, t = cfg("-m", "-f", p)
    T.equal(r, 0)
  end
  T.systemd["stopped ok"] = function()
    T.is_not_nil(string.find(t.stderr[1], ".+%[%sOK%s%].*"))
  end
  T.systemd["stopped check"] = function()
    T.is_nil(cmd.pgrep("nscd"))
  end
end
stopped("test/systemd_stopped.lua")
function enabled(p)
  local r, t
  T.systemd["enabled policy"] = function()
    r, t = cfg("-m", "-f", p)
    T.equal(r, 0)
  end
  T.systemd["enabled ok"] = function()
    T.is_not_nil(string.find(t.stderr[1], ".+%[%sOK%s%].*"))
  end
end
enabled("test/systemd_enabled.lua")
function disabled(p)
  local r, t
  T.systemd["disabled policy"] = function()
    r, t = cfg("-m", "-f", p)
    T.equal(r, 0)
  end
  T.systemd["disabled ok"] = function()
    T.is_not_nil(string.find(t.stderr[1], ".+%[%sOK%s%].*"))
  end
end
disabled("test/systemd_disabled.lua")
T.summary()

