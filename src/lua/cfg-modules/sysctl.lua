--- Kernel paramater modification through sysctl as implemented in procfs.
-- @module sysctl
-- @author Eduardo Tongson <propolice@gmail.com>
-- @license MIT <http://opensource.org/licenses/MIT>
-- @added 2.0.0

local ENV, M, sysctl = {}, {}, {}
local string = string
local tostring = tostring
local cfg = require"cfg-core.lib"
local lib = require"lib"
local stat = require"posix.sys.stat"
_ENV = ENV

M.required = { "value" }

--- Write value to a sysctl key
-- @Promiser key sysctl key to write to
-- @param value value to write
-- @usage sysctl.write"vm.swappiness"{
--   value = 0
-- }
function sysctl.write(S)
    M.report = {
        repaired = "sysctl.write: Successfully wrote value.",
            kept = "sysctl.write: Value already set.",
          failed = "sysctl.write: Error writing value.",
       not_found = "sysctl.write: Sysctl key not found."
    }
    return function(P)
        P.key = S
        local F, R = cfg.init(P, M)
        if R.kept then
            return F.kept(P.key)
        end
        local write_key = function()
            local key = string.gsub(P.key, "%.", "/")
            key = "/proc/sys/"..key
            if stat.stat(key) then
                local write = tostring(P.value)
                if lib.read_all(key) == write then
                    return false
                end
                return lib.fwrite(key, write)
            else
                -- Key not found
                return 0
            end
        end
        local r = write_key()
        if r == false then
            return F.kept(P.key)
        elseif r == 0 then
            return F.result(P.key, nil, M.report.not_found)
        else
            return F.result(P.key, r)
        end
    end
end

return sysctl
