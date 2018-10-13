C = require "configi"
S = {}
{:exec, :table} = require "lib"
{:cmd, :qexec} = exec
export _ENV = nil
-- Author: Eduardo Tongson <propolice@gmail.com>
-- License: MIT <http://opensource.org/licenses/MIT>
--
-- selinux.permissive
--
-- Set a process type to be permissive.
--
-- Arguments:
--     #1 (string) = The type to set.
--
-- Results:
--     Pass     = Type is already set permissive.
--     Repaired = Type successfully set permissive.
--     Fail     = Failed to set the type.
--
-- Examples:
--    selinux.permissive("container_t")
permissive = (setype) ->
    C["selinux.permissive :: #{setype}"] = ->
        return C.fail "semanage(8) executable not found." unless exec.path "semanage"
        _, t = cmd.semanage("permissive", "-l")
        return C.pass! if table.find(t.stdout, setype)
        semanage = {"permissive", "-a", setype}
        semanage.exe = "/usr/sbin/semanage"
        C.equal(0, qexec(semanage), "Unable to set '#{setype}' to permissive. semanage(8) returned non-zero value.")
-- selinux.port
--
-- Add a port to the specified context.
--
-- Arguments:
--     (string) = The context to add to.
--
-- Parameters:
--    (table)
--            port = Port to add (string/number)
--        protocol = Protocol of port (string)
--
-- Results:
--     Pass     = Port already enabled for context.
--     Repaired = Port added to context.
--     Fail     = Failed to add port.
--
-- Examples:
--    selinux.port("ssh_port_t"){
--      port = 1822,
--      protocol = "tcp"
--    }
port = (type) ->
    return (p) ->
        nport = tostring(p.port)
        protocol = p.protocol
        C["selinux.port :: #{type} + #{protocol}:#{nport}"] = ->
            _, t = cmd.semanage("port", "-l")
            return C.pass! if table.find(t.stdout, "#{type}%s+#{protocol}%s+[%d]*[%s,]nport")
            semanage = {"port", "-a", "-t", type, "-p", protocol, nport}
            semanage.exe = "/usr/sbin/semanage"
            C.equal(0, qexec(semanage), "Execution failure. semanage(8) returned non-zero value.")
S["permissive"] = permissive
S["port"] = port
S
