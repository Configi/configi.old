_ENV = require "bin/tests/ENV"
function running(p)
  local r, t
  T.process["running policy"] = function()
    r, t = cfg("-m", "-f", p)
    T.equal(r, 0)
  end
  T.process["running pass"] = function()
    T.equal(PASS(t), 1)
  end
  T.process["running check"] = function()
    T.is_not_nil(stat.stat("/tmp/RUNNING"))
    os.remove("/tmp/RUNNING")
  end
end
running("test/process_running.lua")
function not_running(p)
  local r, t
  T.process["running notify_failed policy"] = function()
    r, t = cfg("-m", "-f", p)
    T.equal(r, 0)
  end
  T.process["running notify_failed fail"] = function()
    T.equal(FAIL(t), 1)
  end
  T.process["running notify_failed check"] = function()
    T.is_not_nil(stat.stat("/tmp/NOT-RUNNING"))
    os.remove("/tmp/NOT-RUNNING")
  end
end
not_running("test/process_not_running.lua")
T.summary()
