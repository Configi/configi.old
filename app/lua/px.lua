local Lua = {
  setmetatable = setmetatable,
  pcall = pcall,
  type = type,
  next = next,
  ipairs = ipairs,
  len = string.len,
  sub = string.sub,
  format = string.format,
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
      Punistd.close(read_fd)
      Punistd.close(write_fd)
      Punistd._exit(pipeline(list.sub(t, 2), pipe_fn))
    else
      save_stdout = Punistd.dup(Punistd.STDOUT_FILENO)
      if not save_stdout then
        Cimicida.errorf("error dup-ing")
      end
      if not Px.dup2(write_fd, Punistd.STDOUT_FILENO) then
        Cimicida.errorf("error dup2-ing")
      end
      Punistd.close(read_fd)
      Punistd.close(write_fd)
    end
  end

  local code, status = Px.execp(t[1])
  Punistd.close(Punistd.STDOUT_FILENO)

  if #t > 1 then
    Punistd.close(write_fd)
    Px.wait(pid)
    if not Px.dup2 (save_stdout, Punistd.STDOUT_FILENO) then
      Cimicida.errorf("error dup2-ing")
    end
    Punistd.close(save_stdout)
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
  _stdin=standard input (STRING)
  _stdout=standard output (FILE)
  _stderr=standard error (FILE)
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
    Punistd.close(fd0)
    Punistd.close(fd1)
    Punistd.close(fd2)
    Px.dup2(stdin, Punistd.STDIN_FILENO)
    Px.dup2(stdout, Punistd.STDOUT_FILENO)
    Px.dup2(stderr, Punistd.STDERR_FILENO)
    Punistd.close(stdin)
    Punistd.close(stdout)
    Punistd.close(stderr)
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
  Punistd.close(stdin)
  Punistd.close(stdout)
  Punistd.close(stderr)
  return pid, err, fd0, fd1, fd2
end

function Px.exec (args)
  local result = { stdout = {}, stderr = {} }
  local sz = 4096
  local pid, err, fd0, fd1, fd2 = pexec(args)
  if not pid then
    return nil, err
  end
  local fdcopy = function (fileno, std, output)
    local buf, str = nil, {}
    local fd, res, msg
    if output then
      fd, msg = Px.open(output, (Pfcntl.O_CREAT | Pfcntl.F_WRLCK | Pfcntl.O_WRONLY))
      if not fd then return nil, msg end
    end
    while true do
      buf = Punistd.read(fileno, sz)
      if buf == nil or Lua.len(buf) == 0 then
        if output then
          Punistd.close(fd)
        end
        break
      elseif output then
        res, msg = Px.write(fd, buf)
        if not res then
          return nil, msg
        end
      else
        str[#str + 1] = buf
      end
    end
    if Lua.next(str) and not output then
      str = Lua.concat(str) -- table to string
      for ln in Lua.gmatch(str, "([^\n]*)\n") do
        if ln ~= "" then result[std][#result[std] + 1] = ln end
      end
      if #result[std] == 0 then
        result[std][1] = str
      end
    end
    return true
  end
  if args._stdin then
    local res, msg = Px.write(fd0, args._stdin)
    if not res then
      return nil, msg
    end
  end
  Punistd.close(fd0)
  fdcopy(fd1, "stdout", args._stdout)
  Punistd.close(fd1)
  fdcopy(fd2, "stderr", args._stderr)
  Punistd.close(fd2)
  result.pid, result.status, result.code = Px.wait(pid)
  result.bin = args._bin
  if args._return_code then
    return result.code, result
  elseif args._ignore_error or result.code == 0 then
    return true, result
  else
    return nil, result
  end
end

-- Use if caller does not care for STDIN, STDOUT or STDERR.
function Px.qexec (args)
  local pid, err = Punistd.fork()
  local result = {}
  if pid == nil or pid == -1 then
    return nil, err
  elseif pid == 0 then
    if args._cwd then
      local res, err = Px.chdir(args._cwd)
      if not res then
        return nil, err
      end
    end
    Px.closefrom()
    Px.execve(args._bin, args, args._env)
    local _, no = Perrno.errno()
    Punistd._exit(no)
  else
    result.pid, result.status, result.code = Px.wait(pid)
    result.bin = args._bin
  end
  -- return values depending on flags
  if args._return_code then
    return result.code, result
  elseif args._ignore_error or result.code == 0 then
    return true, result
  else
    return nil, result
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
      if buf == "" then fds = nil else str = Lua.format("%s%s", str, buf) end
    end
  end
  return str
end

function Px.fwrite (path, str)
  local fd = Px.open(path, (Pfcntl.O_RDWR))
  if not fd then
    return nil
  end
  return Px.write(fd, str)
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
  Punistd.close(fd)
  Punistd.close(tmp)
  return true, Lua.format("Successfully wrote %s", path)
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
