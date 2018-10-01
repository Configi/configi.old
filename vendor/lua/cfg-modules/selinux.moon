C = require"configi"
S = {}
{:exec, :table} = require"lib"
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
permissive = (type) ->
    C["selinux.permissive :: #{type}"] = ->
        _, t = cmd.semanage("permissive", "-l")
        if nil == table.find(t.stdout, type)
            semanage = {"permissive", "-a", type}
            semanage.exe = "/usr/sbin/semanage"
            return C.equal(0, qexec(semanage))
        else
            return C.pass!
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
            if nil == table.find(t.stdout, "#{type}%s+#{protocol}%s+[%d]*[%s,]nport")
                semanage = {"port", "-a", "-t", type, "-p", protocol, nport}
                semanage.exe = "/usr/sbin/semanage"
                return C.equal(0, qexec(semanage))
            else
                return C.pass!
S["permissive"] = permissive
S["port"] = port
S
