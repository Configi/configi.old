local type, rawset, loadfile, require, pcall, next, select, setmetatable, load, pairs, ipairs =
      type, rawset, loadfile, require, pcall, next, select, setmetatable, load, pairs, ipairs
local time, difftime, exit, gsub, char, match = os.time, os.difftime, os.exit, string.gsub, string.char, string.match
local Lc = require"cimicida"
local Posix = require"posix"
local Lustache = require"lustache"
local ENV = {} ;_ENV = ENV
local Lib = {}

--[[ Strings ]]
Lib.string = { ERROR = "ERROR: ", WARN = "WARNING: ", SERR = "SCRIPT ERROR: ", }
local Lstr = Lib.string

--[[ Module internal functions ]]
local Lmod = {}

----[[ Module functions ]]
Lib.configi = {}
local Lconfigi = Lib.configi

--[[ Script functions ]]
Lib.script = {}
local Lscript = Lib.script
Lscript.subit = Lc.subit -- copied function

--[[ Cli functions ]]
Lib.cli = {}
local Lcli = Lib.cli

-- Set value of a specified field in a parameter record.
-- Returns a function that converts strings yes, true and True to boolean true
-- Values no, false and False to boolean false
-- Other strings are set directly as the value
-- @param tbl table to operate on (TABLE)
-- @param field record field name to set the value (FIELD)
-- @return function that sets the value (FUNCTION)
function Lmod.setvalue (tbl, field)
  return function (v)
    if Lc.truthy(v) then
      tbl[field] = true
    elseif
      Lc.falsy(v) then tbl[field] = false
    else
      tbl[field] = v
    end
  end
end

--- Return a function that passes the string argument to syslog() and add it to tbl
-- It calls Lc.strf if a C-like argument is passed to the returned function
-- @param T module table (TABLE)
-- @return function (FUNCTION)
function Lmod.dmsg (C)
  local rs = char(30)
  return function (item, msg, bool, sec)
    sec = sec or 0
    Posix.openlog("Configi")
    item = match(item, "([%S+]+)")
    if bool == true then
      bool = "ok"
    elseif bool == false then
      bool = "fail"
    end
    local str = Lc.strf(" [%s]%s %s%s %s%s '%s'%s '%s'%s '%.fs'",
      bool, rs, C.module.name, rs, C.module.func, rs, msg, rs, item, rs, sec)
    Posix.syslog(6, str)
    C.results.msg[#C.results.msg + 1] = str
  end
end

function Lmod.msg (C)
  return function (item, msg, bool)
    item = match(item, "([%S+]+)")
    if bool == true then
      bool = "ok"
    elseif bool == false
      then bool = "fail"
    end
    local str = Lc.strf("Argument: '%s' Operation: [%s] Result: [%s]", item, msg, bool)
    C.results.msg[#C.results.msg + 1] = str
  end
end

function Lmod.run (f, ...)
  return f(...), 0
end

function Lmod.noop (C)
  return function ()
    return true, Lc.strf("Would execute corrective step for %s", C.module.func), 0
  end
end

function Lmod.results (C)
  return function (v)
    if v == true then
      C.changed = true
    else
      C.failed = true
    end
    return C
  end
end

function Lmod.time(f, ...)
  local t1 = time()
  local ok, err = f(...)
  return ok, err, (difftime(time() , t1))
end

--- Load a string as Lua code under a custom environment
-- The string is a chunk of script code
-- Exit with code 1 if there is an error in the compiled chunk
-- @param T main table (TABLE)
-- @return tail-call to the chunk compilation (TAILCALL)
function Lmod.tload (C)
  local mt = { __index = function (_, k) return
     function (v) C.parameters[k] = Lmod.setvalue(v, k) end
  end }
  setmetatable(C.environment, mt)
  local chunk, err = load(C.source, C.source, "t", C.environment)
  if not chunk then
    Lc.errorf("%s %s", Lstr.SERR, err)
  end
  return chunk()
end

--- Check if a required parameter is set.
-- Produce an error (exit code 1) if a required parameter is missing.
-- @param T main table (TABLE)
function Lmod.required (C)
  for n = 1, #C.required do
    if not C.parameters[C.required[n]] then
      Lc.errorf("%s Required parameter '%s' missing.", Lstr.SERR, C.required[n])
    end
  end
end

-- Warn (stderr output) if a "module.function" parameter is ignored.
-- @param T main table (TABLE)
function Lmod.ignoredwarn (C)
  for n = 1, #C.required do C.module[#C.module + 1] = C.required[n] end -- add C.required to M
  C.module[#C.module + 1] = "comment"
  C.module[#C.module + 1] = "debug"
  C.module[#C.module + 1] = "test"
  local Ps = Lc.arr2rec(C.module, 0)
  for param, _ in pairs(C.parameters) do
    if Ps[param] == nil then
      Lc.warningf("%s[%s %s] Parameter '%s' ignored.", Lstr.WARN, C.module.name, C.module.func, param)
    end
  end
end

-- Boiler-plate table
function Lconfigi.start (M, S)
  local C = {
              alias = {},
              environment = {},
              functions = {},
              module = M or {},
              parameters = {},
              required = {},
              results = { changed = false, failed = false, msg = {} },
              source = S,
              valid = {}
            }
  return C, C.functions
end

--- Process script.
-- 1. Fill environment with functions to assign parameters
-- 2. Load script
-- 3. Check for required parameter(s)
-- 4. Debugging
-- @return functions table
-- @return parameters table
-- @return results table
function Lconfigi.finish (C)
  for n = 1, #C.required do C.environment[C.required[n]] = Lmod.setvalue(C.parameters, C.required[n]) end
  for n = 1, #C.valid do C.environment[C.valid[n]] = Lmod.setvalue(C.parameters, C.valid[n]) end
  if next(C.alias) then
    for p, v in pairs(C.alias) do
      for n = 1, #v do C.environment[v[n]] = Lmod.setvalue(C.parameters, p) end
    end
  end
  C.environment.debug = Lmod.setvalue(C.parameters, "debug")
  C.environment.comment = Lmod.setvalue(C.parameters, "comment")
  C.environment.test = Lmod.setvalue(C.parameters, "test")
  Lmod.tload(C)
  Lmod.required(C)
  if not (C.parameters.test or C.parameters.debug) then
    C.functions.run = Lmod.run
    C.functions.msg = Lmod.msg(C)
  elseif C.parameters.debug or C.parameters.test then
    local debug = require"debug"
    local info = debug.getinfo(2, "S")
    C.module.name = info.short_src
    C.module.func = match(Lc.getln(info.linedefined, info.short_src), "function%s([%S]+)[%s]?%(")
    Lmod.ignoredwarn(C)
    C.functions.msg = Lmod.dmsg(C)
  end
  if C.parameters.test then
    C.functions.run = Lmod.noop(C)
  elseif C.parameters.debug then
    C.functions.run = Lmod.time
  end
  C.environment, C.required, C.valid = nil, nil, nil -- GC
  return C.functions, C.parameters, C.results
end

--- Iterate a table (array) for records.
-- @param tbl table to iterate (TABLE)
-- @return iterator that results in a line terminated field "value" for each record (FUNCTION)
function Lscript.list (tbl)
  if not tbl then
    Lc.errorf("Error: nil table passed to List.")
  end
  local i = 0
  return function ()
    i = i + 1
    if i > #tbl then return nil end
    local str = ""
    local p, v = nil, nil
    while next(tbl[i]) do
      p, v = next(tbl[i], p)
      if p == nil then break end
      str = Lc.strf("%s%s \"%s\"\n", str, p, v)
    end
    str = Lc.strf("%s\n", str)
    return str
  end
end

--- Iterate a table (array) for records.
-- @param tbl table to iterate (TABLE)
-- @return iterator that results in a line terminated field "value" for each record (FUNCTION)
function Lscript.llist (tbl)
  if not tbl then
    Lc.errorf("Error: nil table passed to List.")
  end
  local i = 0
  return function ()
    i = i + 1
    if i > #tbl then return nil end
    local str = ""
    local p, v = nil, nil
    while next(tbl[i]) do
      p, v = next(tbl[i], p)
      if p == nil then break end
      str = Lc.strf("%s%s \"%s\"\n", str, p, v)
    end
    str = Lc.strf("%s\n", str)
    return str
  end
end

--- Assign returned value from require() to the custom environment
-- Exit with code 1 if there was an error
-- @param m name of the module (STRING)
-- @return module (TABLE or FUNCTION)
function Lscript.module (m)
  local rb, rm = pcall(require, m)
  if not rb then
    return Lc.errorf("Lmod.error: %s\n%s", m, rm)
  end
  return rm
end


--[[ CLI functions ]]
function Lcli.compile(s, env)
  if not Lc.isfile(s) then
    Lc.errorf("Script error: %s not found", s)
  end
  local chunk, err = loadfile(s, "t", env)
  if not chunk then
    Lc.errorf("%s%s%s", Lstr.ERR, s, err)
  end
  return chunk()
end

function Lcli.main (script, debug, test)
  local source = {}
  local runenv = {}
  local scripts = { script }
  local env = {}
  local tenv = {}

  -- Built-in functions inside scripts --
  env.pairs, env.ipairs = pairs, ipairs
  env.cfg = Lscript
  env.module = function (m) runenv[m] = Lscript.module(m) end
  env.debug = function (b) if Lc.truthy(b) then debug = true end end
  env.test = function (b) if Lc.truthy(b) then test = true end end
  env.include = function (f) scripts[#scripts + 1] = f end

  -- Metatable for the script environment
  setmetatable(env, {
    __newindex = function (_, var, value)
       rawset(env, var, value)
       tenv[var] = value
    end,
    __index = function (_, mod)
      local tbl = setmetatable({}, {
      __call = function (_, str)
        if type(str) ~= "string" then
          Lc.errorf("%s bad argument #1 passed to %s.%s()", Lstr.SERR, mod, func)
        end
        str = Lustache:render(str, tenv)
        source[#source + 1] = {mod = mod, func = false, str = str }
      end,
      __index = function (_, func) return
        function (str)
          if type(str) ~= "string" then
            Lc.errorf("%s bad argument #1 passed to %s.%s()", Lstr.SERR, mod, func)
          end
          str = Lustache:render(str, tenv)
          source[#source + 1] = {mod = mod, func = func, str = str}
        end
      end })
    return tbl
    end
  })

  -- FIFO scripts queue
  local i, temp = 0, nil
  while next(scripts) do
    i = i + 1
    temp = source
    source = {}
    Lcli.compile(scripts[next(scripts)], env)
    scripts[i] = nil
    --for _, n in ipairs(temp) do source[#source + 1] = n end
    for n = 1, #temp do
      source[#source + 1] = temp[n]
    end
    temp = {}
  end
  --[[ Only enable this during debugging.
  if debug or test then
    for _, src in ipairs(source) do
      for k, v in pairs(src) do
        v = gsub(v, "^(%s+)(%w+[%w%p%s%C]*)\n%s*", "\n%1%2")
        Lc.printf("%s: %s\n", k, v) end
    end
  end
  --]]
  source.debug, source.test = debug, test
  scripts, tenv, env, debug, test = nil, nil, nil, nil, nil -- GC
  return source, runenv
end

function Lcli.opt (arg, version)
  local index = 1
  local short = "hdtvmr:f:"
  local long = {
    {"help", "none", "h"},
    {"debug", "none", "d"},
    {"test", "none", "t"},
    {"runs", "required", "r"},
    {"file", "required", "f"},
    {"version", "none", "v"},
    {"msg", "none", "m"}
  }
  local help = [[
  cfg [-h] [-d] [-t] [-r N] -f "CONFIGI SCRIPT"

    Options:
      -h, --help          This help text.
      -v, --version       Print version.
      -d, --debug         Turn on debugging messages.
      -t, --test          Dry-run mode. All operations are expected to succeed. Turns on debugging.
      -r, --runs          Run the script N times if a failure is encountered. Default is 3.
      -f, --file          Configi script to run.
      -m, --msg           Show debug and test messages.
  ]]
  local script, debug, test
  local runs = 3
  for r, optarg, optind, li in Posix.getopt(arg, short, long) do
    if r == "f" then script = optarg end
    if r == "m" then msg = true end
    if r == "d" then debug = true end
    if r == "t" then test = true end
    if r == "r" then runs = optarg end
    if r == "?" then return Lc.errorf("Error: Unrecognized option passed") end
    if r == "h" then
      Lc.printf("%s", help)
      exit(0)
    end
    if r == "v" then
      Lc.printf("%s\n", version)
      exit(0)
    end
    -- index = optind
  end
  if not script then
    Lc.errorf("%s", help)
  end
  Lc.printf("Started run %s\n", Lc.timestamp())
  Lc.printf("Running script: %s\n", script)
  local source, runenv = Lcli.main(script, debug, test) -- arg[index]
  source.debug = debug
  source.msg = msg
  source.test = test
  return source, runenv, runs
end

function Lcli.run (source, runenv) -- execution step
  local rt = {}
  for i, s in ipairs(source) do
    local mod, func, str = runenv[s.mod], s.func, s.str
    -- append debug and test arguments
    if source.debug == true then
      str = Lc.strf("%s\n%s", str, "debug(true)")
    end
    if source.test == true then
      str = Lc.strf("%s\n%s", str, "test(true)")
    end
    if not func then
      if not mod then
        Lc.errorf("Module error: '%s' not found", s.mod)
      end
      rt[i] = mod(str)
    else
      if not mod[func] then
        Lc.errorf("Module error: function '%s' in module '%s' not found", s.func, s.mod)
      end
      rt[i] = mod[func](str)
    end
  end
  return rt
end

function Lcli.try (source, runenv, runs)
  local rt, R = {}, { changed = false, failed = false, repaired = false, kept = false }
  for this = 1, runs do
    if this > 1 then
      Lc.printf("-- Retry #%.f\n", this - 1)
    end
    rt = Lcli.run(source, runenv)
    for n = 1, #rt do
      -- immediately set the flags on the final results table
      if rt[n].changed == true then
        R.changed = true
      end
      if rt[n].failed == true then
        R.failed = true
      end
      -- read the T.results.msg table if debugging is on or the last result failed
      if source.debug or source.test or source.msg or rt[n].failed then
        for ni = 1, #rt[n].msg do
          Lc.warningf("%s", rt[n].msg[ni])
        end
      end
    end
    if R.failed == false then
      return R
    end
  end
  return R
end

return Lib
