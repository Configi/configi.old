(local C (require "u-cfg"))
(local E {})
(local lib (require "lib"))
(local (exec table) (values lib.exec lib.table))
(global _ENV nil)
(defn simple [cmd tbl]
  (tset C (.. "exec.simple :: " cmd)
    (fn []
      (let [command tbl]
        (tset command "exe" cmd)
        (C.equal 0 (exec.qexec command))))))
(tset E "simple" simple)
E
