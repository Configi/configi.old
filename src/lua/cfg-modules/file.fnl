(local C (require "u-cfg"))
(local print (values print))
(local F {})
(local lib (require "lib"))
(local (require pairs string tostring) (values require pairs string tostring))
(local (os exec func file) (values lib.os lib.exec lib.func lib.file))
(local stat (require "posix.sys.stat"))
(local pwd (require "posix.pwd"))
(local grp (require "posix.grp"))
(global _ENV nil)
(defn owner [owner path]
  (let [info (stat.stat path)
        u (pwd.getpwuid info.st_uid)
        uid (string.format "%s(%s)" u.pw_uid u.pw_name)]
        (tset C (.. "file.owner :: " path " " uid "-> " owner)
              (fn []
                  (if (or (= owner u.pw_name) (= owner (tostring u.pw_uid)))
                    (C.skip true)
                    (let [chown (exec.ctx "chown")]
                      (C.equal 0 (chown owner path))))))))
(defn group [group path]
      (let [info (stat.stat path)
            g (grp.getgrgid info.st_gid)
            cg (string.format "%s(%s)" g.gr_gid g.gr_name)]
            (tset C (.. "file.group :: " path " "  cg "->" group)
                  (fn []
                      (if (or (= group g.gr_name) (= group (tostring g.gr_gid)))
                        (C.skip true)
                        (let [chgrp (exec.ctx "chgrp")]
                          (C.equal 0 (chgrp group path))))))))
(defn directory [d]
      (tset C (.. "file.directory :: " d)
            (fn []
                (local test-directory (func.skip (fn []
                                                    (let [mkdir (exec.ctx "mkdir")]
                                                      (C.equal 0 (mkdir d))))))
                (test-directory (C.skip (os.is_dir d))))))
(defn absent [f]
      (tset C (.. "file.absent :: " f)
            (fn []
                (local test-absent (func.skip
                                     (fn []
                                         (let [rm (exec.ctx "rm")]
                                           (C.equal 0 (rm "-r" "-f" f))))))
                (test-absent (C.nskip (stat.stat f))))))
(defn managed [f]
      (each [k v (pairs (require (.. "files." f)))]
        (tset C (.. "file.managed :: " k ":"  v.path)
              (fn []
                  (let [contents (file.read_to_string v.path)]
                    (if (= contents v.contents)
                      (C.skip true)
                      (C.equal true (file.write v.path v.contents))))))))
(defn mode [m f]
      (let [mode-arg (tostring m)
            info (stat.stat f)
            len (- 0 (string.len mode-arg))
            current-mode (string.sub (tostring (string.format "%o" info.st_mode)) len -1)]
        (if (= current-mode (string.sub mode-arg len -1))
          (C.skip true)
          (let [chmod (exec.ctx "chmod")]
            (C.equal 0 (chmod mode-arg f))))))
(tset F "directory" directory)
(tset F "absent" absent)
(tset F "managed" managed)
(tset F "owner" owner)
(tset F "chown" owner)
(tset F "group" group)
(tset F "chgrp" group)
(tset F "mode" mode)
(tset F "access" mode)
F
