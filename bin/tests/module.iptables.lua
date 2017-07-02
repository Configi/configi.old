_ENV = require "bin/tests/ENV"
function append(p)
  local r, t
  T.iptables["append policy"] = function()
    r, t = cfg("-m", "-f", p)
    T.equal(r, 0)
  end
  T.iptables["append check"] = function()
    local s =
      [[-A INPUT -s 6.6.6.6/32 -p tcp -m tcp --sport 31337 --dport 31337 -m comment --comment "\'Configi\'" -j ACCEPT]]
    r, t = cmd.iptables("--list-rules")
    T.equal(r, 0)
    T.is_number(string.find(t.stdout[4], s, 1, true))
    cmd.iptables("-F")
  end
end
append("test/iptables_append.lua")
function disable(p1, p2)
  local r, t
  T.iptables["disable policy + check"] = function()
    r, t = cfg("-m", "-f", p1)
    T.equal(r, 0)
    T.is_not_nil(OK(t))
    r, t = cmd.iptables("--list-rules")
    T.equal(r, 0)
    T.equal(#t.stdout, 4)
    r, t = cfg("-m", "-f", p2)
    T.equal(r, 0)
    T.is_not_nil(OK(t))
    r, t = cmd.iptables("--list-rules")
    T.equal(r, 0)
    T.equal(#t.stdout, 3)
  end
end
disable("test/iptables_append.lua", "test/iptables_disable.lua")
