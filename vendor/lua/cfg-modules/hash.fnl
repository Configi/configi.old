(local C (require "u-cfg"))
(local H {})
(local lib (require "lib"))
(local bin (require "plc.bin"))
(local shasum (require "plc.sha2"))
(local (file) (values lib.file))
(global _ENV nil)
;; hash.sha2
;;
;; Check that a given sha256 hash value matches the actual hash value of a file.
;; Useful for alerting on changed hashes.
;;
;; Argument:
;;     (string) = The path of the file.
;;
;; Parameters:
;;     (table)
;;         digest = The expected hash digest of the specified file.
;;
;; Results:
;;     Pass = Hash digest matched.
;;     Fail = Hash digest did not match.
;;
;; Examples:
;;     hash.sha2("/usr/local/bin/woah"){
;;        digest =
;;     }
(defn sha2 [path]
  (fn [p]
    (local digest (. p "digest"))
    (tset C (.. "hash.sha2 :: " path " : " digest)
      (fn []
        (if (~= nil (file.stat path))
          (do
            (let [hash256 (bin.stohex (shasum.hash256 (file.read_to_string path)))]
              (if (= digest hash256)
                (C.pass)
                (C.fail (.. "Unexpected hash digest: " hash256)))))
          (C.fail "file not found."))))))
(tset H "sha2" sha2)
H
