--- Ensure that a service managed by systemd-systemctl is started or stopped.
-- @module systemd
-- @author Eduardo Tongson <propolice@gmail.com>
-- @license MIT <http://opensource.org/licenses/MIT>
-- @added 0.9.0

local ENV, M, systemd = {}, {}, {}
local cfg = require"cfg-core.lib"
local lib = require"px"
local cmd = lib.cmd
_ENV = ENV

M.required = { "service" }

--- Start a service.
-- @Subject service
-- @Aliases present
-- @param None
-- @usage systemd.started("rsyncd")!
function systemd.started(S)
    M.report = {
        repaired = "systemd.started: Successfully started service.",
            kept = "systemd.started: Service already started.",
          failed = "systemd.started: Error starting service."
    }
    return function(P)
        P.service = S
        local F, R = cfg.init(P, M)
        if R.kept then
            return F.kept(P.service)
        end
        local code = F.run(cmd["systemctl"], { "--quiet", "is-active", P.service, _return_code = true })
        if code == 0 then
            return F.kept(P.service)
        end
        return F.result(P.service, F.run(cmd["systemctl"], { "--quiet", "start", P.service }))
    end
end

--- Stop a service.
-- @Subject service
-- @Aliases absent
-- @param None
-- @usage systemd.stopped("rsyncd")!
function systemd.stopped(S)
    M.report = {
        repaired = "systemd.stopped: Successfully stopped service.",
            kept = "systemd.stopped: Service already stopped.",
          failed = "systemd.stopped: Error stopping service."
    }
    return function(P)
        P.service = S
        local F, R = cfg.init(P, M)
        if R.kept then
            return F.kept(P.service)
        end
        local code = F.run(cmd["systemctl"], { "--quiet", "is-active", P.service, _return_code = true })
        if code ~= 0 then
            return F.kept(P.service)
        end
        return F.result(P.service, F.run(cmd["systemctl"], { "--quiet", "stop", P.service}))
    end
end

--- Restart a service.
-- @Subject service
-- @Note skips restart if service is not yet active.
-- @param None
-- @usage systemd.restart("rsyncd")!
function systemd.restart(S)
    M.report = {
        repaired = "systemd.restart: Successfully restarted service.",
            kept = "systemd.restart: Service not active.",
          failed = "systemd.restart: Error restarting service."
    }
    return function(P)
        P.service = S
        local F, R = cfg.init(P, M)
        if R.kept then
            return F.kept(P.service)
        end
        local code = F.run(cmd["systemctl"], { "--quiet", "is-active", P.service, _return_code = true})
        if code ~= 0 then
            return F.kept(P.service)
        end
        return F.result(P.service, F.run(cmd["systemctl"], { "--quiet", "restart", P.service }))
    end
end

--- Reload a service.
-- @Subject service
-- @param None
-- @usage systemd.reload("sshd")!
function systemd.reload(S)
    M.report = {
        repaired = "system.reload: Successfully reloaded service.",
            kept = "system.reload: Service not active.",
          failed = "systemd.reload: Error reloading service."
    }
    return function(P)
        P.service = S
        local F, R = cfg.init(P, M)
        if R.kept then
            return F.kept(P.service)
        end
        local code = F.run(cmd["systemctl"], { "--quiet", "is-active", P.service, _return_code = true})
        if code ~= 0 then
            return F.kept(P.service)
        end
        return F.result(P.service, F.run(cmd["systemctl"], { "--quiet", "reload", P.service }))
    end
end

--- Enable a service.
-- @Subject service
-- @param None
-- @usage systemd.enabled("rsyncd")!
function systemd.enabled(S)
    M.report = {
        repaired = "systemd.enabled: Successfully enabled service.",
            kept = "systemd.enabled: Service already enabled.",
          failed = "systemd.enabled: Error enabling service."
    }
    return function(P)
        P.service = S
        local F, R = cfg.init(P, M)
        if R.kept then
            return F.kept(P.service)
        end
        local code = F.run(cmd["systemctl"], { "--quiet", "is-enabled", P.service, _return_code = true})
        if code == 0 then
            return F.kept(P.service)
        end
        return F.result(P.service, F.run(cmd["systemctl"], { "--quiet", "enable", P.service}))
    end
end

--- Disable a service.
-- @Subject service
-- @param None
-- @usage systemd.disabled("rsyncd")!
function systemd.disabled(S)
    M.report = {
        repaired = "systemd.disabled: Successfully disabled service.",
            kept = "systemd.disabled: Service already disabled.",
          failed = "systemd.disabled: Error disabling service."
    }
    return function(P)
        P.service = S
        local F, R = cfg.init(P, M)
        if R.kept then
            return F.kept(P.service)
        end
        local code = F.run(cmd["systemctl"], { "--quiet", "is-enabled", P.service, _return_code = true })
        if code ~= 0 then
            return F.kept(P.service)
        end
        return F.result(P.service, F.run(cmd["systemctl"], { "--quiet", "disable", P.service}))
    end
end

systemd.present = systemd.started
systemd.absent = systemd.stopped
return systemd
