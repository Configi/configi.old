(local C (require "u-cfg"))
(local S {})
(local lib (require "lib"))
(local (exec table) (values lib.exec lib.table))
(global _ENV nil)
(local permissive (fn [type]
  (tset C (.. "selinux.permissive :: " type) (fn []
    (local (r t) (exec.cmd.semanage "permissive" "-l"))
    (var c (table.find t.stdout type))
    (if (= c nil)
      (let [semanage ["permissive" "-a" type]]
      (tset semanage "exe" "/usr/sbin/semanage")
      (C.equal 0 (exec.qexec semanage)))
    (C.skip true))))))
(tset S "permissive" permissive)
S
