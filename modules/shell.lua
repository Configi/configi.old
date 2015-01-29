--- Shell operations.
-- @module shell
-- @author Eduardo Tongson <propolice@gmail.com>
-- @license MIT <http://opensource.org/licenses/MIT>
-- @added 0.9.0

local Str = {}
Str.shell_removes_skip = "removes: Already absent."
Str.shell_removes_fail = "removes: Command or script failed to removed path."
Str.shell_creates_skip = "creates: Already present."
Str.shell_creates_fail = "creates: Command or script failed to create path."
Str.shell_command_ok = "shell.command: Command successfully executed."
Str.shell_command_fail = "shell.command: Error executing command."
Str.shell_system_ok = "shell.system: Script successfully executed."
Str.shell_system_fail = "shell.system: Error executing script."
Str.shell_popenexpect_ok = "expects: Expected pattern found."
Str.shell_popenexpect_fail = "expects: Expected pattern not found."
Str.shell_popen_ok = "shell.popen: Command or script successfully executed."
local Lua = {
  gmatch = string.gmatch,
  remove = table.remove
}
local Func = {}
local Configi = require"configi"
local Lc = require"cimicida"
local Px = require"px"
local Pstat = require"posix.sys.stat"
local shell = {}
local ENV = {}
_ENV = ENV

local main = function (S, M, G)
  local C = Configi.start(S, M, G)
  C.required = { "string" }
  C.alias.cwd = { "chdir" }
  C.alias.string = { "command", "script" }
  C.alias.expects = { "match" }
  return Configi.finish(C)
end

Func.envt = function (P)
  local t = {}
  for f, v in Lua.gmatch(P.env, "%s*([%g=]+)=([%g]+)%s*") do
    t[#t + 1] = f .. "=" .. v end
  return t
end

Func.rc = function (F, P)
  local created, removed
  if P.removes then
    if not Pstat.stat(P.removes) then
      F.msg(P.removes, Str.shell_removes_skip, nil)
      removed = true
    else
      F.msg(P.removes, Str.shell_removes_fail, false)
    end
  end
  if P.creates then
    if Pstat.stat(P.creates) then
      F.msg(P.creates, Str.shell_creates_skip, nil)
      created = true
    else
      F.msg(P.creates, Str.shell_creates_fail, false)
    end
  end
  if P.removes and P.creates then
    if removed and created then
      return true
    end
  elseif P.removes then
    if removed then
      return true
    end
  elseif P.creates then
    if created then
      return true
    end
  else
    return false
  end
end

--- Run a command via execve(3).
-- @param string command to execute [REQUIRED] [ALIAS: command]
-- @param cwd current working directory
-- @param env space separated environment variables
-- @param creates a filename, if found will not run the command
-- @param removes a filename, if not found will not run the command
-- shell.command [[
--   cwd "/tmp"
--   env "test=this whatever=youwant"
--   command "touch test"
--   creates "test"
-- ]]
function shell.command (S)
  local M = { "cwd", "creates", "removes" }
  local F, P, R = main(S, M)
  if Func.rc(F, P) then
    R.notify_kept = P.notify_kept
    return R
  end
  local args = {}
  for c in Lua.gmatch(P.string, "%S+") do
    args[#args + 1] = c
  end
  args._bin = Lua.remove(args, 1)
  args._cwd = P.cwd
  args._return_code = true
  if P.env then
    args._env = Func.envt(P)
  end
  -- passing a dummy arg if no arguments
  if args[2] == nil then
    args[2] = true
  end
  local code = F.run(Px.qexec, args)
  if code == 0 then
    F.msg(P.string, Str.shell_command_ok, true)
    R.notify = P.notify
    R.repaired = true
  else
    R.notify_failed = P.notify_failed
    R.failed = true
  end
  return R
end

--- Run a script or command via os.execute.
-- <br />
-- STDIN and STDERR are closed and STDOUT is piped to /dev/null
-- @aliases script
-- @param string script or command to execute [REQUIRED] [ALIAS: script,command]
-- @param creates a filename, if found will not run the script
-- @param removes a filename, if not found will not run the script
-- @usage shell.system [[
--   script "/root/test.sh"
-- ]]
function shell.system (S)
  local M = { "creates", "removes" }
  local F, P, R = main(S, M)
  local script = Lc.fopen(P.string)
  if not script then
    F.msg(P.string, "shell.system: script not found", false)
    R.notify_failed = P.notify_failed
    R.failed = true
    return R
  end
  if Func.rc(F, P) then
    R.notify_kept = P.notify_kept
    return R
  end
  if F.run(Lc.execute, script) then
    F.msg(P.string, Str.shell_system_ok, true)
    R.notify = P.notify
    R.repaired = true
  else
    R.notify_failed = P.notify_failed
    R.failed = true
  end
  return R
end

--- Run a command via io.popen.
-- @param string command to execute [REQUIRED] [ALIAS: command]
-- @param cwd current working directory
-- @param creates a filename, if found will not run the command
-- @param removes a filename, if not found will not run the command
-- @param expects instead of the exit code, use a string match as a test for success
-- @usage shell.popen [[
--   cwd "/tmp"
--   command "ls -la"
--   expects ".X11-unix"
-- ]]
function shell.popen (S)
  local M = { "cwd", "creates", "removes", "expects" }
  local F, P, R = main(S, M)
  if Func.rc(F, P) then
    R.notify_kept = P.notify_kept
    return R
  end
  local str
  if Px.isfile(P.string) then
    str = Lc.fopen(P.string)
  else
    str = P.string
  end
  str = F.run(Lc.popen, str, P.cwd)
  local res, ok
  if P.expects then
    if P.test then
      F.msg(P.expects, Str.shell_popenexpect_ok, true)
    else
      if Lc.tfind(str, P.expects, true) then
        res = true
        F.msg(P.expects, Str.shell_popenexpect_ok, true)
      end
      if not res then
        F.msg(P.expects, Str.shell_popenexpect_fail, false)
      end
    end
  else
    res = str
  end
  if P.test then
    ok = true
  else
    ok = res
  end
  if ok then
    F.msg(P.string, Str.shell_popen_ok, true)
    R.notify = P.notify
    R.repaired = true
  else
    R.notify_failed = P.notify_failed
    R.failed = true
  end
  return R
end

--- Run a command via Px.exec which can expect strings from STDIN, STDOUT or STDERR
-- @param string command to execute [REQUIRED] [ALIAS: command]
-- @param cwd current working directory
-- @param env space separated string of environment variables
-- @param creates a filename, if found will not run the command
-- @param removes a filename, if not found will not run the command
-- @param stdin pipe a string from STDIN
-- @param stdout test for a string from STDOUT
-- @param stderr test for a string from STDERR
-- @param error ignore errors when set to "ignore" [CHOICES: "yes","no"]
-- @usage shell.popen3 [[
--   cwd "/tmp"
--   command "ls"
--   stdout ".X11-unix"
-- ]]
function shell.popen3 (S)
  local Str = {
    shell_popen3stdout_ok = "stdout: Expected stdout pattern found.",
    shell_popen3stdout_fail = "stdout: Expectd stdout pattern not found.",
    shell_popen3stderr_ok = "stderr: Expected stderr pattern found.",
    shell_popen3stderr_fail = "stderr: Expected stderr pattern not found."
  }
  local M = { "cwd", "creates", "removes", "stdin", "stdout", "stderr", "error" }
  local G = {
    ok = "shell.popen3: Command or script successfully executed.",
    skip = "shell.popen3: `creates` or `removes` parameter satisfied.",
    fail = "shell.popen3: Command or script error."
  }
  local F, P, R = main(S, M, G)
  if Func.rc(F, P) then
    return F.skip(P.string)
  end
  local str
  if Px.isfile(P.string) then
    str = Lc.fopen(P.string)
  else
    str = P.string
  end
  local args = Lc.str2tbl(str)
  args._bin = Lua.remove(args, 1)
  if P.stdin then args._stdin = P.stdin end
  if P.cwd then args._cwd = P.cwd end
  if P.env then args._env = Func.envt(P) end
  if P.error == "ignore" then args._ignore_error = true end
  local res, rt = Px.exec(args)
  local err = Lc.exitstr(rt.bin, rt.status, rt.code)
  F.msg(args[1], err, res or false)
  if P.stdout then
    if P.test then
      F.msg(P.stdout, Str.shell_popen3stdout_ok, true)
    else
      if Lc.tfind(rt.stdout, P.stdout, true) then
        F.msg(P.stdout, Str.shell_popen3stdout_ok, true)
      else
        res = false
        F.msg(P.stdout, Str.shell_popen3stdout_fail, false)
      end
    end
  end
  if P.stderr then
    if P.test then
      F.msg(P.stderr, Str.shell_popen3stderr_ok, true)
    else
      if Lc.tfind(rt.stderr, P.stderr, true) then
        res = true
        F.msg(P.stderr, Str.shell_popen3stderr_ok, true)
      else
        F.msg(P.stderr, Str.shell_popen3stderr_fail, false)
      end
    end
  end
  local ok
  if P.test or P["error"] == "ignore" then
    ok = true
  else
    ok = res
  end
  return F.result(ok, P.string)
end

shell.script = shell.system
return shell
