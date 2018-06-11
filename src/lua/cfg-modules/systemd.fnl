(local C (require "u-cfg"))
(local S {})
(local lib (require "lib"))
(local (exec) (values lib.exec))
(local systemctl (exec.ctx "systemctl"))
(global _ENV nil)
(defn active [unit]
  (tset C (.. "systemd.active :: " unit)
    (fn []
      (systemctl "daemon-reload")
      (if (= nil (systemctl "is-active" unit))
        (C.equal 0 (systemctl "start" unit))
        (C.skip true)))))
(tset S "active" active)
S
