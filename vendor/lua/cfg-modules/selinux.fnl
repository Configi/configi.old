(local C (require "u-cfg"))
(local S {})
(local lib (require "lib"))
(local (exec table) (values lib.exec lib.table))
(global _ENV nil)
;; selinux.permissive(string)
;;
;; Set a process type to be permissive.
;;
;; Arguments:
;;     #1 (string) = The type to set.
;;
;; Results:
;;     Pass     = Type is already set permissive.
;;     Repaired = Type successfully set permissive.
;;     Fail     = Failed to set the type.
;;
;; Examples:
;;    selinux.permissive("container_t")
(defn permissive [type]
  (tset C (.. "selinux.permissive :: " type)
    (fn []
      (let [(_ t) (exec.cmd.semanage "permissive" "-l")]
      (if (= (table.find t.stdout type) nil)
        (let [semanage ["permissive" "-a" type]]
          (tset semanage "exe" "/usr/sbin/semanage")
          (C.equal 0 (exec.qexec semanage)))
        (C.pass true))))))
(tset S "permissive" permissive)
S
