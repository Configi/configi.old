--- Shell operations.
-- @module shell
-- @author Eduardo Tongson <propolice@gmail.com>
-- @license MIT <http://opensource.org/licenses/MIT>
-- @added 0.9.0

local ENV, M, shell = {}, {}, {}
local cfg = require"cfg-core.lib"
local lib = require"lib"
local file, table, string, exec, os = lib.file, lib.table, lib.string, lib.exec, lib.os
local stat = require"posix.sys.stat"
_ENV = ENV

M.required = { "string" }
M.alias = {}
M.alias.cwd = { "chdir" }
M.alias.expects = { "match" }

local envt = function(P)
  local t = {}
  for f, v in string.gmatch(P.env, "%s*([%g=]+)=([%g]+)%s*") do
    t[#t + 1] = f .. "=" .. v end
  return t
end

local rc = function(F, P)
  local report = {
    shell_removes_skip = "removes: Already absent.",
    shell_removes_fail = "removes: Command or script failed to removed path.",
    shell_creates_skip = "creates: Already present.",
    shell_creates_fail = "creates: Command or script failed to create path."
  }
  local created, removed
  if P.removes then
    if not stat.stat(P.removes) then
      F.msg(P.removes, report.shell_removes_skip, false)
      removed = true
    else
      F.msg(P.removes, report.shell_removes_fail, nil)
    end
  end
  if P.creates then
    if stat.stat(P.creates) then
      F.msg(P.creates, report.shell_creates_skip, false)
      created = true
    else
      F.msg(P.creates, report.shell_creates_fail, nil)
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
-- @Promiser command to execute
-- @param cwd current working directory
-- @param env space separated environment variables
-- @param creates a filename, if found will not run the command
-- @param removes a filename, if not found will not run the command
-- @usage shell.command("touch test"){
--       cwd = "/tmp",
--       env = "test=this whatever=youwant",
--     creates = "test"
-- }
function shell.command(S)
  M.parameters = { "cwd" }
  M.report = {
    repaired = "shell.command: Command successfully executed.",
      kept = "shell.command: `creates` or `removes` parameter satisfied.",
      failed = "shell.command: Error executing command."
  }
  return function(P)
    P.string = S
    local F = cfg.init(P, M)
    if rc(F, P) then
      return F.kept(P.string)
    end
    local args = {}
    for c in string.gmatch(P.string, "%S+") do
      args[#args + 1] = c
    end
    args.exe = table.remove(args, 1)
    args.cwd = P.cwd
    if P.env then
      args.env = envt(P)
    end
    -- passing a dummy arg if no arguments
    args[2] = args[2] or true
    local code
    if not P.test then
      code = F.run(exec.qexec, args)
    else
      code = 0
    end
    return F.result(P.string, (code == 0) or nil)
  end
end

--- Run a script or command via os.execute.
-- <br />
-- STDIN and STDERR are closed and STDOUT is piped to /dev/null
-- @Promiser script or command to execute
-- @Aliases script
-- @param creates a filename, if found will not run the script
-- @param removes a filename, if not found will not run the script
-- @usage shell.system("/root/test.sh")()
function shell.system(S)
  M.report = {
    repaired = "shell.system: Script successfully executed.",
      kept = "shell.system: `creates` or `removes` parameter satisfied.",
      failed = "shell.system: Error executing script."
  }
  return function(P)
    P.string = S
    local F = cfg.init(P, M)
    local script
    if os.is_file(P.string) then
      script = file.read_to_string(P.string)
    else
      script = P.string
    end
    if not script then
      return F.result(P.string, nil, "shell.system: script not found")
    end
    if rc(F, P) then
      return F.kept(P.string)
    end
    return F.result(P.string, F.run(exec.script, script))
  end
end

--- Run a command via io.popen.
-- @Promiser command to execute
-- @param cwd current working directory
-- @param creates a filename, if found will not run the command
-- @param removes a filename, if not found will not run the command
-- @param expects instead of the exit code, use a string match as a test for success
-- @usage shell.popen("ls -la"){
--       cwd = "/tmp",
--     expects = ".X11-unix"
-- }
function shell.popen(S)
  local report = {
    shell_popenexpect_ok = "expects: Expected pattern found.",
    shell_popenexpect_fail = "expects: Expected pattern not found."
  }
  M.parameters = { "cwd", "expects" }
  M.report = {
    repaired = "shell.popen: Command or script successfully executed.",
      kept = "shell.popen: `creates` or `removes` parameter satisfied.",
      failed = "shell.popen: Command or script error."
  }
  return function(P)
    P.string = S
    local F = cfg.init(P, M)
    if rc(F, P) then
      return F.kept(P.string)
    end
    local str
    if os.is_file(P.string) then
      str = file.read_to_string(P.string)
    else
      str = P.string
    end
    local code, t = F.run(exec.popen, str, P.cwd)
    local res, ok
    if P.expects then
      if P.test then
        F.msg(P.expects, report.shell_popenexpect_ok, true)
      else
        if table.find(t.output, P.expects, true) then
          res = true
          F.msg(P.expects, report.shell_popenexpect_ok, true)
        end
        if not res then
          F.msg(P.expects, report.shell_popenexpect_fail, nil)
        end
      end
    else
      res = code
    end
    if P.test then
      ok = true
    else
      ok = res
    end
    return F.result(P.string, ok)
  end
end

--- Run a command via lib.exec which can expect strings from STDIN, STDOUT or STDERR
-- @Promiser command to execute
-- @param cwd current working directory
-- @param env space separated string of environment variables
-- @param creates a filename, if found will not run the command
-- @param removes a filename, if not found will not run the command
-- @param stdin pipe a string from STDIN
-- @param stdout test for a string from STDOUT
-- @param stderr test for a string from STDERR
-- @param error ignore errors when set to "ignore" [Default: false]
-- @usage shell.popen3("ls"){
--      cwd = "/tmp",
--     stdout = ".X11-unix"
-- }
function shell.popen3(S)
  local report = {
      shell_popen3stdout_ok = "stdout: Expected stdout pattern found.",
    shell_popen3stdout_fail = "stdout: Expectd stdout pattern not found.",
      shell_popen3stderr_ok = "stderr: Expected stderr pattern found.",
    shell_popen3stderr_fail = "stderr: Expected stderr pattern not found."
  }
  M.parameters = { "cwd", "stdin", "stdout", "stderr", "error" }
  M.report = {
    repaired = "shell.popen3: Command or script successfully executed.",
      kept = "shell.popen3: `creates` or `removes` parameter satisfied.",
      failed = "shell.popen3: Command or script error."
  }
  return function(P)
    P.string = S
    local F = cfg.init(P, M)
    if rc(F, P) then
      return F.kept(P.string)
    end
    local str
    if os.is_file(P.string) then
      str = file.read_to_string(P.string)
    else
      str = P.string
    end
    local args = string.to_array(str)
    args.exe = table.remove(args, 1)
    if P.stdin then args.stdin = P.stdin end
    if P.cwd then args.cwd = P.cwd end
    if P.env then args.env = envt(P) end
    if P.error == "ignore" then args.ignore = true end
    local res, rt = exec.exec(args)
    local err = exec.exit_string(rt.exe, rt.status, res)
    F.msg(args[1], err, res or nil)
    if P.stdout then
      if P.test then
        F.msg(P.stdout, report.shell_popen3stdout_ok, true)
      else
        if table.find(rt.stdout, P.stdout, true) then
          F.msg(P.stdout, report.shell_popen3stdout_ok, true)
        else
          res = false
          F.msg(P.stdout, report.shell_popen3stdout_fail, nil)
        end
      end
    end
    if P.stderr then
      if P.test then
        F.msg(P.stderr, report.shell_popen3stderr_ok, true)
      else
        if table.find(rt.stderr, P.stderr, true) then
          res = true
          F.msg(P.stderr, report.shell_popen3stderr_ok, true)
        else
          F.msg(P.stderr, report.shell_popen3stderr_fail, nil)
        end
      end
    end
    local ok
    if P.test or P["error"] == "ignore" then
      ok = true
    else
      ok = res
    end
    return F.result(P.string, ok)
  end
end

shell.script = shell.system
return shell
