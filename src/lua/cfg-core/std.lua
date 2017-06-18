local lib = require"lib"
local path, log, os = lib.path, lib.log, lib.os
local dirent = require"posix.dirent"
local syslog = require"posix.syslog"
local strings = require"cfg-core.strings"
local unistd = require"posix.unistd"

local Path = function()
  local dir = "."
  for r, optarg, _, _ in unistd.getopt(arg, strings.short_args) do
    if r == "f" then
      dir, _, _ = path.decompose(optarg)
      break
    end
  end
  return dir
end

local Log = function(sys, file, str, level)
  level = level or syslog.LOG_DEBUG
  if sys then
    return log.syslog(file, strings.IDENT, str, syslog.LOG_NDELAY | syslog.LOG_PID, syslog.LOG_DAEMON, level)
  elseif not sys and file then
    return log.file(file, strings.IDENT, str)
  end
end

local Add_From_Dirs = function(scripts, cpath)
  local dirs = {
           "/attributes",
           "/includes",
           "/handlers"
  }
  local dir
  for _, d in ipairs(dirs) do
    dir = cpath..d
    if os.is_dir(dir) then
      for f in dirent.files(dir) do
        if not (f==".") and not (f=="..") then
          scripts[#scripts+1] = dir.."/"..f
        end
      end
    end
  end
  return scripts
end

local Add_From_Role = function(scripts, cpath, role)
  local d = cpath.."/roles/"..role
  local m = d.."/main.lua"
  if os.is_file(m) then
    scripts[#scripts+1] = m
    scripts = Add_From_Dirs(scripts, d)
  end
  return scripts
end

local Add_To_Path = function(pp, cpath, role)
  return pp..";"..cpath.."/roles/"..role.."/?.lua;"..cpath.."/roles/"..role.."/?/init.lua"
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
