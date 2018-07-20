(local C (require "u-cfg"))
(local S {})
(local lib (require "lib"))
(local (exec table) (values lib.exec lib.table))
(global _ENV nil)
;; selinux.permissive(string)
;;
;; Set a process type to be permissive.
;;
;; Arguments:
;;     #1 (string) = The type to set.
;;
;; Results:
;;     Pass     = Type is already set permissive.
;;     Repaired = Type successfully set permissive.
;;     Fail     = Failed to set the type.
;;
;; Examples:
;;    selinux.permissive("container_t")
(defn permissive [type]
  (tset C (.. "selinux.permissive :: " type)
    (fn []
      (let [(_ t) (exec.cmd.semanage "permissive" "-l")]
      (if (= (table.find t.stdout type) nil)
        (let [semanage ["permissive" "-a" type]]
          (tset semanage "exe" "/usr/sbin/semanage")
          (C.equal 0 (exec.qexec semanage)))
        (C.pass true))))))
;; selinux.port
;;
;; Add a port to the specified context.
;;
;; Arguments:
;;     (string) = The context to add to.
;;
;; Parameters:
;;    (table)
;;            port = Port to add (string/number)
;;        protocol = Protocol of port (string)
;;
;; Results:
;;     Pass     = Port already enabled for context.
;;     Repaired = Port added to context.
;;     Fail     = Failed to add port.
;;
;; Examples:
;;    selinux.port("ssh_port_t"){
;;      port = 1822,
;;      protocol = "tcp"
;;    }
(defn port [type]
  (fn [p]
    (local nport (tostring (. p "port")))
    (local protocol (. p "protocol"))
    (tset C (.. "selinux.port :: " type " + " protocol ":" nport)
      (fn []
        (let [(_ t) (exec.cmd.semanage "port" "-l")]
        (if (= (table.find t.stdout (.. type "%s+" protocol "%s+" "[%d]*[%s,]" nport)) nil)
          (let [semanage ["port" "-a" "-t" type "-p" protocol nport]]
            (tset semanage "exe" "/usr/sbin/semanage")
            (C.equal 0 (exec.qexec semanage)))
          (C.pass)))))))
(tset S "permissive" permissive)
(tset S "port" port)
S
