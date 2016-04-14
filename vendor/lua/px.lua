--- luaposix extensions and some unix utilities
-- @module px

local string, table, os = string, table, os
local setmetatable, pcall, type, next, ipairs = setmetatable, pcall, type, next, ipairs 
local lc = require"cimicida"
local pwd = require"posix.pwd"
local unistd = require"posix.unistd"
local errno = require"posix.errno"
local wait = require"posix.sys.wait"
local stat = require"posix.sys.stat"
local poll = require"posix.poll"
local fcntl = require"posix.fcntl"
local stdlib = require"posix.stdlib"
local syslog = require"posix.syslog"
local px_c = require"px_c"
local px = px_c
local ENV = {}
_ENV = ENV

local retry = function (fn)
  return function (...)
    local ret, err, errnum, e, _
    repeat
      ret, err, errnum = fn(...)
      if ret == -1 then
        _, e = errno.errno()
      end
    until(e ~= errno.EINTR)
    return ret, err, errnum
  end
end

-- Handle EINTR
px.fsync = retry(unistd.fsync)
px.chdir = retry(unistd.chdir)
px.fcntl = retry(fcntl.fcntl)
px.dup2 = retry(unistd.dup2)
px.wait = retry(wait.wait)
px.open = retry(fcntl.open)

--- Write to a file descriptor.
-- Wrapper to luaposix unistd.write.
-- @param fd file descriptor
-- @param buf string to write
-- @return true if successfully written.
function px.write (fd, buf)
  local size = string.len(buf)
  local written, err
  while (size > 0) do
    written, err = unistd.write(fd, buf)
    if written == -1 then
      local _, errno = errno.errno()
      if errno == errno.EINTR then
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
function px.execp (t, ...)
  local pid, err = unistd.fork()
  local status, code, _
  if pid == nil or pid == -1 then
    return nil, err
  elseif pid == 0 then
    if type(t) == "table" then
      unistd.exec(table.unpack(t))
      local _, no = errno.errno()
      unistd._exit(no)
    else
      unistd._exit(t(...) or 0)
    end
  else
    _, status, code = px.wait(pid)
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

  pipe_fn = pipe_fn or unistd.pipe
  local pid, read_fd, write_fd, save_stdout
  if #t > 1 then
    read_fd, write_fd = pipe_fn()
    if not read_fd then
      lc.errorf("error opening pipe")
    end
    pid = unistd.fork()
    if pid == nil then
      lc.errorf("error forking")
    elseif pid == 0 then
      if not px.dup2(read_fd, unistd.STDIN_FILENO) then
        lc.errorf("error dup2-ing")
      end
      unistd.close(read_fd)
      unistd.close(write_fd)
      unistd._exit(pipeline(list.sub(t, 2), pipe_fn))
    else
      save_stdout = unistd.dup(unistd.STDOUT_FILENO)
      if not save_stdout then
        lc.errorf("error dup-ing")
      end
      if not px.dup2(write_fd, unistd.STDOUT_FILENO) then
        lc.errorf("error dup2-ing")
      end
      unistd.close(read_fd)
      unistd.close(write_fd)
    end
  end

  local code, status = px.execp(t[1])
  unistd.close(unistd.STDOUT_FILENO)

  if #t > 1 then
    unistd.close(write_fd)
    px.wait(pid)
    if not px.dup2 (save_stdout, unistd.STDOUT_FILENO) then
      lc.errorf("error dup2-ing")
    end
    unistd.close(save_stdout)
  end

  if code == 0 then
    return true, lc.exitstr("pipe", status, code)
  else
    return nil, lc.exitstr("pipe", status, code)
  end
end

--- Checks the existence of a given path.
-- @tparam string path the path to check for.
-- @return the path if path exists.
function px.retpath (path)
  if stat.stat(path) then
    return path
  end
end

--- Deduce the complete path name of an executable.
-- Only checks standard locations.
-- @tparam string bin executable name
-- @treturn string full path name
function px.binpath (bin)
  -- If executable is not in any of these directories then it should be using the complete path.
  local t = { "/usr/bin/", "/bin/", "/usr/sbin/", "/sbin/", "/usr/local/bin/", "/usr/local/sbin/" }
  for _, p in ipairs(t) do
    if stat.stat(p .. bin) then
      return p .. bin
    end
  end
end

--[[
  OVERRIDES for px.exec and px.qexec
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
  local stdin, fd0  = unistd.pipe()
  local fd1, stdout = unistd.pipe()
  local fd2, stderr = unistd.pipe()
  if not (fd0 and fd1 and fd2) then
    return nil, "error opening pipe"
  end
  local _, res, no, pid, err = nil, nil, nil, unistd.fork()
  if pid == nil or pid == -1 then
    return nil, err
  elseif pid == 0 then
    unistd.close(fd0)
    unistd.close(fd1)
    unistd.close(fd2)
    px.dup2(stdin, unistd.STDIN_FILENO)
    px.dup2(stdout, unistd.STDOUT_FILENO)
    px.dup2(stderr, unistd.STDERR_FILENO)
    unistd.close(stdin)
    unistd.close(stdout)
    unistd.close(stderr)
    if args._cwd then
      res, err = px.chdir(args._cwd)
      if not res then
        return nil, err
      end
    end
    px.closefrom()
    px.execve(args._bin, args, args._env)
    _, no = errno.errno()
    unistd._exit(no)
  end
  unistd.close(stdin)
  unistd.close(stdout)
  unistd.close(stderr)
  return pid, err, fd0, fd1, fd2
end

--- Execute a file.
-- @tparam table arguments
-- @treturn table table of results, result.stdout and result.stderr.
function px.exec (args)
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
      fd, msg = px.open(output, (fcntl.O_CREAT | fcntl.F_WRLCK | fcntl.O_WRONLY))
      if not fd then return nil, msg end
    end
    while true do
      buf = unistd.read(fileno, sz)
      if buf == nil or string.len(buf) == 0 then
        if output then
          unistd.close(fd)
        end
        break
      elseif output then
        res, msg = px.write(fd, buf)
        if not res then
          return nil, msg
        end
      else
        str[#str + 1] = buf
      end
    end
    if next(str) and not output then
      str = table.concat(str) -- table to string
      for ln in string.gmatch(str, "([^\n]*)\n") do
        if ln ~= "" then result[std][#result[std] + 1] = ln end
      end
      if #result[std] == 0 then
        result[std][1] = str
      end
    end
    return true
  end
  if args._stdin then
    local res, msg = px.write(fd0, args._stdin)
    if not res then
      return nil, msg
    end
  end
  unistd.close(fd0)
  fdcopy(fd1, "stdout", args._stdout)
  unistd.close(fd1)
  fdcopy(fd2, "stderr", args._stderr)
  unistd.close(fd2)
  result.pid, result.status, result.code = px.wait(pid)
  result.bin = args._bin
  if args._return_code then
    return result.code, result
  elseif args._ignore_error or result.code == 0 then
    return true, result
  else
    return nil, result
  end
end

--- Execute a file.
-- Use if caller does not care for STDIN, STDOUT or STDERR.
-- @tparam table arguments
-- @treturn table table of results, result.stdout and result.stderr.
function px.qexec (args)
  local pid, err = unistd.fork()
  local result = {}
  if pid == nil or pid == -1 then
    return nil, err
  elseif pid == 0 then
    if args._cwd then
      local res, err = px.chdir(args._cwd)
      if not res then
        return nil, err
      end
    end
    px.closefrom()
    px.execve(args._bin, args, args._env)
    local _, no = errno.errno()
    unistd._exit(no)
  else
    result.pid, result.status, result.code = px.wait(pid)
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

--- Read string from a polled STDIN.
-- @tparam number bytes to read
-- @treturn string string read
function px.readin (sz)
  local fd = unistd.STDIN_FILENO
  local str = ""
  sz = sz or 1024
  local fds = { [fd] = { events = { IN = true } } }
  while fds ~= nil do
    poll.poll(fds, -1)
    if fds[fd].revents.IN then
      local buf = unistd.read(fd, sz)
      if buf == "" then fds = nil else str = string.format("%s%s", str, buf) end
    end
  end
  return str
end

--- Write to given path name.
-- Wraps px.write.
-- @tparam string path name 
-- @tparam string string to write 
-- @return true if successfully written; otherwise it returns nil
function px.fwrite (path, str)
  local fd = px.open(path, (fcntl.O_RDWR))
  if not fd then
    return nil
  end
  return px.write(fd, str)
end

--- Write to give path name atomically.
-- Wraps px.write.
-- @tparam string path name
-- @tparam string string to write
-- @tparam number octal mode when opening file
-- @return true when successfully writing; otherwise, return nil
-- @return successful message string; otherwise, return a string describing the error
function px.awrite (path, str, mode)
  mode = mode or 384
  local lock = {
    l_type = fcntl.F_WRLCK,
    l_whence = unistd.SEEK_SET,
    l_start = 0,
    l_len = 0
  }
  local ok, err
  local fd = px.open(path, (fcntl.O_CREAT | fcntl.O_WRONLY | fcntl.O_TRUNC), mode)
  ok = pcall(px.fcntl, fd, fcntl.F_SETLK, lock)
  if not ok then
    return nil
  end
  local tmp, temp = stdlib.mkstemp(lc.split_path(path) .. "/._configiXXXXXX")
  --local tmp = px.open(temp, fcntl.O_WRONLY)
  px.write(tmp, str)
  px.fsync(tmp)
  ok, err = os.rename(temp, path)
  if not ok then
    return nil, err
  end
  px.fsync(fd)
  lock.l_type = fcntl.F_UNLCK
  px.fcntl(fd, fcntl.F_SETLK, lock)
  unistd.close(fd)
  unistd.close(tmp)
  return true, string.format("Successfully wrote %s", path)
end

--- Check if a given path name is a directory.
-- @tparam string path name
-- @return true if a directory; otherwise, return nil
function px.isdir (path)
  local stat = stat.stat(path)
  if stat then
    if stat.S_ISDIR(stat.st_mode) ~= 0 then
      return true
    end
  end
end

--- Check if a given path name is a file.
-- @tparam string path name
-- @return true if a file; otherwise, return nil
function px.isfile (path)
  local stat = stat.stat(path)
  if stat then
    if stat.S_ISREG(stat.st_mode) ~= 0 then
      return true
    end
  end
end

--- Check if a given path name is a symbolic link.
-- @tparam string path name
-- @return true if a symbolic link; otherwise, return nil  
function px.islink (path)
  local stat = stat.stat(path)
  if stat then
    if stat.S_ISLNK(stat.st_mode) ~= 0 then
      return true
    end
  end
end

--- Write to the syslog and a file if given.
-- @tparam string file path name to log to.
-- @tparam string ident arbitrary identification string 
-- @tparam string msg message body
-- @tparam int option see luaposix syslog constants
-- @tparam int facility see luaposix syslog constants
-- @tparam int level see luaposix syslog constants
function px.log (file, ident, msg, option, facility, level)
  local flog = lc.log
  level = level or syslog.LOG_DEBUG
  option = option or syslog.LOG_NDELAY
  facility = facility or syslog.LOG_USER
  if file then
    flog(file, ident, msg)
  end
  syslog.openlog(ident, option, facility)
  syslog.syslog(level, msg)
  syslog.closelog()
end

-- From luaposix
function px.difftime (finish, start)
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

--- Get effective username.
-- @treturn string username
function px.getename ()
 return pwd.getpwuid(unistd.geteuid()).pw_name
end

--- Get real username.
-- @treturn string username
function px.getname ()
 return pwd.getpwuid(unistd.getuid()).pw_name
end

px.pipeline = pipeline

-- Wraps px.exec and px.qexec so you can execute a given executable like cmd["/bin/ls"]{ "/tmp" } 
-- cmd["-/bin/ls"]{ "/tmp" } to ignore the output ala px.qexec.
-- cmd.ls{"/tmp"} also works since px.binpath is called on the executable.
-- Returns a table 'result' with tables stdout and stderr (result.stdout and result.stderr)
px.cmd = setmetatable({}, { __index =
  function (_, key)
    local exec, bin
    -- silent execution (px.qexec) when prepended with "-".
    if string.sub(key, 1, 1) == "-" then
      exec = px.qexec
      bin = string.sub(key, 2)
    else
      exec = px.exec
      bin = key
    end
    -- Search common executable directories if not a full path.
    if string.len(lc.split_path(bin)) == 0 then
      bin = px.binpath(bin)
    end
    return function (args)
      args._bin = bin
      return exec(args)
    end
  end
})

return px
