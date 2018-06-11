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
(local owner (fn [owner path]
  (local chown (exec.ctx "chown"))
  (local info (stat.stat path))
  (local u (pwd.getpwuid info.st_uid))
  (local uid (string.format "%s(%s)" u.pw_uid u.pw_name))
  (tset C (.. "file.owner :: " path " " uid "-> " owner) (fn []
      (if (or (= owner u.pw_name) (= owner (tostring u.pw_uid)))
      (C.skip true)
      (C.equal 0 (chown owner path)))))))
(local group (fn [group path]
  (local chgrp (exec.ctx "chgrp"))
  (local info (stat.stat path))
  (local g (grp.getgrgid info.st_gid))
  (local cg (string.format "%s(%s)" (. g "gr_gid") (. g "gr_name")))
  (tset C (.. "file.group :: " path " "  cg "->" group) (fn []
    (if (or (= group g.gr_name) (= group (tostring g.gr_gid)))
       (C.skip true)
       (C.equal 0 (chgrp group path)))))))
(local directory (fn [d]
  (tset C (.. "file.directory :: " d) (fn []
    (local test-directory (func.skip (fn []
      (let [mkdir (exec.ctx "mkdir")]
        (C.equal 0 (mkdir d))))))
    (test-directory (C.skip (os.is_dir d)))))))
(local absent (fn [f]
  (tset C (.. "file.absent :: " f) (fn []
    (local test-absent (func.skip (fn []
      (let [rm (exec.ctx "rm")]
        (C.equal 0 (rm "-r" "-f" f))))))
    (test-absent (C.nskip (stat.stat f)))))))
(local managed (fn [f]
  (local t (require (.. "files." f)))
    (each [k v (pairs t)]
      (tset C (.. "file.managed :: " k ":"  v.path) (fn []
        (local contents (file.read_to_string v.path))
        (if (= contents v.contents)
          (C.skip true)
          (C.equal true (file.write v.path v.contents))))))))
(tset F "directory" directory)
(tset F "absent" absent)
(tset F "managed" managed)
(tset F "owner" owner)
(tset F "chown" owner)
(tset F "group" group)
(tset F "chgrp" group)
F
