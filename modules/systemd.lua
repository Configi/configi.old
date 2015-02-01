--- Ensure that a service managed by systemd-systemctl is started or stopped.
-- @module systemd
-- @author Eduardo Tongson <propolice@gmail.com>
-- @license MIT <http://opensource.org/licenses/MIT>
-- @added 0.9.0

local Configi = require"configi"
local Px = require"px"
local Cmd = Px.cmd
local systemd = {}
_ENV = nil

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
    ok = "systemd.started: Successfully started service.",
    skip = "systemd.started: Service already started.",
    fail = "systemd.started: Error starting service."
  }
  local F, P, R = main(S, M, G)
  local code = F.run(Cmd["-/usr/bin/systemctl"], { "--quiet", "is-active", P.service, _return_code = true })
  if code == 0 then
    return F.skip(P.service)
  end
  return F.result(F.run(Cmd["-/usr/bin/systemctl"], { "--quiet", "start", P.service }), P.service)
end

--- Stop a service.
-- @aliases absent
-- @param service service to stop [REQUIRED]
-- @usage systemd.stopped [[
--   service "rsyncd"
-- ]]
function systemd.stopped (S)
  local G = {
    ok = "systemd.stopped: Successfully stopped service.",
    skip = "systemd.stopped: Service already stopped.",
    fail = "systemd.stopped: Error stopping service."
  }
  local F, P, R = main(S, M, G)
  local code = F.run(Cmd["-/usr/bin/systemctl"], { "--quiet", "is-active", P.service, _return_code = true })
  if code ~= 0 then
    return F.skip(P.service)
  end
  return F.result(F.run(Cmd["-/usr/bin/systemctl"], { "--quiet", "stop", P.service}), P.service)
end

--- Restart a service.
-- @note skips restart if service is not yet active.
-- @param service service to restart [REQUIRED]
-- @usage systemd.restart [[
--   service "rsyncd"
-- ]]
function systemd.restart (S)
  local G = {
    ok = "systemd.restart: Successfully restarted service.",
    skip = "systemd.restart: Service not active.",
    fail = "systemd.restart: Error restarting service."
  }
  local F, P, R = main(S, M, G)
  local code = F.run(Cmd["-/usr/bin/systemctl"], { "--quiet", "is-active", P.service, _return_code = true})
  if code ~= 0 then
    return F.skip(P.service)
  end
  return F.result(F.run(Cmd["-/usr/bin/systemctl"], { "--quiet", "restart", P.service }), P.service)
end

--- Reload a service.
-- @param service service to reload [REQUIRED]
-- @usage systemd.reload [[
--   service "sshd"
-- ]]
function systemd.reload (S)
  local G = {
    ok = "system.reload: Successfully reloaded service.",
    skip = "system.reload: Service not active.",
    fail = "systemd.reload: Error reloading service."
  }
  local F, P, R = main(S, M, G)
  local code = F.run(Cmd["-/usr/bin/systemctl"], { "--quiet", "is-active", P.service, _return_code = true})
  if code ~= 0 then
    return F.skip(P.service)
  end
  return F.result(F.run(Cmd["-/usr/bin/systemctl"], { "--quiet", "reload", P.service }), P.service)
end

--- Enable a service.
-- @param service service to enable [REQUIRED]
-- @usage systemd.enabled [[
--   service "rsyncd"
-- ]]
function systemd.enabled (S)
  local G = {
    ok = "systemd.enabled: Successfully enabled service.",
    skip = "systemd.enabled: Service already enabled.",
    fail = "systemd.enabled: Error enabling service."
  }
  local F, P, R = main(S, M, G)
  local code = F.run(Cmd["-/usr/bin/systemctl"], { "--quiet", "is-enabled", P.service, _return_code = true})
  if code == 0 then
    return F.skip(P.service)
  end
  return F.result(F.run(Cmd["-/usr/bin/systemctl"], { "--quiet", "enable", P.service}), P.service)
end

--- Disable a service.
-- @param service service to disable [REQUIRED]
-- @usage systemd.disabled [[
--   service "rsyncd"
-- ]]
function systemd.disabled (S)
  local G = {
    ok = "systemd.disabled: Successfully disabled service.",
    skip = "systemd.disabled: Service already disabled.",
    fail = "systemd.disabled: Error disabling service."
  }
  local F, P, R = main(S, M, G)
  local code = F.run(Cmd["-/usr/bin/systemctl"], { "--quiet", "is-enabled", P.service, _return_code = true })
  if code ~= 0 then
    return F.skip(P.service)
  end
  return F.result(F.run(Cmd["-/usr/bin/systemctl"], { "--quiet", "disable", P.service}), P.service)
end

systemd.present = systemd.started
systemd.absent = systemd.stopped
return systemd

