--- Ensure that a package managed by Opkg is installed or absent.
-- @module opkg
-- @author Eduardo Tongson <propolice@gmail.com>
-- @license MIT <http://opensource.org/licenses/MIT>
-- @added 0.9.0

local cfg = require"configi"
local lib = require"lib"
local cmd = lib.cmd
local opkg = {}
local ENV = {}
_ENV = ENV

local main = function (S, M, G)
  local C = cfg.start(S, M, G)
  C.required = { "package" }
  return cfg.finish(C)
end

local found = function (package)
  local _, ret = cmd.opkg{ "status", package }
  if lib.find_string(ret.stdout, "Installed-Time", true) then
    return true
  end
end

--- Install a package.
-- See `opkg --help`
-- @aliases installed
-- @aliases install
-- @param package package to install [REQUIRED]
-- @param force_depends install despite failed dependencies [CHOICES: "yes","no"]
-- @param force_reinstall reinstall package [CHOICES: "yes","no"]
-- @param force_overwrite overwrite files from other packages [CHOICES: "yes","no"]
-- @param force_downgrade Allow downgrading packages [CHOICES: "yes","no"]
-- @param force_maintainer Overwrite existing config files [CHOICES: "yes","no"]
-- @param nodeps Do not install dependencies [CHOICES: "yes","no"]
-- @param proxy HTTP proxy to use for connections
-- @param update update package [CHOICES: "yes","no"]
-- @usage opkg.present [[
--   package "strace"
--   update "yes"
-- ]]
function opkg.present (S)
  local M = { "force_depends", "force_reinstall", "force_ovewrite", "force_downgrade", "force_maintainer",
              "nodeps", "proxy", "update" }
  local G = {
    repaired = "opkg.present: Successfully installed package.",
    kept = "opkg.present: Package already installed.",
    failed = "opkg.present: Error installing package."
  }
  local F, P, R = main(S, M, G)
  local env
  if P.proxy then
    env = { "http_proxy=" .. P.proxy }
  end
  -- Update mode
  if P.update == true then
     return F.result(P.package, F.run(cmd.opkg, { _env = env, "update", P.package}))
  end
  -- Install mode
  if found(P.package) then
    return F.kept(P.package)
  end
  local args = { _env = env, "install", P.package }
  lib.insert_if(P.force_depends, args, 1, "--force-depends")
  lib.insert_if(P.force_reinstall, args, 1, "--force-reinstall")
  lib.insert_if(P.force_downgrade, args, 1, "--force-downgrade")
  lib.insert_if(P.force_remove, args, 1, "--force-remove")
  lib.insert_if(P.force_maintainer, args, 1, "--force-maintainer")
  lib.insert_if(P.nodeps, args, 1, "--nodeps")
  return F.result(P.package, F.run(cmd.opkg, args))
end

--- Uninstall a package.
-- @aliases removed
-- @aliases remove
-- @param package package to remove [REQUIRED]
-- @param force_depends remove despite failed dependencies [CHOICES: "yes","no"]
-- @param force_remove Remove packages even if prerm hook fails [CHOICES: "yes","no"]
-- @param autoremove Remove packages that were installed to satisfy dependencies [CHOICES: "yes","no"]
-- @param force_removal_of_dependent_packages Remove package and all dependencies [CHOICES: "yes","no"]
-- @usage opkg.absent [[
--   package "ncurses"
--   force_remove "yes"
-- ]]
function opkg.absent (S)
  local M = { "force_depends", "force_remove", "autoremove", "force_removal_of_dependent_packages" }
  local G = {
    repaired = "opkg.absent: Successfully removed package.",
    kept = "opkg.absent: Package not installed.",
    failed = "opkg.absent: Error removing package."
  }
  local F, P, R = main(S, M, G)
  if not found(P.package) then
    return F.kept(P.package)
  end
  local args = { "remove", P.package }
  lib.insert_if(P.force_remove, args, 1, "--force-remove")
  lib.insert_if(P.autoremove, args, 1, "--autoremove")
  lib.insert_if(P.force_removal_of_dependent_packages, args, 1, "--force--removal-of-dependent-packages")
  return F.result(P.package, F.run(cmd.opkg, args))
end

opkg.installed = opkg.present
opkg.install = opkg.present
opkg.removed = opkg.absent
opkg.remove = opkg.absent
return opkg
