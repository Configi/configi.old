(local C (require "u-cfg"))
(local I {})
(local lib (require "lib"))
(local (table tonumber tostring) (values table tonumber tostring))
(local (exec path string) (values lib.exec lib.path lib.string))
(global _ENV nil)
;; iptables.add(string)
;;
;; Add an iptables rule. Omit the append (-A) or insert (-I) command from the rule.
;;
;; Arguments:
;;     #1 (string) = The rule to add.
;;
;; Results:
;;     Skip = The rule is already loaded.
;;     Ok   = The rule was successfully added.
;;     Fail = Failed adding the rule. Likely an invalid iptables rule.
;;
;; Examples:
;;     iptables.add("INPUT -p udp -m udp --dport 53 -j ACCEPT")
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
;; iptables.count(string, number)
;;
;; Compare the actual number of iptables rules in the given table with an expected number.
;;
;; Arguments:
;;      #1 (string) = The table (e.g. "nat", "filter") to count rules on.
;;      #2 (number) = The expected number of rules in the table.
;;
;; Results:
;;      Skip = The actual and expected number of rules match.
;;      Fail = The actual and expected number of rules are different.
;;
;; Examples:
;;      iptables.count("filter", 5)
(defn count [tbl no]
  (tset C (.. "iptables.count :: " tbl " == " (tostring no))
    (fn []
      (let [(r t) (exec.cmd.iptables "-S" "-t" tbl)]
        (if (= (# t.stdout) (tonumber no))
           (C.skip true)
           (C.equal 1 0))))))
(tset I "add" add)
(tset I "count" count)
