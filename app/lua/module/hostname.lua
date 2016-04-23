--- Set hostname.
-- @module hostname
-- @author Eduardo Tongson <propolice@gmail.com>
-- @license MIT <http://opensource.org/licenses/MIT>
-- @added 0.9.0

local cfg = require"configi"
local factid = require"factid"
local cmd = require"lib".cmd
local hostname = {}
local ENV = {}
_ENV = ENV

local main = function (S, M, G)
  local C = cfg.start(S, M, G)
  C.required = { "hostname" }
  C.alias.hostname = { "name" }
  return cfg.finish(C)
end

--- Set hostname.
-- @param hostname hostname to set [ALIAS: name]
-- @usage hostname.set [[
--   name "aardvark"
-- ]]
function hostname.set (S)
  local G = {
    repaired = "hostname.set: Successfully set hostname.",
    kept = "hostname.set: Hostname already set.",
    failed = "hostname.set: Error setting hostname.",
  }
  local F, P, R = main(S, M, G)
  if P.hostname == factid.hostname() then
    return F.kept(P.hostname)
  end
  return F.result(P.hostname, F.run(cmd.hostname{ P.hostname }))
end

return hostname
