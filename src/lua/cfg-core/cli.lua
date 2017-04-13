local pcall, rawset, next, setmetatable, load, pairs, ipairs, require =
      pcall, rawset, next, setmetatable, load, pairs, ipairs, require
local ENV, cli, functions = {}, {}, {}
local string, coroutine, os = string, coroutine, os
local Factid = require"factid"
local Pgetopt = require"posix.getopt"
local strings = require"cfg-core.strings"
local std = require"cfg-core.std"
local lib = require"lib"
local tsort = require"tsort"
local ep_found, policy = pcall(require, "cfg-policy")
local path = std.path()
local embed = std.embed()
package.path = path .. "/?.lua" .. ";./?.lua;./?"
_ENV = ENV

--- Assign returned value from require() to the custom environment
-- Exit with code 1 if there was an error
-- @param m name of the module (STRING)
-- @return module (TABLE or FUNCTION)
function functions.module (m)
    -- Try custom modules in the arg path .. "/modules" directory first.
    local rb, rm = pcall(require, "modules." .. m)
    if not rb then
        rb, rm = pcall(require, "cfg-modules." .. m)
        if not rb then
            return lib.errorf("%s%s\n%s\n", strings.MERR, m, rm)
        end
    end
    return rm
end

function cli.compile(s, env)
    local chunk, err, script
    local p, base, _ = lib.decomp_path(s)
    if lib.is_file(s) then
        script = lib.fopen(s)
    elseif embed then
        script = policy[p][base]
    end
    if not script then
        lib.errorf("%s%s\n", strings.SERR, "Unable to load policy.")
    end
    chunk, err = load(script, script, "t", env)
    if not chunk then
        lib.errorf("%s%s%s\n", strings.SERR, s, err)
    end
    return chunk()
end

function cli.main (opts)
    local source = {}
    local hsource = {}
    local runenv = {}
    local scripts = { [1] = opts.script }
    local env = { fact = {}, global = {} }

    -- Built-in functions inside scripts --
    env.pairs = pairs
    env.ipairs = ipairs
    env.format = string.format
    env._ = function (str)
        return lib.sub(str, env)
    end
    env.sub = env._
    env.module = function (m)
        if m == "fact" then
            env.fact = Factid.gather()
        else
            runenv[m] = functions.module(m)
        end
    end
    env.debug = function (b) if lib.truthy(b) then opts.debug = true end end
    env.test = function (b) if lib.truthy(b) then opts.test = true end end
    env.syslog = function (b) if lib.truthy(b) then opts.syslog = true end end
    env.log = function (b) opts.log = b end
    env.include = function (f)
        -- Only include files relative to the same directory as opts.script.
        -- Includes with path information has priority.
        local include = path.."/"..f
        if lib.is_file(include) then
            scripts[#scripts+1] = include
        else
            scripts[#scripts+1] = f
        end
    end
    env.each = function (t, f)
        for str, tbl in pairs(t) do
            f(str)(tbl)
        end
    end
    -- Metatable for the script environment
    setmetatable(env, {
        __index = function (_, mod)
            local tbl = setmetatable({}, {
                __index = function (_, func)
                    return function (subject)
                        return function (ptbl) -- mod.func
                            ptbl = ptbl or {}
                            local qt = { environment = {}, parameters = {} }
                            for p, v in next, ptbl do
                                if p == "register" then
                                    rawset(env.global, v, true)
                                end
                                qt.parameters[p] = v
                            end
                            local resource = qt.parameters.handle
                            local rs = string.char(9)
                            if qt.parameters.context == true or (qt.parameters.context == nil) then
                                if not qt.parameters.handle then
                                    source[#source + 1] = { res = mod..rs..func..rs..subject,
                                        mod = mod, func = func, subject = subject, param = ptbl }
                                else
                                    if hsource[resource] and (#hsource[resource] > 0) then
                                        hsource[resource][#hsource[resource] + 1] =
                                        { mod = mod, func = func, subject = subject, param = ptbl }
                                    else
                                        hsource[resource] = {}
                                        hsource[resource][#hsource[resource] + 1] =
                                        { mod = mod, func = func, subject = subject, param = ptbl }
                                    end
                                end
                            end -- context
                        end -- mod.func
                    end -- function (subject)
                end }) -- __index = function (_, func)
            return tbl
        end -- __index = function (_, mod)
    })

    scripts = std.add_from_dirs(scripts, path)
    if embed then
        scripts = std.add_from_embedded(scripts, policy)
    end

    -- scripts queue
    local i, temp, htemp = 0
    while next(scripts) do
        i = i + 1
        temp, htemp = source, hsource
        source, hsource = {}, {}
        cli.compile(scripts[next(scripts)], env)
        scripts[i] = nil
        -- main queue
        for n = 1, #temp do
            source[#source + 1] = temp[n]
        end
        -- handlers queue
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
                local rs = string.char(9)
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
                    lib.errorf("%s %s %s\n", strings.SERR, opts.script, err)
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
        lib.errorf("%s %s %s\n", strings.SERR, opts.script, tsort_err)
    end
    sorted.debug, sorted.test, sorted.log, sorted.syslog, sorted.msg =
    opts.debug, opts.test, opts.log, opts.syslog, opts.msg
    hsource[1], hsource[2], hsource[3], hsource[4] =
        opts.debug, opts.test, opts.syslog, opts.log -- source.msg already handles the msg output
    scripts, env = nil, nil -- GC
    return sorted, hsource, runenv
end

function cli.opt (arg, version)
    local short = strings.short_args
    local long = strings.long_args
    local help = strings.help
    -- Defaults. runs field is always used
    local opts = { runs = 3, _periodic = "300" }
    local tags = {}
    -- optind and li are unused
    for r, optarg, _, _ in Pgetopt.getopt(arg, short, long) do
        if r == "f" then
            local dir, base, ext = lib.decomp_path(optarg)
            opts.script = dir.."/"..base.."."..ext
        end
        if r == "e" then
            if not ep_found then
                lib.errorf("%s %s\n", strings.ERROR, "Missing embedded policy")
            end
            local _, base, ext = lib.decomp_path(optarg)
            -- policy["."][base]
            if not ext then
                lib.errorf("%s %s\n", strings.ERROR, "Missing .lua extension?")
            end
            opts.script = base.."."..ext
        end
        if r == "m" then opts.msg = true end
        if r == "v" then opts.debug = true end
        if r == "t" then opts.test = true end
        if r == "s" then opts.syslog = true end
        if r == "r" then opts.runs = optarg or opts._runs end
        if r == "l" then opts.log = optarg end
        if r == "?" then return lib.errorf("%sUnrecognized option passed\n", strings.ERR) end
        if r == "p" then opts.periodic = optarg or opts._periodic end
        if r == "w" then opts.watch = true end
        if r == "g" then
            for tag in string.gmatch(optarg, "([%w_]+)") do
                tags[#tags + 1] = tag
            end
        end
        if r == "h" then
            lib.printf("%s", help)
            os.exit(0)
        end
        if r == "V" then
            lib.printf("%s\n", version)
            os.exit(0)
        end
    end
    if not opts.script then
        lib.errorf("%s", help)
    end
    if opts.debug then
        lib.printf("Started run %s\n", lib.timestamp())
        lib.printf("Applying policy: %s\n", opts.script)
    end
    local source, hsource, runenv = cli.main(opts) -- arg[index]
    source.runs, source.tags = opts.runs, tags
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
        local mod, func, subject, param = runenv[s.mod], s.func, s.subject, s.param
        -- append debug and test arguments
        param.debug = source.debug or param.debug
        param.test = source.test or param.test
        param.syslog = source.syslog or param.syslog
        param.log = source.log or param.log
        if not mod[func] then
           lib.errorf("%sfunction '%s' in module '%s' not found\n", strings.MERR, func, mod)
        end
        rt[i] = mod[func](subject)(param)
    end -- for each line
    return rt
end

function cli.hrun (tags, hsource, runenv) -- execution step for handlers
    for tag, _ in next, tags do
        local r, mod, func, subject, param = {}
        if hsource[tag] then
            for n = 1, #hsource[tag] do
                if runenv[hsource[tag][n].mod] == nil then
                    -- auto-load the module
                    runenv[hsource[tag][n].mod] = functions.module(hsource[tag][n].mod)
                end
                mod, func, subject, param = runenv[hsource[tag][n].mod],
                    hsource[tag][n].func,
                    hsource[tag][n].subject,
                    hsource[tag][n].param
                -- append debug and test arguments
                param.debug = hsource[1] or param.debug
                param.test = hsource[2] or param.test
                param.syslog = hsource[3] or param.syslog
                param.log = hsource[4] or param.log
                if not mod[func] then
                    lib.errorf("%sfunction '%s' in module '%s' not found\n", strings.MERR, func, mod)
                end
                r[n] = mod[func](subject)(param)
                coroutine.yield(r)
            end -- for each tag
        end -- if a tag
    end -- #tags
end

function cli.try (source, hsource, runenv)
    local M, R, results = {}, { failed = false, repaired = false, kept = false }
    local tags, notify = {}
    for this = 1, source.runs do
        if this > 1 and (source.debug or source.test or source.msg) then
            lib.printf("-- Retry #%.f\n", this - 1)
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
                if (result.failed or source.debug or source.test or source.msg) and result.msg then
                    for ni = 1, #result.msg do
                        lib.warn("%s\n", result.msg[ni])
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
                if (rh[#rh].failed or source.debug or source.test or source.msg) and rh[#rh].msg then
                    for ni = 1, #rh[#rh].msg do
                        lib.warn("%s\n", rh[#rh].msg[ni])
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
