(local C (require "u-cfg"))
(local I {})
(local lib (require "lib"))
(local (tonumber tostring ipairs) (values tonumber tostring ipairs))
(local (exec path string table) (values lib.exec lib.path lib.string lib.table))
(global _ENV nil)
;; iptables.default(string/number)
;;
;; Add baseline iptables rules.
;; Sets the default policy to DROP and open specified port.
;;
;; Arguments:
;;     #1 (string/number) = Port to open.
;;
;; Results:
;;     Pass     = Port is already opened.
;;     Repaired = The policy was implemented.
;;     Fail     = Failed implementing policy.
;;
;; Examples:
;;     iptables.default(22)
(defn default [port]
  (local policy [["-F"]
                 ["-X"]
                 ["-P" "INPUT" "DROP"]
                 ["-P" "OUTPUT" "DROP"]
                 ["-P" "FORWARD" "DROP"]])
  (local localhost [["" "INPUT" "-i" "lo" "-j" "ACCEPT"]
                 ["" "OUTPUT" "-o" "lo" "-j" "ACCEPT"]
                 ["" "INPUT" "-s" "127.0.0.1/8" "-j" "DROP"]])
  (local rules [["" "INPUT" "-p" "tcp" "-s" "0/0" "-d" "0/0" "--sport" "513:65535" "--dport" ""  "-m" "state" "--state" "NEW,ESTABLISHED" "-j" "ACCEPT"]
                ["" "OUTPUT" "-p" "tcp" "-s" "0/0" "-d" "0/0" "--sport" "" "--dport" "513:65535" "-m" "state" "--state" "ESTABLISHED" "-j" "ACCEPT"]])
  (tset C (.. "iptables.default :: " (table.concat ports ", "))
    (fn []
      (each [_ i (ipairs policy)]
        (local iptables (table.copy i))
        (tset iptables "exe" (path.bin "iptables"))
        (let [ret (exec.qexec iptables)]
          (if (= nil ret)
            (C.equal ret 0))))
      (each [_ i (ipairs localhost)]
        (local iptables (table.copy i))
        (tset iptables "exe" (path.bin "iptables"))
        (tset iptables 1 "-C")
        (if (= nil (exec.qexec iptables))
          (do (tset iptables 1 "-A")
            (let [ret (exec.qexec iptables)]
              (if (= nil ret)
                (C.equal ret 0))))))
      (each [_ i (ipairs rules)]
        (local iptables (table.copy i))
        (tset iptables "exe" (path.bin "iptables"))
        (tset iptables 1 "-C")
        (if (= "INPUT" (. iptables 2))
          (tset iptables 12 (tostring port)))
        (if (= "OUTPUT" (. iptables 2))
          (tset iptables 10 (tostring port)))
        (if (= nil (exec.qexec iptables))
          (do (tset iptables 1 "-A")
            (let [ret (exec.qexec iptables)]
              (if (= nil ret)
                (C.equal ret 0)))))))
      (C.equal 0 0)))
;; iptables.add(string)
;;
;; Add an iptables rule. Omit the append (-A) or insert (-I) command from the rule.
;;
;; Arguments:
;;     #1 (string) = The rule to add.
;;
;; Results:
;;     Pass     = The rule is already loaded.
;;     Repaired = The rule was successfully added.
;;     Fail     = Failed adding the rule. Likely an invalid iptables rule.
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
        (C.pass true))))))
;; iptables.count(string, number)
;;
;; Compare the actual number of iptables rules in the given table with an expected number.
;;
;; Arguments:
;;      #1 (string) = The table (e.g. "nat", "filter") to count rules on.
;;      #2 (number) = The expected number of rules in the table.
;;
;; Results:
;;      Pass = The actual and expected number of rules match.
;;      Fail = The actual and expected number of rules are different.
;;
;; Examples:
;;      iptables.count("filter", 5)
(defn count [tbl no]
  (tset C (.. "iptables.count :: " tbl " == " (tostring no))
    (fn []
      (let [(r t) (exec.cmd.iptables "-S" "-t" tbl)]
        (if (= (# t.stdout) (tonumber no))
           (C.pass true)
           (C.fail "Unexpected number of rules."))))))
(tset I "default" default)
(tset I "add" add)
(tset I "count" count)
I
