(local C (require "u-cfg"))
(local E {})
(local lib (require "lib"))
(local (exec table) (values lib.exec lib.table))
(global _ENV nil)
;; exec.simple(string, table)
;;
;; Run command and arguments through posix_spawn(3).
;;
;; Arguments:
;;     #1 (string) = Path of executable.
;;     #2 (table)  = Arguments as a table sequence.
;;
;; Results:
;;     Ok   = Successfully executed.
;;     Fail = Error encountered when running executable+arguments.
;;
;; Examples:
;;     exec.simple("/bin/touch", {"/tmp/touch"})
(defn simple [cmd tbl]
  (tset C (.. "exec.simple :: " cmd)
    (fn []
      (let [command tbl]
        (tset command "exe" cmd)
        (C.equal 0 (exec.qexec command))))))
(tset E "simple" simple)
E
