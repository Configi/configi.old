local start = os.time()
local argparse = require "argparse"
local parser = argparse("cfg", "Configi. A wrapper to rerun, for lightweight configuration management.")
parser:argument("script", "Script to load.")
parser:flag("-v --verbose", "Verbose output.")
parser:flag("-t --cut", "Truncate verbose or error output to 80 columns.")
local args = parser:parse()
local lib = require "lib"
local exec = require "exec"
local string, fmt, file, path, util = lib.string, lib.fmt, lib.file, lib.path, lib.util
if args.verbose then util.echo "Start Configi run...\n" end
if file.test(args.script) == nil then
  return fmt.panic("abort: \"%s\" not found.\n", args.script)
end
local dir = path.split(args.script)
package.path = dir
if dir == "" then dir = "." end
local rerun = function(dir, mod, cmd, a, params)
  local rpath = "/usr/local/bin/rerun"
  if not file.test(rpath) then
    file.write_all(rpath, require("rerun"))
    os.execute("chmod +x " .. rpath)
  end
  local t = {"-M", "./modules", mod..":"..cmd, "--arg", a}
  if params and next(params) then
    for o, p in pairs(params) do
      t[#t+1] = "--" .. o
      t[#t+1] = p
    end
  end
  return exec.spawn(rpath, t, {LC_ALL="C"}, dir, nil, nil, nil, true)
end
local printer = function(o, mod, cmd, a)
  if o.code == 0 then fmt.print("[PASS] %s.%s \"%s\"\n", mod, cmd, a) end
  if o.code == 113 then fmt.print("[REPAIRED] %s.%s \"%s\"\n", mod, cmd, a) end
  if o.code == 1 then fmt.print("[FAIL] %s.%s \"%s\"\n", mod, cmd, a) end
  if o.stdout[1] then
    util.echo"stdout\n"
    local ln = ""
    for _, l in ipairs(o.stdout) do
      if args.cut then l = l:sub(1, 80) end
      ln = string.format("%s | %s \n", ln, l)
    end
    util.echo(ln)
  end
  if o.stderr[1] then
    util.echo"stderr\n"
    ln = ""
    for _, l in ipairs(o.stderr) do
      if args.cut then l = l:sub(1, 80) end
        ln = string.format("%s | %s \n", ln, l)
      end
    util.echo(ln)
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
            printer(o, mod, cmd, a)
          end
        else
          printer(o, mod, cmd, a)
          local err = o.err or ""
          return fmt.panic("abort: failure at %s.%s \"%s\"...\ncode: %s\nerror: %s\n", mod, cmd, a, o.code, err)
        end
        if p.register then
          if ENV[p.register] then
            return fmt.panic("abort: failure at %s.%s \"%s\"...\nerror: attempted to overwrite existing registered variable: \"%s\"\n",
              mod, cmd, a, p.register)
          else
            ENV[p.register] = o.stdout[#o.stdout]
          end
        end
      end
    end
  end})
end})
do
  local source = file.read_all(args.script)
  if not source then return fmt.panic("error: problem reading script '%s'.\n", args.script) end
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
    local src = io.open(args.script)
    for ln in src:lines() do
      tbl[#tbl + 1] = ln
    end
    local ln = string.match(err, "^.+:([%d]+):%s.*")
    local sp = string.rep(" ", string.len(ln))
    local err = string.match(err, "^.+:[%d]+:%s(.*)")
    return fmt.panic("error: %s\n%s |\n%s | %s\n%s |\n", err, sp, ln, tbl[tonumber(ln)], sp)
  end
end
