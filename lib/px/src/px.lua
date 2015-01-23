local Lua = {
  setmetatable = setmetatable,
  pcall = pcall,
  type = type,
  ipairs = ipairs,
  len = string.len,
  sub = string.sub,
  gmatch = string.gmatch,
  unpack = table.unpack,
  concat = table.concat,
  remove = table.remove,
  rename = os.rename
}
local Cimicida = require"cimicida"
local Ppwd = require"posix.pwd"
local Punistd = require"posix.unistd"
local Perrno = require"posix.errno"
local Pwait = require"posix.sys.wait"
local Pstat = require"posix.sys.stat"
local Ppoll = require"posix.poll"
local Pfcntl = require"posix.fcntl"
local Pstdlib = require"posix.stdlib"
local Psyslog = require"posix.syslog"
local px_c = require"px_c"
local Px = px_c
local ENV = {}
_ENV = ENV

local retry = function (fn)
  return function (...)
    local ret, err, errnum, errno, _
    repeat
      ret, err, errnum = fn(...)
      if ret == -1 then
        _, errno = Perrno.errno()
      end
    until(errno ~= Perrno.EINTR)
    return ret, err, errnum
  end
end

-- Handle EINTR
Px.fsync = retry(Punistd.fsync)
Px.chdir = retry(Punistd.chdir)
Px.close = retry(Punistd.close)
Px.fcntl = retry(Pfcntl.fcntl)
Px.dup2 = retry(Punistd.dup2)
Px.wait = retry(Pwait.wait)
Px.open = retry(Pfcntl.open)

function Px.write (fd, buf)
  local size = Lua.len(buf)
  local written, err
  while (size > 0) do
    written, err = Punistd.write(fd, buf)
    if written == -1 then
      local _, errno = Perrno.errno()
      if errno == Perrno.EINTR then
        goto continue
      end
      return nil, err
    end
    size = size - written
    ::continue::
  end
  return true
end

-- exec for pipeline
function Px.execp (t, ...)
  local pid, err = Punistd.fork()
  local status, code, _
  if pid == nil or pid == -1 then
    return nil, err
  elseif pid == 0 then
    if Lua.type(t) == "table" then
      Punistd.exec(Lua.unpack(t))
      local _, no = Perrno.errno()
      Punistd._exit(no)
    else
      Punistd._exit(t(...) or 0)
    end
  else
    _, status, code = Px.wait(pid)
  end
  return code, status
end

-- Derived from luaposix/posix.lua pipeline()
local pipeline
pipeline = function (t, pipe_fn)
  local list = {
    sub = function (l, from, to)
      local r = {}
      local len = #l
      from = from or 1
      to = to or len
      if from < 0 then
        from = from + len + 1
      end
      if to < 0 then
        to = to + len + 1
      end
      for i = from, to do
        table.insert (r, l[i])
      end
      return r
    end
  }

  pipe_fn = pipe_fn or Punistd.pipe
  local pid, read_fd, write_fd, save_stdout
  if #t > 1 then
    read_fd, write_fd = pipe_fn()
    if not read_fd then
      Cimicida.errorf("error opening pipe")
    end
    pid = Punistd.fork()
    if pid == nil then
      Cimicida.errorf("error forking")
    elseif pid == 0 then
      if not Px.dup2(read_fd, Punistd.STDIN_FILENO) then
        Cimicida.errorf("error dup2-ing")
      end
      Px.close(read_fd)
      Px.close(write_fd)
      Punistd._exit(pipeline(list.sub(t, 2), pipe_fn))
    else
      save_stdout = Punistd.dup(Punistd.STDOUT_FILENO)
      if not save_stdout then
        Cimicida.errorf("error dup-ing")
      end
      if not Px.dup2(write_fd, Punistd.STDOUT_FILENO) then
        Cimicida.errorf("error dup2-ing")
      end
      Px.close(read_fd)
      Px.close(write_fd)
    end
  end

  local code, status = Px.execp(t[1])
  Px.close(Punistd.STDOUT_FILENO)

  if #t > 1 then
    Px.close(write_fd)
    Px.wait(pid)
    if not Px.dup2 (save_stdout, Punistd.STDOUT_FILENO) then
      Cimicida.errorf("error dup2-ing")
    end
    Px.close(save_stdout)
  end

  if code == 0 then
    return true, Cimicida.exitstr("pipe", status, code)
  else
    return nil, Cimicida.exitstr("pipe", status, code)
  end
end

function Px.retpath (path)
  if Pstat.stat(path) then
    return path
  end
end

function Px.binpath (bin)
  -- If executable is not in any of these directories then it should be using the complete path.
  local t = { "/usr/bin/", "/bin/", "/usr/sbin/", "/sbin/", "/usr/local/bin/", "/usr/local/sbin/" }
  for _, p in Lua.ipairs(t) do
    if Pstat.stat(p .. bin) then
      return p .. bin
    end
  end
end

--[[
  OVERRIDES for Px.exec and Px.qexec
  _bin=path to binary
  _env=environment
  _cwd=current working directory
  _stdin=standard input
  _return_code=return the exit code instead of boolean true
  _ignore_error=always return boolean true
]]

local pexec = function (args)
  local stdin, fd0  = Punistd.pipe()
  local fd1, stdout = Punistd.pipe()
  local fd2, stderr = Punistd.pipe()
  if not (fd0 and fd1 and fd2) then
    return nil, "error opening pipe"
  end
  local _, res, no, pid, err = nil, nil, nil, Punistd.fork()
  if pid == nil or pid == -1 then
    return nil, err
  elseif pid == 0 then
    Px.close(fd0)
    Px.close(fd1)
    Px.close(fd2)
    Px.dup2(stdin, Punistd.STDIN_FILENO)
    Px.dup2(stdout, Punistd.STDOUT_FILENO)
    Px.dup2(stderr, Punistd.STDERR_FILENO)
    Px.close(stdin)
    Px.close(stdout)
    Px.close(stderr)
    if args._cwd then
      res, err = Px.chdir(args._cwd)
      if not res then
        return nil, err
      end
    end
    Px.closefrom()
    Px.execve(args._bin, args, args._env)
    _, no = Perrno.errno()
    Punistd._exit(no)
  end
  Px.close(stdin)
  Px.close(stdout)
  Px.close(stderr)
  return pid, err, fd0, fd1, fd2
end

function Px.exec (args)
  local result = { stdout = {}, stderr = {} }
  local pid, err, fd0, fd1, fd2 = pexec(args)
  if not pid then
    return nil, err
  end
  if args._stdin then
    Px.write(fd0, args._stdin)
    Px.close(fd0)
  else
    Px.close(fd0)
  end
  local buf, sz, stdout, stderr = nil, 4096, {}, {}
  while true do
    buf = Punistd.read(fd1, sz)
    if buf == nil or Lua.len(buf) == 0 then
      break
    else
      stdout[#stdout + 1] = buf
    end
  end
  while true do
    buf = Punistd.read(fd2, sz)
    if buf == nil or Lua.len(buf) == 0 then
      break
    else
      stderr[#stderr + 1] = buf
    end
  end
  for ln in Lua.gmatch(Lua.concat(stdout), "([^\n]*)\n") do
    if ln ~= "" then result.stdout[#result.stdout + 1] = ln end
  end
  if #result.stdout == 0 then
    result.stdout[1] = Lua.concat(stdout)
  end
  for ln in Lua.gmatch(Lua.concat(stderr), "([^\n]*)\n") do
    if ln ~= "" then result.stderr[#result.stderr + 1] = ln end
  end
  if #result.stderr == 0 then
    result.stderr[1] = Lua.concat(stderr)
  end
  Px.close(fd1)
  Px.close(fd2)
  local _, status, code = Px.wait(pid)
  if args._return_code then
    return code, Cimicida.exitstr(args._bin, status, code), result
  elseif args._ignore_error or code == 0 then
    return true, Cimicida.exitstr(args._bin, status, code), result
  else
    return nil, Cimicida.exitstr(args._bin, status, code), result
  end
end

-- Use if caller does not care for STDIN, STDOUT or STDERR.
function Px.qexec (args)
  local pid, err = Punistd.fork()
  local res, status, code
  if pid == nil or pid == -1 then
    return nil, err
  elseif pid == 0 then
    if args._cwd then
      res, err = Px.chdir(args._cwd)
      if not res then
        return nil, err
      end
    end
    Px.closefrom()
    Px.execve(args._bin, args, args._env)
    local _, no = Perrno.errno()
    Punistd._exit(no)
  else
    local _ -- pid is unused
    _, status, code = Px.wait(pid)
  end
  -- return values depending on flags
  if args._return_code then
    return code, Cimicida.exitstr(args._bin, status, code)
  elseif args._ignore_error or code == 0 then
    return true, Cimicida.exitstr(args._bin, status, code)
  else
    return nil, Cimicida.exitstr(args._bin, status, code)
  end
end

-- read string from a polled STDIN
function Px.readin (sz)
  local fd = Punistd.STDIN_FILENO
  local str = ""
  sz = sz or 1024
  local fds = { [fd] = { events = { IN = true } } }
  while fds ~= nil do
    Ppoll.poll(fds, -1)
    if fds[fd].revents.IN then
      local buf = Punistd.read(fd, sz)
      if buf == "" then fds = nil else str = Cimicida.strf("%s%s", str, buf) end
    end
  end
  return str
end

-- atomic write
function Px.awrite (path, str, mode)
  mode = mode or 384
  local lock = {
    l_type = Pfcntl.F_WRLCK,
    l_whence = Punistd.SEEK_SET,
    l_start = 0,
    l_len = 0
  }
  local ok, err
  local fd = Px.open(path, (Pfcntl.O_CREAT | Pfcntl.O_WRONLY | Pfcntl.O_TRUNC), mode)
  ok = Lua.pcall(Px.fcntl, fd, Pfcntl.F_SETLK, lock)
  if not ok then
    return nil
  end
  local tmp, temp = Pstdlib.mkstemp(Cimicida.splitp(path) .. "/._configiXXXXXX")
  --local tmp = Px.open(temp, Pfcntl.O_WRONLY)
  Px.write(tmp, str)
  Px.fsync(tmp)
  ok, err = Lua.rename(temp, path)
  if not ok then
    return nil, err
  end
  Px.fsync(fd)
  lock.l_type = Pfcntl.F_UNLCK
  Px.fcntl(fd, Pfcntl.F_SETLK, lock)
  Px.close(fd)
  Px.close(tmp)
  return true, Cimicida.strf("Successfully wrote %s", path)
end

function Px.isdir (path)
  local stat = Pstat.stat(path)
  if stat then
    if Pstat.S_ISDIR(stat.st_mode) ~= 0 then
      return true
    end
  end
end

function Px.isfile (path)
  local stat = Pstat.stat(path)
  if stat then
    if Pstat.S_ISREG(stat.st_mode) ~= 0 then
      return true
    end
  end
end

function Px.islink (path)
  local stat = Pstat.stat(path)
  if stat then
    if Pstat.S_ISLNK(stat.st_mode) ~= 0 then
      return true
    end
  end
end

function Px.log (file, ident, msg, option, facility, level)
  local flog = Cimicida.log
  level = level or Psyslog.LOG_DEBUG
  option = option or Psyslog.LOG_NDELAY
  facility = facility or Psyslog.LOG_USER
  if file then
    flog(file, ident, msg)
  end
  Psyslog.openlog(ident, option, facility)
  Psyslog.syslog(level, msg)
  Psyslog.closelog()
end

-- From luaposix
function Px.difftime (finish, start)
  local sec, usec = 0, 0
  if finish.tv_sec then sec = finish.tv_sec end
  if start.tv_sec then sec = sec - start.tv_sec end
  if finish.tv_usec then usec = finish.tv_usec end
  if start.tv_usec then usec = usec - start.tv_usec end
  if usec < 0 then
    sec = sec - 1
    usec = usec + 1000000
  end
  return { sec = sec, usec = usec }
end

function Px.getename ()
 return Ppwd.getpwuid(Punistd.geteuid()).pw_name
end

function Px.getname ()
 return Ppwd.getpwuid(Punistd.getuid()).pw_name
end

Px.pipeline = pipeline
Px.cmd = Lua.setmetatable({}, { __index =
  function (_, key)
    local exec, bin
    -- silent execution (Px.qexec) when prepended with "-".
    if Lua.sub(key, 1, 1) == "-" then
      exec = Px.qexec
      bin = Lua.sub(key, 2)
    else
      exec = Px.exec
      bin = key
    end
    -- Search common executable directories if not a full path.
    if Lua.len(Cimicida.splitp(bin)) == 0 then
      bin = Px.binpath(bin)
    end
    return function (args)
      args._bin = bin
      return exec(args)
    end
  end
})
return Px
