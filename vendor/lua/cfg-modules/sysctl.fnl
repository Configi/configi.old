(local C (require "u-cfg"))
(local S {})
(local lib (require "lib"))
(local (file) (values lib.file))
(global _ENV nil)
;; sysctl.write(string, string/number)
;;
;; Kernel paramater modification through sysctl as implemented in procfs.d
;; Write value to a sysctl key.
;;
;; Arguments:
;;     #1 (string) = The key to write to.
;;
;; Results:
;;     Pass     = Value already set.
;;     Repaired = Successfully wrote value.
;;     Fail     = Failed to set value.
;;
;; Examples:
;;     sysctl.write("vm.swappiness", 0)
(defn write [key value]
  (tset C (.. "sysctl.write :: " key " = " (tostring value))
    (fn []
      (var k (string.gsub key "%." "/"))
      (set k (.. "/proc/sys/" k))
      (if (= nil (file.stat k))
        (C.fail "sysctl key not found.")
        (do (let [v (tostring value)]
          (if (= v (file.read_line k))
            (C.pass true)
            (C.is_true (file.write_all k v)))))))))
(tset S "write" write)
S
