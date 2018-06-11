(local C (require "u-cfg"))
(local S {})
(local lib (require "lib"))
(local (exec) (values lib.exec))
(local systemctl (exec.ctx "systemctl"))
(global _ENV nil)
(tset systemctl "stderr" "/tmp/systemctl-stderr.log")
(local active (fn [unit]
  (tset C (.. "systemd.active :: " unit) (fn []
    (systemctl "daemon-reload")
    (local r (systemctl "is-active" unit))
    (if (= r nil)
      (C.equal 0 (systemctl "start" unit))
      (C.skip true))))))
(tset S "active" active)
S
