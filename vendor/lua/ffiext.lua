local ffi = require "ffi"
local C = ffi.C
local ffiext = {}

ffi.cdef[[
static const int EINTR = 4; /* Interrupted system call */
static const int EAGAIN = 11; /* Try again */
char *strerror(int);
]]
ffiext.strerror = function(s)
  s = s or "error"
  return string.format("%s: %s\n", s, ffi.string(C.strerror(ffi.errno())))
end
ffiext.retry = function(fn)
  return function(...)
    local r, e
    repeat
      r = fn(...)
      e = ffi.errno()
      if r ~= -1 then
        break
      end
    until((e ~= C.EINTR) and (e ~= C.EAGAIN))
    return r, e
  end
end

return ffiext
