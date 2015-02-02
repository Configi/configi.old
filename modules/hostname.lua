--- Set hostname.
-- @module hostname
-- @author Eduardo Tongson <propolice@gmail.com>
-- @license MIT <http://opensource.org/licenses/MIT>
-- @added 0.9.0

local Configi = require"configi"
local Fact = require"factid"
local Cmd = require"px".cmd
local hostname = {}
local ENV = {}
_ENV = ENV

local main = function (S, M, G)
  local C = Configi.start(S, M, G)
  C.required = { "hostname" }
  C.alias.hostname = { "name" }
  return Configi.finish(C)
end

--- Set hostname.
-- @param hostname hostname to set [ALIAS: name]
-- @usage hostname.set [[
--   name "aardvark"
-- ]]
function hostname.set (S)
  local G = {
    ok = "hostname.set: Successfully set hostname.",
    skip = "hostname.set: Hostname already set.",
    fail = "hostname.set: Error setting hostname.",
  }
  local F, P, R = main(S, M, G)
  if P.hostname == Fact.hostname() then
    return F.skip(P.hostname)
  end
  return F.result(P.hostname, F.run(Cmd.hostname{ P.hostname }))
end

return hostname
