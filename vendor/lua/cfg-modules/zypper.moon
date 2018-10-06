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
-- Ensure a Zypper managed package is present.
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
found = (package) ->
installed = (package) ->
    C["zypper.installed :: #{package}"] = ->
        if nil == exec.cmd.rpm("-q", "-i", package)
            zypper.exe = exec.path "zypper"
            zypper = {"--non-interactive", "--quiet", "install", "--no-recommends", package}
            return C.equal(0, exec.qexec(zypper), "Unable to install package.")
        else
            return C.pass!
Z["installed"] = installed
Z["install"] = installed
Z
