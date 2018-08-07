(local C (require "configi"))
(local lib (require "lib"))
(local (exec table which) (values lib.exec lib.table lib.path.bin))
(local A {})
(global _ENV nil)
;; Author: Eduardo Tongson <propolice@gmail.com>
;; License: MIT <http://opensource.org/licenses/MIT>
;;
;; apt.installed
;;
;; Ensure a Debian package is present.
;; Note: Does not check for the existence of the apt-get and dpkg executables since they are included in the base of Debian.
;;
;; Argument:
;;     (string) = Package to install.
;;
;; Results:
;;     Pass     = Package already installed.
;;     Repaired = Successfully installed package.
;;     Fail     = Failed to install package.
;;
;; Examples:
;;     apt.installed("mtr")
(defn found [package]
   (let [r (exec.popen (.. "dpkg -s " package))]
     (table.find r.output "Status: install ok installed" true)))
(defn installed [package]
  (tset C (.. "apt.installed :: " package)
    (fn []
      (if (= nil (found package))
        (let [apt-get ["--no-install-recommends" "-q" "-y" "install" package]]
          (tset apt-get "exe" (which "apt-get"))
          (tset apt-get "env" "DEBIAN_FRONTEND=noninteractive")
          (C.equal 0 (exec.qexec apt-get)))
        (C.pass)))))
(tset A "installed" installed)
(tset A "install" installed)
(tset A "get" installed)
A
