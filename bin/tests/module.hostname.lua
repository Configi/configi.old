_ENV = require "bin/tests/ENV"
function test(p)
  if path.bin "hostnamectl" then
    local current_hostnames = function()
      local _, hostnamectl = cmd.hostnamectl{}
      local hostnames = {
        Pretty = false,
        Static = false,
        Transient = false
      }
      local _k, _v
      for ln = 1, #hostnamectl.stdout do
        for type, _ in pairs(hostnames) do
          _k, _v = string.match(hostnamectl.stdout[ln], "^%s*(" .. type .. " hostname):%s([%g%s]*)$")
          if _k then
            -- New keys that starts with lower case characters.
            hostnames[string.lower(type)] = _v
          end
        end
      end
      return hostnames
    end
    local hostnames = current_hostnames()
    local before = {
      transient = hostnames.transient,
      pretty = hostnames.pretty,
      static = hostnames.static
    }
    T.hostname["set policy"] = function()
      T.equal(cfg("-F", "-f", p), 0)
    end
    T.hostname["set check"] = function()
      local after = current_hostnames()
      T.equal(after.transient, "testing.configi.org")
      T.equal(after.pretty, "Testing Configi")
      T.equal(after.static, "static")
      for type, hostname in pairs(before) do
        cmd.hostnamectl("--"..type, "set-hostname", hostname)
      end
    end
  else
    local _, t = cmd.hostname()
    local before = t.stdout[1]
    T.policy = function()
      T.equal(cfg("-f", p), 0)
    end
    T.set = function()
      _, t = cmd.hostname()
      T.equal(t.stdout[1], "testing")
      T.equal(cmd.hostname(before), 0)
      _, t = cmd.hostname()
      T.equal(t.stdout[1], before)
    end
  end
end
test("test/hostname_set.lua")
T.summary()
