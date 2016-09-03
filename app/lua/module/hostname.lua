--- Set hostname.
-- @module hostname
-- @author Eduardo Tongson <propolice@gmail.com>
-- @license MIT <http://opensource.org/licenses/MIT>
-- @added 0.9.0

local ENV, M, hostname = {}, {}, {}
local cfg = require"configi"
local factid = require"factid"
local cmd = require"lib".cmd
_ENV = ENV

M.required = { "hostname" }
M.alias = {}
M.alias.hostname = { "name" }

--- Set hostname.
-- @param hostname hostname to set [ALIAS: name]
-- @usage hostname.set("aardvark")!
function hostname.set(S)
    M.report = {
        repaired = "hostname.set: Successfully set hostname.",
            kept = "hostname.set: Hostname already set.",
          failed = "hostname.set: Error setting hostname.",
    }
    return function(P)
        P.hostname = S
        local F, R = cfg.init(P, M)
        if P.hostname == factid.hostname() then
            return F.kept(P.hostname)
        end
        return F.result(P.hostname, F.run(cmd.hostname{ P.hostname }))
    end
end

return hostname
