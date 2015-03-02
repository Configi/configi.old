local version = "Configi 0.9.7"
local arg = arg
local Lua = {
  exit = os.exit,
  next = next,
  tostring = tostring,
  format = string.format,
  collectgarbage = collectgarbage
}
local Lib = require"configi"
local Lc = require"cimicida"
local Lcli = Lib.cli
local Punistd = require"posix.unistd"
local Psignal = require"posix.signal"
local Pstat = require"posix.sys.stat"
local Psyslog = require"posix.syslog"
local Psystime = require"posix.sys.time"
local Px = require"px"
local inotify = require"inotify"
local t1
local ENV = {}
_ENV = ENV

while true do
  local handle, wd
  local source, hsource, runenv, opts = Lcli.opt(arg, version)
  ::RUN::
  t1 = Psystime.gettimeofday()
  local R, M = Lcli.try(source, hsource, runenv)
  if not R.failed and not R.repaired then
    R.kept = true
  end
  if opts.debug then
    Lc.printf("------------\n")
    if R.kept then
      Lc.printf("Kept: %s\n", R.kept)
    elseif R.repaired then
      Lc.printf("Repaired: %s\n", R.repaired)
    elseif R.failed then
      Lc.printf("Failed: %s\n", R.failed)
      Lc.errorf("Failed!\n")
    end
    local t2 = Px.difftime(Psystime.gettimeofday(), t1)
    t2 = Lua.format("%s.%s", Lua.tostring(t2.sec), Lua.tostring(t2.usec))
    if t2 == 0 or t2 == 1.0 then
      Lc.printf("Finished run in %.f second\n", 1.0)
    else
      Lc.printf("Finished run in %.f seconds\n", t2)
    end
  else
    if R.failed then
      Lua.exit(1)
    end
  end
  if opts.daemon then
    if Punistd.geteuid() == 0 then
      if Pstat.stat("/proc/self/oom_score_adj") then
        Px.fwrite("/proc/self/oom_score_adj", "-1000")
      else
        Px.fwrite("/proc/self/oom_adj", "-1000")
      end
    end
    handle = inotify.init()
    wd = handle:addwatch(opts.script, inotify.IN_MODIFY, inotify.IN_ATTRIB)
    local bail = function(sig)
      handle:rmwatch(wd)
      handle:close()
      Lib.LOG(opts.syslog, opts.log, Lua.format("Caught signal %s. Exiting.", Lua.tostring(sig)), Psyslog.LOG_ERR)
      Lua.exit(255)
    end
    Psignal.signal(Psignal.SIGINT, bail)
    Psignal.signal(Psignal.SIGTERM, bail)
    handle:read()
    Lua.collectgarbage()
  elseif opts.periodic then
    Punistd.sleep(opts.periodic)
    Lua.collectgarbage()
    goto RUN
  else
    break
  end
end

