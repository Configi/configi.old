(local C (require "u-cfg"))
(local F {})
(local lib (require "lib"))
(local (os exec) (values lib.os lib.exec))
(local directory (fn [d]
  (let [td (os.is_dir(d))]
    (if (= td d)
      (return (C.skip))))
  (let [mkdir (exec.ctx "mkdir")]
    (return (C.equal (mkdir d) 0)))))
(local absent (fn [f]))
(tset F "directory" directory)
(tset F "absent" absent)
F
