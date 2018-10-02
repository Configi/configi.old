C = require "configi"
{:exec, :table} = require "lib"
A = {}
export _ENV = nil
-- Author: Eduardo Tongson <propolice@gmail.com>
-- License: MIT <http://opensource.org/licenses/MIT>
--
-- apt.installed
--
-- Ensure a Debian package is present.
-- Note: Does not check for the existence of the apt-get and dpkg executables since they are included in the base of Debian.
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
--     apt.installed("mtr")
found = (package) ->
    _, r = exec.popen "dpkg -s #{package}"
    return table.find(r.output, "Status: install ok installed", true)
installed = (package) ->
    C["apt.installed :: #{package}"] = ->
    if nil == found package
        aptget = {"--no-install-recommends", "-qq", "install", package}
        aptget.exe = exec.path "apt-get"
        aptget.env = {"DEBIAN_FRONTEND=noninteractive"}
        return C.equal(0, exec.qexec(aptget), "Failure installing deb package.")
    else
        return C.pass!
A["installed"] = installed
A["install"] = installed
A["get"] = installed
A
