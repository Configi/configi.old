C = require"configi"
S = {}
{:exec} = require"lib"
systemctl = exec.ctx"systemctl"
export _ENV = nil
-- Author: Eduardo Tongson <propolice@gmail.com>
-- License: MIT <http://opensource.org/licenses/MIT>
--
-- systemd.active
--
-- Ensure a systemd service is active.
--
-- Arguments:
--     #1 (string) = The systemd unit.
--
-- Results:
--     Pass     = The service is active.
--     Repaired = Successfully started service.
--     Fail     = Failed to start service.
--
-- Examples:
--     systemd.active("unbound")
active = (unit) ->
    C["systemd.active :: #{unit}"] = ->
        if 0 == systemctl("-q", "is-active", unit) return C.pass!
        systemctl"daemon-reload"
        if nil == systemctl("enable", unit)
            return C.fail"systemctl enable failed."
        else
            return C.equal 0 == systemctl("start", unit)
S["active"] = active
S
