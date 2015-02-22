local Lua = {
  type = type,
  rawset = rawset,
  rawget = rawget,
  loadfile = loadfile,
  pcall = pcall,
  next = next,
  setmetatable = setmetatable,
  load = load,
  pairs = pairs,
  ipairs = ipairs,
  require = require,
  exit = os.exit,
  gsub = string.gsub,
  char = string.char,
  match = string.match,
  find = string.find,
  gmatch = string.gmatch,
  concat = table.concat,
  insert = table.insert,
  len = string.len,
  format = string.format,
  tostring = tostring
}
local Lc = require"cimicida"
local Factid = require"factid"
local Psyslog = require"posix.syslog"
local Pgetopt = require"posix.getopt"
local Psystime = require"posix.sys.time"
local Px = require"px"
local Lib = {}
local ENV = { PATH = "./" }
_ENV = ENV

--[[ Strings ]]
Lib.str = { IDENT = "Configi", ERROR = "ERROR: ", WARN = "WARNING: ", SERR = "POLICY ERROR: ", OPERATION = "Operation" }
local Lstr = Lib.str

-- Logging function for export too
Lib.LOG = function (syslog, file, str, level)
  level = level or Psyslog.LOG_DEBUG
  if syslog then
    return Px.log(file, Lstr.IDENT, str, Psyslog.LOG_NDELAY|Psyslog.LOG_PID, Psyslog.LOG_DAEMON, level)
  elseif not syslog and file then
    return Lc.log(file, Lstr.IDENT, str)
  end
end

--[[ Module internal functions ]]
local Lmod = {}

--[[ Script functions ]]
Lib.script = {}
local Lscript = Lib.script

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
      tbl.parameters[field] = true
    elseif Lc.falsy(v) then
      tbl.parameters[field] = false
    else
      tbl.parameters[field] = v
    end
  end
end

--- Return a function that passes the string argument to syslog() and add it to tbl
-- It calls Lua.format if a C-like argument is passed to the returned function
-- @param T module table (TABLE)
-- @return function (FUNCTION)
function Lmod.dmsg (C)
  return function (item, flag, bool, sec, extra)
    local level, msg
    item = Lua.match(item, "([%S+]+)")
    if flag == true then
      flag = " ok "
      msg = C.messages.repaired
    elseif flag == nil then
      flag = "skip"
      msg = C.messages.kept
    elseif flag == false then
      flag = "fail"
      msg = C.messages.failed
      level = Psyslog.LOG_ERR
    elseif Lua.type(flag) == "string" then
      msg = flag
      if bool == true then
        flag = " ok "
      elseif bool == false then
        level = Psyslog.LOG_ERR
        flag = "fail"
      elseif bool == nil then
        flag = "skip"
      else
        flag = "exit"
      end
    end
    local str
    if sec == nil then
      str = Lua.format([[

 [%s] %s
        Comment: %s
        Item: %s
        %s%s]],
    flag, msg, C.parameters.comment, item or "", extra or "", "\n")
    else
       str = Lua.format([[

 [%s] %s
        Elapsed: %.fs
        %s%s]],
    flag, msg, sec, extra or "", "\n")
    end
    local rs = Lua.char(9)
    local lstr
    sec = sec or ""
    if Lua.len(C.parameters.comment) > 0 then
      lstr = Lua.format("[%s]%s%s%s%s%s%s%s#%s", flag, rs, msg, rs, item, rs, sec, rs, C.parameters.comment)
    else
      lstr = Lua.format("[%s]%s%s%s%s%s%s", flag, rs, msg, rs, item, rs, sec)
    end
    Lib.LOG(C.parameters.syslog, C.parameters.log, lstr, level)
    C.results.msgt[#C.results.msgt + 1] = {
      item = item,
      msg = msg,
      elapsed = sec,
      comment = C.parameters.comment,
      result = flag,
    }
    C.results.msg[#C.results.msg + 1] = str .. "\n"
  end
end

function Lmod.msg (C)
  return function (item, flag, bool)
    local level, msg
    item = Lua.match(item, "([%S+]+)")
    if flag == true then
      flag = " ok "
      msg = C.messages.repaired
    elseif flag == nil then
      flag = "skip"
      msg = C.messages.kept
    elseif flag == false then
      flag = "fail"
      msg = C.messages.failed
      level = Psyslog.LOG_ERR
    elseif Lua.type(flag) == "string" then
      msg = flag
      if bool == true then
        flag = " ok "
      elseif bool == false then
        level = Psyslog.LOG_ERR
        flag = "fail"
      elseif bool == nil then
        flag = "skip"
      else
        flag = "exit"
      end
    end

    local str = Lua.format([[

 [%s] %s
        Item: %s
        Comment: %s
        %s%s]], flag, msg, item, C.parameters.comment, "", "\n")
    local rs = Lua.char(9)
    local lstr
    if Lua.len(C.parameters.comment) > 0 then
      lstr = Lua.format("[%s]%s%s%s%s%s#%s", flag, rs, msg, rs, item, rs, C.parameters.comment)
    else
      lstr = Lua.format("[%s]%s%s%s%s", flag, rs, msg, rs, item)
    end
    Lib.LOG(C.parameters.syslog, C.parameters.log, lstr, level)
    C.results.msgt[#C.results.msgt + 1] = {
      item = item,
      msg = msg,
      comment = C.parameters.comment,
      result = flag
    }
    C.results.msg[#C.results.msg + 1] = str
  end
end

--- Load a string as Lua code under a custom environment
-- The string is a chunk of script code
-- Exit with code 1 if there is an error in the compiled chunk
-- @param T main table (TABLE)
-- @return tail-call to the chunk compilation (TAILCALL)
function Lmod.pload (C)
  local mt = { __index = function (_, k) return
     function (v) C.parameters[k] = Lmod.setvalue(v, k) end
  end }
  Lua.setmetatable(C.environment, mt)
  local chunk, err = Lua.load(C.source, C.source, "t", C.environment)
  if not chunk then
    Lc.errorf("pload: %s %s", Lstr.ERR, err)
  end
  return chunk()
end

--- Check if a required parameter is set.
-- Produce an error (exit code 1) if a required parameter is missing.
-- @param T main table (TABLE)
function Lmod.required (C)
  for n = 1, #C.required do
    if not C.parameters[C.required[n]] then
      Lc.errorf("%s Required parameter '%s' missing.\n", Lstr.SERR, C.required[n])
    end
  end
end

-- Warn (stderr output) if a "module.function" parameter is ignored.
-- @param T main table (TABLE)
function Lmod.ignoredwarn (C)
  for n = 1, #C.required do C.module[#C.module + 1] = C.required[n] end -- add C.required to M
  -- Core parameters are added as valid parameters
  C.module[#C.module + 1] = "comment"
  C.module[#C.module + 1] = "debug"
  C.module[#C.module + 1] = "test"
  C.module[#C.module + 1] = "syslog"
  C.module[#C.module + 1] = "log"
  C.module[#C.module + 1] = "handle"
  C.module[#C.module + 1] = "register"
  C.module[#C.module + 1] = "context"
  C.module[#C.module + 1] = "notify"
  C.module[#C.module + 1] = "notify_failed"
  C.module[#C.module + 1] = "notify_kept"
  -- Now check for any undeclared module parameter
  local Ps = Lc.arr2rec(C.module, 0)
  for param, _ in Lua.pairs(C.parameters) do
    if Ps[param] == nil then
      Lc.warningf("%s Parameter '%s' ignored.\n", Lstr.WARN, param)
    end
  end
end

-- Boiler-plate table
function Lib.start (S, M, G)
  local C = {
              source = S,
              module = M or {},
              messages = G,
              alias = {},
              environment = {},
              functions = {},
              parameters = {},
              required = {},
              results = { repaired = false, failed = false, msg = {}, msgt = {} }
            }
  return C
end

--- Process a promise.
-- 1. Fill environment with functions to assign parameters
-- 2. Load promise chunk
-- 3. Check for required parameter(s)
-- 4. Debugging
-- @return functions table
-- @return parameters table
-- @return results table
function Lib.finish (C)
  -- Process required parameters
  for n = 1, #C.required do
    C.environment[C.required[n]] = Lmod.setvalue(C, C.required[n])
  end
  -- Process valid module parameters
  for n = 1, #C.module do
    C.environment[C.module[n]] = Lmod.setvalue(C, C.module[n])
  end
  -- Process aliases
  if Lua.next(C.alias) then
    for p, v in Lua.pairs(C.alias) do
      for n = 1, #v do
        C.environment[v[n]] = Lmod.setvalue(C, p)
      end
    end
  end
  -- Process core parameters
  C.environment.comment = Lmod.setvalue(C, "comment")
  C.environment.debug = Lmod.setvalue(C, "debug")
  C.environment.test = Lmod.setvalue(C, "test")
  C.environment.syslog = Lmod.setvalue(C, "syslog")
  C.environment.log = Lmod.setvalue(C, "log")
  C.environment.handle = Lmod.setvalue(C, "handle")
  C.environment.register = Lmod.setvalue(C, "register")
  C.environment.context = Lmod.setvalue(C, "context")
  C.environment.notify = Lmod.setvalue(C, "notify")
  C.environment.notify_kept = Lmod.setvalue(C, "notify_kept")
  C.environment.notify_failed = Lmod.setvalue(C, "notify_failed")
  -- Evaluate the promise chunk
  Lmod.pload(C)
  -- Check for required parameters
  Lmod.required(C)
  C.parameters.comment = C.parameters.comment or ""
  -- Return an F.run() depending on debug, test flags
  local msg
  local functime = function (f, ...)
    local t1 = Psystime.gettimeofday()
    local stdout, stderr = "", ""
    local ok, rt = f(...)
    local err = Lc.exitstr(rt.bin, rt.status, rt.code)
    if rt then
      if Lua.type(rt.stdout) == "table" then
        stdout = Lua.concat(rt.stdout, "\n")
      end
      if Lua.type(rt.stderr) == "table" then
        stderr = Lua.concat(rt.stderr, "\n")
      end
    end
    local secs = Px.difftime(Psystime.gettimeofday(), t1)
    secs = Lua.format("%s.%s", Lua.tostring(secs.sec), Lua.tostring(secs.usec))
    msg(Lstr.OPERATION, err, ok or false, secs, Lua.format("stdout:\n%s\n        stderr:\n%s\n", stdout, stderr))
    return ok, rt
  end -- functime()
  if not (C.parameters.test or C.parameters.debug) then
    msg = Lmod.msg(C)
    C.functions.run = function (f, ...)
      local ok, rt = f(...)
      local err = Lc.exitstr(rt.bin, rt.status, rt.code)
      local res = false
      if ok then
        res = true
      end
      msg(Lstr.OPERATION, err, ok, res, 0)
      return ok, rt
    end -- F.run()
  elseif C.parameters.debug or C.parameters.test then
    msg = Lmod.dmsg(C)
    Lmod.ignoredwarn(C) -- Warn for ignored parameters
  end
  if C.parameters.test then
    C.functions.run = function ()
      msg(Lstr.OPERATION, Lua.format("Would execute a corrective operation"), true)
      return true, {stdout={}, stderr={}}, true
    end -- F.run()
    C.functions.xrun = functime -- if you must execute something use F.xrun()
  elseif C.parameters.debug then
    C.functions.run = functime -- functime() is used when debug=true
  end
  C.functions.msg = msg -- Assign msg to F.msg()
  C.functions.result = function (item, test, alt)
    local flag = false
    if test then
      flag = true
      C.results.notify = C.parameters.notify
      C.results.repaired = true
    elseif test == nil then
      flag = nil
      C.results.notify_kept = C.parameters.notify_kept
    else
      C.results.notify_failed = C.parameters.notify_failed
      C.results.failed = true
    end
    if Lua.type(alt) == "string" then
      msg(item, alt, flag)
    else
      msg(item, flag)
    end
    return C.results
  end -- F.result()
  C.functions.kept =  function (item)
    C.results.notify_kept = C.parameters.notify_kept
    msg(item, nil)
    return C.results
  end -- F.kept()
  C.functions.open = function (f)
    if Lua.type(PATH) == "table" then
      f = PATH[f]
    else
      f = Lc.fopen(PATH .. "/" .. f)
    end
    return f
  end
  C.environment, C.required = nil, nil -- GC
  return C.functions, C.parameters, C.results -- F, P, R
end

--- Iterate a table (array) for records.
-- @param tbl table to iterate (TABLE)
-- @return iterator that results in a line terminated field "value" for each record (FUNCTION)
function Lscript.list (tbl)
  if not tbl then
    Lc.errorf("Error: cfg.list: Expected table but got nil.\n")
  end
  local i = 0
  return function ()
    i = i + 1
    if i > #tbl then return nil end
    local str = ""
    local p, v = nil, nil
    while Lua.next(tbl[i]) do
      p, v = Lua.next(tbl[i], p)
      if p == nil then break end
      str = Lua.format("%s%s \"%s\"\n", str, p, v)
    end
    str = Lua.format("%s\n", str)
    return str
  end
end

--- Assign returned value from require() to the custom environment
-- Exit with code 1 if there was an error
-- @param m name of the module (STRING)
-- @return module (TABLE or FUNCTION)
function Lscript.module (m)
  local rb, rm = Lua.pcall(Lua.require, "module." .. m)
  if not rb then
    return Lc.errorf("Module error: %s\n%s\n", m, rm)
  end
  return rm
end

--[[ CLI functions ]]
function Lcli.compile(s, env)
  local chunk, err
  if Lua.type(PATH) == "table" then
    Lc.warningf("HERE")
    if not PATH[s] then
      Lc.errorf("%s %s not found\n", Lstr.SERR, s)
    end
    chunk, err = Lua.load(PATH[s], PATH[s], "t", env)
  else
    if not Lc.isfile(s) then
      Lc.errorf("%s %s not found\n", Lstr.SERR, s)
    end
    chunk, err = Lua.loadfile(s, "t", env)
  end
  if not chunk then
    Lc.errorf("%s%s%s\n", Lstr.ERR, s, err)
  end
  return chunk()
end

function Lcli.main (opts)
  local source = {}
  local hsource = {}
  local runenv = {}
  local scripts = { opts.script }
  local env = { volatile = nil, fact = {}, global = {} }
  local textenv = {} -- used to store variables for interpolation

  -- Built-in functions inside scripts --
  env.pairs = Lua.pairs
  env.ipairs = Lua.ipairs
  env.format = Lua.format
  env.list = Lscript.list
  env.sub = Lc.sub
  env.module = function (m)
    if m == "fact" then
      env.fact = Factid.gather()
    else
      runenv[m] = Lscript.module(m)
    end
  end
  env.debug = function (b) if Lc.truthy(b) then opts.debug = true end end
  env.test = function (b) if Lc.truthy(b) then opts.test = true end end
  env.syslog = function (b) if Lc.truthy(b) then opts.syslog = true end end
  env.log = function (b) opts.log = b end
  env.include = function (f)
    if Lua.type(PATH) == "table" then
      scripts[#scripts + 1] = f
    else
      scripts[#scripts + 1] = PATH .. "/" .. f
    end
  end
  env.each = function (t, f)
    for i in Lscript.list(t) do
      f(i)
    end
  end
  -- Metatable for the script environment
  Lua.setmetatable(env, {
    __newindex = function (_, var, value) -- var = "something"
       -- assign value to var inside env
       Lua.rawset(env, var, value)
       -- store strings and table into the textenv
       local y = Lua.type(value)
       if y == "number" then
         value = Lua.tostring(value)
       end
       if y == "string" or y == "table" then
         textenv[var] = value
       end
    end,
    __index = function (_, mod)
      local tbl = Lua.setmetatable({}, {
      __call = function (_, str) -- func(), no interpolation here
          if Lua.type(str) ~= "string" then
          Lc.errorf("%s bad argument #1 passed to %s()\n", Lstr.SERR, mod)
        end
        source[#source + 1] = { mod = mod, func = false, str = str }
      end, -- func()
      __index = function (_, func) return
        function (str) -- mod.func [[ ]], interpolate strings inside [[ ]]
          local qt = { environment = {}, parameters = {}, source = str }
          local qload = function (q)
            Lua.setmetatable(q.environment, { __index = function (_, k) return
              function (v)
                v = Lc.sub(v, textenv)
                if k == "register" then
                 Lua.rawset(env.global, v, true)
                else
                  q.parameters[k] = v
                end
              end
            end })
            if Lua.type(q.source) ~= "string" then
              Lc.errorf("qload: %s %s\n", Lstr.SERR, "Non-string passed to a promise(function)")
            end
            local chunk, err = Lua.load(q.source, q.source, "t", q.environment)
            if not chunk then
              Lc.errorf("qload: %s %s\n", Lstr.SERR, err)
            end
            return chunk()
          end
          qload(qt)
          -- if context "fact..." matched assign it to env.volatile
          if Lua.pcall(Lua.find, qt.parameters.context, "^fact") then
            local fload = function (s)
              local chunk, err = Lua.load(s, s, "t", env)
                 if not chunk then
                   Lc.errorf("fload: %s %s", Lstr.ERR, err)
                 end
              return chunk()
            end
            -- auto-load the fact module
            if not Lua.next(env.fact) then
              env.fact = Factid.gather()
            end
            fload("volatile=" .. qt.parameters.context)
          end
          if Lua.rawget(env.global, qt.parameters.context) == true or env.volatile == true or not qt.parameters.context then
            env.volatile = nil
            if qt.parameters.handle then
              if hsource[qt.parameters.handle] and (#hsource[qt.parameters.handle] > 0) then
                hsource[qt.parameters.handle][#hsource[qt.parameters.handle] + 1] = { mod = mod, func = func, str = str }
              else
                hsource[qt.parameters.handle] = {}
                hsource[qt.parameters.handle][#hsource[qt.parameters.handle] + 1] = { mod = mod, func = func, str = str }
              end
            elseif Lua.type(str) == "string" then
              -- interpolate before adding to the 'source' queue
              str = Lc.sub(str, textenv)
              source[#source + 1] = {mod = mod, func = func, str = str}
            end
          end -- context
        end -- mod.func [[ ]]
      end }) -- __index = function (_, func) return
      return tbl
    end -- __index = function (_, mod)
  })

  -- scripts queue
  local i, temp, htemp = 0, nil, nil
  while Lua.next(scripts) do
    i = i + 1
    temp, htemp = source, hsource
    source, hsource = {}, {}
    Lcli.compile(scripts[Lua.next(scripts)], env)
    scripts[i] = nil
    -- main queue
    for n = 1, #temp do
      source[#source + 1] = temp[n]
    end
    -- handlers queue
    for t, _ in Lua.pairs(htemp) do
      for n = 1, #htemp[t] do
        if hsource[t] and Lua.next(hsource[t]) then
          hsource[t][#hsource[t] + 1] = htemp[t][n]
        else
          hsource[t] = {}
          hsource[t][#hsource[t] + 1] = htemp[t][n]
        end
      end
    end
    temp, htemp = {}, {}
  end
  source.debug, source.test, source.log, source.syslog, source.msg =
  opts.debug, opts.test, opts.log, opts.syslog, opts.msg
  hsource[1], hsource[2], hsource[3], hsource[4] =
    opts.debug, opts.test, opts.syslog, opts.log -- source.msg already handles the msg output
  scripts, textenv, env = nil, nil, nil -- GC
  return source, hsource, runenv
end

function Lcli.opt (arg, version)
  local short = "hvtDsmjVl:p:g:r:f:"
  local long = {
    {"help", "none", "h"},
    {"debug", "none", "v"},
    {"test", "none", "t"},
    {"daemon", "none", "D"},
    {"periodic", "none", "p"},
    {"syslog", "none", "s"},
    {"log", "required", "l"},
    {"msg", "none", "m"},
    {"version", "none", "V"},
    {"tag", "required", "g"},
    {"runs", "required", "r"},
    {"file", "required", "f"}
  }
  local help = [[
  cfg [-h] [-V] [-v] [-t] [-D] [-p N] [-s] [-l FILE] [-m] [-g TAG] [-r N] -f "CONFIGI POLICY"

    Options:
      -h, --help          This help text.
      -V, --version       Print version.
      -v, --debug         Turn on debugging messages.
      -t, --test          Dry-run mode. All operations are expected to succeed. Turns on debugging.
      -D, --daemon        Daemon mode. Watch for IN_MODIFY and IN_ATTRIB events to the policy file.
      -p, --periodic      Do a run after N seconds.
      -s, --syslog        Enable logging to syslog.
      -l, --log           Log to an specified file.
      -m, --msg           Show debug and test messages.
      -g, --tag           Only run specified tag(s).
      -r, --runs          Run the policy N times if a failure is encountered. Default is 3.
      -f, --file          Path to the Configi policy.

]]
  -- Defaults. runs field is always used
  local opts = { runs = 3, _periodic = "300" }
  local tags = {}
  -- optind and li are unused
  for r, optarg, optind, li in Pgetopt.getopt(arg, short, long) do
    if r == "f" then
      opts.script = optarg
      local _, policy = Lua.pcall(Lua.require, "policy")
      if not Px.isfile(opts.script) and Lua.type(policy) == "table" then
        PATH = policy
      else
        PATH = Lc.splitp(opts.script)
      end
    end
    if r == "m" then opts.msg = true end
    if r == "v" then opts.debug = true end
    if r == "t" then opts.test = true end
    if r == "s" then opts.syslog = true end
    if r == "r" then opts.runs = optarg or opts._runs end
    if r == "l" then opts.log = optarg end
    if r == "?" then return Lc.errorf("Error: Unrecognized option passed\n") end
    if r == "p" then opts.periodic = optarg or opts._periodic end
    if r == "D" then opts.daemon = true end
    if r == "g" then
      for tag in Lua.gmatch(optarg, "([%w_]+)") do
        tags[#tags + 1] = tag
      end
    end
    if r == "h" then
      Lc.printf("%s", help)
      Lua.exit(0)
    end
    if r == "V" then
      Lc.printf("%s\n", version)
      Lua.exit(0)
    end
  end
  if not opts.script then
    Lc.errorf("%s", help)
  end
  if opts.debug then
    Lc.printf("Started run %s\n", Lc.timestamp())
    Lc.printf("Running script: %s\n", opts.script)
  end
  local source, hsource, runenv = Lcli.main(opts) -- arg[index]
  source.runs, source.tags = opts.runs, tags
  return source, hsource, runenv, opts
end

function Lcli.run (source, runenv) -- execution step
  local rt = {}
  for i, s in Lua.ipairs(source) do
    if runenv[s.mod] == nil then
      -- auto-load the module
      runenv[s.mod] = Lscript.module(s.mod)
    end
    local mod, func, str = runenv[s.mod], s.func, s.str
    -- append debug and test arguments
    if source.debug == true then
      str = Lc.appendln(str, "debug(true)")
    end
    if source.test == true then
      str = Lc.appendln(str, "test(true)")
    end
    if source.syslog == true then
      str = Lc.appendln(str, "syslog(true)")
    end
    if source.log then
      str = Lc.appendln(str, [[log"]] .. source.log .. [["]])
    end
    if not func then
      if not mod then
        Lc.errorf("Module error: '%s' not found\n", s.mod)
      end
      rt[i] = mod(str)
    else
      if not mod[func] then
        Lc.errorf("Module error: function '%s' in module '%s' not found\n", s.func, s.mod)
      end
      rt[i] = mod[func](str)
    end -- if not a module.function
  end -- for each line
  return rt
end

function Lcli.hrun (hsource, tag, runenv) -- execution step for handlers
  local mod, func, str, r = nil, nil, nil, {}
  if hsource[tag] then
    for n = 1, #hsource[tag] do
      if runenv[hsource[tag][n].mod] == nil then
        -- auto-load the module
        runenv[hsource[tag][n].mod] = Lscript.module(hsource[tag][n].mod)
      end
      mod, func, str = runenv[hsource[tag][n].mod], hsource[tag][n].func, hsource[tag][n].str
      -- append debug and test arguments
      if hsource[1] == true then
        str = Lc.appendln(str, "debug(true)")
      end
      if hsource[2] == true then
        str = Lc.appendln(str, "test(true)")
      end
      if hsource[3] == true then
        str = Lc.appendln(str, "syslog(true)")
      end
      if hsource[4] then
        str = Lc.appendln(str, [[log"]] .. hsource[4] .. [["]])
      end
      if not func then
        r[#r + 1] = mod(str)
      elseif not mod[func] then
        Lc.errorf("Module error: function in module not found\n")
      end
      r[#r + 1] = mod[func](str)
    end -- for each tag
  end -- if a tag
  return r
end

function Lcli.try (source, hsource, runenv)
  local M, results, R = {}, nil, { repaired = false, failed = false, repaired = false, kept = false }
  local notify, handlers = nil, {}
  for this = 1, source.runs do
    if this > 1 and (source.debug or source.test or source.msg) then
      Lc.printf("-- Retry #%.f\n", this - 1)
    end
    if #source.tags == 0 then
      -- Run and collect results into the results table
      results = Lcli.run(source, runenv)
      -- Go over the results from the execution
      for _, result in Lua.ipairs(results) do
        -- immediately set the flags on the final results table
        if result.repaired == true then
          R.repaired = true
          R.failed = false
        end
        if result.failed == true then
          R.failed = true
        end
        -- if P.notify is set, run the corresponding handlers and append the results.
        notify = result.notify or result.notify_failed or result.notify_kept -- notify on one flag only
        if notify then
          handlers[notify] = true -- toggle handle "$tag"
        end
        -- read the T.results.msg table if debugging is on or the last result failed
        if (result.failed or source.debug or source.test or source.msg) and result.msg then
          for ni = 1, #result.msg do
            Lc.warningf("%s\n", result.msg[ni])
          end
        end
      end -- for each result
    else
      -- handle/tags mode `cfg -g`
      for n = 1, #source.tags do
        handlers[source.tags[n]] = true
      end
    end

    -- Run handlers
    if Lua.next(handlers) then
      for handler, _ in Lua.pairs(handlers) do
        for _, rh in Lua.ipairs(Lcli.hrun(hsource, handler, runenv)) do
          if rh.repaired == true then
            R.repaired = true
            R.failed = false
          else
            R.failed = rh.failed
	        end -- if repaired
          if (rh.failed or source.debug or source.test or source.msg) and rh.msg then
            for ni = 1, #rh.msg do
              Lc.warningf("%s\n", rh.msg[ni])
            end -- for handler messages
          end  -- if failed or debug
        end -- for each handler run
      end -- for each handlers
    end -- if handlers
    if R.failed == false then
      return R, M
    end
  end -- for each run
  return R, M
end

return Lib

