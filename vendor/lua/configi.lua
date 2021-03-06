local ntests = 0
local npassed = 0
local failed = false
local passed = false
local failed_list = {}
local quiet = false
local grey = false
local test_regex = false
local remote = false
local nocolor = false
local UUID = false
local seq = 0
local argparse = require"argparse"
local lib = require"lib"
local fmt = lib.fmt
local env

local function red(str)    return grey and str or "\27[1;31m" .. str .. "\27[0m" end
local function blue(str)   return grey and str or "\27[1;34m" .. str .. "\27[0m" end
local function green(str)  return grey and str or "\27[1;32m" .. str .. "\27[0m" end
local function yellow(str) return grey and str or "\27[1;33m" .. str .. "\27[0m" end
local function magenta(str) return grey and str or "\27[1;35m" .. str .. "\27[0m" end

local configi_tag  = blue   "INFO: ---- Configi"
local done_tag     = blue   "INFO: ------- Done"
local repair_tag   = green  "MEND:"
local pass_tag     = yellow "PASS:"
local fail_tag     = red    "FAIL:"
local disabled_tag = magenta"DISABLED:"
local tpass_tag    = green  "  Compliant :"
local trepair_tag  = green  "   Repaired :"
local failed_tag   = red    "     Failed :"

local function trace(msg, start_frame)
  local o = {msg}
  local frame = start_frame
  while true do
    local info = debug.getinfo(frame, "Sl")
    if not info then break end
    local d = frame - start_frame
    if ((d >= 4) and (d <= 5)) then
      o[#o + 1] = "  --> " .. (string.gsub(info.source, "%.", "/")) ..  ".lua:" .. info.currentline
    end
    frame = frame + 1
  end
  return table.concat(o,"\n")
end

local function log(msg, tag, name, tm)
  if not quiet then
    if nocolor then
      local tmsg, m = pcall(string.gsub, msg, string.char(27).."[%d%p]+m", "")
      if tmsg then
        fmt.print(m.."\n")
      end
    else
      fmt.print(msg.."\n")
    end
  end
  if remote then
    seq = seq + 1
    local tmsg, ttag
    tmsg, msg = pcall(string.gsub, msg, string.char(27).."[%d%p]+m", "")
    if not tmsg then msg = nil end
    if tag and string.find(tag, "^"..string.char(27)) then
      ttag, tag = pcall(string.match, tag, string.char(27).."[%d%p]+m[%s]+([%w]+)[%s]+:"..string.char(27))
      if not ttag then tag = nil end
    end
    local json = require"dkjson"
    local px = require"px"
    local payload = json.encode({ version = "1.1",
                                     host = px.hostname(),
                            short_message = "configi: " .. (tag or ""),
                             full_message = (name or msg),
                                    _uuid = UUID,
                                _sequence = seq,
                                 _elapsed = (tm or nil)})
    local ip, port = string.match(remote, "([%d]+%.[%d]+%.[%d]+%.[%d]*)[%:]?([%d]*)")
    if port == "" then port = 12201 end
    local socket = require"lsocket"
    local client = socket.connect(ip, port)
    socket.select(nil, {client})
    local ok , err = client:status()
    if not ok then fmt.warn("Error connecting to remote GELF endpoint. ("..err..")\n") end
    ok, err = client:send(payload)
    if not ok then fmt.warn("Error connecting to remote GELF endpoint. ("..err..")\n") end
    client:close()
  end
end

local function fail(msg, start_frame)
  failed = true
  msg = "Fail: " .. msg
  local backtrace = trace(msg, start_frame or 4)
  log(backtrace, "FAIL")
end

local function pass()
  passed = true
  npassed = npassed + 1
end

local function stringize_var_arg(varg, ...)
  if varg then
    local rest = stringize_var_arg(...)
    if rest ~= "" then
      return tostring(varg) .. ", ".. rest
    else
      return tostring(varg)
    end
  else
    return ""
  end
end

local function test_pretty_name(suite_name, test_name)
  if suite_name == "__root" then
    return test_name
  else
    return suite_name .. "." .. test_name
  end
end

local api = { test_suite_name = "__root", disabled = false }

api.parameter = function (p)
  p = p or {}
  return setmetatable(p, { __index = {
    set_if_not = function(self, test, value)
      if not self[test] then
        self[test] = value
      end
    end,
    set_if = function(self, test, value)
      if self[test] then
        self[test] = value
      end
    end}})
end

api.equal = function (l, r, m)
  if l ~= r then
    fail(tostring(l) .. " ~= " .. tostring(r) .. "\n" .. m)
  end
  return true, "ok"
end

api.pass = function (...)
  local ok
  local n = select('#', ...)
  if (n == 0) or (n == 1) then ok = true end
  if n == 2 then
    local a, b = select(1, ...)
    if a == b then ok = true end
  end
  if ok then pass() end
end

api.register = function (r, v)
  if r and type(r) == "string" then env[r] = v end
end

api.fail = function(s)
  fail(tostring(s))
end

api.print = function(s)
  log(s, "Output")
end

api.not_equal = function (l, r)
  if l == r then
    fail(tostring(l) .. " == " .. tostring(r))
  end
  return true, "ok"
end

api.almost_equal = function (l, r, diff)
  if require("math").abs(l - r) > diff then
    fail("|" .. tostring(l) .. " - " .. tostring(r) .."| > " .. tostring(diff))
  end
  return true, "ok"
end

api.is_false = function (maybe_false)
  if maybe_false or type(maybe_false) ~= "boolean" then
    fail("got " .. tostring(maybe_false) .. " instead of false")
  end
  return true, "ok"
end

api.is_true = function (maybe_true, m)
  if not maybe_true or type(maybe_true) ~= "boolean" then
    fail("got " .. tostring(maybe_true) .. " instead of true" .. "\n" .. m)
  end
  return true, "ok"
end

api.is_not_nil = function (maybe_not_nil)
  if type(maybe_not_nil) == "nil" then
    fail("got nil")
  end
  return true, "ok"
end

local function make_type_checker(typename)
  api["is_" .. typename] = function (maybe_type)
    if type(maybe_type) ~= typename then
      fail("got " .. tostring(maybe_type) .. " instead of " .. typename, 4)
    end
  end
end

local supported_types = {"nil", "boolean", "string", "number", "userdata", "table", "function", "thread"}
for _, supported_type in ipairs(supported_types) do
  make_type_checker(supported_type)
end

local last_test_suite
local function run_test(test_suite, test_name, test_function, ...)
  local suite_name = test_suite.test_suite_name
  local full_test_name = test_pretty_name(suite_name, test_name)

  if test_regex and not string.match(full_test_name, test_regex) then
    return
  end

  if test_suite.disabled then
    log(disabled_tag .. " " .. full_test_name, disabled_tag)
    return
  end


  if suite_name ~= last_test_suite then
    log(configi_tag, "Begin")
    last_test_suite = suite_name
  end

  ntests = ntests + 1
  failed = false
  passed = false

  local start = os.time()

  local status, err
  for _, f in ipairs({test_suite.start_up,  test_function, test_suite.tear_down}) do
    status, err = pcall(f, ...)
    if not status then
      failed = true
      fmt.print(tostring(err))
    end
  end

  local stop = os.time()

  local difftime = os.difftime(stop, start)
  local is_test_failed = not status or failed
  local tag = (is_test_failed and fail_tag) or (passed and pass_tag) or repair_tag
  log(string.format("%s %s = %ds", tag, full_test_name, difftime), tag, full_test_name, difftime)

  if is_test_failed then
    table.insert(failed_list, full_test_name)
  end
end

api.INIT = function(a)
  local start = os.time()
  env = {
    SUMMARY = function ()
      log(done_tag, "Done")
      local nfailed = #failed_list
      if nfailed == 0 then
        log(trepair_tag .. " " .. (ntests - npassed) .. " out of " .. ntests, "Summary")
        log(tpass_tag .. " " .. npassed .. " out of " .. ntests, "Summary")
        log(" Finished run in " .. string.format("%d", os.difftime(os.time(), start)) .. " second(s)", "Summary")
        os.exit(0)
      else
        log(trepair_tag .. " " .. ((ntests - nfailed) - npassed) .. " out of " .. ntests, "Summary")
        log(tpass_tag .. " " .. npassed .. " out of " .. ntests, "Summary")
        log(failed_tag .. " " .. nfailed .. " out of " .. ntests .. ":", "Summary")
        for _, test_name in ipairs(failed_list) do
          log(failed_tag .. "\t" .. test_name, "Summary")
        end
        log(" Finished run in " .. string.format("%d", os.difftime(os.time(), start)) .. " second(s)", "Summary")
        os.exit(1)
      end
    end
  }
  local parser = argparse(a[0], "Options")
  parser:flag("-C --nocolor", "Disable colors")
  parser:flag("-q --quiet", "Silent output")
  parser:option("-g --log", "Log to remote GELF TCP endpoint. Example: '127.0.0.1:12201'")
  local args = parser:parse()
  remote = args.log
  if remote then
    local uuid = require"uuid"
    uuid.seed()
    UUID = uuid.new()
  end
  nocolor = args.nocolor
  quiet = args.quiet
  return setmetatable(env, {
      __index = function(_, m)
        local rb, rm = pcall(require, "modules." .. m)
        if not rb then
          rb, rm = pcall(require, "cfg-modules." .. m)
          if not rb then
            return log(string.format("%s: `%s`", "WARN: Value not set or no such Configi module", m))
          end
        end
        return rm
      end})
end

api.result = function ()
  return ntests, #failed_list
end

local default_start_up = function () end
local default_tear_down = function () collectgarbage() end

api.start_up = default_start_up
api.tear_down = default_tear_down

local all_test_cases = { __root = {} }
local function handle_new_test(suite, test_name, test_function)
  local suite_name = suite.test_suite_name
  if not all_test_cases[suite_name] then
    all_test_cases[suite_name] = {}
  end
  all_test_cases[suite_name][test_name] = test_function
  run_test(suite, test_name, test_function)
end

local function lookup_test_with_params(suite, test_name)
  local suite_name = suite.test_suite_name

  if all_test_cases[suite_name] and all_test_cases[suite_name][test_name] then
    return function (...)
      run_test(suite
        , test_name .. "(" .. stringize_var_arg(...) .. ")"
        , all_test_cases[suite_name][test_name], ...)
    end
  else
    local full_test_name = test_pretty_name(suite_name, test_name)
    table.insert(failed_list, full_test_name)
    ntests = ntests + 1
    log(fail_tag .. " No " .. full_test_name .. " parametrized test case!")
  end
end

local function new_test_suite(_, name)
  local test_suite = {
    test_suite_name = name,
    start_up = default_start_up,
    tear_down = default_tear_down,
  passed = false }

  setmetatable(test_suite, {
      __newindex = handle_new_test,
    __index = lookup_test_with_params })
  return test_suite
end

local test_suites = {}
setmetatable(api, {
    __index = function (tbl, name)
      if all_test_cases.__root[name] then
        return lookup_test_with_params(tbl, name)
      end

      if not test_suites[name] then
        test_suites[name] = new_test_suite(tbl, name)
      end
      return test_suites[name]
    end,
    __newindex = handle_new_test
  })

return api
