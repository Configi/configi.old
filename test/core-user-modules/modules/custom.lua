-- @module custom
-- @author Eduardo Tongson <propolice@gmail.com>
-- @license MIT <http://opensource.org/licenses/MIT>

local ENV, M, custom = {}, {}, {}
local cfg = require"cfg-core.lib"
local lib = require"lib"
local cmd = lib.cmd
_ENV = ENV

M.required = { "path" }

function custom.action(S)
    M.report = {
        repaired = "custom.action: Success.",
            kept = "custom.action: Skipped.",
          failed = "custom.action: Failure."
    }
    return function(P)
        P.path = S
        local F, R = cfg.init(P, M)
        if F.run(cmd.touch, { P.path }) then
            F.msg(P.path, M.report.repaired, true)
            return F.result(P.path, true)
        else
            return F.result(P.path, false)
        end
    end
end

return custom
