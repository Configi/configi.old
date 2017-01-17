local type, pcall, rawset, next, setmetatable, load, pairs, ipairs, require =
      type, pcall, rawset, next, setmetatable, load, pairs, ipairs, require
local ENV, cli, functions, string, table, coroutine = {}, {}, {}, string, table, coroutine
local Factid = require"factid"
local Pgetopt = require"posix.getopt"
local strings = require"cfg-core.strings"
local aux = require"cfg-core.aux"
local lib = require"lib"
local tsort = require"tsort"
local loaded, policy = pcall(require, "cfg-policy")
if not loaded then
    policy = { lua = {} }
end
package.path = aux.path() .. "/" .. "?.lua"
_ENV = ENV

-- Iterate a table (array) for records.
-- @param tbl table to iterate (TABLE)
-- @return iterator that results in a line terminated field "value" for each record (FUNCTION)
function functions.list(tbl)
    if not tbl then
        lib.errorf("%scfg.list: Expected table but got nil.\n", strings.ERR)
    end
    local i, v
    return function()
       i, v = next(tbl, i)
       return i, v
    end
end

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
    local chunk, err
    local _, base, ext = lib.decomp_path(s)
    local script = policy[ext][base]
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
    local scripts = { opts.base .. "." .. opts.ext }
    local env = { fact = {}, global = {} }

    -- Built-in functions inside scripts --
    env.pairs = pairs
    env.ipairs = ipairs
    env.format = string.format
    env.list = functions.list
    env.sub = lib.sub
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
        local include, base, ext = aux.file(f)
        -- Only include files relative to the same directory as opts.script.
        -- Includes with path information has priority.
        local include_name = base .. "." .. ext
        if lib.is_file(include) then
             -- Overwrite any matching base.ext
            policy[ext][base] = lib.fopen(include)
        elseif not policy[ext][base] then
            lib.errorf("%s %s or %s missing for inclusion\n", strings.SERR, include, include_name)
        else
            -- Should not be reached. Just in case.
            include_name = nil
        end
        scripts[#scripts + 1] = include_name
    end
    env.each = function (t, f)
        for str, tbl in functions.list(t) do
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
                                if p == register then
                                    rawset(env.global, v, true)
                                end
                                qt.parameters[p] = v
                            end
                            local resource = qt.parameters.handle or subject
                            if qt.parameters.context == true or (qt.parameters.context == nil) then
                                if not qt.parameters.handle and type(ptbl) == "table" then
                                    source[#source + 1] = { mod = mod, func = func, subject = subject, param = ptbl }
                                end
                                if type(ptbl) == "table" then
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

    -- scripts queue
    local i, temp, htemp = 0, nil, nil
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
        temp, htemp = {}, {}
    end
    local graph = tsort.new()
    do -- Create the DAG
        for _, src in ipairs(source) do
            local dep = src.param.wants or src.param.requires
            if dep then -- Found a dependency
                for _, edge in ipairs(hsource[dep]) do
                    local first_handler = edge.param.wants or edge.param.requires
                    if first_handler then -- Found a handler's dependency
                        for _, first_edge in ipairs(hsource[first_handler]) do
                            local second_handler = first_edge.param.wants or first_edge.param.requires
                            if second_handler then -- Found another dependency
                                for _, second_edge in ipairs(hsource[second_handler]) do
                                    graph:add{ second_edge, first_edge }
                                end
                            end
                            graph:add{ first_edge, edge }
                        end
                        graph:add{ edge, src }
                    else
                        graph:add{ edge, src }
                    end
                end
            end
        end
    end
    local sorted_graph, tsort_err = graph:sort()
    if not sorted_graph then
        lib.errorf("%s %s %s\n", strings.SERR, opts.script, tsort_err)
    end
    if #sorted_graph > 0 then
        source = lib.clone(sorted_graph)
    end
    source.debug, source.test, source.log, source.syslog, source.msg =
    opts.debug, opts.test, opts.log, opts.syslog, opts.msg
    hsource[1], hsource[2], hsource[3], hsource[4] =
        opts.debug, opts.test, opts.syslog, opts.log -- source.msg already handles the msg output
    scripts, env = nil, nil -- GC
    return source, hsource, runenv
end

function cli.opt (arg, version)
    local short = strings.short_args
    local long = strings.long_args
    local help = strings.help
    -- Defaults. runs field is always used
    local opts = { runs = 3, _periodic = "300" }
    local tags = {}
    -- optind and li are unused
    for r, optarg, optind, li in Pgetopt.getopt(arg, short, long) do
        if r == "f" then
            local full, base, ext = aux.file(optarg)
            opts.ext = ext
            opts.base = base
            opts.script = full
            if lib.is_file(opts.script) then
                -- overwrite [ext][base] with the contents of opts.script
                policy[ext][base] = lib.fopen(opts.script)
            else
                lib.errorf("%s %s not found\n", strings.SERR, opts.script)
            end
        end
        if r == "e" then
            local _, base, ext = lib.decomp_path(optarg)
            opts.script = base .. "." .. ext
            opts.ext = ext
            opts.base = base
            if not policy[ext][base] then
                lib.errorf("%s %s not found\n", strings.SERR, optarg)
            end
        end
        if r == "m" then opts.msg = true end
        if r == "v" then opts.debug = true end
        if r == "t" then opts.test = true end
        if r == "s" then opts.syslog = true end
        if r == "r" then opts.runs = optarg or opts._runs end
        if r == "l" then opts.log = optarg end
        if r == "?" then return lib.errorf("%sUnrecognized option passed\n", strings.ERR) end
        if r == "p" then opts.periodic = optarg or opts._periodic end
        if r == "D" then opts.daemon = true end
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
        local mod, func, subject, param, r = nil, nil, nil, nil, {}
        if hsource[tag] then
            for n = 1, #hsource[tag] do
                if runenv[hsource[tag][n].mod] == nil then
                    -- auto-load the module
                    runenv[hsource[tag][n].mod] = functions.module(hsource[tag][n].mod)
                end
                mod, func, subject, param = runenv[hsource[tag][n].mod], hsource[tag][n].func, hsource[tag][n].subject, hsource[tag][n].param
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
    local M, results, R = {}, nil, { repaired = false, failed = false, repaired = false, kept = false }
    local notify, tags = nil, {}
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
        local hrun = function(tags)
            local h = coroutine.create(function ()
                cli.hrun(tags, hsource, runenv)
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
