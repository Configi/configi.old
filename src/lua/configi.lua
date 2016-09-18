local type, rawset, rawget, loadfile, pcall, next, setmetatable, load, pairs, ipairs, require, tostring =
      type, rawset, rawget, loadfile, pcall, next, setmetatable, load, pairs, ipairs, require, tostring
local coroutine, os, string, table = coroutine, os, string, table
local Factid = require"factid"
local moonscript = require"moonscript"
local Psyslog = require"posix.syslog"
local Pgetopt = require"posix.getopt"
local Psystime = require"posix.sys.time"
local lib = require"lib"
local cfg = {}
local ENV = { PATH = "./" }
_ENV = ENV

--[[ Strings ]]
cfg.str = {
        IDENT = "Configi",
        ERROR = "ERROR: ",
         WARN = "WARNING: ",
         SERR = "POLICY ERROR: ",
    OPERATION = "Operation"
}
local Lstr = cfg.str

-- Logging function for export too
cfg.LOG = function (syslog, file, str, level)
    level = level or Psyslog.LOG_DEBUG
    if syslog then
        return lib.log(file, Lstr.IDENT, str, Psyslog.LOG_NDELAY|Psyslog.LOG_PID, Psyslog.LOG_DAEMON, level)
    elseif not syslog and file then
        return lib.log(file, Lstr.IDENT, str)
    end
end

--[[ Module internal functions ]]
local Lmod = {}

--[[ Script functions ]]
cfg.script = {}
local Lscript = cfg.script

--[[ Cli functions ]]
cfg.cli = {}
local cli = cfg.cli

-- Set value of a specified field in a parameter record.
-- Returns a function that converts strings yes, true and True to boolean true
-- Values no, false and False to boolean false
-- Other strings are set directly as the value
-- @param tbl table to operate on (TABLE)
-- @param field record field name to set the value (FIELD)
-- @return function that sets the value (FUNCTION)
function Lmod.setvalue (tbl, field)
    return function (v)
        if lib.truthy(v) then
            tbl.parameters[field] = true
        elseif lib.falsy(v) then
            tbl.parameters[field] = false
        else
            tbl.parameters[field] = v
        end
    end
end

--- Return a function that passes the string argument to syslog() and add it to tbl
-- It calls string.format if a C-like argument is passed to the returned function
-- @param T module table (TABLE)
-- @return function (FUNCTION)
function Lmod.dmsg (C)
    return function (item, flag, bool, sec, extra)
        local level, msg
        item = string.match(item, "([%S+]+)")
        if flag == true then
            flag = " ok "
            msg = C.report.repaired
        elseif flag == nil then
            flag = "skip"
            msg = C.report.kept
        elseif flag == false then
            flag = "fail"
            msg = C.report.failed
            level = Psyslog.LOG_ERR
        elseif type(flag) == "string" then
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
            str = string.format([[

 [%s] %s
        Comment: %s
        Item: %s
        %s%s]],
        flag, msg, C.parameters.comment, item or "", extra or "", "\n")
        else
             str = string.format([[

 [%s] %s
        Elapsed: %.fs
        %s%s]],
        flag, msg, sec, extra or "", "\n")
        end
        local rs = string.char(9)
        local lstr
        sec = sec or ""
        if string.len(C.parameters.comment) > 0 then
            lstr = string.format("[%s]%s%s%s%s%s%s%s#%s", flag, rs, msg, rs, item, rs, sec, rs, C.parameters.comment)
        else
            lstr = string.format("[%s]%s%s%s%s%s%s", flag, rs, msg, rs, item, rs, sec)
        end
        cfg.LOG(C.parameters.syslog, C.parameters.log, lstr, level)
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
        item = string.match(item, "([%S+]+)")
        if flag == true then
            flag = " ok "
            msg = C.report.repaired
        elseif flag == nil then
            flag = "skip"
            msg = C.report.kept
        elseif flag == false then
            flag = "fail"
            msg = C.report.failed
            level = Psyslog.LOG_ERR
        elseif type(flag) == "string" then
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

        local str = string.format([[

 [%s] %s
        Item: %s
        Comment: %s
        %s%s]], flag, msg, item, C.parameters.comment, "", "\n")
        local rs = string.char(9)
        local lstr
        if string.len(C.parameters.comment) > 0 then
            lstr = string.format("[%s]%s%s%s%s%s#%s", flag, rs, msg, rs, item, rs, C.parameters.comment)
        else
            lstr = string.format("[%s]%s%s%s%s", flag, rs, msg, rs, item)
        end
        cfg.LOG(C.parameters.syslog, C.parameters.log, lstr, level)
        C.results.msgt[#C.results.msgt + 1] = {
            item = item,
            msg = msg,
            comment = C.parameters.comment,
            result = flag
        }
        C.results.msg[#C.results.msg + 1] = str
    end
end

--- Check if a required parameter is set.
-- Produce an error (exit code 1) if a required parameter is missing.
-- @param T main table (TABLE)
function Lmod.required (C)
    for n = 1, #C._required do
        if not C.parameters[C._required[n]] then
            lib.errorf("%s Required parameter '%s' missing.\n", Lstr.SERR, C._required[n])
        end
    end
end

-- Warn (stderr output) if a "module.function" parameter is ignored.
-- @param T main table (TABLE)
function Lmod.ignoredwarn (C)
    for n = 1, #C._required do C._module[#C._module + 1] = C._required[n] end -- add C.required to M
    -- Core parameters are added as valid parameters
    C._module[#C._module + 1] = "comment"
    C._module[#C._module + 1] = "debug"
    C._module[#C._module + 1] = "test"
    C._module[#C._module + 1] = "syslog"
    C._module[#C._module + 1] = "log"
    C._module[#C._module + 1] = "handle"
    C._module[#C._module + 1] = "register"
    C._module[#C._module + 1] = "context"
    C._module[#C._module + 1] = "notify"
    C._module[#C._module + 1] = "notify_failed"
    C._module[#C._module + 1] = "notify_kept"
    -- Now check for any undeclared _module parameter
    local Ps = lib.arr_to_rec(C._module, 0)
    for param, _ in next, C.parameters do
        if Ps[param] == nil then
            lib.warn("%s Parameter '%s' ignored.\n", Lstr.WARN, param)
        end
    end
end

--- Process a promise.
-- 1. Fill environment with functions to assign parameters
-- 2. Load promise chunk
-- 3. Check for required parameter(s)
-- 4. Debugging
-- @return functions table
-- @return parameters table
-- @return results table
function cfg.init(P, M)
    local C = {
            _module = M.parameters or {},
             report = M.report, -- cannot be unset
          _required = M.required or {},
          functions = {},
         parameters = P,
            results = { repaired = false, failed = false, msg = {}, msgt = {} }
    }
    -- assign aliases
    local _temp = {}
    if pcall(next, M.alias) then
        for param, aliases in next, M.alias do
            for n = 1, #aliases do
                _temp[aliases[n]] = param
            end
        end
        -- Preset found aliases to true since it's not ok to iterate and add at the same time.
        for alias, param in next, _temp do
            if C.parameters[alias] then
                C.parameters[param] = true
            end
        end
    end
    -- assign values
    for p, v in next, C.parameters do
        if _temp[p] then
            -- remove alias so it won't warn about an ignored parameter
            C.parameters[p] = nil
            -- reuse and update p for each alias hit
            p = _temp[p]
        end
        if lib.truthy(v) then
            C.parameters[p] = true
        elseif lib.falsy(v) then
            C.parameters[p] = false
        else
            C.parameters[p] = v
        end
    end
    -- Check for required parameters
    Lmod.required(C)
    -- Return an F.run() depending on debug, test flags
    C.parameters.comment = C.parameters.comment or ""
    local msg
    local functime = function (f, ...)
    local t1 = Psystime.gettimeofday()
    local stdout, stderr = "", ""
    local ok, rt = f(...)
    local err = lib.exit_string(rt.bin, rt.status, rt.code)
    if rt then
        if type(rt.stdout) == "table" then
            stdout = table.concat(rt.stdout, "\n")
        end
        if type(rt.stderr) == "table" then
            stderr = table.concat(rt.stderr, "\n")
        end
    end
    local secs = lib.diff_time(Psystime.gettimeofday(), t1)
        secs = string.format("%s.%s", tostring(secs.sec), tostring(secs.usec))
        msg(Lstr.OPERATION, err, ok or false, secs, string.format("stdout:\n%s\n        stderr:\n%s\n", stdout, stderr))
        return ok, rt
    end -- functime()
    if not (C.parameters.test or C.parameters.debug) then
        msg = Lmod.msg(C)
        C.functions.run = function (f, ...)
            local ok, rt = f(...)
            local err = lib.exit_string(rt.bin, rt.status, rt.code)
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
            msg(Lstr.OPERATION, string.format("Would execute a corrective operation"), true)
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
        if type(alt) == "string" then
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
        if type(PATH) == "table" then
            f = PATH[f]
        else
            f = lib.fopen(PATH .. "/" .. f)
        end
        return f
    end
    _temp, C._module, C._required = nil, nil, nil -- GC

    -- Methods available to P
    local insert_if = function(self, source, target, i)
        i = i or #target
        for k, v in next, source do
            lib.insert_if(self[k], target, i, v)
        end
    end
    local set_if_not = function(self, test, value)
        if not self[test] then
            self[test] = value
        end
    end
    local set_if = function(self, test, value)
        if self[test] then
            self[test] = value
        end
    end
    local P_methods = {
        insert_if = insert_if,
        set_if_not = set_if_not,
        set_if = set_if
    }
    setmetatable(C.parameters, { __index = P_methods })
    return C.functions, C.results -- F, R
end

--- Iterate a table (array) for records.
-- @param tbl table to iterate (TABLE)
-- @return iterator that results in a line terminated field "value" for each record (FUNCTION)
function Lscript.list(tbl)
    if not tbl then
        lib.errorf("Error: cfg.list: Expected table but got nil.\n")
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
function Lscript.module (m)
    local rb, rm = pcall(require, "module." .. m)
    if not rb then
        return lib.errorf("Module error: %s\n%s\n", m, rm)
    end
    return rm
end

--[[ CLI functions ]]
function cli.compile(s, env)
    local chunk, err
    if type(PATH) == "table" then
        if not PATH[s] then
            lib.errorf("%s %s not found\n", Lstr.SERR, s)
        end
        chunk, err = load(PATH[s], PATH[s], "t", env)
    else
        if not lib.is_file(s) then
            lib.errorf("%s %s not found\n", Lstr.SERR, s)
        end
        local ext = string.match(s, "%w?", -1)
        if ext == "a" then
            chunk, err = loadfile(s, "t", env)
        end
        if ext == "n" then
            local script = lib.fopen(s)
            local parse = require "moonscript.parse"
            local tree, err = parse.string(script)
            if not tree then
                lib.errorf("%s%s\n", Lstr.SERR, err)
            end
            local compile = require "moonscript.compile"
            local code, posmap_or_err, err_pos = compile.tree(tree)
            if not code then
                lib.errorf("%s%s\n", Lstr.SERR, compile.format_error(posmap_or_err, err_pos, script))
            end
            chunk, err = load(code, code, "t", env)
        end
    end
    if not chunk then
        lib.errorf("%s%s%s\n", Lstr.SERR, s, err)
    end
    return chunk()
end

function cli.main (opts)
    local source = {}
    local hsource = {}
    local runenv = {}
    local scripts = { opts.script }
    local env = { fact = {}, global = {} }

    -- Built-in functions inside scripts --
    env.pairs = pairs
    env.ipairs = ipairs
    env.format = string.format
    env.list = Lscript.list
    env.sub = lib.sub
    env.module = function (m)
        if m == "fact" then
            env.fact = Factid.gather()
        else
            runenv[m] = Lscript.module(m)
        end
    end
    env.debug = function (b) if lib.truthy(b) then opts.debug = true end end
    env.test = function (b) if lib.truthy(b) then opts.test = true end end
    env.syslog = function (b) if lib.truthy(b) then opts.syslog = true end end
    env.log = function (b) opts.log = b end
    env.include = function (f)
        if type(PATH) == "table" then
            scripts[#scripts + 1] = f
        else
            scripts[#scripts + 1] = PATH .. "/" .. f
        end
    end
    env.each = function (t, f)
        for str, tbl in Lscript.list(t) do
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
                            if qt.parameters.context == true or (qt.parameters.context == nil) then
                                if qt.parameters.handle then
                                    if hsource[qt.parameters.handle] and (#hsource[qt.parameters.handle] > 0) then
                                        hsource[qt.parameters.handle][#hsource[qt.parameters.handle] + 1] =
                                            { mod = mod, func = func, subject = subject, param = ptbl }
                                    else
                                        hsource[qt.parameters.handle] = {}
                                        hsource[qt.parameters.handle][#hsource[qt.parameters.handle] + 1] =
                                            { mod = mod, func = func, subject = subject, param = ptbl }
                                    end
                                elseif type(ptbl) == "table" then
                                    source[#source + 1] = {mod = mod, func = func,subject=subject, param = ptbl}
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
    source.debug, source.test, source.log, source.syslog, source.msg =
    opts.debug, opts.test, opts.log, opts.syslog, opts.msg
    hsource[1], hsource[2], hsource[3], hsource[4] =
        opts.debug, opts.test, opts.syslog, opts.log -- source.msg already handles the msg output
    scripts, env = nil, nil -- GC
    return source, hsource, runenv
end

function cli.opt (arg, version)
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
            -h, --help                  This help text.
            -V, --version               Print version.
            -v, --debug                 Turn on debugging messages.
            -t, --test                  Dry-run mode. All operations are expected to succeed. Turns on debugging.
            -D, --daemon                Daemon mode. Watch for IN_MODIFY and IN_ATTRIB events to the policy file.
            -p, --periodic              Do a run after N seconds.
            -s, --syslog                Enable logging to syslog.
            -l, --log                   Log to an specified file.
            -m, --msg                   Show debug and test messages.
            -g, --tag                   Only run specified tag(s).
            -r, --runs                  Run the policy N times if a failure is encountered. Default is 3.
            -f, --file                  Path to the Configi policy.

]]
    -- Defaults. runs field is always used
    local opts = { runs = 3, _periodic = "300" }
    local tags = {}
    -- optind and li are unused
    for r, optarg, optind, li in Pgetopt.getopt(arg, short, long) do
        if r == "f" then
            opts.script = optarg
            local _, policy = pcall(require, "policy")
            if not lib.is_file(opts.script) and type(policy) == "table" then
                PATH = policy
            else
                PATH = lib.split_path(opts.script)
            end
        end
        if r == "m" then opts.msg = true end
        if r == "v" then opts.debug = true end
        if r == "t" then opts.test = true end
        if r == "s" then opts.syslog = true end
        if r == "r" then opts.runs = optarg or opts._runs end
        if r == "l" then opts.log = optarg end
        if r == "?" then return lib.errorf("Error: Unrecognized option passed\n") end
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
            runenv[s.mod] = Lscript.module(s.mod)
        end
        local mod, func, subject, param = runenv[s.mod], s.func, s.subject, s.param
        -- append debug and test arguments
        param.debug = source.debug or param.debug
        param.test = source.test or param.test
        param.syslog = source.syslog or param.syslog
        param.log = source.log or param.log
        if not mod[func] then
           lib.errorf("Module error: function '%s' in module '%s' not found\n", s.func, s.mod)
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
                    runenv[hsource[tag][n].mod] = Lscript.module(hsource[tag][n].mod)
                end
                mod, func, subject, param = runenv[hsource[tag][n].mod], hsource[tag][n].func, hsource[tag][n].subject, hsource[tag][n].param
                -- append debug and test arguments
                param.debug = hsource[1] or param.debug
                param.test = hsource[2] or param.test
                param.syslog = hsource[3] or param.syslog
                param.log = hsource[4] or param.log
                if not func then
                    r[#r + 1] = mod(param)
                elseif not mod[func] then
                    lib.errorf("Module error: function '%s' in module '%s' not found\n", func, mod)
                end
                r[#r + 1] = mod[func](subject)(param)
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

return cfg

