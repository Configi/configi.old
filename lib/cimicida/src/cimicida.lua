--- Lua utilities
-- @module cimicida
local Lua = {
  open = io.open,
  close = io.close,
  flush = io.flush,
  write = io.write,
  setvbuf = io.setvbuf,
  input = io.input,
  output = io.output,
  read = io.read,
  popen = io.popen,
  stderr = io.stderr,
  find = string.find,
  gsub = string.gsub,
  format = string.format,
  len = string.len,
  sub = string.sub,
  gmatch = string.gmatch,
  pcall = pcall,
  pairs = pairs,
  exit = os.exit,
  date = os.date,
  difftime = os.difftime,
  time = os.time,
  execute = os.execute,
  concat = table.concat,
  insert = table.insert,
  unpack = table.unpack
}
local cimicida = {}
local ENV = {}
_ENV = ENV

--- Format string.
-- @param str C-like string (STRING)
-- @param ... Variable number of arguments to interpolate str (VARS)
-- @return formatted string
function cimicida.strf (str, ...)
  return Lua.format(str, ...)
end

--- Output formatted string to the current output.
-- @param str C-like string (STRING)
-- @param ... Variable number of arguments to interpolate str (VARS)
function cimicida.printf (str, ...)
  Lua.write(cimicida.strf(str, ...))
end

--- Output formatted string to a specified output.
-- @param fd stream/descriptor
-- @param str C-like string (STRING)
-- @param ... Variable number of arguments to interpolate str (VARS)
function cimicida.outf (fd, str, ...)
  local o = Lua.output()
  Lua.output(fd)
  local ret, err = Lua.write(cimicida.strf(str, ...))
  Lua.output(o)
  return ret, err
end

-- Append a line break and string to an input string.
-- @param str Input string (STRING)
-- @param a String to append to str (STRING)
-- @return new string (STRING)
function cimicida.appendln (str, a)
  return cimicida.strf("%s\n%s", str, a)
end

--- Output formatted string to STDERR and return 1 as the exit status.
-- @param str C-like string (STRING)
-- @param ... Variable number of arguments to interpolate str (VARGS)
function cimicida.errorf (str, ...)
  cimicida.outf(Lua.stderr, str, ...)
  Lua.exit(1)
end


--- Call cimicida.errorf if the first argument is not nil or not false.
-- @param v value to evaluate (VALUE)
-- @param str C-like string (STRING)
-- @param ... Variable number of arguments to interpolate str (VARGS)
function cimicida.perror (v, str, ...)
  if v then
    return true
  else
    cimicida.errorf(str, ...)
  end
end

--- Output formatted string to STDERR.
-- @param str C-like string (STRING)
-- @param ... Variable number of arguments to interpolate str (VARGS)
function cimicida.warningf (str, ...)
  cimicida.outf(Lua.stderr, str, ...)
end

--- Time in the strftime(3) format %H:%M.
-- @return the time as a string (STRING)
function cimicida.timehm ()
  return Lua.date("%H:%M")
end


--- Date in the strftime(3) format %Y-%m-%d.
-- @return the date as a string (STRING)
function cimicida.dateymd ()
  return Lua.date("%Y-%m-%d")
end

--- Timestamp in the strftime(3) format %Y-%m-%d %H:%M:%S %Z%z.
-- @return the timestamp as a string (STRING)
function cimicida.timestamp ()
  return Lua.date("%Y-%m-%d %H:%M:%S %Z%z")
end

--- Check if a table has an specified value.
-- @param tbl table to search (TABLE)
-- @param value value to look for in tbl (VALUE)
-- @return a boolean value, true if v is found, nil otherwise (BOOLEAN)
function cimicida.hasv (tbl, value)
  for _, tval in Lua.pairs(tbl) do
    tval = Lua.gsub(tval, '[%c]', '')
    if tval == value then return true end
  end
end

--- Convert an array to a record.
-- Array values are converted into field names
-- @param tbl table to convert (TABLE)
-- @param def default value for each field in the record (VALUE)
-- @return the converted table (TABLE)
function cimicida.arr2rec (tbl, def)
  local t = {}
  for n = 1, #tbl do t[tbl[n]] = def end
  return t
end

--- Convert string to table.
-- Each line is a table value
-- @param str string to convert (STRING)
-- @return the table (TABLE)
function cimicida.ln2tbl (str)
  local tbl = {}
  if not str then
    return tbl
  end
  for ln in Lua.gmatch(str, "([^\n]*)\n") do
    tbl[#tbl + 1] = ln
  end
  return tbl
end

--- Split alphanumeric matches of a string into table values.
-- @param str string to convert (STRING)
-- @return the table (TABLE)
function cimicida.split2tbl (str)
  local t = {}
  for s in Lua.gmatch(str, "%w+") do
    t[#t + 1] = s
  end
  return t
end

--- Split non-space character matches of a string into table values.
-- @param str string to convert (STRING)
-- @return the table (TABLE)
function cimicida.str2tbl (str)
  local t = {}
  for s in Lua.gmatch(str, "%S+") do
    t[#t + 1] = s
  end
  return t
end

--- Filter table values.
-- Adapted from <http://stackoverflow.com/questions/12394841/safely-remove-items-from-an-array-table-while-iterating>
-- @param tbl table to operate on (TABLE)
-- @param patt pattern to filter (STRING)
-- @param plain set to true if doing plain matching (BOOLEAN)
-- @return modified table (TABLE)
function cimicida.filtertval (tbl, patt, plain)
  plain = plaint or true
  local s, c = #tbl, 0
  for n = 1, s do
    if Lua.find(tbl[n], patt, 1, plain) then
      tbl[n] = nil
    end
  end
  for n = 1, s do
    if tbl[n] ~= nil then
      c = c + 1
      tbl[c] = tbl[n]
    end
  end
  for n = c + 1, s do
    tbl[n] = nil
  end
  return tbl
end

--- Convert file into a table.
-- Each line is a table value
-- @param file file to convert (STRING)
-- @return a table (TABLE)
function cimicida.file2tbl (file)
  local _, fd = Lua.pcall(Lua.open, file, "re")
  if fd then
    Lua.flush(fd)
    local tbl = {}
    for ln in fd:lines("*L") do
      tbl[#tbl + 1] = ln
    end
    Lua.close(fd)
    return tbl
  end
end

--- Find a string in a table value.
-- string is a plain string not a pattern
-- @param tbl table to traverse (TABLE)
-- @param str string to find (STRING)
-- @param patt boolean setting for plain strings (BOOLEAN)
-- @return the matching index if string is found, nil otherwise (NUMBER)
function cimicida.tfind (tbl, str, patt)
  patt = patt or true
  local ok, found
  for n = 1, #tbl do
    ok, found = Lua.pcall(Lua.find, tbl[n], str, 1, patt)
    if ok and found then
      return n
    end
  end
end

--- Do a shallow copy of a table.
-- An nul table is created in the copy when table is encountered
-- @param tbl table to be copied (TABLE)
-- @return the copy as a table (TABLE)
function cimicida.shallowcp (tbl)
  local copy
  copy = {}
  for f, v in Lua.pairs(tbl) do
    if type(v) == "table" then
      copy[f] = {} -- first level only
    else
      copy[f] = v
    end
  end
  return copy
end

--- Split a path into its immediate location and file/directory components.
-- @param path path to split (STRING)
-- @return location (STRING)
-- @return file/directory (STRING)
function cimicida.splitp (path)
  local l = Lua.len(path)
  local c = Lua.sub(path, l, l)
  while l > 0 and c ~= "/" do
    l = l - 1
    c = Lua.sub(path, l, l)
  end
  if l == 0 then
    return '', path
  else
    return Lua.sub(path, 1, l - 1), Lua.sub(path, l + 1)
  end
end


--- Check if a path is a file or not.
-- @param file path to the file (STRING)
-- @return true if path is a file, nil otherwise (BOOLEAN)
function cimicida.isfile (file)
  local fd = Lua.open(file, "rb")
  if fd then
    Lua.close(fd)
    return true
  end
end

--- Read a file/path.
-- @param file path to the file (STRING)
-- @param mode io.open mode (STRING)
-- @return the contents of the file, nil if the file cannot be read or opened (STRING or NIL)
function cimicida.fopen (file, mode)
  mode = mode or "rb"
  local _, fd = Lua.pcall(Lua.open, file, mode)
  if fd then
    Lua.input(fd)
    local str = Lua.read("*a")
    Lua.flush(fd)
    Lua.close(fd)
    if not str then
      return
    end
    return str
  end
end

--- Write a string to a file/path.
-- @param path path to the file (STRING)
-- @param str string to write (STRING)
-- @param mode io.open mode (STRING)
-- @return true if the write succeeded, nil and the error message otherwise (BOOLEAN)
function cimicida.fwrite (path, str, mode)
  local setvbuf, write = Lua.setvbuf, Lua.write
  mode = mode or "we+"
  local fd = Lua.open(path, mode)
  if fd then
    fd:setvbuf("no")
    local _, err = fd:write(str)
    Lua.flush(fd)
    Lua.close(fd)
    if err then
      return nil, err
    end
    return true
  end
end

--- Get line.
-- Given a line number return the line as a string.
-- @param ln line number (NUMBER)
-- @param file (STRING)
-- @return the line (STRING)
function cimicida.getln (ln, file)
  local str = cimicida.fopen(file)
  local i = 0
  for line in Lua.gmatch(str, "([^\n]*)\n") do
    i = i + 1
    if i == ln then return line end
  end
end

--- Simple string interpolation.
-- Given a record, interpolate by replacing field names with the respective value
-- Example:
-- tbl = { "field" = "value" }
-- str = [[ this is the {{ field }} ]]
-- If passed with these arguments 'this is the {{ field }}' becomes 'this is the value'
-- @param str string to interpolate (STRING)
-- @param tbl table (record) to deduce values from (TABLE)
-- @return processed string (STRING)
function cimicida.sub (str, tbl)
  -- note: string coercion
  local _
  _, str = Lua.pcall(Lua.gsub, str, '{{[%s]-([%w_]+)[%s]-}}', function (v) return tbl[v] end)
  _, str = Lua.pcall(Lua.gsub, str, '{{[%s]-([%w_]+)%.([%w_]+)[%s]-}}', function (t, v) return tbl[t][v] end)
  return str
end

--- Generate a string based on the values returned by os.execute or px.exec.
--- Usually used inside cimicida.mmsg
-- @param proc process name (STRING)
-- @param status exit status (STRING)
-- @param code exit code (NUMBER)
-- @return a formatted string (STRING)
function cimicida.exitstr (proc, status, code)
  if status == "exit" or status == "exited" then
    return cimicida.strf("%s: Exited with code %s", proc, code)
  end
  if status == "signal" or status == "killed" then
    return cimicida.strf("%s: Caught signal %s", proc, code)
  end
end

--- Check if "yes" or a "true" was passed.
-- @param s string (STRING)
-- @return the boolean true if the string matches, nil otherwise (BOOLEAN)
function cimicida.truthy (s)
  if s == "yes" or
     s == "YES" or
     s == "true" or
     s == "True" or
     s == "TRUE" then
     return true
  end
end

--- Convert a "no" or a "false" was passed.
-- @param s string (STRING)
-- @return the boolean true if the string matches, nil otherwise (BOOLEAN)
function cimicida.falsy (s)
  if s == "no" or
     s == "NO" or
     s == "false" or
     s == "False" or
     s == "FALSE" then
     return true
  end
end

--- Wrap io.popen also known as popen(3)
-- The command has a script preamble.
-- 1. Exit immediately if a command exits with a non-zero status
-- 2. Pathname expansion is disabled.
-- 3. STDIN is closed
-- 4. Copy STDERR to STDOUT
-- 5. Finally replace the shell with the command
-- @param str command to popen(3) (STRING)
-- @param cwd current working directory (STRING)
-- @param ignore_error boolean setting to ignore errors (BOOLEAN)
-- @param return_code boolean setting to return exit code (BOOLEAN)
-- @return the output as a string if the command exits with a non-zero status, nil otherwise (STRING or BOOLEAN)
-- @return a status output from cimicida.exitstr as a string (STRING)
function cimicida.popen (str, cwd, _ignore_error, _return_code)
  local header = [[  set -ef
  export LC_ALL=C
  exec 0>&- 2>&1
  ]]
  if cwd then
    str = cimicida.strf("%scd %s\n%s", header, cwd, str)
  else
    str = cimicida.strf("%s%s", header, str)
  end
  local pipe = Lua.popen(str, "re")
  Lua.flush(pipe)
  local tbl = {}
  for ln in pipe:lines() do
    tbl[#tbl + 1] = ln
  end
  local _, status, code = Lua.close(pipe)
  if _return_code then
    return code, cimicida.exitstr("io.popen", status, code)
  elseif _ignore_error or code == 0 then
    return tbl, cimicida.exitstr("io.popen", status, code)
  else
    return nil, cimicida.exitstr("io.popen", status, code)
  end
end

--- Wrap io.popen also known as popen(3)
-- Unlike cimicida.popen this writes to the pipe
-- The command has a script preamble.
-- 1. Exit immediately if a command exits with a non-zero status
-- 2. Pathname expansion is disabled.
-- 3. STDOUT is closed
-- 4. STDERR is closed
-- 5. Finally replace the shell with the command
-- @param str command to popen(3) (STRING)
-- @param data string to feed to the pipe (STRING)
-- @return the true if the command exits with a non-zero status, nil otherwise (BOOLEAN)
-- @return a status output from cimicida.exitstr as a string (STRING)
function cimicida.pwrite (str, data)
  local write = Lua.write
  str = [[  set -ef
  export LC_ALL=C
  exec ]] .. str
  local pipe = Lua.popen(str, "we")
  Lua.flush(pipe)
  pipe:write(data)
  local _, status, code = Lua.close(pipe)
  if code == 0 then
    return true, cimicida.exitstr("io.popen", status, code)
  else
    return nil, cimicida.exitstr("io.popen", status, code)
  end
end

--- Wrap os.execute also known as system(3).
-- The command has a script preamble.
-- 1. Exit immediately if a command exits with a non-zero status
-- 2. Pathname expansion is disabled.
-- 3. STDERR and STDIN are closed
-- 4. STDOUT is piped to /dev/null
-- 5. Finally replace the shell with the command
-- @param str command to pass to system(3) (STRING)
-- @return true if exit code is equal to zero, nil otherwise (BOOLEAN)
-- @return a status output from cimicida.exitstr as a string (STRING)
function cimicida.system (str)
  local set = [[  set -ef
  export LC_ALL=C
  exec 0>&- 2>&- 1>/dev/null
  exec ]]
  local redir = [[ 0>&- 2>&- 1>/dev/null ]]
  local _, status, code = Lua.execute(set .. str .. redir)
  if code == 0 then
    return true, cimicida.exitstr("os.execute", status, code)
  else
    return nil, cimicida.exitstr("os.execute", status, code)
  end
end

--- Wrap os.execute also known as system(3).
-- Similar to cimicida.system but it does not replace the shell.
-- Suitable for scripts.
-- @param str string to pass to system(3) (STRING)
-- @return true if exit code is equal to zero, nil otherwise (BOOLEAN)
-- @return a status output from cimicida.exitstr as a string (STRING)
function cimicida.execute (str)
  local set = [[  set -ef
  exec 0>&- 2>&- 1>/dev/null
  ]]
  local _, status, code = Lua.execute(set .. str)
  if code == 0 then
    return true, cimicida.exitstr("os.execute", status, code)
  else
    return nil, cimicida.exitstr("os.execute", status, code)
  end
end

--- Run a shell pipe.
-- @param ... a vararg containing the command pipe. The first argument should be popen or execute
-- @return the output from cimicida.popen or cimicida.execute, nil if popen or execute was not passed (STRING or BOOLEAN)
function cimicida.pipeline (...)
  local pipe = {}
  local cmds = {...}
  for n = 2, #cmds do
    pipe[#pipe + 1] = Lua.concat(cmds[n], " ")
    if n ~= #cmds then pipe[#pipe + 1] = " | " end
  end
  if cmds[1] == "popen" then
    return cimicida.popen(Lua.concat(pipe))
  elseif cmds[1] == "execute" then
    return cimicida.execute(Lua.concat(pipe))
  else
    return
  end
end

--- Time a function run.
-- @param f the function (FUNCTION)
-- @param ... a vararg containing the arguments for the function (VARGS)
-- @return the seconds elapsed as a number (NUMBER)
-- @return the return values of the function (VALUE)
function cimicida.time(f, ...)
  local t1 = Lua.time()
  local fn = {f(...)}
  return Lua.unpack(fn), Lua.difftime(Lua.time() , t1)
end

--- Escape quotes ",'.
-- @param str string to quote (STRING)
-- @return quoted string (STRING)
function cimicida.escapep (str)
  str = Lua.gsub(str, [["]], [[\"]])
  str = Lua.gsub(str, [[']], [[\']])
  return str
end

--- Log to a file.
-- @param file path name of the file (STRING)
-- @param ident identification (STRING)
-- @param msg string to log (STRING)
-- @return a boolean value, true if not errors, nil otherwise (BOOLEAN)
function cimicida.log (file, ident, msg)
  local setvbuf = Lua.setvbuf
  local openlog = function (f)
    local fd = Lua.open(f, "ae+")
    if fd then
      return fd
    end
  end
  local fd = openlog(file)
  local log = "%s %s: %s\n"
  local timestamp = Lua.date("%a %b %d %T")
  fd:setvbuf("line")
  local _, err = cimicida.outf(fd, log, timestamp, ident, msg)
  Lua.flush(fd)
  Lua.close(fd)
  if err then
    return nil, err
  end
  return true
end

--- Insert a value to a table position if the first argument is not nil or not false.
-- Wraps table.insert().
-- @param bool value to evaluate (VALUE)
-- @param list table to insert to (TABLE)
-- @param pos position in the table (NUMBER)
-- @param value value to insert (VALUE)
-- @return the result of table.insert() (VALUE)
function cimicida.insertif (bool, list, pos, value)
  if bool then
    return Lua.insert(list, pos, value)
  end
end

--- Return the second argument if the first argument is not nil or not false.
-- For value functions there should be no evaluation in the arguments.
-- @param bool value to evaluate (VALUE)
-- @param value to return (VALUE)
-- @return the value if bool is not nil or not false
function cimicida.returnif (bool, value)
  if bool then
    return (value)
  end
end

--- Return the second argument if the first argument is nil or false.
-- @param bool value to evaluate (VALUE)
-- @param value to return (VALUE)
-- @return the value if bool is nil or false
function cimicida.returnifnot (bool, value)
  if bool == false or bool == nil then
    return value
  end
end

return cimicida
