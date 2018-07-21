(local C (require "configi"))
(local S {})
(local lib (require "lib"))
(local (string tostring file) (values string tostring lib.file))
(global _ENV nil)
;; sysctl.write
;;
;; Kernel paramater modification through sysctl as implemented in procfs.d
;; Write value to a sysctl key.
;;
;; Arguments:
;;     (string) = The key to write to
;;
;; Parameters:
;;     (table)
;;         value = Value to write to the sysctl key
;;
;; Results:
;;     Pass     = Value already set.
;;     Repaired = Successfully wrote value.
;;     Fail     = Failed to set value.
;;
;; Examples:
;;     sysctl.write("vm.swappiness"){
;;        value = 0
;;     }
(defn write [key]
  (fn [p]
    (if (= nil (. p "value"))
      (C.fail "required table key 'value' missing"))
    (local value (tostring (. p "value")))
    (tset C (.. "sysctl.write :: " key " = " value)
      (fn []
        (var k (string.gsub key "%." "/"))
        (set k (.. "/proc/sys/" k))
        (if (= nil (file.stat k))
          (C.fail "sysctl key not found.")
          (do (let [v (tostring value)]
            (if (= v (file.read_line k))
              (C.pass)
              (C.is_true (file.write_all k v))))))))))
(tset S "write" write)
S
