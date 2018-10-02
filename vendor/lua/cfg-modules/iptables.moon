(local C (require "configi"))
(local I {})
(local lib (require "lib"))
(local (tonumber tostring ipairs) (values tonumber tostring ipairs))
(local (exec path string table which) (values lib.exec lib.path lib.string lib.table lib.path.bin))
(global _ENV nil)
;; Author: Eduardo Tongson <propolice@gmail.com>
;; License: MIT <http://opensource.org/licenses/MIT>
;;
;; iptables.default
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
  (tset C (.. "iptables.default :: " (tostring port))
    (fn []
      (if (= nil (which "iptables"))
        (C.fail "iptables(8) executable not found."))
      (let [iptables {}]
        (table.copy iptables (. rules 1))
        (tset iptables "exe" (path.bin "iptables"))
        (tset iptables 1 "-C")
        (tset iptables 12 (tostring port))
        (if (= 0 (exec.qexec iptables))
          (C.pass "Rule already in place")
        (do (each [_ i (ipairs policy)]
            (table.copy iptables i)
            (tset iptables "exe" (path.bin "iptables"))
            (let [ret (exec.qexec iptables)]
              (if (= nil ret)
                (C.equal ret 0))))
          (each [_ i (ipairs localhost)]
            (table.copy iptables i)
            (tset iptables "exe" (path.bin "iptables"))
            (tset iptables 1 "-C")
            (if (= nil (exec.qexec iptables))
              (do (tset iptables 1 "-A")
                (let [ret (exec.qexec iptables)]
                  (if (= nil ret)
                    (C.equal ret 0))))))
          (each [_ i (ipairs rules)]
            (table.copy iptables i)
            (tset iptables "exe" (path.bin "iptables"))
            (tset iptables 1 "-C")
            (if (= "INPUT" (. iptables 2))
              (tset iptables 12 (tostring port)))
            (if (= "OUTPUT" (. iptables 2))
              (tset iptables 10 (tostring port)))
            (if (= nil (exec.qexec iptables))
              (do (tset iptables 1 "-A")
                (let [ret (exec.qexec iptables)]
                  (C.equal ret 0)))))))))))
;; iptables.open(string/number)
;;
;; Open stateful port.
;;
;; Arguments:
;;     #1 (string/number) = Port to open.
;;
;; Results:
;;     Pass     = Port is already opened.
;;     Repaired = Port opened.
;;     Fail     = Failed to open port.
;;
;; Examples:
;;     iptables.open(443)
(defn open [port]
  (local rules [["" "INPUT" "-p" "tcp" "-s" "0/0" "-d" "0/0" "--sport" "513:65535" "--dport" ""  "-m" "state" "--state" "NEW,ESTABLISHED" "-j" "ACCEPT"]
                ["" "OUTPUT" "-p" "tcp" "-s" "0/0" "-d" "0/0" "--sport" "" "--dport" "513:65535" "-m" "state" "--state" "ESTABLISHED" "-j" "ACCEPT"]])
  (tset C (.. "iptables.open :: " (tostring port))
    (fn []
      (if (= nil (which "iptables"))
        (C.fail "iptables(8) executable not found."))
      (let [iptables {}]
        (table.copy iptables (. rules 1))
        (tset iptables "exe" (path.bin "iptables"))
        (tset iptables 1 "-C")
        (tset iptables 12 (tostring port))
        (if (= 0 (exec.qexec iptables))
          (C.pass "Rule already in place")
	  (do
            (each [_ i (ipairs rules)]
              (table.copy iptables i)
              (tset iptables "exe" (path.bin "iptables"))
              (tset iptables 1 "-C")
              (if (= "INPUT" (. iptables 2))
                (tset iptables 12 (tostring port)))
              (if (= "OUTPUT" (. iptables 2))
                (tset iptables 10 (tostring port)))
              (if (= nil (exec.qexec iptables))
                (do (tset iptables 1 "-A")
                  (let [ret (exec.qexec iptables)]
                    (C.equal ret 0)))))))))))
;; iptables.outgoing
;;
;; Allow outgoing connections from the specified interface.
;;
;; Arguments:
;;     #1 (string) = Interface to allow.
;;
;; Results:
;;     Pass     = Interface already allowed.
;;     Repaired = Rule for interface added.
;;     Fail     = Failed to add rule.
;;
;; Examples:
;;     iptables.outgoing(eth0)
(defn outgoing [interface]
  (local rules [["" "OUTPUT" "-d" "0/0" "-o" "" "-j" "ACCEPT"]
                ["" "INPUT" "-i" "" "-m" "state" "--state" "ESTABLISHED,RELATED" "-j" "ACCEPT"]])
  (tset C (.. "iptables.outgoing :: " interface)
    (fn []
      (if (= nil (which "iptables"))
        (C.fail "iptables(8) executable not found."))
      (let [iptables {}]
        (table.copy iptables (. rules 1))
        (tset iptables "exe" (path.bin "iptables"))
        (tset iptables 1 "-C")
        (tset iptables 6 interface)
        (if (= 0 (exec.qexec iptables))
          (C.pass "Rule already in place")
	  (do
            (each [_ i (ipairs rules)]
              (table.copy iptables i)
              (tset iptables "exe" (path.bin "iptables"))
              (tset iptables 1 "-C")
              (if (= "OUTPUT" (. iptables 2))
                (tset iptables 6 interface))
              (if (= "INPUT" (. iptables 2))
                (tset iptables 4 interface))
              (if (= nil (exec.qexec iptables))
                (do (tset iptables 1 "-A")
                  (let [ret (exec.qexec iptables)]
                    (C.equal 0 ret)))))))))))
;; iptables.add(string)
;;
;; Add an iptables rule.
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
;;     iptables.add("-A INPUT -p udp -m udp --dport 53 -j ACCEPT")
(defn add [rule]
  (tset C (.. "iptables.add :: "  rule)
    (fn []
      (if (= nil (which "iptables"))
        (C.fail "iptables(8) executable not found."))
      (let [iptables (string.to_table rule)]
        (tset iptables 1 "-C")
        (tset iptables "exe" (path.bin "iptables"))
      (if (= nil (exec.qexec iptables))
        (do (tset iptables 1 "-A")
          (C.equal 0 (exec.qexec iptables)))
        (C.pass))))))
;; iptables.count
;;
;; Compare the actual number of iptables rules in the given table with an expected number.
;;
;; Argument:
;;      (string) = The table (e.g. "nat", "filter") to count rules on.
;;
;; Parameters:
;;      (table)
;;          expect = The expected number of rules in the table (number)
;;
;; Results:
;;      Pass = The actual and expected number of rules match.
;;      Fail = The actual and expected number of rules are different.
;;
;; Examples:
;;      iptables.count("filter"){
;;        expect = 5
;;      }
(defn count [tbl no]
  (tset C (.. "iptables.count :: " tbl " == " (tostring no))
    (fn []
      (if (= nil (which "iptables"))
        (C.fail "iptables(8) executable not found."))
      (let [(_ t) (exec.cmd.iptables "-S" "-t" tbl)]
        (if (= (# t.stdout) (tonumber no))
          (C.pass true)
          (C.fail "Unexpected number of rules."))))))
(tset I "default" default)
(tset I "add" add)
(tset I "open" open)
(tset I "allow" open)
(tset I "count" count)
(tset I "outgoing" outgoing)
I
