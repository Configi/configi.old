local lib = require"lib"
local dirent = require"posix.dirent"
local syslog = require"posix.syslog"
local strings = require"cfg-core.strings"
local getopt = require"posix.getopt"

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

local Add_From_Dirs = function(scripts, path)
    local dirs = {
                   "/attributes",
                   "/includes",
                   "/handlers"
    }
    local dir
    for _, d in ipairs(dirs) do
        dir = path..d
        if lib.is_dir(dir) then
            for f in dirent.files(dir) do
                if not (f==".") and not (f=="..") then
                    scripts[#scripts+1] = dir.."/"..f
                end
            end
        end
    end
    return scripts
end

local Add_From_Role = function(scripts, path, role)
    local d = path.."/roles/"..role
    local m = d.."/main.lua"
    if lib.is_file(m) then
        scripts[#scripts+1] = m
        scripts = Add_From_Dirs(scripts, d)
    end
    return scripts
end

local Add_To_Path = function(pp, path, role)
    return pp..";"..path.."/roles/"..role.."/?.lua;"..path.."/roles/"..role.."/?/init.lua"
end

local Add_From_Embedded = function(scripts, pol)
    local keys = {
                "attributes",
                "includes",
                "handlers"
    }
    for _, k in ipairs(keys) do
        if pol and pol[k] then
            for n, _ in pairs(pol[k]) do
                scripts[#scripts+1] = k.."/"..n..".lua"
            end
        end
    end
    return scripts
end

return {
                 path = Path,
                  log = Log,
        add_from_dirs = Add_From_Dirs,
        add_from_role = Add_From_Role,
          add_to_path = Add_To_Path,
    add_from_embedded = Add_From_Embedded
}
