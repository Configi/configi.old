(local C (require "configi"))
(local S {})
(local lib (require "lib"))
(local (exec) (values lib.exec))
(local systemctl (exec.ctx "systemctl"))
(global _ENV nil)
;; Author: Eduardo Tongson <propolice@gmail.com>
;; License: MIT <http://opensource.org/licenses/MIT>
;;
;; systemd.active
;;
;; Ensure a systemd service is active.
;;
;; Arguments:
;;     #1 (string) = The systemd unit.
;;
;; Results:
;;     Pass     = The service is active.
;;     Repaired = Successfully started service.
;;     Fail     = Failed to start service.
;;
;; Examples:
;;     systemd.active("unbound")
(defn active [unit]
  (tset C (.. "systemd.active :: " unit)
    (fn []
      (if (= 0 (systemctl "-q" "is-active" unit))
        (C.pass)
        (do
          (systemctl "daemon-reload")
          (if (= nil (systemctl "enable" unit))
            (C.fail "systemctl enable failed.")
            (C.equal 0 (systemctl "start" unit))))))))
(tset S "active" active)
S
