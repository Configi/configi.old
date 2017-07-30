local rawget, type, pcall, next, setmetatable, load, pairs, ipairs, require =
  rawget, type, pcall, next, setmetatable, load, pairs, ipairs, require
local package, coroutine = package, coroutine
local cli, functions = {}, {}
local factid = require"factid"
local args = require"cfg-core.args"
if args["F"] then
  package.loaded["cfg-core.fact"] = factid.gather()
end
local strings = require"cfg-core.strings"
local std = require"cfg-core.std"
local lib = require"lib"
local path, fmt, os, string, file, time = lib.path, lib.fmt, lib.os, lib.string, lib.file, lib.time
local tsort = require"tsort"
local ep_found, policy = pcall(require, "cfg-policy")
local cpath = std.path()
package.path = "./?.lua;"..cpath.."/?.lua;"..cpath.."/?.lua;"..cpath.."/?"
_ENV = nil

--- Assign returned value from require() to the custom environment
-- Exit with code 1 if there was an error
-- @param m name of the module (STRING)
-- @return module (TABLE or FUNCTION)
function functions.module (m, roles)
  if roles then
    for _, role in ipairs(roles) do
      package.path = std.add_to_path(package.path, cpath, role)
    end
  end
  -- Try custom modules in the arg path .. "/modules" directory first.
  local rb, rm = pcall(require, "modules." .. m)
  if not rb then
    rb, rm = pcall(require, "cfg-modules." .. m)
    if not rb then
      return fmt.panic("%s%s\n%s\n", strings.MERR, m, rm)
    end
  end
  return rm
end

function cli.compile(s, env)
  local chunk, err, script
  local p, base, _ = path.decompose(s)
  if os.is_file(s) then
    script = file.read_to_string(s)
  elseif args["e"] then
    script = policy[p][base]
  end
  if not script then
    fmt.panic("%s%s\n", strings.SERR, "Unable to load policy.")
  end
  chunk, err = load(script, script, "t", env)
  if not chunk then
    fmt.panic("%s%s%s\n", strings.SERR, s, err)
  end
  return chunk()
end

function cli.main (opts)
  local source = {}
  local hsource = {}
  local runenv = {}
  local roles = {}
  local scripts = { [1] = opts.script }
  local env
  if args["F"] then
    env = { fact = package.loaded["cfg-core.fact"] }
  else
    env = {}
  end

  -- Built-in functions inside scripts --
  env.roles = function(r)
    for _, role in ipairs(r) do
      roles[#roles+1] = role
    end
  end
  env.pairs = pairs
  env.ipairs = ipairs
  env.format = string.format
  env._ = function (str)
    return string.template(str, env)
  end
  env.module = function (m)
    runenv[m] = functions.module(m, roles)
  end
  env.each = function (t, f)
    for str, tbl in pairs(t) do
      f(str)(tbl)
    end
  end
  -- Metatable for the script environment
  setmetatable(env, {
    __index = function (_, mod)
      local null
      if rawget(env, mod) == nil then
        null = mod
      end
      local tbl = setmetatable({}, {
        __index = function (_, func)
          return function (promiser)
            return function (ptbl) -- mod.func
              ptbl = ptbl or {}
              local tag = ptbl.handle
              local rs = strings.rs
              local is_string = (type(promiser) == "string")
              if not is_string then
                fmt.warn("%sIgnoring promise. \"%s\" is not set, passed to %s.%s()\n",
                  strings.WARN, null, mod, func)
              end
              if (ptbl.context == true or (ptbl.context == nil)) and is_string then
                if not ptbl.handle then
                  source[#source + 1] = { res = mod..rs..func..rs..promiser,
                    mod = mod, func = func, promiser = promiser, param = ptbl }
                else
                  if hsource[tag] and (#hsource[tag] > 0) then
                    hsource[tag][#hsource[tag] + 1] =
                    { mod = mod, func = func, promiser = promiser, param = ptbl }
                  else
                    hsource[tag] = {}
                    hsource[tag][#hsource[tag] + 1] =
                    { mod = mod, func = func, promiser = promiser, param = ptbl }
                  end
                end
              end -- context
            end -- mod.func
          end -- function (promiser)
        end }) -- __index = function (_, func)
      return tbl
    end -- __index = function (_, mod)
  })

  if args["e"] then
    scripts = std.add_from_embedded(scripts, policy)
  end
  cli.compile(scripts[1], env)
  -- We should only populate roles.
  scripts = std.add_from_dirs(scripts, cpath)
  if #roles > 0 then
    for _, role in ipairs(roles) do
      scripts = std.add_from_role(scripts, cpath, role)
      package.loaded["cfg-core.roles"] = roles
    end
  end
  -- scripts queue
  local i = 0
  local temp, htemp
  source, hsource = {}, {}
  while next(scripts) do
    i = i + 1
    -- Should be a reference. Copying does not work.
    temp, htemp = source, hsource
    cli.compile(scripts[i], env)
    scripts[i] = nil
    -- Main queue
    -- Should be new empty tables. Clearing does not work.
    source, hsource = {}, {}
    for n = 1, #temp do
      source[#source + 1] = temp[n]
    end
    -- Handlers queue
    for t, _ in next, htemp do
      for n = 1, #htemp[t] do
        if hsource[t] and next(hsource[t]) then
          hsource[t][#hsource[t] + 1] = htemp[t][n]
        else
          hsource[t] = {}
          hsource[t][#hsource[t] + 1] = htemp[t][n]
        end

      end
    end
  end
  local graph = tsort.new()
  do -- Create the DAG
     for n = #source, 1, -1 do
      local req = source[n].param.require
      local bef = source[n].param.before
      if not req and not bef then
        if not (n == 1) and not (source[n-1].param.require) and not (source[n-1].param.before) then
          graph:add{source[n-1], source[n]}
        else
          graph:add{source[n]}
        end
      else
        local e = {}
        local rs = strings.rs
        setmetatable(e, {
          __index = function(_, mod)
            local t = setmetatable({}, {
              __index=function(_,fn)
                return function(subj)
                  return mod..rs..fn..rs..subj
                end
              end
            })
            return t
          end
        })
        if req then
          req = "R="..req
        else
          req = "R=''"
        end
        if bef then
          bef = "B="..bef
        else
          bef = "B=''"
        end
        local code = req..";"..bef
        local run, err = load(code, code, "t", e)
        if run then
          run()
        else
          fmt.panic("%s %s %s\n", strings.SERR, opts.script, err)
        end
        req = e.R
        bef = e.B
        for x = 1, #source do
          if source[x].res == req then
            graph:add{source[x], source[n]}
          end
          if source[x].res == bef then
            graph:add{source[n], source[x]}
          end
        end
      end
    end
  end
  local sorted, tsort_err = graph:sort()
  if not sorted then
    fmt.panic("%s %s %s\n", strings.SERR, opts.script, tsort_err)
  end
  return sorted, hsource, runenv
end

function cli.opt (version)
  -- Defaults. runs field is always used
  local opts = { runs = 3, _periodic = "300" }
  if args["f"] then
    local dir, base, ext = path.decompose(args["f"])
    opts.script = dir.."/"..base.."."..ext
  end
  if args["e"] then
    if not ep_found then
      fmt.panic("%s %s\n", strings.ERROR, "Missing embedded policy")
    end
    local _, base, ext = path.decompose(args["e"])
    -- policy["."][base]
    if not ext then
      fmt.panic("%s %s\n", strings.ERROR, "Missing .lua extension?")
    end
    opts.script = base.."."..ext
  end
  if args["m"] then opts.msg = true end
  if args["v"] then opts.debug = true end
  if args["t"] then opts.test = true end
  if args["s"] then opts.syslog = true end
  if args["r"] then opts.runs = args["r"] or opts._runs end
  if args["l"] then opts.log = args["l"] end
  if args["?"] then return fmt.panic("%sUnrecognized option passed\n", strings.ERR) end
  if args["p"] then opts.periodic = args["p"] or opts._periodic end
  if args["w"] then opts.watch = true end
  local tags = {}
  if args["g"] then
    for tag in string.gmatch(args["g"], "([%w_]+)") do
      tags[#tags + 1] = tag
    end
  end
  if args["h"] then
    fmt.print("%s", strings.help)
    os.exit(0)
  end
  if args["V"] then
    fmt.print("%s\n", version)
    os.exit(0)
  end
  if not opts.script then
    fmt.panic("%s", strings.help)
  end
  if opts.debug then
    fmt.print("Started run %s\n", time.stamp())
    fmt.print("Applying policy: %s\n", opts.script)
  end
  local source, hsource, runenv = cli.main(opts) -- arg[index]
  source.runs = opts.runs
  source.tags = tags
  return source, hsource, runenv, opts
end

function cli.run (source, runenv) -- execution step
  local rt = {}
  if #source == 0 then
    return {}
  end
  for i, s in ipairs(source) do
    if runenv[s.mod] == nil then
      -- auto-load the module
      runenv[s.mod] = functions.module(s.mod)
    end
    local mod, func, promiser, param = runenv[s.mod], s.func, s.promiser, s.param
    if not mod[func] then
      fmt.panic("%sfunction '%s' in module '%s' not found\n", strings.MERR, func, mod)
    end
    rt[i] = mod[func](promiser)(param)
  end -- for each line
  return rt
end

function cli.hrun (tags, hsource, runenv) -- execution step for handlers
  for tag, _ in next, tags do
    local r, mod, func, promiser, param = {}
    if hsource[tag] then
      for n = 1, #hsource[tag] do
        if runenv[hsource[tag][n].mod] == nil then
          -- auto-load the module
          runenv[hsource[tag][n].mod] = functions.module(hsource[tag][n].mod)
        end
        mod, func, promiser, param = runenv[hsource[tag][n].mod],
          hsource[tag][n].func,
          hsource[tag][n].promiser,
          hsource[tag][n].param
        if not mod[func] then
          fmt.panic("%sfunction '%s' in module '%s' not found\n", strings.MERR, func, mod)
        end
        r[n] = mod[func](promiser)(param)
        coroutine.yield(r)
      end -- for each tag
    end -- if a tag
  end -- #tags
end

function cli.try (source, hsource, runenv)
  local M, R, results = {}, { failed = false, repaired = false, kept = false }
  local tags, notify = {}
  for this = 1, source.runs do
    if this > 1 then
      fmt.print("-- Retry #%.f\n", this - 1)
    end
    if #source.tags == 0 then
      -- Run and collect results into the results table
      results = cli.run(source, runenv)
      -- Go over the results from the execution
      for _, result in ipairs(results) do
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
          tags[notify] = true -- toggle handle "$tag"
        end
        -- read the T.results.msg table if debugging is on or the last result failed
        if (result.failed or args["m"] or args["v"]) and result.msg then
          for ni = 1, #result.msg do
            fmt.warn("%s\n", result.msg[ni])
          end
        end
      end -- for each result
    else
      -- handle/tags mode `cfg -g`
      for n = 1, #source.tags do
        tags[source.tags[n]] = true
      end
    end

    -- Run handlers
    local hrun = function(htags)
      local h = coroutine.create(function ()
        cli.hrun(htags, hsource, runenv)
      end)
      return function()
        local _, res = coroutine.resume(h)
        return res
      end
    end
    if next(tags) then
      for rh in hrun(tags) do
        if rh[#rh].repaired == true then
          R.repaired = true
          R.failed = false
        end -- if repaired
        R.failed = rh[#rh].failed or false
        if (rh[#rh].failed or args["m"] or args["v"]) and rh[#rh].msg then
          for ni = 1, #rh[#rh].msg do
            fmt.warn("%s\n", rh[#rh].msg[ni])
          end -- for handler messages
        end  -- if failed or debug
      end -- for each handler run
    end -- if handlers
    if R.failed == false then
      return R, M
    end
  end -- for each run
  return R, M
end

return cli
