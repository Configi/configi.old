-- Author: Eduardo Tongson <propolice@gmail.com>
-- License: MIT <http://opensource.org/licenses/MIT>
C = require "configi"
tostring = tostring
{:exec, :file}  = require "lib"
A = {}
export _ENV = nil
----
--  ### configi.systemd
--
--  Ensure that Configi is installed as a timer unit on a systemd-based host.
--
--  #### Argument:
--      (string) = Path of Configi executable binary
--
--  #### Parameters:
--      (table)
--          interval = Interval in minutes to run Configi (string/number)
--
--  #### Results:
--      Pass     = systemd timer and service already in place.
--      Repaired = Installed systemd timer and service.
--      Fail     = Failed to install systemd timer and service.
--
--  #### Examples:
--  ```
--  configi.systemd(5)
--  ```
----

systemd = (exe = "/srv/cfg") ->
    return (p) ->
        min = tostring p.interval or "5"
        timer = "
[Unit]
    Description=Configi Timer

[Timer]
    OnCalendar=*:0/#{min}

[Install]
    WantedBy=timers.target
"
        service = "
[Unit]
    Description=Configi Service

[Service]
    Type=oneshot
    ExecStart=#{exe} -C
"
        timer_path = "/etc/systemd/system/configi.timer"
        service_path = "/etc/systemd/system/configi.service"
        systemctl = exec.ctx "systemctl"
        C["configi.systemd :: Run #{exe} every #{min} minute(s)"] = ->
            return C.pass! if file.read(timer_path) == timer and file.read(service_path) == service
            return C.fail "Unable to write the systemd timer (#{timer_path})." unless file.write(timer_path, timer)
            return C.fail "Unable to write the systemd service (#{service_path})." unless file.write(service_path, service)
            return C.fail "Unable to reload systemd daemon." unless systemctl "daemon-reload"
            return C.fail "Unable to enable Configi systemd timer." unless systemctl("enable", "configi.timer")
            return C.fail "Unable to start Configi systemd timer." unless systemctl("start", "configi.timer")
            C.equal(0, systemctl("is-active", "configi"), "systemctl(1) returned non-zero when checking if Configi is active.")
A["systemd"] = systemd
A
