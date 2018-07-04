(local C (require "u-cfg"))
(local E {})
(local lib (require "lib"))
(local (exec)  (values lib.exec))
(local stat (require "posix.sys.stat"))
(global _ENV nil)
;; exec.simple(string, table, string)
;;
;; Run executable and arguments through posix_spawn(3).
;; A path can be checked before running the executable.
;;
;; Arguments:
;;     #1 (string) = Path of executable.
;;     #2 (table)  = Arguments as a table sequence.
;;     #3 (string) = A precondition. Path should NOT exist before running the executable.
;;
;; Results:
;;     Ok   = Successfully executed.
;;     Fail = Error encountered when running executable+arguments.
;;     Skip = The specified file already exists.
;;
;; Examples:
;;     exec.simple("/bin/touch", {"/tmp/touch"}, "/tmp/touch")
(defn simple [cmd tbl path]
  (tset C (.. "exec.simple :: " cmd)
    (fn []
        (if (or (= nil path) (= nil (stat.stat path)))
          (let [command tbl]
            (tset command "exe" cmd)
            (C.equal 0 (exec.qexec command)))
          (C.skip true)))))
(tset E "simple" simple)
E
