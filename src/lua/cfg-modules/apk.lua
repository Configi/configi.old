--- Ensure that an apk managed package is present, absent or updated.
-- @module apk
-- @author Eduardo Tongson <propolice@gmail.com>
-- @license MIT <http://opensource.org/licenses/MIT>
-- @added 0.9.0

local ENV, M, apk = {}, {}, {}
local cfg = require"cfg-core.lib"
local lib = require"lib"
local cmd = lib.cmd
_ENV = ENV

M.required = { "package" }

local found = function(package)
    local _, out = cmd["/sbin/apk"]{ "version", package }
    if lib.find_string(out.stdout, package, true) then
        return true
    end
end

--- Install a package via apk
-- See `apk help` for full description of options and parameters
-- @Subject package
-- @Aliases installed
-- @Aliases install
-- @param update_cache update cache before adding package [DEFAULT: "no", false]
-- @usage apk.present("strace")
--     update_cache: true
function apk.present(S)
    M.parameters = { "update_cache" }
    M.report = {
        repaired = "apk.present: Successfully installed package.",
            kept = "apk.present: Package already installed.",
          failed = "apk.present: Error installing package."
    }
    return function(P)
        P.package = S
        local F, R = cfg.init(P, M)
        if R.kept or found(P.package) then
            return F.kept(P.package)
        end
        local args = { "add", "--no-progress", "--quiet", P.package }
        lib.insert_if(P.update_cache, args, 2, "--update-cache")
        return F.result(P.package, F.run(cmd["/sbin/apk"], args))
    end
end

--- Remove a package
-- @Subject package
-- @Aliases removed
-- @Aliases remove
-- @param None
-- @usage apk.absent"strace"!
function apk.absent(S)
    M.report = {
        repaired = "apk.absent: Successfully removed package",
            kept = "apk.absent: Package not installed.",
          failed = "apk.absent: Error removing package."
    }
    return function(P)
        P.package = S
        local F, R = cfg.init(P, M)
        if R.kept or not found(P.package) then
            return F.kept(P.package)
        end
        return F.result(P.package, F.run(cmd["/sbin/apk"], { "del", "--no-progress", "--quiet", P.package }))
    end
end

apk.installed = apk.present
apk.install = apk.present
apk.removed = apk.absent
apk.remove = apk.absent
return apk
