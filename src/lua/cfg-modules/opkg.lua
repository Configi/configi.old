--- Ensure that a package managed by Opkg is installed or absent.
-- @module opkg
-- @author Eduardo Tongson <propolice@gmail.com>
-- @license MIT <http://opensource.org/licenses/MIT>
-- @added 0.9.0

local ENV, M, opkg = {}, {}, {}
local cfg = require"configi"
local lib = require"lib"
local cmd = lib.cmd
_ENV = ENV

M.required = { "package" }

local found = function(package)
    local _, ret = cmd.opkg{ "status", package }
    if lib.find_string(ret.stdout, "Installed-Time", true) then
        return true
    end
end

--- Install a package.
-- See `opkg --help`
-- @Aliases installed
-- @Aliases install
-- @Subject package
-- @param force_depends install despite failed dependencies [CHOICES: "yes","no"]
-- @param force_reinstall reinstall package [CHOICES: "yes","no"]
-- @param force_overwrite overwrite files from other packages [CHOICES: "yes","no"]
-- @param force_downgrade Allow downgrading packages [CHOICES: "yes","no"]
-- @param force_maintainer Overwrite existing config files [CHOICES: "yes","no"]
-- @param nodeps Do not install dependencies [CHOICES: "yes","no"]
-- @param proxy HTTP proxy to use for connections
-- @param update update package [CHOICES: "yes","no"]
-- @usage opkg.present("strace")
--     update: "yes"
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
            return F.result(P.package, F.run(cmd.opkg, { _env = env, "update", P.package}))
        end
        -- Install mode
        if found(P.package) then
            return F.kept(P.package)
        end
        local args = { _env = env, "install", P.package }
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
-- @Subject package
-- @Aliases removed
-- @Aliases remove
-- @param force_depends remove despite failed dependencies [CHOICES: "yes","no"]
-- @param force_remove Remove packages even if prerm hook fails [CHOICES: "yes","no"]
-- @param autoremove Remove packages that were installed to satisfy dependencies [CHOICES: "yes","no"]
-- @param force_removal_of_dependent_packages Remove package and all dependencies [CHOICES: "yes","no"]
-- @usage opkg.absent("ncurses")
--     force_remove: "yes"
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
        if not found(P.package) then
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
