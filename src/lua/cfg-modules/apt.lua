--- Ensure that a Debian APT managed package is present, absent or updated.
-- @module apt
-- @author Eduardo Tongson <propolice@gmail.com>
-- @license MIT <http://opensource.org/licenses/MIT>
-- @added 1.0.0

local ENV, M, apt = {}, {}, {}
local cfg = require"cfg-core.lib"
local lib = require"lib"
local cmd = lib.cmd
_ENV = ENV

M.required = { "package" }
M.alias = {}
M.alias.package = { "option" } -- for clean mode

local found = function(package)
    local _, ret = cmd.dpkg{ "-s", package }
    if lib.find_string(ret.stdout, "Status: install ok installed", true) then
        return true
    end
end

--- Install a package via Debian APT.
-- See apt-get(8) for full description of options and parameters
-- @Subject package
-- @Aliases installed
-- @Aliases install
-- @param update_cache Run `apt-get update` before any operation [DEFAULT: false]
-- @param no_upgrade Prevent upgrade of specified package if already installed [DEFAULT: false]
-- @usage apt.present("strace")
--     update_cache: true
function apt.present(S)
    M.parameters = {
        "update_cache", "no_upgrade"
    }
    M.report = {
        repaired = "apt.present: Successfully installed package.",
            kept = "apt.present: Package already installed.",
          failed = "apt.present: Error installing package."
    }
    return function(P)
        P.package = S
        local F = cfg.init(P, M)
        local env
        if P.proxy then
            env = { "http_proxy=" .. P.proxy }
        end
        local args = { _env = env, "-q", "-y", "install", P.package }
        local set = {
          no_upgrade = "--no-upgrade",
        }
        -- `apt-get update` mode
        if P.update_cache == true then
            if F.run(cmd["apt-get"], { "-q", "-y", "update" }) then
                F.msg("update", "Update successful", true)
            else
                return F.result("update", nil, "Update failed")
            end
        end
        -- Install mode
        if found(P.package) then
            return F.kept(P.package)
        end
        P:insert_if(set, args, 3)
        return F.result(P.package, F.run(cmd["apt-get"], args))
    end
end

--- Remove a package via Debian APT.
-- @Subject package
-- @Aliases removed
-- @Aliases remove
-- @param None
-- @usage apt.absent("strace")!
function apt.absent(S)
    M.report = {
        repaired = "apt.absent: Successfully removed package.",
            kept = "apt.absent: Package not installed.",
          failed = "apt.absent: Error removing package."
    }
    return function(P)
        P.package = S
        local F = cfg.init(P, M)
        local args = { "-q", "-y", "remove", P.package }
        if not found(P.package) then
            return F.kept(P.package)
        end
        return F.result(P.package, F.run(cmd["apt-get"], { "-q", "-y", "remove", P.package }))
    end
end

apt.installed = apt.present
apt.install = apt.present
apt.removed = apt.absent
apt.remove = apt.absent
return apt
