local ffi = require "ffi"
local C = ffi.C
local ffiext = {}
ffi.cdef[[
static const int EINTR = 4; /* Linux: Interrupted system call */
static const int EAGAIN = 11; /* Linux: Try again */
char *strerror(int);
int dprintf(int, const char *, ...);
]]
ffiext.dprintf = function(fd, s, ...)
  s = string.format(s, ...)
  local len = string.len(s)
  local str = ffi.new("char[?]", len + 1)
  ffi.copy(str, s, len)
  C.dprintf(fd, str)
end
ffiext.strerror = function(e, s)
  s = s or "error"
  return string.format("%s: %s\n", s, ffi.string(C.strerror(e)))
end
ffiext.retry = function(fn)
  return function(...)
    local r, e
    repeat
      r = fn(...)
      e = ffi.errno()
      if (r ~= -1) or ((r == -1) and (e ~= C.EINTR) and (e ~= C.EAGAIN)) then
        break
      end
    until((e ~= C.EINTR) and (e ~= C.EAGAIN))
    return r, e
  end
end
return ffiext
