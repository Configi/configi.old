--- Ensure a Linux kernel module is inserted or removed
-- @module lkm
-- @author Eduardo Tongson <propolice@gmail.com>
-- @license MIT <http://opensource.org/licenses/MIT>
-- @added 2.0.0
local M, lkm = {}, {}
local pairs, string = pairs, string
local cfg = require"cfg-core.lib"
local lib = require"lib"
local file = lib.file
local cmd = lib.exec.cmd
local fact = require"cfg-core.fact"
_ENV = nil
M.required = { "module" }
local function get_mods()
  local modules = file.to_table("/proc/modules", "l")
  local t = {}
  for _, m in pairs(modules) do
    m = string.match(m, "([%g]+)%s")
    t[m] = true
  end
  return t
end
--- Ensure that a specified Linux kernel module is loaded.
-- @Promiser module
-- @Aliases loaded
-- @usage lkm.inserted("vfat"){
--   comment = "Linux kernel module for the VFAT file system"
-- }
function lkm.inserted(S)
  M.report = {
    repaired = "lkm.inserted: Module loaded.",
    kept = "lkm.inserted: Module already loaded.",
    failed = "lkm.inserted: Failure loading module.",
    modprobe_failed = "lkm.inserted: modprobe(8) command failed."
  }
  return function(P)
    P.module = S
    local F, R = cfg.init(P, M)
    if R.kept or fact.modules[P.module] or get_mods()[P.module] then
      return F.kept(P.module)
    end
    if not F.run(cmd.modprobe, "-q", "--first-time", P.module) then
      return F.result(P.module, nil, modprobe_failed)
    end
    if not get_mods()[P.module] then
      return F.result(P.module)
    end
    return F.result(P.module, true)
  end
end
--- Ensure that a specified Linux kernel module is unloaded.
-- @Promiser module
-- @Aliases unloaded
-- @usage lkm.removed("vfat")()
function lkm.removed(S)
  M.report = {
    repaired = "lkm.removed: Module unloaded.",
    kept = "lkm.removed: Module already unloaded.",
    failed = "lkm.removed: Failure to unload module.",
    modprobe_failed = "lkm.removed: modprobe(8) command failed."
  }
  return function(P)
    P.module = S
    local F, R = cfg.init(P, M)
    if R.kept or not fact.modules[P.module] or not get_mods()[P.module] then
      return F.kept(P.module)
    end
    if not F.run(cmd.modprobe, "-r", "-q", "--first-time", P.module) then
      return F.result(P.module, nil, modprobe_failed)
    end
    if get_mods()[P.module] then
      return F.result(P.module)
    end
    return F.result(P.module, true)
  end
end
lkm.loaded = lkm.inserted
lkm.unloaded = lkm.removed
return lkm
