local ENV, M, testing = {}, {}, {}
local cfg = require"cfg-core.lib"
local lib = require"lib"
local cmd = lib.cmd
_ENV = ENV

M.required = { "path" }

function testing.touch(S)
    M.report = {
        repaired = "testing.touch: Success",
            kept = "testing.touch: Skip",
          failed = "testing.touch: Error"
    }
    return function(P)
        P.path = S
        local F, R = cfg.init(P, M)
        if R.kept then
            return F.kept(P.path)
        end
        return F.result(P.path, F.run(cmd.touch, {P.path}))
    end
end

return testing
