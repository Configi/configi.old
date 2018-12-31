local start = os.time()
local argparse = require "argparse"
local parser = argparse("cfg", "Configi. A wrapper to rerun, for lightweight configuration management.")
parser:argument("script", "Script to load.")
parser:flag("-v --verbose", "Verbose output.")
parser:flag("-t --cut", "Truncate verbose or error output to 80 columns.")
local args = parser:parse()
local lib = require "cimicida"
local string, fmt, file, path, util = lib.string, lib.fmt, lib.file, lib.path, lib.util
if args.verbose then
  util.echo "Start Configi run...\n"
end
local dir = path.split(args.script)
package.path = dir
local rpath = "/usr/local/bin/rerun"
local rerun = function(dir, mod, cmd, a, params)
  if not file.test(rpath) then
    file.write_all(rpath, require("rerun"))
    os.execute("chmod +x " .. rpath)
  end
  local header = [[
  export LC_ALL=C
  export PATH=/bin:/usr/bin:/usr/local/bin
  exec 0>&- 2>&1
  ]]
  local str = string.format("%s cd %s && rerun -M modules %s:%s --arg %s", header, dir, mod, cmd, a)
  if params and next(params) then
    for o, p in pairs(params) do
      str = string.format("%s --%s %s", str, o, p)
    end
  end
  local pipe = io.popen(str, "r")
  io.flush(pipe)
  local output = {}
  for ln in pipe:lines() do
    output[#output + 1] = ln
  end
  local _, _, code = io.close(pipe)
  if code == 0 then
    return true, output
  else
    return nil, output
  end
end
local ENV = {}
setmetatable(ENV, {__index = function(_, mod)
  if not file.test(dir .. "/modules/" .. mod .. "/metadata") then
    if lib[mod] then
      return lib[mod]
    else
      return _G[mod]
    end
  end
  return setmetatable({}, {__index = function(_, cmd)
    if not file.test(dir .. "/modules/" .. mod .. "/commands/" .. cmd .. "/script") then
      return fmt.warn("%s: `%s`", "warning: no such valid command in module.\n", cmd)
    end
    return function (a)
      return function (p)
        local c, o = rerun(dir, mod, cmd, a, p)
        if c then
          if args.verbose or (p and next(p) and p.verbose == true) then
            local ln = ""
            for _, l in ipairs(o) do
              if args.cut then l = l:sub(1, 80) end
              ln = string.format("%s | %s \n", ln, l)
            end
            util.echo(ln)
          end
        else
          local err = ""
          for _, l in ipairs(o) do
            if args.cut then l = l:sub(1, 80) end
            err = string.format("%s | %s \n", err, l)
          end
          return fmt.panic("abort: error at %s.%s \"%s\"...\n%s", mod, cmd, a, err)
        end
      end
    end
  end})
end})
do
  local source = file.read_all(args.script)
  if not source then
    return fmt.panic("error: problem reading script '%s'.\n", args.script )
  end
  local chunk, err = loadstring(source)
  if chunk then
    setfenv(chunk, ENV)
    chunk()
    if args.verbose then
      local sec = os.difftime(os.time(), start)
      if sec == 0 then sec = 1 end
      util.echo("Finished run in " .. string.format("%d", sec) .. " second(s)\n")
    end
    return os.exit(0)
  else
    local tbl = {}
    local ln = ""
    for ln in string.gmatch(source, "([^\n]*)\n*") do
      tbl[#tbl + 1] = ln
    end
    local ln = string.match(err, "^.+:([%d]):%s.*")
    local sp = string.rep(" ", string.len(ln))
    local err = string.match(err, "^.+:[%d]:%s(.*)")
    return fmt.panic("error: %s\n%s |\n%s | %s\n%s |\n", err, sp, ln, tbl[tonumber(ln)], sp)
  end
end
