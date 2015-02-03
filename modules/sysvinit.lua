--- Ensure that a service managed by sysvinit is started or stopped.
-- Tested on OpenWRT only.
-- @module sysvinit
-- @author Eduardo Tongson <propolice@gmail.com>
-- @license MIT <http://opensource.org/licenses/MIT>
-- @added 0.9.0

local Func = {}
local Configi = require"configi"
local Px = require"px"
local Cmd = Px.cmd
local sysvinit = {}
local ENV = {}
_ENV = ENV

local main = function (S, M, G)
  local C = Configi.start(S, M, G)
  C.required = { "service" }
  C.alias.service = { "daemon" }
  return Configi.finish(C)
end

Func.pgrep = function (service)
  local ok, cmd = Cmd.pgrep{ service }
  if ok then
    return true, cmd.stdout[1]
  end
end

--- Start a service.
-- @aliases present
-- @param service service to start [REQUIRED]
-- @usage sysvinit.started [[
--   service "ntpd"
-- ]]
function sysvinit.started (S)
  local G = {
    repaired = "sysvinit.started: Successfully started service.",
    kept = "sysvinit.started: Service already started.",
    failed = "sysvinit.started: Error restarting service."
  }
  local F, P, R = main(S, M, G)
  if Func.pgrep(P.service) then
    return F.kept(P.service)
  end
  F.run(Cmd["-/etc/init.d/" .. P.service], { "start", _ignore_error = true })
  return F.result(P.service, Func.pgrep(P.service))
end

--- Stop a service.
-- @aliases absent
-- @param service service to stop [REQUIRED]
-- @usage sysvinit.stopped [[
--   service "telnetd"
-- ]]
function sysvinit.stopped (S)
  local G = {
    repaired = "sysvinit.stopped: Successfully stopped service.",
    kept = "sysvinit.stopped: Service already stopped.",
    failed = "sysvinit.stopped: Error stopping service."
  }
  local F, P, R = main(S, M, G)
  if not Func.pgrep(P.service) then
    return F.kept(P.service)
  end
  F.run(Cmd["-/etc/init.d/" .. P.service], { "stop", _ignore_error = true })
  return F.result(P.service, (Func.pgrep(P.service) == nil))
end

--- Restart a service.
-- @param service service to restart [REQUIRED]
-- @usage sysvinit.restart [[
--   service "ntpd"
-- ]]
function sysvinit.restart (S)
  local G = {
    repaired = "sysvinit.restart: Successfully restarted service.",
    kept = "sysvinit.restart: Service not yet started.",
    failed = "sysvinit.restart: Error restarting service."
  }
  local F, P, R = main(S, M, G)
  local _, pid = Func.pgrep(P.service)
  if not pid then
    return F.kept(P.service)
  end
  F.run(Cmd["-/etc/init.d/" .. P.service], { "restart", _ignore_error = true })
  local _, npid = Func.pgrep(P.service)
  return F.result(P.service, (pid ~= npid))
end

--- Reload a service.
-- @note OpenWRT sysvinit can not detect reload failures
-- @param service service to reload [REQUIRED]
-- @usage sysvinit.reload [[
--   service "ntpd"
-- ]]
function sysvinit.reload (S)
  local G = {
    repaired = "sysvinit.reload: Successfully reloaded service.",
    kept = "sysvinit.reload: Service not yet started.",
    failed = "sysvinit.reload: Error reloading service."
  }
  local F, P, R = main(S, M, G)
  local _, pid = Func.pgrep(P.service)
  if not pid then
    return F.kept(P.service)
  end
  -- Assumed to always succeed
  F.run(Cmd["-/etc/init.d/" .. P.service], { "reload", _ignore_error = true })
  return F.result(P.service, true)
end

--- Enable a service
-- @param service service to enable [REQUIRED]
-- @usage sysvinit.enabled [[
--   service "ntpd"
-- ]]
function sysvinit.enabled (S)
  local G = {
    repaired = "sysvinit.enabled: Successfully enabled service.",
    kept = "sysvinit.enabled: Service already enabled.",
    failed = "sysvinit.enabled: Error enabling service."
  }
  local F, P, R = main(S, M, G)
  if F.run(Cmd["-/etc/init.d/" .. P.service], { "enabled" }) then
    return F.kept(P.service)
  end
  F.run(Cmd["-/etc/init.d/" .. P.service], { "enable", _ignore_error = true })
  return F.result(P.service, F.run(Cmd["-/etc/init.d/" .. P.service], { "enabled"}))
end

--- Disable a service.
-- @param service service to disable [REQUIRED]
-- @usage sysvinit.disabled [[
--   service "ntpd"
-- ]]
function sysvinit.disabled (S)
  local G = {
    repaired = "sysvinit.disabled: Successfully disabled service.",
    kept = "sysvinit.disabled: Service already disabled.",
    failed = "sysvinit.disabled: Error disabling service."
  }
  local F, P, R = main(S, M, G)
  local ok = Cmd["-/etc/init.d/" .. P.service]{ "enabled" }
  if not ok then
    return F.kept(P.service)
  end
  F.run(Cmd["-/etc/init.d/" .. P.service], { "disable", _ignore_error = true })
  ok = Cmd["-/etc/init.d/" .. P.service]{ "enabled" }
  return F.result(P.service, (not ok))
end

sysvinit.present = sysvinit.started
sysvinit.absent = sysvinit.stopped
return sysvinit

