--- Ensure that an OpenRC service is started or stopped.
-- <br />
-- This module can also restart and reload a service.
-- <br />
-- And add or remove a service from a particular runlevel.
-- @module openrc
-- @author Eduardo Tongson <propolice@gmail.com>
-- @license MIT <http://opensource.org/licenses/MIT>
-- @added 0.9.0

local Configi = require"configi"
local Px = require"px"
local Lc = require"cimicida"
local Cmd = Px.cmd
local openrc = {}
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
-- @usage openrc.started [[
--   service "rsyncd"
-- ]]
function openrc.started (S)
  local G = {
    ok = "openrc.started: Successfully started service.",
    skip = "openrc.started: Service already started.",
    fail = "openrc.started: Error starting service"
  }
  local F, P, R = main(S, M, G)
  local code, out, test = F.run(Cmd["/bin/rc-status"], { "--nocolor", "--servicelist", _return_code = true })
  local pattern = "^%s" .. P.service .. "%s*%[%s%sstarted%s%s%]$"
  if test or ((code ==0) and (Lc.tfind(out.stdout, pattern))) then
    return F.skip(P.service)
  end
  local start =
    F.run(Cmd["/sbin/rc-service"], { "--nocolor", "--quiet", P.service, "start", _return_code = true })
  return F.result((start == 0), P.service)
end

--- Stop a service.
-- @aliases absent
-- @param service service to stop [REQUIRED]
-- @usage openrc.stopped [[
--   service "rsyncd"
-- ]]
function openrc.stopped (S)
  local G = {
    ok = "openrc.stopped: Successfully stopped service.",
    skip = "openrc.stopped: Service already stopped.",
    fail = "openrc.stopped: Error stopping service."
  }
  local F, P, R = main(S, M, G)
  local code, out, test = F.run(Cmd["/bin/rc-status"], { "--nocolor", "--servicelist", _return_code = true })
  local pattern = "^%s" .. P.service .. "%s*%[%s%sstarted%s%s%]$"
  if test or ((code == 0) and not (Lc.tfind(out.stdout, pattern))) then
    return F.skip(P.service)
  end
  local stop = F.run(Cmd["/sbin/rc-service"], { "--nocolor", "--quiet", P.service, "stop", _return_code = true })
  return F.result((stop == 0), P.service)
end

--- Restart a service.
-- @param service service to restart [REQUIRED]
-- @usage openrc.restart [[
--   service "rsyncd"
-- ]]
function openrc.restart (S)
  local G = {
    ok = "openrc.restart: Successfully restarted service.",
    fail = "openrc.restart: Error restarting service."
  }
  local F, P, R = main(S, M, G)
  local code, _, test =
    F.run(Cmd["/sbin/rc-service"], { "--nocolor", "--quiet", P.service, "restart", _return_code = true })
  if test or (code == 0) then
    return F.result(true, P.service)
  end
end

--- Reload a service.
-- @param service service to reload [REQUIRED]
-- @usage openrc.reload [[
--   service "sshd"
-- ]]
function openrc.reload (S)
  local G = {
    ok = "openrc.reload: Successfully reloaded service",
    fail = "openrc.reload: Error reloading service."
  }
  local F, P, R = main(S, M, G)
  local code, _, test =
    F.run(Cmd["/sbin/rc-service"], { "--nocolor", "--quiet", P.service, "reload", _return_code = true })
  if test or (code == 0) then
    return F.result(true, P.service)
  end
end

--- Add a service to runlevel.
-- @param service service to add [REQUIRED]
-- @param runlevel runlevel to add to [REQUIRED]
-- @usage openrc.add [[
--   service "rsyncd"
--   runlevel "default"
-- ]]
function openrc.add (S)
  local M = { "runlevel" }
  local G = {
    ok = "openrc.add: Successfully added service to runlevel.",
    skip = "openrc.add: Service already in the runlevel.",
    fail = "openrc.add: Error adding service to runlevel."
  }
  local F, P, R = main(S, M, G)
  local _
  local code, out, test =
    F.run(Cmd["/sbin/rc-update"], { "--nocolor", "--quiet", "show", P.runlevel, _return_code = true })
  local pattern = "^%s*" .. P.service .. "%s|%s" .. P.runlevel .. "%s*$"
  if test or ((code == 0) and Lc.tfind(out.stdout, pattern)) then
    return F.skip(P.service)
  end
  code, _, test =
    F.run(Cmd["/sbin/rc-update"], { "--nocolor", "--quiet", "add", P.service, P.runlevel, _return_code = true })
  return F.result((test or (code == 0)), P.service)
end

--- Remove a service from a runlevel.
-- @aliases del
-- @param service service to remove [REQUIRED] [ALIAS: daemon]
-- @param runlevel runlevel to remove from [REQUIRED]
-- @usage openrc.delete [[
--   service "rsyncd"
--   runlevel "default"
-- ]]
function openrc.delete (S)
  local M = { "runlevel" }
  local G = {
    ok = "openrc.delete: Successfully deleted service from runlevel.",
    skip = "openrc.delete: Service already absent from runlevel.",
    fail = "openrc.delete: Error deleting service from runlevel."
  }
  local F, P, R = main(S, M, G)
  local _
  local code, out, test =
    F.run(Cmd["/sbin/rc-update"], { "--nocolor", "--quiet", "show", P.runlevel, _return_code = true })
  local pattern = "^%s*" .. P.service .. "%s|%s" .. P.runlevel .. "%s*$"
  if test or ((code == 0) and not (Lc.tfind(out.stdout, pattern))) then
    return F.skip(P.service)
  end
  code, _, test =
    F.run(Cmd["/sbin/rc-update"], { "--nocolor", "--quiet", "del", P.service, P.runlevel, _return_code = true })
  return F.result((test or (code == 0)), P.service)
end

openrc.present = openrc.started
openrc.absent = openrc.stopped
openrc.del = openrc.delete
return openrc

