local Lua = {
  ipairs = ipairs,
  pairs = pairs,
  tonumber = tonumber,
  next = next,
  len = string.len,
  match = string.match,
  format = string.format,
  find = string.find
}
local Lc = require"cimicida"
local Pstat = require"posix.sys.stat"
local Pdirent = require"posix.dirent"
local Px = require"px"
local Cmd = Px.cmd
local factid_c = require"factid_c"
local factid = factid_c
local ENV = {}
_ENV = ENV

--- Deduce the distro ID from /etc/os-release or /etc/*release.
-- @return the id as a string (STRING)
function factid.osfamily ()
  local id
  if Pstat.stat("/etc/os-release") then
    id = Lua.match(Lc.fopen("/etc/os-release"), "ID[%s]*=[%s%p]*([%w]+)")
  elseif Pstat.stat("/etc/openwrt_release") then
    id = "openwrt"
  end
  if Lua.len(id) == 0 then
    return nil, "factid.osfamily: string.match failed."
  end
  return id
end

--- Deduce the distro NAME from /etc/os-release or /etc/*release.
-- @return the name as a string (STRING)
function factid.operatingsystem ()
  local name
  if Pstat.stat("/etc/os-release") then
    name = Lua.match(Lc.fopen("/etc/os-release"), "NAME[%s]*=[%s%p]*([%w]+)")
  elseif Pstat.stat("/etc/openwrt_release") then
    name = "OpenWRT"
  end
  if Lua.len(name) == 0 then
    return nil, "factid.operatingsystem: string.match failed."
  end
  return name
end

--- Gather ...
-- Requires Linux sysfs support.
-- @return partitions as a partition name and size pair (TABLE)
function factid.partitions ()
  local partitions = {}
  local sysfs = Pstat.stat("/sys/block")
  if Pstat.S_ISDIR(sysfs.st_mode) == 0 then
    return nil, "factid.partitions: No sysfs support detected."
  end
  for partition in Pdirent.files("/sys/block/") do
    if not Lua.find(partition, "^%.") then
      local size = Lua.tonumber(Lc.fopen("/sys/block/" .. partition .. "/size" ))
      partitions[partition] = size*512
    end
  end
  if not Lua.next(partitions) then
    return nil, "factid.partitions: posix.dirent failed."
  end
  return partitions
end

function factid.interfaces ()
  local ifs = {}
  for _, y in Lua.ipairs(factid.ifaddrs()) do
    if y.ipv4 then
      ifs[y.interface] = {}
      ifs[y.interface]["ipv4"] = y.ipv4
    elseif y.ipv6 then
      ifs[y.interface]["ipv6"] = y.ipv6
    end
  end
  return ifs
end

function factid.aws_instance_id ()
  local ok, err, res
  local curl, wget = Px.binpath("curl"), Px.binpath("wget")
  local url = "http://169.254.169.254/latest/meta-data/instance-id"
  if curl then
    ok, err, res = Cmd[curl]{ url }
  elseif wget then
    ok, err, res = Cmd[wget]{ "-q", "-O-", url }
  end
  if ok then
    if not Lua.next(res.stdout) then
      return nil, "factid.aws_instance_id: No stdout."
    end
    local id = res.stdout[1]
    if Lua.len(id) == 0 then
      return nil, "factid.aws_instance_id: Empty stdout."
    else
      return id
    end
  else
    return nil, err
  end
end

-- XXX TODO WORK IN PROGRESS
function factid.gather ()
  local fact = {}
  fact.version = "0.1.0"

  do
    local hostname = factid.hostname()
    fact.hostname = {}
    fact.hostname.string = hostname
    fact.hostname[hostname] = true
  end

  do
    local uniqueid = factid.hostid()
    fact.uniqueid = {}
    fact.uniqueid.string = uniqueid
    fact.uniqueid[uniqueid] = true
  end

  do
    local timezone = factid.timezone()
    fact.timezone = {}
    fact.timezone.string = timezone
    fact.timezone[timezone] = true
  end

  do
    local procs = factid.sysconf().procs
    procs = Lua.tonumber(procs)
    fact.physicalprocessorcount = {}
    fact.physicalprocessorcount.number = procs
    fact.physicalprocessorcount[procs] = true
  end

  do
    local osfamily = factid.osfamily()
    fact.osfamily = {}
    fact.osfamily.string = osfamily
    fact.osfamily[osfamily] = true
  end

  do
    local operatingsystem = factid.operatingsystem()
    fact.operatingsystem = {}
    fact.operatingsystem.string = operatingsystem
    fact.operatingsystem[operatingsystem] = true
  end

  do
    local uname = factid.uname()
    local kernel = uname.sysname
    fact.kernel = {}
    fact.kernel.string = kernel
    fact.kernel[kernel] = true
    local architecture = uname.machine
    fact.architecture = {}
    fact.architecture.string = architecture
    fact.architecture[architecture] = true
    -- kernel version information are strings
    local v1, v2, v3 = Lua.match(uname.release, "(%d+).(%d+).(%d+)")
    kernelmajversion = Lua.format("%d.%d", v1, v2)
    fact.kernelmajversion = {}
    fact.kernelmajversion.string = kernelmajversion
    fact.kernelmajversion[kernelmajversion] = true
    kernelrelease = uname.release
    fact.kernelrelease = {}
    fact.kernelrelease.string = kernelrelease
    fact.kernelrelease[kernelrelease] = true
    kernelversion = Lua.format("%d.%d.%d", v1, v2, v3)
    fact.kernelversion = {}
    fact.kernelversion.string = kernelversion
    fact.kernelversion[kernelversion] = true
  end

  do
    -- uptime table values are integers
    -- fields: days, hours, totalseconds, totalminutes
    local uptime = factid.uptime()
    fact.uptime = {}
    fact.uptime.days = {}
    fact.uptime.days.number = uptime.days
    fact.uptime.days[uptime.days] = true
    fact.uptime.hours = {}
    fact.uptime.hours.number = uptime.hours
    fact.uptime.hours[uptime.hours] = true
    fact.uptime.totalseconds = {}
    fact.uptime.totalseconds.number = uptime.totalseconds
    fact.uptime.totalseconds[uptime.totalseconds] = true
    fact.uptime.totalminutes = {}
    fact.uptime.totalminutes.number = uptime.totalminutes
    fact.uptime.totalminutes[uptime.totalminutes] = true
  end

  do
    -- string, number table
    -- { sda = 500000 }
    local partitions = factid.partitions()
    fact.partitions = {}
    fact.partitions.table = partitions
    for p, s in Lua.pairs(partitions) do
      fact.partitions[p] = {}
      fact.partitions[p][s] = true
    end
  end

  do
    -- string, string table
    -- fields: ipv4, ipv6 default outgoing
    local ipaddress = factid.ipaddress()
    fact.ipaddress = {}
    fact.ipaddress.table = ipaddress
    for p, i in Lua.pairs(ipaddress) do
      fact.ipaddress[p] = {}
      fact.ipaddress[p][i] = true
    end
  end

  do
    -- string, number table
    -- fields: mem_unit, freehigh, freeswap, totalswap, bufferram, sharedram, freeram, totalram
    local memory = factid.mem()
    fact.memory = {}
    fact.memory.table = memory
    for k, v in Lua.pairs(memory) do
      fact.memory[k] = {}
      fact.memory[k][v] = true
    end
  end

  do
    -- { eth0 = {ipv4=, ipv6=} }
    local interfaces = factid.interfaces()
    fact.interfaces = {}
    fact.interfaces.table = interfaces
    for interface, prototbl in Lua.pairs(interfaces) do
      fact.interfaces[interface] = {}
      for proto, ip in Lua.pairs(prototbl) do
        fact.interfaces[interface][proto] = {}
        fact.interfaces[interface][proto][ip] = true
      end
    end
  end

  -- { dir, type, freq, opts, passno, fsname }
  -- fact.mounts = factid.mount()
  return fact
end

return factid
