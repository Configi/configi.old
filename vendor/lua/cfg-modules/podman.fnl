(local C (require "configi"))
(local P {})
(local lib (require "lib"))
(local (exec table which) (values lib.exec lib.table lib.path.bin))
(global _ENV nil)
;; Author: Eduardo Tongson <propolice@gmail.com>
;; License: MIT <http://opensource.org/licenses/MIT>
;;
;; podman.image
;;
;; Ensure that a container image is pulled locally.
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
;;     podman.image("docker.elastic.co/elasticsearch/elasticsearch:6.3.0")
(defn image [i]
  (tset C (.. "podman.image :: " i)
    (fn []
      (if (= nil (which "podman"))
        (C.fail "podman(1) executable not found"))
      (let [r (exec.popen (.. "podman history " i))]
        (if (= r nil)
          (C.equal 0 (exec.popen (.. "podman pull " i)))
          (C.pass true))))))
;; podman.update(string)
;;
;; Ensure that a container image is up-to-date.
;;
;; Arguments:
;;     #1 (string) = The url of the image.
;;
;; Results:
;;     Pass     = Image up-to-date.
;;     Repaired = Successfully updated image.
;;     Fail     = Failed to update the image.
;;
;; Examples:
;;     podman.update("docker.elastic.co/elasticsearch/elasticsearch:6.3.0")
(defn update [i]
  (tset C (.. "podman.update :: " i)
    (fn []
      (if (= nil (which "podman"))
        (C.fail "podman(1) executable not found"))
      (let [(r t) (exec.popen (.. "podman pull " i))]
        (if (= r nil)
          (C.fail "Failed to update image.")
          (if (= nil (table.find t.output "Copying blob" true))
            (C.pass)
            (C.equal r 0)))))))
(tset P "image" image)
(tset P "update" update)
P
