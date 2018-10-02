C = require "configi"
S = {}
{:exec} = require "lib"
systemctl = exec.ctx "systemctl"
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
        return C.pass! if 0 == systemctl("-q", "is-active", unit)
        return C.fail "Unable to reload systemd daemon." unless systemctl "daemon-reload"
        return C.fail "Attempt to enable systemd unit failed." unless systemctl("enable", unit)
        return C.equal(0, systemctl("start", unit), "Unable to start systemd unit.")
S["active"] = active
S
