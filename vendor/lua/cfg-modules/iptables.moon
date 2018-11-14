-- Author: Eduardo Tongson <propolice@gmail.com>
-- License: MIT <http://opensource.org/licenses/MIT>
C = require "configi"
I = {}
tonumber, tostring = tonumber, tostring
{:exec, :string, :table} = require "lib"
export _ENV = nil
----
--  ### iptables.default
--
--  Add baseline iptables rules.
--  Sets the default policy.
--
--  #### Arguments:
--      #1 (string) = Iptables TARGET. Valid values are ACCEPT, DROP, REJECT. Default is DROP.
--
--  #### Results:
--      Pass     = Policy already in place.
--      Repaired = The policy was implemented.
--      Fail     = Failed implementing policy.
--
--  #### Examples:
--  ```
--  iptables.default("DROP")
--  ```
----
default = (target = "DROP") ->
    target = string.upper target
    policy = {
        {"-F"}
        {"-X"}
        {"-P", "INPUT",   target}
        {"-P", "OUTPUT",  target}
        {"-P", "FORWARD", target}
    }
    localhost = {
        {"", "INPUT",  "-i", "lo",          "-j", "ACCEPT"}
        {"", "OUTPUT", "-o", "lo",          "-j", "ACCEPT"}
        {"", "INPUT",  "-s", "127.0.0.1/8", "-j", target}
    }
    C["iptables.default :: #{target}"] = ->
        ipt = exec.path "iptables"
        if nil == ipt return C.fail"iptables(8) executable not found."
        iptables = {}
        check = (l) ->
            table.copy(iptables, l)
            iptables.exe = ipt
            iptables[1] = "-C"
            exec.qexec iptables
        lo = [check(l) for l in *localhost]
        if 0 == lo[1] and 0 == lo[2]
            if 0 == lo[3]
                return C.pass "Policy already in place."
        for i in *policy
            table.copy(iptables, i)
            iptables.exe = ipt
            C.equal(0, exec.qexec(iptables), "Failure applying policy.")
        for i in *localhost
            table.copy(iptables, i)
            iptables.exe = ipt
            iptables[1] = "-A"
            C.equal(0, exec.qexec(iptables), "Failure applying localhost policy.")
----
--  ### iptables.open
--
--  Open stateful port.
--
--  #### Arguments:
--         #1 (string/number) = Port to open.
--
--  #### Parameters:
--         (table)
--             protocol = TCP or UDP (TCP by default)
--
--  #### Results:
--         Pass     = Port is already opened.
--         Repaired = Port opened.
--         Fail     = Failed to open port.
--
--  #### Examples:
--  ```
--  iptables.open(443)
--  ```
----
open = (port) ->
    return (p) ->
        p.protocol = string.lower p.protocol or "tcp"
        port = tostring port
        ip4_rules = {
            {
                ""
                "INPUT"
                "-p"
                p.protocol
                "-s"
                "0/0"
                "-d"
                "0/0"
                "--sport"
                "513:65535"
                "--dport"
                ""
                "-m"
                "state"
                "--state"
                "NEW,ESTABLISHED"
                "-j"
                "ACCEPT"
            }
            {
                ""
                "OUTPUT"
                "-p"
                p.protocol
                "-s"
                "0/0"
                "-d"
                "0/0"
                "--sport"
                ""
                "--dport"
                "513:65535"
                "-m"
                "state"
                "--state"
                "ESTABLISHED"
                "-j"
                "ACCEPT"
            }
        }
        C["iptables.open :: #{p.protocol}:#{port}"] = ->
            ipt = exec.path "iptables"
            if nil == ipt return C.fail "iptables(8) executable not found."
            iptables = {}
            for  i in *ip4_rules
                table.copy(iptables, i)
                iptables.exe = ipt
                if "INPUT" == iptables[2]
                    iptables[1] = "-C"
                    iptables[12] = port
                    return C.pass "IPv4 port already open." if 0 == exec.qexec iptables
                    iptables[1] = "-A"
                    C.equal(0, exec.qexec(iptables), "Failure opening IPv4 port. Unable to add INPUT rule.")
                if "OUTPUT" == iptables[2]
                    iptables[10] = port
                    iptables[1] = "-A"
                    C.equal(0, exec.qexec(iptables), "Failure opening IPv4 port. Unable to add OUTPUT rule.")
----
--  ### iptables.outgoing
--
--  Allow outgoing connections from the specified interface.
--
--  #### Arguments:
--         #1 (string) = Interface to allow.
--
--  #### Results:
--         Pass     = Interface already allowed.
--         Repaired = Rule for interface added.
--         Fail     = Failed to add rule.
--
--  #### Examples:
--  ```
--  iptables.outgoing "eth0"
--  ```
----
outgoing = (interface) ->
    rules = {
        {
            ""
            "OUTPUT"
            "-d"
            "0/0"
            "-o"
            ""
            "-j"
            "ACCEPT"
        }
        {
            ""
            "INPUT"
            "-i"
            ""
            "-m"
            "state"
            "--state"
            "ESTABLISHED,RELATED"
            "-j"
            "ACCEPT"
        }
    }
    C["iptables.outgoing :: #{interface}"] = ->
        ipt = exec.path "iptables"
        if nil == ipt return C.fail "iptables(8) executable not found."
        iptables = {}
        table.copy(iptables, rules[1])
        iptables.exe = ipt
        iptables[1] = "-C"
        iptables[6] = interface
        if 0 == exec.qexec iptables return C.pass "Rule already in place."
        for i in *rules
            table.copy(iptables, i)
            iptables.exe = ipt
            iptables[1] = "-A"
            if "OUTPUT" == iptables[2]
                iptables[6] = interface
                C.equal(0, exec.qexec(iptables), "Failure allowing outgoing interface. Unable to add OUTPUT rule.")
            if "INPUT" == iptables[2]
                iptables[4] = interface
                C.equal(0, exec.qexec(iptables), "Failure allowing outgoing interface. Unable to add INPUT rule.")
----
--  ### iptables.add
--
--  Add an iptables rule.
--
--  #### Arguments:
--         #1 (string) = Description of the rule
--
--  #### Parameters:
--         (table)
--             rule = The rule to add (string)
--
--  #### Results:
--         Pass     = The rule is already loaded.
--         Repaired = The rule was successfully added.
--         Fail     = Failed adding the rule. Likely an invalid iptables rule.
--
--  #### Examples:
--  ```
--  iptables.add("Allow DNS"){
--    rule = "-A INPUT -p udp -m udp --dport 53 -j ACCEPT"
--  }
--  ```
----
add = (desc = "") ->
    return (p) ->
        C["iptables.add :: #{desc}"] = ->
            return C.fail "Missing iptables rule to add." if nil == p.rule
            ipt = exec.path "iptables"
            return C.fail "iptables(8) executable not found." if nil == ipt
            iptables = string.to_table p.rule
            iptables[1] = "-C"
            iptables.exe = ipt
            return C.pass! if exec.qexec iptables
            iptables[1] = "-A"
            C.equal(0, exec.qexec(iptables), "Failure adding iptables rule.")
----
--  ### iptables.count
--
--  Compare the actual number of iptables rules in the given table with an expected number.
--
--  #### Argument:
--         (string) = The table (e.g. "nat", "filter") to count rules on.
--
--  #### Parameters:
--         (table)
--             expect = The expected number of rules in the table (number)
--
--  #### Results:
--         Pass = The actual and expected number of rules match.
--         Fail = The actual and expected number of rules are different.
--
--  #### Examples:
--  ```
--  iptables.count("filter"){
--    expect = 5
--  }
--  ```
----
count = (tbl = "all") ->
    return (p) ->
        no = tonumber p.expect
        tbl = string.lower tbl
        C["iptables.count :: #{tbl} == #{no}"] = ->
            return C.fail "iptables(8) executable not found." if nil == exec.path "iptables"
            local r, t
            if "all" == tbl
                r, t = exec.cmd.iptables("-S")
            else
                r, t = exec.cmd.iptables("-S", "-t", tbl)
            return C.pass! if no == #t.stdout
            return C.fail "iptables(8) command failure." if nil == r
            C.equal(no, #t.stdout, "Unexpected number of rules.")
I["default"] = default
I["add"] = add
I["open"] = open
I["allow"] = open
I["count"] = count
I["outgoing"] = outgoing
I
