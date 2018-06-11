(local C (require "u-cfg"))
(local D {})
(local lib (require "lib"))
(local (exec) (values lib.exec))
(local (docker) (exec.ctx "docker"))
(global _ENV nil)
(defn image [i]
  (tset C (.. "docker.image :: " i)
    (fn []
      (let [r (docker "history" i)]
        (if (= r nil)
          (C.equal 0 (docker "pull" i))
          (C.skip true))))))
(tset D "image" image)
D
