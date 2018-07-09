(local C (require "u-cfg"))
(local D {})
(local lib (require "lib"))
(local (exec) (values lib.exec))
(local (docker) (exec.ctx "docker"))
(global _ENV nil)
;; docker.image(string)
;;
;; Ensure that a Docker image is pulled locally.
;; Does not update the existing local image.
;;
;; Arguments:
;;     #1 (string) = The url of the image.
;;
;; Results:
;;     Pass     = Image already pulled.
;;     Repaired = Successfully pulled image.
;;     Fail     = Failed to pull the image.
;;
;; Examples:
;;     docker.image("docker.elastic.co/elasticsearch/elasticsearch:6.3.0")
(defn image [i]
  (tset C (.. "docker.image :: " i)
    (fn []
      (let [r (docker "history" i)]
        (if (= r nil)
          (C.equal 0 (docker "pull" i))
          (C.pass true))))))
(tset D "image" image)
D
