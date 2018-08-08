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
;; exec.spawn
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
;;     exec.spawn("/bin/touch"){
;;       args = "/tmp/touch",
;;       expects = "/tmp/touch"
;;     }
(defn spawn [exe]
  (fn [p]
    (local path (. p "expects"))
    (local args (. p "args"))
    (tset C (.. "exec.spawn :: " exe)
      (fn []
          (if (or (= nil path) (= nil (stat.stat path)))
            (let [command (string.to_table args)]
              (tset command "exe" exe)
              (C.equal 0 (exec.qexec command)))
            (C.pass))))))
;; Author: Eduardo Tongson <propolice@gmail.com>
;; License: MIT <http://opensource.org/licenses/MIT>
;;
;; exec.script
;;
;; Runs a shell script through popen(3).
;; A path can be checked before running the executable.
;;
;; The Lua module should return the body of the script.
;; Example:
;;     $ cat src/lua/scripts/script.lua
;;     return [==[
;;     echo "test"
;;     touch "./file"
;;     ]==]
;; In the above example, the basename of the filename 'script' is the argument to exec.script()
;;
;; Arguments:
;;     (string) = Name of shell script sourced from `src/lua/scripts`
;;
;; Parameters:
;;     (table)
;;         expects = A precondition. Path MUST NOT exist before running the executable.
;;          ignore = if set to `true`, always pass, the shell scripts return result is ignored.
;;          output = if set to `true`, show the popen(3) output.
;;
;; Results:
;;     Repaired = Successfully executed.
;;     Fail     = Error encountered when running script.
;;     Pass     = The specified path of file passed in the `expects` parameter already exists. Or the popen(3) result is ignored.
;;
;; Examples:
;;     exec.script("script"){
;;       expects = "/tmp/touch",
;;       output = true,
;;       ignore = true
;;     }
;;
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
(tset E "spawn" spawn)
(tset E "simple" spawn)
(tset E "script" script)
E
