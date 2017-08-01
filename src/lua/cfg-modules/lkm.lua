--- Ensure a Linux kernel module is inserted or removed
-- @module lkm
-- @author Eduardo Tongson <propolice@gmail.com>
-- @license MIT <http://opensource.org/licenses/MIT>
-- @added 2.0.0
local M, lkm = {}, {}
local cfg = require"cfg-core.lib"
local cmd = require"lib".exec.cmd
local fact = require"cfg-core.fact"
local factid = require"factid"
_ENV = nil

M.required = { "module" }

local function get_modules()
  local m = factid.modules()
  local t = {}
  for _, mod in ipairs(m) do
    t[mod] = true
  end
  return t
end
local modules = get_modules()
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
    if R.kept or fact.modules[P.module] or modules[P.module] then
      return F.kept(P.module)
    end
    if not F.run(cmd.modprobe, "-q", "--first-time", P.module) then
      return F.result(P.module, nil, M.modprobe_failed)
    end
    if not modules[P.module] then
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
    if R.kept or not fact.modules[P.module] or not modules[P.module] then
      return F.kept(P.module)
    end
    if not F.run(cmd.modprobe, "-r", "-q", "--first-time", P.module) then
      return F.result(P.module, nil, M.modprobe_failed)
    end
    if modules[P.module] then
      return F.result(P.module)
    end
    return F.result(P.module, true)
  end
end
--- Ensure that a specified Linux kernel module cannot be loaded.
-- @Promiser module
-- @usage lkm.disabled("vfat"()
function lkm.disabled(S)
  M.report = {
    kept = "lkm.disabled: Module is already disabled.",
    failed = "lkm.disabled: Module loaded."
  }
  return function(P)
    P.module = S
    local F, R = cfg.init(P, M)
    if R.kept then
      return F.kept(P.module)
    end
    cmd.modprobe("-q", P.module)
    if modules[P.module] then
      return F.result(P.module)
    end
    return F.result(P.module, true)
  end
end
lkm.loaded = lkm.inserted
lkm.unloaded = lkm.removed
return lkm
