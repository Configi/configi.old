local factid = require"factid"
local Ct = require"cwtest"
local T = Ct.new()

T:start"factid.uptime"
  do
    local uptime = factid.uptime()
    T:eq(type(uptime), "table")
  end
T:done()

T:start"factid.loads"
  do
    local loads = factid.loads()
    T:eq(type(loads), "table")
  end
T:done()

T:start"factid.mem"
  do
    local mem = factid.mem()
    T:eq(type(mem), "table")
  end
T:done()

T:start"factid.procs"
  do
    local loads = factid.procs()
    T:eq(type(loads), "number")
  end
T:done()

T:start"factid.sysconf"
  do
    local sysconf = factid.sysconf()
    T:eq(type(sysconf), "table")
  end
T:done()

T:start"factid.hostname"
  do
    local hostname = factid.hostname()
    T:eq(type(hostname), "string")
  end
T:done()

T:start"factid.uname"
  do
    local uname = factid.uname()
    T:eq(type(uname), "table")
  end
T:done()

T:start"factid.hostid"
  do
    local hostid = factid.hostid()
    T:eq(type(hostid), "string")
  end
T:done()

T:start"factid.timezone"
  do
    local timezone = factid.timezone()
    T:eq(type(timezone), "string")
  end
T:done()

T:start"factid.mount"
 do
   local mount = factid.mount()
   T:eq(type(mount), "table")
 end
T:done()

T:start"factid.ipaddress"
  do
    local ipaddress = factid.ipaddress()
    T:eq(type(ipaddress), "table")
  end
T:done()

T:start"factid.ifaddrs"
  do
    local ifaddrs = factid.ifaddrs()
    T:eq(type(ifaddrs), "table")
  end
T:done()

T:start"factid.utmp"
  do
    local utmp = factid.utmp()
    T:eq(type(utmp), "table")
  end
T:done()

T:start"factid.macaddrs"
  do
    local macaddrs = factid.macaddrs()
    T:eq(type(macaddrs), "table")
  end
T:done()

T:start"factid.id"
  do
    local id = factid.id()
    T:eq(type(id), "string")
  end
T:done()
