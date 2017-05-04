--- Ensure that an OpenRC service is started or stopped.
-- <br />
-- This module can also restart and reload a service.
-- <br />
-- And add or remove a service from a particular runlevel.
-- @module openrc
-- @author Eduardo Tongson <propolice@gmail.com>
-- @license MIT <http://opensource.org/licenses/MIT>
-- @added 0.9.0

local ENV, M, openrc = {}, {}, {}
local cfg = require"cfg-core.lib"
local lib = require"lib"
local cmd = lib.cmd
_ENV = ENV

M.required = { "service" }

--- Start a service.
-- @Promiser service
-- @Aliases present
-- @param None
-- @usage openrc.started("rsyncd")()
function openrc.started(S)
    M.report = {
        repaired = "openrc.started: Successfully started service.",
            kept = "openrc.started: Service already started.",
          failed = "openrc.started: Error starting service"
    }
    return function(P)
        P.service = S
        local F, R = cfg.init(P, M)
        if R.kept then
            return F.kept(P.service)
        end
        local code, out, test = F.run(cmd["/bin/rc-status"], { "--nocolor", "--servicelist", _return_code = true })
        local pattern = "^%s" .. lib.escape_pattern(P.service) .. "%s*%[%s%sstarted%s%s%]$"
        if test or ((code ==0) and (lib.find_string(out.stdout, pattern))) then
            return F.kept(P.service)
        end
        local start = F.run(cmd["/sbin/rc-service"],
            { "--nocolor", "--quiet", P.service, "start", _return_code = true })
        return F.result(P.service, (start == 0) or nil)
    end
end

--- Stop a service.
-- @Promiser service
-- @Aliases absent
-- @param None
-- @usage openrc.stopped("rsyncd")()
function openrc.stopped(S)
    M.report = {
        repaired = "openrc.stopped: Successfully stopped service.",
            kept = "openrc.stopped: Service already stopped.",
          failed = "openrc.stopped: Error stopping service."
    }
    return function(P)
        P.service = S
        local F, R = cfg.init(P, M)
        if R.kept then
            return F.kept(P.service)
        end
        local code, out, test = F.run(cmd["/bin/rc-status"], { "--nocolor", "--servicelist", _return_code = true })
        local pattern = "^%s" .. lib.escape_pattern(P.service) .. "%s*%[%s%sstarted%s%s%]$"
        if test or ((code == 0) and not (lib.find_string(out.stdout, pattern))) then
            return F.kept(P.service)
        end
        local stop = F.run(cmd["/sbin/rc-service"],
            { "--nocolor", "--quiet", P.service, "stop", _return_code = true })
        return F.result(P.service, (stop == 0) or nil)
    end
end

--- Restart a service.
-- @Promiser service
-- @param None
-- @usage openrc.restart("rsyncd")()
function openrc.restart(S)
    M.report = {
        repaired = "openrc.restart: Successfully restarted service.",
        failed = "openrc.restart: Error restarting service."
    }
    return function(P)
        P.service = S
        local F, R = cfg.init(P, M)
        if R.kept then
            return F.kept(P.service)
        end
        local code, _, test =
            F.run(cmd["/sbin/rc-service"], { "--nocolor", "--quiet", P.service, "restart", _return_code = true })
        if test or (code == 0) then
            return F.result(P.service, true)
        end
    end
end

--- Reload a service.
-- @Promiser service
-- @param None
-- @usage openrc.reload("sshd")()
function openrc.reload(S)
    M.report = {
        repaired = "openrc.reload: Successfully reloaded service",
          failed = "openrc.reload: Error reloading service."
    }
    return function(P)
        P.service = S
        local F, R = cfg.init(P, M)
        if R.kept then
            return F.kept(P.service)
        end
        local code, _, test =
            F.run(cmd["/sbin/rc-service"], { "--nocolor", "--quiet", P.service, "reload", _return_code = true })
        if test or (code == 0) then
            return F.result(P.service, true)
        end
    end
end

--- Add a service to runlevel.
-- @Promiser service
-- @param runlevel runlevel to add to [REQUIRED] [DEFAULT: default]
-- @usage openrc.add("rsyncd"){
--     runlevel = "default"
-- }
function openrc.add(S)
    M.parameters = { "runlevel" }
    M.report = {
        repaired = "openrc.add: Successfully added service to runlevel.",
            kept = "openrc.add: Service already in the runlevel.",
          failed = "openrc.add: Error adding service to runlevel."
    }
    return function(P)
        P.service = S
        local F, R = cfg.init(P, M)
        if R.kept then
            return F.kept(P.service)
        end
        P.runlevel = P.runlevel or "default"
        local _
        local code, out, test =
            F.run(cmd["/sbin/rc-update"], { "--nocolor", "--quiet", "show", P.runlevel, _return_code = true })
        local pattern = "^%s*" .. lib.escape_pattern(P.service) .. "%s|%s" .. P.runlevel .. "%s*$"
        if test or ((code == 0) and lib.find_string(out.stdout, pattern)) then
            return F.kept(P.service)
        end
        code, _, test =
            F.run(cmd["/sbin/rc-update"], { "--nocolor", "--quiet", "add", P.service, P.runlevel, _return_code = true })
        return F.result(P.service, (test or (code == 0) or nil))
    end
end

--- Remove a service from a runlevel.
-- @Promiser service
-- @Aliases del
-- @param runlevel runlevel to remove from [REQUIRED] [DEFAULT: default]
-- @usage openrc.delete("rsyncd"){
--     runlevel = "default"
-- }
function openrc.delete(S)
    M.parameters = { "runlevel" }
    M.report = {
        repaired = "openrc.delete: Successfully deleted service from runlevel.",
            kept = "openrc.delete: Service already absent from runlevel.",
          failed = "openrc.delete: Error deleting service from runlevel."
    }
    return function(P)
        P.service = S
        local F, R = cfg.init(P, M)
        if R.kept then
            return F.kept(P.service)
        end
        P.runlevel = P.runlevel or "default"
        local _
        local code, out, test =
            F.run(cmd["/sbin/rc-update"], { "--nocolor", "--quiet", "show", P.runlevel, _return_code = true })
        local pattern = "^%s*" .. lib.escape_pattern(P.service) .. "%s|%s" .. P.runlevel .. "%s*$"
        if test or ((code == 0) and not (lib.find_string(out.stdout, pattern))) then
            return F.kept(P.service)
        end
        code, _, test =
            F.run(cmd["/sbin/rc-update"], { "--nocolor", "--quiet", "del", P.service, P.runlevel, _return_code = true })
        return F.result(P.service, (test or (code == 0) or nil))
    end
end

openrc.present = openrc.started
openrc.absent = openrc.stopped
openrc.del = openrc.delete
return openrc
