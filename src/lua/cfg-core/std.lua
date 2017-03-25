local lib = require"lib"
local dirent = require"posix.dirent"
local syslog = require"posix.syslog"
local getopt = require"posix.getopt"
local strings = require"cfg-core.strings"

local Path = function()
    local path = "."
    for r, optarg, _, _ in getopt.getopt(arg, strings.short_args, strings.long_args) do
        if r == "f" then
            path, _, _ = lib.decomp_path(optarg)
            break
        end
    end
    return path
end

local Log = function(sys, file, str, level)
    level = level or syslog.LOG_DEBUG
    if sys then
        return lib.log(file, strings.IDENT, str, syslog.LOG_NDELAY | syslog.LOG_PID, syslog.LOG_DAEMON, level)
    elseif not sys and file then
        return lib.log(file, strings.IDENT, str)
    end
end

local Add_Policies = function(tbl, dir)
    local path = Path()
    dir = path.."/"..dir
    if lib.is_dir(dir) then
        for f in dirent.files(dir) do
            tbl[#tbl+1] = dir.."/"..f
        end
    end
    return tbl
end

return {
            path = Path,
            file = File,
             log = Log,
    add_policies = Add_Policies
}
