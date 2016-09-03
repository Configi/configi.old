local core = {
  ipairs   = ipairs,
  pairs    = pairs,
  tonumber = tonumber,
  next     = next
}
local string = string
local util = require"cimicida"
local sysstat = require"posix.sys.stat"
local dirent = require"posix.dirent"
local px = require"px"
local cmd = px.cmd
local factid = require"factidC"
local ENV = {}
_ENV = ENV

--- Deduce the distro ID from /etc/os-release or /etc/*release.
-- @return the id as a string (STRING)
function factid.osfamily ()
  local id
  if sysstat.stat("/etc/os-release") then
    id = string.match(util.fopen("/etc/os-release"), "ID[%s]*=[%s%p]*([%w]+)")
  elseif sysstat.stat("/etc/openwrt_release") then
    id = "openwrt"
  else
    id = "unknown"
  end
  return id
end

--- Deduce the distro NAME from /etc/os-release or /etc/*release.
-- @return the name as a string (STRING)
function factid.operatingsystem ()
  local name
  if sysstat.stat("/etc/os-release") then
    name = string.match(util.fopen("/etc/os-release"), "NAME[%s]*=[%s%p]*([%w]+)")
  elseif sysstat.stat("/etc/openwrt_release") then
    name = "OpenWRT"
  else
    name = "unknown"
  end
  return name
end

--- Gather ...
-- Requires Linux sysfs support.
-- @return partitions as a partition name and size pair (TABLE)
function factid.partitions ()
  local partitions = {}
  local sysfs = sysstat.stat("/sys/block")
  if not sysfs or sysstat.S_ISDIR(sysfs.st_mode) == 0 then
    return nil, "factid.partitions: No sysfs support detected."
  end
  for partition in dirent.files("/sys/block/") do
    if not string.find(partition, "^%.") then
      local size = core.tonumber(util.fopen("/sys/block/" .. partition .. "/size" ))
      partitions[partition] = size*512
    end
  end
  if not core.next(partitions) then
    return nil, "factid.partitions: posix.dirent failed."
  end
  return partitions
end

function factid.interfaces ()
  local ifs = {}
  for _, y in core.ipairs(factid.ifaddrs()) do
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
  local curl, wget = px.binpath("curl"), px.binpath("wget")
  local url = "http://169.254.169.254/latest/meta-data/instance-id"
  if curl then
    ok, err, res = cmd[curl]{ url }
  elseif wget then
    ok, err, res = cmd[wget]{ "-q", "-O-", url }
  end
  if ok then
    if not core.next(res.stdout) then
      return nil, "factid.aws_instance_id: No stdout."
    end
    local id = res.stdout[1]
    if string.len(id) == 0 then
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
    procs = core.tonumber(procs)
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
    local v1, v2, v3 = string.match(uname.release, "(%d+).(%d+).(%d+)")
    kernelmajversion = string.format("%d.%d", v1, v2)
    fact.kernelmajversion = {}
    fact.kernelmajversion.string = kernelmajversion
    fact.kernelmajversion[kernelmajversion] = true
    kernelrelease = uname.release
    fact.kernelrelease = {}
    fact.kernelrelease.string = kernelrelease
    fact.kernelrelease[kernelrelease] = true
    kernelversion = string.format("%d.%d.%d", v1, v2, v3)
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
    if partitions then
      fact.partitions = {}
      fact.partitions.table = partitions
      for p, s in core.pairs(partitions) do
        fact.partitions[p] = {}
        fact.partitions[p][s] = true
      end
    end
  end

  do
    -- string, string table
    -- fields: ipv4, ipv6 default outgoing
    local ipaddress = factid.ipaddress()
    fact.ipaddress = {}
    fact.ipaddress.table = ipaddress
    for p, i in core.pairs(ipaddress) do
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
    for k, v in core.pairs(memory) do
      fact.memory[k] = {}
      fact.memory[k][v] = true
    end
  end

  do
    -- { eth0 = {ipv4=, ipv6=} }
    local interfaces = factid.interfaces()
    fact.interfaces = {}
    fact.interfaces.table = interfaces
    for interface, prototbl in core.pairs(interfaces) do
      fact.interfaces[interface] = {}
      for proto, ip in core.pairs(prototbl) do
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
