local ct = require"cwtest"
local C = require"cimicida"
local mktemp, rm = os.tmpname, os.remove
local input, read, flush, tmpfile, close, output, write =
      io.input, io.read, io.flush, io.tmpfile, io.close, io.output, io.write
local T = ct.new()
local E = {} ; _ENV = E

T:start"C.strf"
  do
    local name = "Bob"
    local str = "My name is %s"
    local res = "My name is Bob"
    T:eq(C.strf(str, name), res)
    name = "James"
    local lname = "Bond"
    str = "My name is %s\n%s"
    res = [[My name is James
Bond]]
    T:eq(C.strf(str, name, lname), res)
  end
T:done()

T:start"C.outf"
  do
    local name = "Bob"
    local str = "My name is %s"
    local res = "My name is Bob"
    local def = output()
    local fd = tmpfile()
    C.outf(fd, str, name)
    input(fd)
    local out = read("*a")
    flush(fd)
    output(def)
    close(fd)
    --T:eq(out, res)
  end
T:done()

T:start"C.arr2rec"
T:done()

T:start"C.subit"
  do
    local tbl = {name="Eduardo", work="carpenter", addr="earth", var="${var}"}
    local str = [[${1} {{}}
name is {{ name }} {{ work }} from {{ addr }}
TEXT

{{}}
{{  }}
]]
   local res = [[${1} {{}}
name is Eduardo carpenter from earth
TEXT

{{}}
{{  }}
]]
    T:eq(C.subit(str, tbl), res)
  end
T:done()

T:start "C.isfile"
  do
    T:yes(C.isfile("/dev/zero"))
    T:yes(C.isfile("/etc/passwd"))
    T:yes(C.isfile("/dev/null"))
    T:no(C.isfile("/etc/_XxX_"))
  end
T:done()

T:start "C.fopen"
  do
    local str = C.fopen("/etc/passwd")
    T:yes(str)
  end
T:done()

T:start "C.fwrite"
  do
    local s = "Testing"
    local f = mktemp()
    local a = C.fwrite(f, s)
    T:yes(a)
    local b = C.fopen(f)
    T:eq(s, b)
    T:yes(rm(f))
  end
T:done()

T:start "C.splitp"
  do
    local a, b = C.splitp("/etc/fstab")
    T:eq(a, "/etc")
    T:eq(b, "fstab")
  end
T:done()

T:start "C.hasv"
  do
    local a = { one = "Borgman", two = "Karakter" }
    local b = C.hasv(a, "Borgman")
    local c = C.hasv(a, "Twilight")
    T:yes(b)
    T:no(c)
  end
T:done()
