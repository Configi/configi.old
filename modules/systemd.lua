--- Ensure that a service managed by systemd-systemctl is started or stopped.
-- @module systemd
-- @author Eduardo Tongson <propolice@gmail.com>
-- @license MIT <http://opensource.org/licenses/MIT>
-- @added 0.9.0

local Configi = require"configi"
local Px = require"px"
local Cmd = Px.cmd
local systemd = {}
local ENV = {}
_ENV = ENV

local main = function (S, M, G)
  local C = Configi.start(S, M, G)
  C.required = { "service" }
  C.alias.service = { "daemon" }
  return Configi.finish(C)
end

--- Start a service.
-- @aliases present
-- @param service service to start [REQUIRED]
-- @usage systemd.started [[
--   service "rsyncd"
-- ]]
function systemd.started (S)
  local G = {
    repaired = "systemd.started: Successfully started service.",
    kept = "systemd.started: Service already started.",
    failed = "systemd.started: Error starting service."
  }
  local F, P, R = main(S, M, G)
  local code = F.run(Cmd["-/usr/bin/systemctl"], { "--quiet", "is-active", P.service, _return_code = true })
  if code == 0 then
    return F.kept(P.service)
  end
  return F.result(P.service, F.run(Cmd["-/usr/bin/systemctl"], { "--quiet", "start", P.service }))
end

--- Stop a service.
-- @aliases absent
-- @param service service to stop [REQUIRED]
-- @usage systemd.stopped [[
--   service "rsyncd"
-- ]]
function systemd.stopped (S)
  local G = {
    repaired = "systemd.stopped: Successfully stopped service.",
    kept = "systemd.stopped: Service already stopped.",
    failed = "systemd.stopped: Error stopping service."
  }
  local F, P, R = main(S, M, G)
  local code = F.run(Cmd["-/usr/bin/systemctl"], { "--quiet", "is-active", P.service, _return_code = true })
  if code ~= 0 then
    return F.kept(P.service)
  end
  return F.result(P.service, F.run(Cmd["-/usr/bin/systemctl"], { "--quiet", "stop", P.service}))
end

--- Restart a service.
-- @note skips restart if service is not yet active.
-- @param service service to restart [REQUIRED]
-- @usage systemd.restart [[
--   service "rsyncd"
-- ]]
function systemd.restart (S)
  local G = {
    repaired = "systemd.restart: Successfully restarted service.",
    kept = "systemd.restart: Service not active.",
    failed = "systemd.restart: Error restarting service."
  }
  local F, P, R = main(S, M, G)
  local code = F.run(Cmd["-/usr/bin/systemctl"], { "--quiet", "is-active", P.service, _return_code = true})
  if code ~= 0 then
    return F.kept(P.service)
  end
  return F.result(P.service, F.run(Cmd["-/usr/bin/systemctl"], { "--quiet", "restart", P.service }))
end

--- Reload a service.
-- @param service service to reload [REQUIRED]
-- @usage systemd.reload [[
--   service "sshd"
-- ]]
function systemd.reload (S)
  local G = {
    repaired = "system.reload: Successfully reloaded service.",
    kept = "system.reload: Service not active.",
    failed = "systemd.reload: Error reloading service."
  }
  local F, P, R = main(S, M, G)
  local code = F.run(Cmd["-/usr/bin/systemctl"], { "--quiet", "is-active", P.service, _return_code = true})
  if code ~= 0 then
    return F.kept(P.service)
  end
  return F.result(P.service, F.run(Cmd["-/usr/bin/systemctl"], { "--quiet", "reload", P.service }))
end

--- Enable a service.
-- @param service service to enable [REQUIRED]
-- @usage systemd.enabled [[
--   service "rsyncd"
-- ]]
function systemd.enabled (S)
  local G = {
    repaired = "systemd.enabled: Successfully enabled service.",
    kept = "systemd.enabled: Service already enabled.",
    failed = "systemd.enabled: Error enabling service."
  }
  local F, P, R = main(S, M, G)
  local code = F.run(Cmd["-/usr/bin/systemctl"], { "--quiet", "is-enabled", P.service, _return_code = true})
  if code == 0 then
    return F.kept(P.service)
  end
  return F.result(P.service, F.run(Cmd["-/usr/bin/systemctl"], { "--quiet", "enable", P.service}))
end

--- Disable a service.
-- @param service service to disable [REQUIRED]
-- @usage systemd.disabled [[
--   service "rsyncd"
-- ]]
function systemd.disabled (S)
  local G = {
    repaired = "systemd.disabled: Successfully disabled service.",
    kept = "systemd.disabled: Service already disabled.",
    failed = "systemd.disabled: Error disabling service."
  }
  local F, P, R = main(S, M, G)
  local code = F.run(Cmd["-/usr/bin/systemctl"], { "--quiet", "is-enabled", P.service, _return_code = true })
  if code ~= 0 then
    return F.kept(P.service)
  end
  return F.result(P.service, F.run(Cmd["-/usr/bin/systemctl"], { "--quiet", "disable", P.service}))
end

systemd.present = systemd.started
systemd.absent = systemd.stopped
return systemd

