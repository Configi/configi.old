(local C (require "configi"))
(local E {})
(local lib (require "lib"))
(local (exec string)  (values lib.exec lib.string))
(local stat (require "posix.sys.stat"))
(global _ENV nil)
;; Author: Eduardo Tongson <propolice@gmail.com>
;; License: MIT <http://opensource.org/licenses/MIT>
;;
;; exec.simple
;;
;; Run executable and arguments through posix_spawn(3).
;; A path can be checked before running the executable.
;;
;; Arguments:
;;     (string) = Complete path of executable.
;;
;; Parameters:
;;     (table)
;;         args    = Arguments as a space delimited string.
;;         expects = A precondition. Path MUST NOT exist before running the executable.
;;
;; Results:
;;     Repaired = Successfully executed.
;;     Fail     = Error encountered when running executable+arguments.
;;     Pass     = The specified path of file passed in the `expects` parameter already exists.
;;
;; Examples:
;;     exec.simple("/bin/touch"){
;;       args = "/tmp/touch",
;;       expects = "/tmp/touch"
;;     }
(defn simple [exe]
  (fn [p]
    (local path (. p "expects"))
    (local args (. p "args"))
    (tset C (.. "exec.simple :: " exe)
      (fn []
          (if (or (= nil path) (= nil (stat.stat path)))
            (let [command (string.to_table args)]
              (tset command "exe" exe)
              (C.equal 0 (exec.qexec command)))
            (C.pass))))))
(tset E "simple" simple)
(tset E "spawn" simple)
E
