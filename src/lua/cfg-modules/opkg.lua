--- Ensure that a package managed by Opkg is installed or absent.
-- @module opkg
-- @author Eduardo Tongson <propolice@gmail.com>
-- @license MIT <http://opensource.org/licenses/MIT>
-- @added 0.9.0

local ENV, M, opkg = {}, {}, {}
local cfg = require"cfg-core.lib"
local lib = require"lib"
local table = lib.table
local cmd = lib.exec.cmd
_ENV = ENV

M.required = { "package" }

local found = function(package)
  local _, ret = cmd.opkg{ "status", package }
  if table.find(ret.stdout, "Installed-Time", true) then
    return true
  end
end

--- Install a package.
-- See `opkg --help`
-- @Aliases installed
-- @Aliases install
-- @Promiser package
-- @param force_depends install despite failed dependencies [Default: false]
-- @param force_reinstall reinstall package [Default: false]
-- @param force_overwrite overwrite files from other packages [Default: false]
-- @param force_downgrade Allow downgrading packages [Default: false]
-- @param force_maintainer Overwrite existing config files [Default: false]
-- @param nodeps Do not install dependencies [Default: false]
-- @param proxy HTTP proxy to use for connections
-- @param update update package [Default: false]
-- @usage opkg.present("strace") {
--     update = true
-- }
function opkg.present(S)
  M.parameters = {
       "force_depends",
     "force_reinstall",
      "force_ovewrite",
     "force_downgrade",
    "force_maintainer",
          "nodeps",
           "proxy",
          "update"
  }
  M.report = {
    repaired = "opkg.present: Successfully installed package.",
      kept = "opkg.present: Package already installed.",
      failed = "opkg.present: Error installing package."
  }
  return function(P)
    P.package = S
    local F, R = cfg.init(P, M)
    local env
    if P.proxy then
      env = { "http_proxy=" .. P.proxy }
    end
    -- Update mode
    if P.update == true then
      return F.result(P.package, F.run(cmd.opkg, { env = env, "update", P.package}))
    end
    -- Install mode
    if R.kept or found(P.package) then
      return F.kept(P.package)
    end
    local args = { env = env, "install", P.package }
    local set = {
         force_depends = "--force-depends",
       force_reinstall = "--force-reinstall",
       force_downgrade = "--force-downgrade",
        force_remove = "--force-remove",
      force_maintainer = "--force-maintainer",
            nodeps = "--nodeps",
    }
    P:insert_if(set, args, 1)
    return F.result(P.package, F.run(cmd.opkg, args))
  end
end

--- Uninstall a package.
-- @Promiser package
-- @Aliases removed
-- @Aliases remove
-- @param force_depends remove despite failed dependencies
-- @param force_remove Remove packages even if prerm hook fails [Default: false]
-- @param autoremove Remove packages that were installed to satisfy dependencies [Default: false]
-- @param force_removal_of_dependent_packages Remove package and all dependencies [Default: false]
-- @usage opkg.absent("ncurses"){
--     force_remove = true
-- }
function opkg.absent(S)
  M.parameters = { "force_depends", "force_remove", "autoremove", "force_removal_of_dependent_packages" }
  M.report = {
    repaired = "opkg.absent: Successfully removed package.",
    kept = "opkg.absent: Package not installed.",
    failed = "opkg.absent: Error removing package."
  }
  return function(P)
    P.package = S
    local F, R = cfg.init(P, M)
    if R.kept or not found(P.package) then
      return F.kept(P.package)
    end
    local args = { "remove", P.package }
    local set = {
                   force_remove = "--force-remove",
                   autoremove = "--autoremove",
      force_removal_of_dependent_packages = "--force-removal-of-dependent-packges"
    }
    P:prepend_if_set(set, args)
    return F.result(P.package, F.run(cmd.opkg, args))
  end
end

opkg.installed = opkg.present
opkg.install = opkg.present
opkg.removed = opkg.absent
opkg.remove = opkg.absent
return opkg
