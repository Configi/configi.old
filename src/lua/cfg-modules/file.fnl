(local C (require "u-cfg"))
(local F {})
(local lib (require "lib"))
(local (os exec func) (values lib.os lib.exec lib.func))
(local stat (require "posix.sys.stat"))
(global _ENV nil)
(local directory (fn [d]
  (local test-directory (func.skip (fn []
    (let [mkdir (exec.ctx "mkdir")]
      (C.equal 0 (mkdir d))))))
  (test-directory (C.skip (os.is_dir d)))))
(local absent (fn [f]
  (local test-absent (func.skip (fn []
    (let [rm (exec.ctx "rm")]
      (C.equal 0 (rm "-r" "-f" f))))))
  (let [nstat (stat.stat f)]
    (if (= nil nstat)
      (test-absent (C.skip true))
      (test-absent (C.skip false))))))
(tset F "directory" directory)
(tset F "absent" absent)
F
