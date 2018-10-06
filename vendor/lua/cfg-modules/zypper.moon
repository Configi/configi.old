C = require "configi"
tostring = tostring
exec = require "lib".exec
Z = {}
export _ENV = nil
-- Author: Eduardo Tongson <propolice@gmail.com>
-- License: MIT <http://opensource.org/licenses/MIT>
--
-- zypper.installed
--
-- Ensure a ZYpp managed package is present.
--
-- Argument:
--     (string) = Package to install.
--
-- Results:
--     Pass     = Package already installed.
--     Repaired = Successfully installed package.
--     Fail     = Failed to install package.
--
-- Examples:
--     zypper.installed("mtr")
installed = (package) ->
    C["zypper.installed :: #{package}"] = ->
        if nil == exec.cmd.rpm("-q", "-i", package)
            zypper.exe = exec.path "zypper"
            zypper = {"--non-interactive", "--quiet", "install", "--no-recommends", "--auto-agree-with-licenses", "--force-resolution", package}
            return C.equal(0, exec.qexec(zypper), "Unable to install package.")
        else
            return C.pass!
-- Author: Eduardo Tongson <propolice@gmail.com>
-- License: MIT <http://opensource.org/licenses/MIT>
--
-- zypper.distupgrade
--
-- Perform a distribution upgrade through zypper.
--
-- Results:
--     Repaired = Successfully perform distribution upgrade.
--     Fail     = Failed to perform distribution upgrade.
--
-- Examples:
--     zypper.dup()
distupgrade = ->
    C["zypper.distupgrade"] = ->
        zypper.exe = exec.path "zypper"
        zypper = {"--non-interactive", "--quiet", "dist-upgrade", "--no-recommends", "--auto-agree-with-licenses"}
        return C.equal(0, exec.qexec(zypper), "Unable to perform a distribution upgrade.")
Z["installed"] = installed
Z["install"] = installed
Z["in"] = installed
Z["distupgrade"] = distupgrade
Z["dist_upgrade"] = distupgrade
Z["dup"] = distupgrade
Z
