-- Author: Eduardo Tongson <propolice@gmail.com>
-- License: MIT <http://opensource.org/licenses/MIT>
tostring = tostring
C = require "configi"
S = {}
{:exec} = require "lib"
systemctl = exec.ctx "systemctl"
export _ENV = nil
----
--  ### systemd.unit
--
--  Ensure a systemd unit file is present.
--
--  #### Arguments:
--      #1 (string) = The systemd unit.
--
--  #### Results:
--      Pass     = The unit is already present.
--      Repaired = Successfully written unit.
--      Fail     = Failed to write unit.
--
--  #### Examples:
--  ```
--  systemd.unit("openvpn")
--  ```
----
unit = (f) ->
    m = require "systemd.#{f}"
    C["systemd.unit :: #{f}: #{m.path}"] = ->
        return C.fail "Source not found." if nil == m
        contents = file.read m.path
        return C.pass! if contents == m.contents
        C.is_true(file.write(m.path, m.contents), "Failure writing contents to #{m.path}.")
----
--  ### systemd.active
--
--  Ensure a systemd service is active.
--
--  #### Arguments:
--      #1 (string) = The systemd unit.
--
--  #### Results:
--      Pass     = The service is active.
--      Repaired = Successfully started service.
--      Fail     = Failed to start service.
--
--  #### Examples:
--  ```
--  systemd.active("unbound")
--  ```
----
active = (unit) ->
    C["systemd.active :: #{unit}"] = ->
        return C.pass! if systemctl("-q", "is-active", unit)
        return C.fail "Unable to reload systemd daemon." unless systemctl "daemon-reload"
        return C.fail "Attempt to enable systemd unit failed." unless systemctl("enable", unit)
        C.equal(0, systemctl("start", unit), "Unable to start systemd unit.")
S["unit"] = unit
S["active"] = active
S
