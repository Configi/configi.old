local ffi = require "ffi"
local ffiext = require "ffiext"
local C = ffi.C
local exec = {}
ffi.cdef([[
typedef int32_t pid_t;
pid_t fork(void);
pid_t waitpid(pid_t pid, int *status, int options);
int open(const char *pathname, int flags, int mode);
int close(int fd);
int dup2(int oldfd, int newfd);
int setenv(const char*, const char*, int);
int execvp(const char *file, char *const argv[]);
int chdir(const char *);
int pipe(int fd[2]);
typedef long unsigned int size_t;
typedef long signed int ssize_t;
ssize_t read(int, void *, size_t);
ssize_t write(int, const void *, size_t);
int fcntl(int, int, ...);
]])
local STDIN = 0
local STDOUT = 1
local STDERR = 2
local dup2 = ffiext.retry(C.dup2)
local strerror = ffiext.strerror
local errno = ffi.errno
-- dest should be either 0 or 1 (STDOUT or STDERR)
local redirect = function(io_or_filename, dest_fd)
  if io_or_filename == nil then return true end
  -- first check for regular
  if (io_or_filename == io.stdout or io_or_filename == STDOUT) and dest_fd ~= STDOUT then
    local r, e = dup2(STDERR, STDOUT)
    if r == -1 then return nil, strerror(e, "dup2(2) failed") end
  elseif (io_or_filename == io.stderr or io_or_filename == STDERR) and dest_fd ~= STDERR then
    local r, e = dup2(STDOUT, STDERR)
    if r == -1 then return nil, strerror(e, "dup2(2) failed") end
    -- otherwise handle file-based redirection
  else
    local fd, r, e
    fd, e = ffiext.open(io_or_filename)
    if fd == -1 then return nil, strerror(e, "open(2) failed") end
    r, e = dup2(fd, dest_fd)
    if r == -1 then
      C.close(fd)
      return nil, strerror(e, "dup2(2) failed")
    end
    C.close(fd)
  end
  return true
end

exec.spawn = function (exe, args, env, cwd, stdin_string, stdout_redirect, stderr_redirect, ignore)
  --[[
    INPUT
      exe: program or executable (string)
      args: arguments to program (table)
      env: environment variables when running program (table)
      cwd: current working directory before running program (string)
      stdin_string: STDIN input to program (string)
      stdout_redirect: file to redirect STDOUT stream to (string)
      stderr_redirect: file to redirect STDERR stream to (string)
      ignore: when not nil or false, ignores the return value of the program (string)

    OUTPUT
    { stdout = "STDOUT (string)",
      stderr = "STDERR (string)",
      code = "return code (number)",
      error = "error (string)"
    }
  ]]
  args = args or {}
  local R = {
    stdout = {},
    stderr = {}
  }
  local ret
  local stdin = ffi.new("int[2]")
  local stdout = ffi.new("int[2]")
  local stderr = ffi.new("int[2]")
  if C.pipe(stdin) == -1 then
     R.error = strerror(errno(), "pipe(2) for STDIN failed")
     return nil, R
  end
  if C.pipe(stdout) == -1 then
     R.error = strerror(errno(), "pipe(2) for STDOUT failed")
     return nil, R
  end
  if C.pipe(stderr) == -1 then
     R.error = strerror(errno(), "pipe(2) for STDERR failed")
     return nil, R
  end
  local pid = C.fork()
  if pid < 0 then
    R.error = strerror(errno(), "fork(2) failed")
    return nil, R
  elseif pid == 0 then -- child process
    C.close(stdin[1])
    C.close(stdout[0])
    C.close(stderr[0])
    if stdin_string then
      local r, e = dup2(stdin[0], STDIN)
      if r == -1 then
        R.error = strerror(e, "dup2(2) failed")
        return nil, R
      end
    end
    if stdout_redirect then
      local r, es = redirect(stdout_redirect, STDOUT)
      if r == nil then
        R.error = es
        return nil, R
      end
    else
      local r, e = dup2(stdout[1], STDOUT)
      if r == -1 then
        R.error = strerror(e, "dup2(2) failed")
        return nil, R
      end
    end
    if stderr_redirect then
      local r, es = redirect(stderr_redirect, STDERR)
      if r == nil then
        R.error = es
        return nil, R
      end
    else
      local r, e = dup2(stderr[1], STDERR)
      if r == -1 then
        R.error = strerror(e, "dup2(2) failed")
        return nil, R
      end
    end
    C.close(stdin[0])
    C.close(stdout[1])
    C.close(stderr[1])
    local string_array_t = ffi.typeof('const char *[?]')
    -- local char_p_k_p_t   = ffi.typeof('char *const*')
    -- args is 1-based Lua table, argv is 0-based C array
    -- automatically NULL terminated
    local argv = string_array_t(#args + 1 + 1)
    for i = 1, #args do
      argv[i] = tostring(args[i])
    end
    do
      local function setenv(name, value)
        local overwrite_flag = 1
        if C.setenv(name, value, overwrite_flag) == -1 then
          return nil, strerror(errno(), "setenv(3) failed")
        else
          return value
        end
      end
      for name, value in pairs(env or {}) do
        local x, es = setenv(name, tostring(value))
        if x == nil then
          R.error = es
          return nil, R
        end
      end
    end
    if cwd then
      if C.chdir(tostring(cwd)) == -1 then
        R.error = strerror(errno(), "chdir(2) failed")
        return nil, R
      end
    end
    argv[0] = exe
    argv[#args + 1] = nil
    C.execvp(exe, ffi.cast("char *const*", argv))
    assert(nil, "assertion failed: exec.spawn (should be unreachable!)")
  else
    if stdin_string then
      local len = string.len(stdin_string)
      local str = ffi.new("char[?]", len + 1)
      ffi.copy(str, stdin_string, len)
      local r, e = ffiext.retry(C.write)(stdin[1], str, len)
      if r == -1 then
        R.error = strerror(e, "write(2) failed")
        return nil, R
      end
      C.close(stdin[1])
    else
      C.close(stdin[1])
    end
    do
      local status = ffi.new("int[?]", 1)
      local r, e = ffiext.retry(C.waitpid)(pid, status, 0)
      if r == -1 then
        R.error = strerror(e, "waitpid(2) failed")
        return nil, R
      end
      ret = bit.rshift(bit.band(status[0], 0xff00), 8)
      if ret == 1 then R.error = "execvp(2) failed" end
      R.code = ret
    end
    local output = function(i, o)
      local F_GETFL = 0x03
      local F_SETFL = 0x04
      local O_NONBLOCK = 0x800
      local buf = ffi.new("char[?]", 1)
      local flags = C.fcntl(i, F_GETFL, 0)
      flags = bit.bor(flags, O_NONBLOCK)
      if C.fcntl(i, F_SETFL, ffi.new("int", flags)) == -1 then
        return nil, strerror(errno(), "fcntl(2) failed")
      end
      local n, s, c
      while true do
        n = C.read(i, buf, 1)
        if n == 0 then
          break
        elseif n > 0 then
          c = ffi.string(buf, 1)
          if c ~= "\n" then
            s = string.format("%s%s", s or "", c)
          elseif ffi.errno() == C.EAGAIN then
            o[#o+1] = s
            break
          else
            o[#o+1] = s
            s = nil
          end
        elseif ffi.errno() == C.EAGAIN then
          o[#o+1] = s
          break
        else
          return nil, strerror(errno(), "read(2) failed")
        end
      end
      return true
    end
    local sr, se
    sr, se = output(stdout[0], R.stdout)
    if sr == nil then
      R.error = se
      return nil, R
    end
    sr, se = output(stderr[0], R.stderr)
    if sr == nil then
      R.error = se
      return nil, R
    end
    C.close(stdin[0])
    C.close(stdin[1])
    C.close(stdout[0])
    C.close(stdout[1])
    C.close(stderr[0])
    C.close(stderr[1])
  end
  if ret == 0 or ignore then
    return pid, R
  else
    return nil, R
  end
end
exec.context = function(exe)
  local args = {}
  return setmetatable(args, {__call = function(_, ...)
    local n = select("#", ...)
    if n == 1 then
      for k in string.gmatch(..., "%S+") do
        args[#args+1] = k
      end
    elseif n > 1 then
      for _, k in ipairs({...}) do
        args[#args+1] = k
      end
    end
    return exec.spawn(exe, args, args.env, args.cwd, args.stdin, args.stdout, args.stderr, args.ignore)
  end})
end
exec.ctx = exec.context
exec.cmd = setmetatable({},
  {__index =
    function (_, exe)
      return function(...)
        local args
        if not (...) then
          args = {}
        elseif type(...) == "table" then
          args = ...
        else
          args = {...}
        end
        return exec.spawn(exe, args, args.env, args.cwd, args.stdin, args.stdout, args.stderr, args.ignore)
      end
    end
  })
return exec
