#!bin/lua
local ENV, os, string, arg, next, tostring, collectgarbage =
       {}, os, string, arg, next, tostring, collectgarbage
local version = require"cfg-core.strings".version
local std = require"cfg-core.std"
local cli = require"cfg-core.cli"
local lib = require"lib"
local unistd = require"posix.unistd"
local signal = require"posix.signal"
local sysstat = require"posix.sys.stat"
local syslog = require"posix.syslog"
local systime = require"posix.sys.time"
local inotify = require"inotify"
local t1
_ENV = ENV

while true do
    local handle, wd
    local source, hsource, runenv, opts = cli.opt(arg, version)
    ::RUN::
    t1 = systime.gettimeofday()
    local R, M = cli.try(source, hsource, runenv)
    if not R.failed and not R.repaired then
        R.kept = true
    end
    if opts.debug then
        lib.printf("------------\n")
        if R.kept then
            lib.printf("Kept: %s\n", R.kept)
        elseif R.repaired then
            lib.printf("Repaired: %s\n", R.repaired)
        elseif R.failed then
            lib.printf("Failed: %s\n", R.failed)
            lib.errorf("Failed!\n")
        end
        local t2 = lib.diff_time(systime.gettimeofday(), t1)
        t2 = string.format("%s.%s", tostring(t2.sec), tostring(t2.usec))
        if t2 == 0 or t2 == 1.0 then
            lib.printf("Finished run in %.f second\n", 1.0)
        else
            lib.printf("Finished run in %.f seconds\n", t2)
        end
    else
        if R.failed then
            os.exit(1)
        end
    end
    if opts.daemon then
        if unistd.geteuid() == 0 then
            if sysstat.stat("/proc/self/oom_score_adj") then
                lib.fdwrite("/proc/self/oom_score_adj", "-1000")
            else
                lib.fdwrite("/proc/self/oom_adj", "-1000")
            end
        end
        handle = inotify.init()
        wd = handle:addwatch(opts.script, inotify.IN_MODIFY, inotify.IN_ATTRIB)
        local bail = function(sig)
            handle:rmwatch(wd)
            handle:close()
            std.log(opts.syslog, opts.log, string.format("Caught signal %s. Exiting.", tostring(sig)), syslog.LOG_ERR)
            os.exit(255)
        end
        signal.signal(signal.SIGINT, bail)
        signal.signal(signal.SIGTERM, bail)
        handle:read()
        collectgarbage()
    elseif opts.periodic then
        unistd.sleep(opts.periodic)
        collectgarbage()
        goto RUN
    else
        break
    end
end

