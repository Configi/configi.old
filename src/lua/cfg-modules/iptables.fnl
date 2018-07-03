(local C (require "u-cfg"))
(local I {})
(local lib (require "lib"))
(local (table tonumber tostring) (values table tonumber tostring))
(local (exec path string) (values lib.exec lib.path lib.string))
(global _ENV nil)
(defn add [rule]
  (tset C (.. "iptables.add :: "  rule)
    (fn []
      (let [iptables (string.to_table rule)]
        (table.insert iptables 1 "-C")
        (tset iptables "exe" (path.bin "iptables"))
      (if (= nil (exec.qexec iptables))
        (do (tset iptables 1 "-A")
            (C.equal 0 (exec.qexec iptables)))
        (C.skip true))))))
(defn count [tbl no]
  (tset C (.. "iptables.count :: " tbl "==" (tostring no))
    (fn []
      (let [(r t) (exec.cmd.iptables "-S" "-t" tbl)]
        (C.equal (# t.stdout) (tonumber no))))))
(tset I "add" add)
(tset I "count" count)
