_ENV = require "bin/tests/ENV"
function clone(p)
  local r, t
  T.git["clone policy"] = function()
    r, t = cfg("-m", "-f", p)
    T.equal(r, 0)
  end
  T.git["clone ok"] = function()
    T.is_not_nil(OK(t))
  end
  T.git["clone check"] = function()
    T.is_not_nil(stat.stat(dir.."git/.git/config"))
  end
end
clone("test/git_clone.lua")
function pull(p)
  local r, t
  T.git["pull policy"] = function()
    r, t = cfg("-v", "-f", p)
    T.equal(r, 0)
  end
  T.git["pull check"] = function()
    local out = table.concat(t.stderr, "\n")
    T.equal(string.find(out, "Already up-to-date.", 1, true), 70)
    cmd.rm("-r", "-f", dir.."git")
  end
end
pull("test/git_pull.lua")
