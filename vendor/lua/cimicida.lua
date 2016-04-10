--- Lua utilities
-- @module cimicida
local io, string, os, table = io, string, os, table
local type, pcall, load, setmetatable, ipairs, next = type, pcall, load, setmetatable, ipairs, next
local ENV = {}
_ENV = ENV

--- Output formatted string to the current output.
-- @function printf
-- @param str C-like string (STRING)
-- @param ... Variable number of arguments to interpolate str (VARARGS)
local printf = function (str, ...)
  io.write(string.format(str, ...))
end

--- Output formatted string to a specified output.
-- @function fprintf
-- @param fd stream/descriptor
-- @param str C-like string (STRING)
-- @param ... Variable number of arguments to interpolate str (VARARGS)
local fprintf = function (fd, str, ...)
  local o = io.output()
  io.output(fd)
  local ret, err = printf(str, ...)
  io.output(o)
  return ret, err
end

--- Output formatted string to STDERR.
-- @function warn
-- @param str C-like string (STRING)
-- @param ... Variable number of arguments to interpolate str (VARARGS)
local warn = function (str, ...)
  fprintf(io.stderr, str, ...)
end

--- Output formatted string to STDERR and return 1 as the exit status.
-- @function errorf
-- @param str C-like string (STRING)
-- @param ... Variable number of arguments to interpolate str (VARARGS)
local errorf = function (str, ...)
  warn(str, ...)
  os.exit(1)
end

--- Call cimicida.errorf if the first argument is false (i.e. nil or false).
-- @function assertf
-- @param v value to evaluate
-- @param str C-like string (STRING)
-- @param ... Variable number of arguments to interpolate str (VARARGS)
local assertf = function (v, str, ...)
  if v then
    return true
  else
    errorf(str, ...)
  end
end

-- Append a line break and string to an input string.
-- @function append
-- @param str Input string (STRING)
-- @param a String to append to str (STRING)
-- @return new string (STRING)
local append = function (str, a)
  return string.format("%s\n%s", str, a)
end

--- Time in the strftime(3) format %H:%M.
-- @function timehm
-- @return the time as a string (STRING)
local timehm = function ()
  return os.date("%H:%M")
end


--- Date in the strftime(3) format %Y-%m-%d.
-- @function dateymd
-- @return the date as a string (STRING)
local dateymd = function ()
  return os.date("%Y-%m-%d")
end

--- Timestamp in the strftime(3) format %Y-%m-%d %H:%M:%S %Z%z.
-- @function timestamp
-- @return the timestamp as a string (STRING)
local timestamp = function ()
  return os.date("%Y-%m-%d %H:%M:%S %Z%z")
end

--- Check if a table has an specified string.
-- @function find_string
-- @param tbl table to search (TABLE)
-- @param string value to look for in tbl (STRING)
-- @return a boolean value, true if v is found, nil otherwise (BOOLEAN)
local find_string = function (tbl, value)
  for _, tval in next, tbl do
    tval = string.gsub(tval, '[%c]', '')
    if tval == value then return true end
  end
end

--- Convert an array to a record.
-- Array values are converted into field names
-- @function arr_to_rec
-- @warning Does not check if input table is a sequence.
-- @param tbl the properly sequenced table to convert (TABLE)
-- @param def default value for each field in the record (VALUE)
-- @return the converted table (TABLE)
local arr_to_rec = function (tbl, def)
  local t = {}
  for n = 1, #tbl do t[tbl[n]] = def end
  return t
end

--- Convert string to table.
-- Each line is a table value
-- @function ln_to_tbl
-- @param str string to convert (STRING)
-- @return the table (TABLE)
local ln_to_tbl = function (str)
  local tbl = {}
  if not str then
    return tbl
  end
  for ln in string.gmatch(str, "([^\n]*)\n") do
    tbl[#tbl + 1] = ln
  end
  return tbl
end

--- Split alphanumeric matches of a string into table values.
-- @function word_to_tbl
-- @param str string to convert (STRING)
-- @return the table (TABLE)
local word_to_tbl = function (str)
  local t = {}
  for s in string.gmatch(str, "%w+") do
    t[#t + 1] = s
  end
  return t
end

--- Split non-space character matches of a string into table values.
-- @function str_to_tbl
-- @param str string to convert (STRING)
-- @return the table (TABLE)
local str_to_tbl = function (str)
  local t = {}
  for s in string.gmatch(str, "%S+") do
    t[#t + 1] = s
  end
  return t
end

--- Escape a string for pattern usage
-- From lua-nucleo.
-- @function escape_pattern
-- @param str string to escape (STRING)
-- @return a new string (STRING)
local escape_pattern = function (str)
  local matches =
  {
    ["^"] = "%^",
    ["$"] = "%$",
    ["("] = "%(",
    [")"] = "%)",
    ["%"] = "%%",
    ["."] = "%.",
    ["["] = "%[",
    ["]"] = "%]",
    ["*"] = "%*",
    ["+"] = "%+",
    ["-"] = "%-",
    ["?"] = "%?",
    ["\0"] = "%z"
  }
  return string.gsub(str, ".", matches)
end

--- Filter table values.
-- Adapted from <http://stackoverflow.com/questions/12394841/safely-remove-items-from-an-array-table-while-iterating>
-- @function filter_tbl_value
-- @param tbl table to operate on (TABLE)
-- @param patt pattern to filter (STRING)
-- @param plain set to true if doing plain matching (BOOLEAN)
-- @return modified table (TABLE)
local filter_tbl_value = function (tbl, patt, plain)
  plain = plain or nil
  local s, c = #tbl, 0
  for n = 1, s do
    if string.find(tbl[n], patt, 1, plain) then
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
-- @function file_to_tbl
-- @param file file to convert (STRING)
-- @return a table (TABLE)
local file_to_tbl = function (file)
  local _, fd = pcall(io.open, file, "re")
  if fd then
    io.flush(fd)
    local tbl = {}
    for ln in fd:lines("*L") do
      tbl[#tbl + 1] = ln
    end
    io.close(fd)
    return tbl
  end
end

--- Find a string in a table value.
-- string is a plain string not a pattern
-- @function find_in_tbl
-- @param tbl properly sequenced table to traverse (TABLE)
-- @param str string to find (STRING)
-- @param patt boolean setting for plain strings (BOOLEAN)
-- @return the matching index if string is found, nil otherwise (NUMBER)
local find_in_tbl = function (tbl, str, patt)
  patt = patt or nil
  local ok, found
  for n = 1, #tbl do
    ok, found = pcall(Lua.find, tbl[n], str, 1, patt)
    if ok and found then
      return n
    end
  end
end

--- Do a shallow copy of a table.
-- An empty table is created in the copy when a table is encountered
-- @function shallow_cp
-- @param tbl table to be copied (TABLE)
-- @return the copy as a table (TABLE)
local shallow_cp = function (tbl)
  local copy = {}
  for f, v in next, tbl do
    if type(v) == "table" then
      copy[f] = {} -- first level only
    else
      copy[f] = v
    end
  end
  return copy
end

--- Split a path into its immediate location and file/directory components.
-- @function split_path
-- @param path path to split (STRING)
-- @return location (STRING)
-- @return file/directory (STRING)
local split_path = function (path)
  local l = string.len(path)
  local c = string.sub(path, l, l)
  while l > 0 and c ~= "/" do
    l = l - 1
    c = string.sub(path, l, l)
  end
  if l == 0 then
    return '', path
  else
    return string.sub(path, 1, l - 1), string.sub(path, l + 1)
  end
end


--- Check if a path is a file or not.
-- @function isfile
-- @param file path to the file (STRING)
-- @return true if path is a file, nil otherwise (BOOLEAN)
local isfile = function (file)
  local fd = io.open(file, "rb")
  if fd then
    io.close(fd)
    return true
  end
end

--- Read a file/path.
-- @function fopen
-- @param file path to the file (STRING)
-- @return the contents of the file, nil if the file cannot be read or opened (STRING or NIL)
local fopen = function (file)
  local str
  for s in io.lines(file, 2^12) do
    str = string.format("%s%s", str or "", s)
  end
  if string.len(str) ~= 0 then
    return str
  end
end

--- Write a string to a file/path.
-- @function fwrite
-- @param path path to the file (STRING)
-- @param str string to write (STRING)
-- @param mode io.open mode (STRING)
-- @return true if the write succeeded, nil and the error message otherwise (BOOLEAN)
local fwrite = function (path, str, mode)
  local setvbuf, write = io.setvbuf, io.write
  mode = mode or "we+"
  local fd = io.open(path, mode)
  if fd then
    fd:setvbuf("no")
    local _, err = fd:write(str)
    io.flush(fd)
    io.close(fd)
    if err then
      return nil, err
    end
    return true
  end
end

--- Get line.
-- Given a line number return the line as a string.
-- @function getln
-- @param ln line number (NUMBER)
-- @param file (STRING)
-- @return the line (STRING)
local getln = function (ln, file)
  local str = fopen(file)
  local i = 0
  for line in string.gmatch(str, "([^\n]*)\n") do
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
-- @function sub
-- @param str string to interpolate (STRING)
-- @param tbl table (record) to deduce values from (TABLE)
-- @return processed string (STRING)
local sub = function (str, tbl)
  local t, _ = {}, nil
  _, str = pcall(string.gsub, str, "{{[%s]-([%g]+)[%s]-}}",
    function (s)
      t.type = type
      local code = [[
        V=%s
        if type(V) == "function" then
          V=V()
        end
      ]]
      local lua = string.format(code, s)
      local chunk, err = load(lua, lua, "t", setmetatable(t, {__index=tbl}))
      if chunk then
        chunk()
        return t.V
      else
        return s
      end
    end) -- pcall
  return str
end

--- Generate a string based on the values returned by os.execute or px.exec.
-- @function exit_string
-- @param proc process name (STRING)
-- @param status exit status (STRING)
-- @param code exit code (NUMBER)
-- @return a formatted string (STRING)
local exit_string = function (proc, status, code)
  if status == "exit" or status == "exited" then
    return string.format("%s: Exited with code %s", proc, code)
  end
  if status == "signal" or status == "killed" then
    return string.format("%s: Caught signal %s", proc, code)
  end
end

--- Check if "yes" or a "true" was passed.
-- @function truthy
-- @param s string (STRING)
-- @return the boolean true if the string matches, nil otherwise (BOOLEAN)
local truthy = function (s)
  if s == "yes" or
     s == "YES" or
     s == "true" or
     s == "True" or
     s == "TRUE" then
     return true
  end
end

--- Convert a "no" or a "false" was passed.
-- @function falsy
-- @param s string (STRING)
-- @return the boolean true if the string matches, nil otherwise (BOOLEAN)
local falsy = function (s)
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
-- @function popen
-- @param str command to popen(3) (STRING)
-- @param cwd current working directory (STRING)
-- @param ignore_error boolean setting to ignore errors (BOOLEAN)
-- @param return_code boolean setting to return exit code (BOOLEAN)
-- @return the output as a string if the command exits with a non-zero status, nil otherwise (STRING or BOOLEAN)
-- @return a status output from cimicida.exitstr as a string (STRING)
local popen = function (str, cwd, _ignore_error, _return_code)
  local result = {}
  local header = [[  set -ef
  export LC_ALL=C
  exec 0>&- 2>&1
  ]]
  if cwd then
    str = string.format("%scd %s\n%s", header, cwd, str)
  else
    str = string.format("%s%s", header, str)
  end
  local pipe = io.popen(str, "re")
  io.flush(pipe)
  local tbl = {}
  for ln in pipe:lines() do
    tbl[#tbl + 1] = ln
  end
  local _
  _, result.status, result.code = io.close(pipe)
  result.bin = "io.popen"
  if _return_code then
    return result.code, result
  elseif _ignore_error or result.code == 0 then
    return tbl, result
  else
    return nil, result
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
-- @function pwrite
-- @param str command to popen(3) (STRING)
-- @param data string to feed to the pipe (STRING)
-- @return the true if the command exits with a non-zero status, nil otherwise (BOOLEAN)
-- @return a status output from cimicida.exitstr as a string (STRING)
local pwrite = function (str, data)
  local result = {}
  local write = io.write
  str = [[  set -ef
  export LC_ALL=C
  exec ]] .. str
  local pipe = io.popen(str, "we")
  io.flush(pipe)
  pipe:write(data)
  local _
  _, result.status, result.code = io.close(pipe)
  if result.code == 0 then
    return true, result
  else
    return nil, result
  end
end

--- Wrap os.execute also known as system(3).
-- The command has a script preamble.
-- 1. Exit immediately if a command exits with a non-zero status
-- 2. Pathname expansion is disabled.
-- 3. STDERR and STDIN are closed
-- 4. STDOUT is piped to /dev/null
-- 5. Finally replace the shell with the command
-- @function system
-- @param str command to pass to system(3) (STRING)
-- @return true if exit code is equal to zero, nil otherwise (BOOLEAN)
-- @return a status output from cimicida.exitstr as a string (STRING)
local system = function (str)
  local result = {}
  local set = [[  set -ef
  export LC_ALL=C
  exec 0>&- 2>&- 1>/dev/null
  exec ]]
  local redir = [[ 0>&- 2>&- 1>/dev/null ]]
  local _
  _, result.status, result.code = os.execute(set .. str .. redir)
  result.bin = "os.execute"
  if result.code == 0 then
    return true, result
  else
    return nil, result
  end
end

--- Wrap os.execute also known as system(3).
-- Similar to cimicida.system but it does not replace the shell.
-- Suitable for scripts.
-- @function execute
-- @param str string to pass to system(3) (STRING)
-- @return true if exit code is equal to zero, nil otherwise (BOOLEAN)
-- @return a status output from cimicida.exitstr as a string (STRING)
local execute = function (str)
  local result = {}
  local set = [[  set -ef
  exec 0>&- 2>&- 1>/dev/null
  ]]
  local _
  _, result.status, result.code = os.execute(set .. str)
  if result.code == 0 then
    return true, result
  else
    return nil, result
  end
end

--- Run a shell pipe.
-- @function pipeline
-- @param ... a vararg containing the command pipe. The first argument should be popen or execute
-- @return the output from cimicida.popen or cimicida.execute, nil if popen or execute was not passed (STRING or BOOLEAN)
local pipeline = function (...)
  local pipe = {}
  local cmds = {...}
  for n = 2, #cmds do
    pipe[#pipe + 1] = table.concat(cmds[n], " ")
    if n ~= #cmds then pipe[#pipe + 1] = " | " end
  end
  if cmds[1] == "popen" then
    return popen(table.concat(pipe))
  elseif cmds[1] == "execute" then
    return execute(table.concat(pipe))
  else
    return
  end
end

--- Time a function run.
-- @function time
-- @param f the function (FUNCTION)
-- @param ... a vararg containing the arguments for the function (VARARGS)
-- @return the return values of the function (VALUE)
-- @return the seconds elapsed as a number (NUMBER)
local time = function (f, ...)
  local t1 = os.time()
  local fn = {f(...)}
  return table.unpack(fn), os.difftime(os.time() , t1)
end

--- Escape quotes ",'.
-- @function escape_quotes
-- @param str string to quote (STRING)
-- @return quoted string (STRING)
local escape_quotes = function (str)
  str = string.gsub(str, [["]], [[\"]])
  str = string.gsub(str, [[']], [[\']])
  return str
end

--- Log to a file.
-- @function log
-- @param file path name of the file (STRING)
-- @param ident identification (STRING)
-- @param msg string to log (STRING)
-- @return a boolean value, true if not errors, nil otherwise (BOOLEAN)
local log = function (file, ident, msg)
  local setvbuf = io.setvbuf
  local openlog = function (f)
    local fd = io.open(f, "ae+")
    if fd then
      return fd
    end
  end
  local fd = openlog(file)
  local log = "%s %s: %s\n"
  local timestamp = os.date("%a %b %d %T")
  fd:setvbuf("line")
  local _, err = fprintf(fd, log, timestamp, ident, msg)
  io.flush(fd)
  io.close(fd)
  if err then
    return nil, err
  end
  return true
end

--- Insert a value to a table position if the first argument is not nil or not false.
-- Wraps table.insert().
-- @function insert_if
-- @param bool value to evaluate (VALUE)
-- @param list table to insert to (TABLE)
-- @param pos position in the table (NUMBER)
-- @param value value to insert (VALUE)
-- @return the result of table.insert() (VALUE)
local insert_if = function (bool, list, pos, value)
  if bool then
    if type(value) == "table" then
      for n, i in ipairs(value) do
        local p = n - 1
        table.insert(list, pos + p, i)
      end
    else
      table.insert(list, pos, value)
    end
  end
end

--- Return the second argument if the first argument is not nil or not false.
-- For value functions there should be no evaluation in the arguments.
-- @function return_if
-- @param bool value to evaluate (VALUE)
-- @param value to return (VALUE)
-- @return the value if bool is not nil or not false
local return_if = function (bool, value)
  if bool then
    return (value)
  end
end

--- Return the second argument if the first argument is nil or false.
-- @function return_if_not
-- @param bool value to evaluate (VALUE)
-- @param value to return (VALUE)
-- @return the value if bool is nil or false
local return_if_not = function (bool, value)
  if bool == false or bool == nil then
    return value
  end
end

return {
  printf = printf,
  fprintf = fprintf,
  errorf = errorf,
  assertf = assertf,
  warn = warn,
  append = append,
  timehm = timehm,
  dateymd = dateymd,
  timestamp = timestamp,
  find_string = find_string,
  arr_to_rec = arr_to_rec,
  ln_to_tbl = ln_to_tbl,
  word_to_tbl = word_to_tbl,
  str_to_tbl = str_to_tbl,
  escape_pattern = escape_pattern,
  filter_tbl_value = filter_tbl_value,
  file_to_tbl = file_to_tbl,
  find_in_tbl = find_in_tbl,
  shallow_cp = shallow_cp,
  split_path = split_path,
  isfile = isfile,
  fopen = fopen,
  fwrite = fwrite,
  getln = getln,
  sub = sub,
  exit_string = exit_string,
  truthy = truthy,
  falsy = falsy,
  popen = popen,
  pwrite = pwrite,
  system = system,
  execute = execute,
  pipeline = pipeline,
  time = time,
  escape_quotes = escape_quotes,
  log = log,
  insert_if = insert_if,
  return_if = return_if,
  return_if_not = return_if_not
}
