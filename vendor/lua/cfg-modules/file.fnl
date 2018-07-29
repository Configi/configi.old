(local C (require "configi"))
(local F {})
(local lib (require "lib"))
(local (require pairs tostring) (values require pairs tostring))
(local (string os exec file which) (values lib.string lib.os lib.exec lib.file lib.path.bin))
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
      (var pw_name (tostring info.st_uid))
      (when (~= nil u)
        (set uid (string.format "%s(%s)" u.pw_uid u.pw_name))
        (set pw_uid u.pw_uid)
        (set pw_name u.pw_name))
      (tset C (.. "file.owner :: " path " " uid " -> " user)
        (if (= nil (which "chown"))
          (C.fail "chown(1) executable not found"))
        (fn []
          (if (or (= user pw_name) (= user (tostring pw_uid)))
            (C.pass true)
            (let [chown (exec.ctx "chown")]
              (C.equal 0 (chown user path)))))))))
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
        (if (= nil (which "chgrp"))
          (C.fail "chgrp(1) executable not found"))
        (fn []
          (if (or (= grp gr_name) (= grp (tostring gr_gid)))
            (C.pass true)
            (let [chgrp (exec.ctx "chgrp")]
              (C.equal 0 (chgrp grp path)))))))))
(defn directory [d]
  (tset C (.. "file.directory :: " d)
    (if (= nil (which "mkdir"))
      (C.fail "mkdir(1) executable not found"))
    (fn []
      (let [mkdir (exec.ctx "mkdir")]
        (if (= d (os.is_dir d))
          (C.pass true)
          (C.equal 0 (mkdir "-p" d)))))))
(defn absent [f]
  (tset C (.. "file.absent :: " f)
    (if (= nil (which "rm"))
      (C.fail "rm(1) executable not found"))
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
            (C.pass)
            (C.equal true (file.write v.path v.contents))))))))
(defn templated [f]
  (fn [p]
    (each [k v (pairs (require (.. "files." f)))]
      (tset C (.. "file.templated :: " k ":"  v.path)
        (fn []
          (let [contents (file.read_to_string v.path)
                payload (string.template v.contents p)]
            (if (= contents payload)
              (C.pass)
              (C.equal true (file.write v.path payload)))))))))
(defn chmod [f]
  (fn [p]
    (let [mode-arg (tostring (. p "mode"))
          info (stat.stat f)
          len (- 0 (string.len mode-arg))
          current-mode (string.sub (tostring (string.format "%o" info.st_mode)) len -1)]
      (tset C (.. "file.mode :: " f ": " current-mode " -> " mode-arg)
        (if (= nil (which "chmod"))
          (C.fail "chmod(1) executable not found"))
        (fn []
          (if (= current-mode (string.sub mode-arg len -1))
            (C.pass)
            (let [chmod1 (exec.ctx "chmod")]
              (C.equal 0 (chmod1 mode-arg f)))))))))
(tset F "directory" directory)
(tset F "absent" absent)
(tset F "managed" managed)
(tset F "templated" templated)
(tset F "owner" owner)
(tset F "chown" owner)
(tset F "group" group)
(tset F "chgrp" group)
(tset F "chmod" chmod)
(tset F "access" chmod)
F
