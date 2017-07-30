--- Set hostname.
-- @module hostname
-- @author Eduardo Tongson <propolice@gmail.com>
-- @license MIT <http://opensource.org/licenses/MIT>
-- @added 0.9.0

local M, hostname = {}, {}
local string, ipairs, next = string, ipairs, next
local cfg = require"cfg-core.lib"
local fact = require"cfg-core.fact"
local factid = require"factid"
local lib = require"lib"
local path = lib.path
local cmd = lib.exec.cmd
_ENV = nil

M.required = { "hostname" }

local current_hostnames = function()
  local _, hostnamectl = cmd.hostnamectl{}
  local hostnames = {
    Pretty = false,
    Static = false,
    Transient = false
  }
  local _k, _v
  for ln = 1, #hostnamectl.stdout do
    for type, _ in next, hostnames do
      _k, _v = string.match(hostnamectl.stdout[ln], "^%s*(" .. type .. " hostname):%s([%g%s]*)$")
      if _k then
        -- New keys that starts with lower case characters.
        hostnames[string.lower(type)] = _v
      end
    end
  end
  return hostnames
end

--- Set hostname.
-- On systems that support hostnamectl(1) you can omit the `static` parameter
-- since the subject is used to set the static hostname.
-- @Promiser hostname
-- @usage hostname.set("aardvark")()
-- @usage hostname.set("aardvark"){
--   transient = "aardvark.configi.org",
--   pretty = "Aardvark host"
-- }
function hostname.set(S)
  M.parameters = { "static", "transient", "pretty" }
  M.report = {
    repaired = "hostname.set: Successfully set hostname(s).",
    kept = "hostname.set: Hostname already set.",
    failed = "hostname.set: Error setting hostname.",
  }
  return function(P)
    P.hostname = S
    local F, R = cfg.init(P, M)
    if R.kept then
      return F.kept(P.hostname)
    end
    if path.bin("hostnamectl") then
      local hostnames = current_hostnames()
      -- Handle hostname.set("localhost")! on hostnamectl(1) systems.
      if not P.transient and not P.pretty and not P.static then
        -- Only set static if only P.hostname(subject) is given.
        if hostnames.static == P.hostname then
          return F.kept(P.hostname)
        end
        return F.result(P.hostname, F.run(cmd.hostnamectl, { "--static", "set-hostname", P.hostname }))
      end
      -- Static may override Transient in some cases so it's the last one here.
      local kept = true
      for _, type in ipairs{ "transient", "pretty", "static" } do
        if P[type] and not (P[type] == hostnames[type]) then
          kept = false
          if cmd.hostnamectl{ "--" .. type, "set-hostname", P[type]} == nil then
            return F.result(P[type])
          end
        end
      end
      if not P.static then
        if cmd.hostnamectl{ "--static", "set-hostname", P.hostname} == nil then
          return F.result(P.hostname)
        end
      end
      if kept then
        return F.kept(P.hostname)
      end
      -- Everything went well so pass true to the result().
      return F.result(P.hostname, true)
    else
      if fact.hostname[P.hostname] or (P.hostname == factid.hostname()) then
        return F.kept(P.hostname)
      end
      return F.result(P.hostname, F.run(cmd.hostname, {P.hostname}))
    end
  end
end

return hostname
