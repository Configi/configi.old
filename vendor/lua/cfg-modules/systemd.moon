-- Author: Eduardo Tongson <propolice@gmail.com>
-- License: MIT <http://opensource.org/licenses/MIT>
tostring, require = tostring, require
C = require "configi"
S = {}
{:exec, :file} = require "lib"
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
    path = "/etc/systemd/system/#{f}.service"
    C["systemd.unit :: #{path}"] = ->
        m = require "systemd.#{f}"
        return C.fail "Source not found." if nil == m
        contents = file.read path
        return C.pass! if contents == m
        C.is_true(file.write(path, m), "Failure writing contents to #{path}.")
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
active = (u) ->
    C["systemd.active :: #{u}"] = ->
        return C.pass! if systemctl("-q", "is-active", u)
        return C.fail "Unable to reload systemd daemon." unless systemctl "daemon-reload"
        return C.fail "Attempt to enable systemd unit failed." unless systemctl("enable", u)
        C.equal(0, systemctl("start", u), "Unable to start systemd unit.")
S["unit"] = unit
S["active"] = active
S
