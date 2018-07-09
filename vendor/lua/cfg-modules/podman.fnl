(local C (require "u-cfg"))
(local P {})
(local lib (require "lib"))
(local (exec) (values lib.exec))
(global _ENV nil)
;; podman.image(string)
;;
;; Ensure that a container image is pulled locally.
;; Does not update the existing local image.
;;
;; Arguments:
;;     #1 (string) = The url of the image.
;;
;; Results:
;;     Skip = Image already pulled.
;;     Ok   = Successfully pulled image.
;;     Fail = Failed to pull the image.
;;
;; Examples:
;;     podman.image("docker.elastic.co/elasticsearch/elasticsearch:6.3.0")
(defn image [i]
  (tset C (.. "podman.image :: " i)
    (fn []
      (let [r (exec.popen (.. "podman history " i))]
        (if (= r nil)
          (C.equal 0 (exec.popen (.. "podman pull " i)))
          (C.skip true))))))
(tset P "image" image)
P
