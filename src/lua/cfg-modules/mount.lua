--- Perform mount(8) operations
-- @module mount
-- @author Eduardo Tongson <propolice@gmail.com>
-- @license MIT <http://opensource.org/licenses/MIT>
-- @added 2.0.0
local M, mount = {}, {}
local ipairs, string = ipairs, string
local cfg = require"cfg-core.lib"
local lib = require"lib"
local table, util = lib.table, lib.util
local cmd = lib.exec.cmd
local fact = require"cfg-core.fact"
local factid = require"factid"
_ENV = nil

M.required = { "dir" }

local function get_mounts()
  local t = {}
  for _, m in ipairs(factid.mount()) do
    t[m.dir] = m.opts
  end
  return t
end

local mounts = get_mounts()

--- Remount a filesystem with specified options
-- @Promiser mount mount point to remount
-- @param value value to write
-- @usage mount.opts"/tmp"{
--   nodev = true
-- }
function mount.opts(S)
  M.parameters = {
    "async",
    "atime",
    "noatime",
    "dev",
    "nodev",
    "diratime",
    "nodiratime",
    "dirsync",
    "exec",
    "noexec",
    "iversion",
    "noiversion",
    "mand",
    "nomand",
    "relatime",
    "norelatime",
    "strictatime",
    "nostrictatime",
    "suid",
    "nosuid",
    "owner",
    "ro",
    "rw",
    "sync",
    "uid",
    "gid",
    "seclabel",
    "context",
    "fscontext",
    "defcontext",
    "rootcontext",
    "size",
    "mode"
  }
  M.report = {
    repaired = "mount.remount: Successfully remounted mount point.",
    kept = "mount.remount: Mount option already set.",
    failed = "mount.remount: Error remounting mount point.",
    unmounted = "mount.remount: Error remounting unmounted mount point."
  }
  return function(P)
    P.dir = S
    local F, R = cfg.init(P, M)
    if R.kept then
      return F.kept(P.dir)
    end
    if fact.mount[P.dir] == false or mounts[P.dir] then
      return F.result(P.dir, nil, M.report.unmounted)
    end
    local tmp = {}
    for _, o in ipairs(M.parameters) do
      table.insert_if(P[o], tmp, -1, o)
    end
    local to = {}
    for _, o in ipairs(tmp) do
      if P[o] == true or util.truthy(P[o]) then
        to[#to+1] = o
      elseif P[o] then
        to[#to+1] = o.."="..P[o]
      end
    end
    local co
    if fact.mount then
      for _, o in ipairs(fact.mount.table) do
        if P.dir == o.dir then
          co = o.opts
          break
        end
      end
    else
      for _, m in pairs(mounts) do
        if m[P.dir] then
          co = m[P.dir]
        end
      end
    end
    local st
    for _, o in ipairs(to) do
      st = string.find(co, o, 1, true)
      if st == nil then
        local r = F.run(cmd.mount, { "-o", "remount,"..table.concat(to, ","), P.dir })
        return F.result(P.dir, r)
      end
    end
    if st then
      return F.kept(P.dir)
    end
  end
end

function mount.mounted(S)
  M.parameters = {
    "dev"
  }
  M.alias = {}
  M.alias.dev = { "device" }
  M.report = {
    repaired = "mount.mounted: Successfully mounted.",
    kept = "mount.mounted: Already mounted.",
    failed = "mount.mounted: Failed to mount."
  }
  return function(P)
    P.dir = S
    local F, R = cfg.init(P, M)
    if R.kept or fact.mount[P.dir] then
      return F.kept(P.dir)
    else
      local a = { P.dir }
      table.insert_if(P.dev, a, 1, P.dev)
      local r = F.run(cmd.mount, a)
      return F.result(P.dir, r)
    end

  end
end

function mount.unmounted(S)
  M.report = {
    repaired = "mount.ummounted: Successfully unmounted.",
    kept = "mount.unmounted: Already unmounted.",
    failed = "mount.unmounted: Failed to unmount."
  }
  return function(P)
    P.dir = S
    local F, R = cfg.init(P, M)
    if R.kept or fact.mount[P.dir] == false then
      return F.kept(P.dir)
    else
      local r = F.run(cmd.umount, { P.dir })
      return F.result(P.dir, r)
    end
  end
end

mount.remount = mount.opts
return mount
