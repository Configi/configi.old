(local C (require "u-cfg"))
(local E {})
(local lib (require "lib"))
(local (exec string)  (values lib.exec lib.string))
(local stat (require "posix.sys.stat"))
(global _ENV nil)
;; exec.simple(string, string, string)
;;
;; Run executable and arguments through posix_spawn(3).
;; A path can be checked before running the executable.
;;
;; Arguments:
;;     #1 (string) = Path of executable.
;;     #2 (string) = Arguments as a space delimited string.
;;     #3 (string) = A precondition. Path MUST NOT exist before running the executable.
;;
;; Results:
;;     Repaired = Successfully executed.
;;     Fail     = Error encountered when running executable+arguments.
;;     Pass     = The specified file already exists.
;;
;; Examples:
;;     exec.simple("/bin/touch", {"/tmp/touch"}, "/tmp/touch")
(defn simple [cmd args path]
  (tset C (.. "exec.simple :: " cmd)
    (fn []
        (if (or (= nil path) (= nil (stat.stat path)))
          (let [command (string.to_table args)]
            (tset command "exe" cmd)
            (C.equal 0 (exec.qexec command)))
          (C.pass true)))))
(tset E "simple" simple)
E
