(local C (require "u-cfg"))
(local F {})
(local lib (require "lib"))
(local (require pairs string tostring) (values require pairs string tostring))
(local (os exec file) (values lib.os lib.exec lib.file))
(local stat (require "posix.sys.stat"))
(local Ppwd (require "posix.pwd"))
(local Pgrp (require "posix.grp"))
(global _ENV nil)
(defn owner [path]
  (fn [p]
    (local user (tostring (. p "user")))
    (let [info (stat.stat path)
          u (Ppwd.getpwuid info.st_uid)]
      (var uid (tostring info.st_uid))
      (var pw_uid (tostring info.st_uid))
      (var pw_name (tostring info.st_uid)))
      (when (~= nil u)
        (set uid (string.format "%s(%s)" u.pw_uid u.pw_name))
        (set pw_uid u.pw_uid)
        (set pw_name u.pw_name))
      (tset C (.. "file.owner :: " path " " uid " -> " user)
        (fn []
          (if (or (= user pw_name) (= user (tostring pw_uid)))
            (C.pass true)
            (let [chown (exec.ctx "chown")]
              (C.equal 0 (chown user path))))))))
(defn group [path]
  (fn [p]
    (local grp (tostring (. p "group")))
    (let [info (stat.stat path)
          g (Pgrp.getgrgid info.st_gid)]
      (var cg (tostring info.st_gid))
      (var gr_gid (tostring info.st_gid))
      (var gr_name (tostring info.st_gid))
      (when (~= nil g)
        (set cg (string.format "%s(%s)" g.gr_gid g.gr_name))
        (set gr_gid g.gr_gid)
        (set gr_name g.gr_name))
      (tset C (.. "file.group :: " path " "  cg " -> " grp)
        (fn []
          (if (or (= grp gr_name) (= grp (tostring gr_gid)))
            (C.pass true)
            (let [chgrp (exec.ctx "chgrp")]
              (C.equal 0 (chgrp grp path)))))))))
(defn directory [d]
  (tset C (.. "file.directory :: " d)
    (fn []
      (let [mkdir (exec.ctx "mkdir")]
        (if (= d (os.is_dir d))
          (C.pass true)
          (C.equal 0 (mkdir d)))))))
(defn absent [f]
  (tset C (.. "file.absent :: " f)
    (fn []
      (let [rm (exec.ctx "rm")]
        (if (= nil (stat.stat f))
          (C.pass true)
          (C.equal 0 (rm "-r" "-f" f)))))))
(defn managed [f]
  (each [k v (pairs (require (.. "files." f)))]
    (tset C (.. "file.managed :: " k ":"  v.path)
      (fn []
        (let [contents (file.read_to_string v.path)]
          (if (= contents v.contents)
            (C.pass true)
            (C.equal true (file.write v.path v.contents))))))))
(defn mode [m f]
  (let [mode-arg (tostring m)
        info (stat.stat f)
        len (- 0 (string.len mode-arg))
        current-mode (string.sub (tostring (string.format "%o" info.st_mode)) len -1)]
    (tset C (.. "file.mode :: " f ": " current-mode " -> " m)
      (fn []
        (if (= current-mode (string.sub mode-arg len -1))
          (C.pass true)
          (let [chmod (exec.ctx "chmod")]
            (C.equal 0 (chmod mode-arg f))))))))
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
