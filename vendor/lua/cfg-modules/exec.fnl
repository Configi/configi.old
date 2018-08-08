(local C (require "configi"))
(local E {})
(local lib (require "lib"))
(local (exec string require type table io)  (values lib.exec lib.string require type table io))
(local stat (require "posix.sys.stat"))
(global _ENV nil)

(defn popen [str ignore]
  (local R {})
  (tset R "output" {})
  (tset R "exe" "io.popen")
  (let [pipe (io.popen str "r")]
    (io.flush pipe)
    (each [ln (: pipe :lines)]
      (tset R.output (+ 1 (# R.output)) ln))
    (let [(_ _ code) (io.close pipe)]
      (tset R "code" code)
      (if (or (= 0 code) ignore)
        (values code R)
        (values nil R)))))
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
(defn script [str]
  (fn [p]
    (local s (require (.. "scripts." str)))
    (tset C (.. "exec.script :: " str)
      (fn []
        (if (= s nil)
          (C.fail "Script not found.")
          (do
            (var (code ret expects output ignore) (values nil nil nil nil nil))
            (when (= "table" (type p))
              (set expects (. p "expects"))
              (set output (. p "output"))
              (set ignore (. p "ignore")))
            (if (or (= nil expects) (= nil (stat.stat expects)))
              (do
                (set (code ret) (popen s))
                (if (= true output)
                  (C.print (table.concat ret.output "\n")))
                (if (= true ignore)
                  (C.pass)
                  (C.equal 0 code)))
              (C.pass))))))))
(tset E "simple" simple)
(tset E "spawn" simple)
(tset E "script" script)
E
