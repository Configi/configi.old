(local C (require "u-cfg"))
(local F {})
(local lib (require "lib"))
(local (os exec func) (values lib.os lib.exec lib.func))
(global _ENV nil)
(local directory (fn [d]
  (local test-directory (func.skip (fn []
    (let [mkdir (exec.ctx "mkdir")]
      (C.equal 0 (mkdir d))))))
  (test-directory (C.skip (os.is_dir d)))))
(local absent (fn [f]))
(tset F "directory" directory)
(tset F "absent" absent)
F
