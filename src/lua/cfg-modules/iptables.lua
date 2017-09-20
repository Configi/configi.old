--- iptables.
-- This module is for configuring rules on a host. Warning: the FORWARD chain is unsupported.
-- @module iptables
-- @author Eduardo Tongson <propolice@gmail.com>
-- @license MIT <http://opensource.org/licenses/MIT>
-- @added 0.9.7

local M, iptables = {}, {}
local io = io
local cfg = require"cfg-core.lib"
local lib = require"lib"
local table, string = lib.table, lib.string
local cmd = lib.exec.cmd
local stat = require"posix.sys.stat"
_ENV = nil

M.required = { "chain" }
M.alias = {}
M.alias.match = { "module" }

--- Add iptables rules.
-- @Promiser tag
-- @param table packet matching table [DEFAULT: filter]
-- @param chain [DEFAULT: INPUT]
-- @param source source specification. Default network mask is /32.
-- @param destination destination specification. Default network mask is /32.
-- @param protocol protocol of the rule to match for
-- @param target target of the rule
-- @param options space delimited string that is passed as extra options to iptables
-- @param in incoming interface via which the rule to match for
-- @param out outgoing interface via which the rule to match for
-- @param ipv6 Use ip6tables
-- @param ipv4 Use iptables [DEFAULT: "yes", true]
-- @usage iptables.append("comment"){
--   table = "filter",
--   chain = "input",
--   target = "accept",
--   source = "6.6.6.6",
--   protocol = "tcp",
--   options = "-m tcp --sport 31337 --dport 31337"
-- }
function iptables.append(S)
  --[[
     -A INPUT -s P.source -d P.destination -i lo -p tcp -m tcp
     --sport 31337 --dport 8080 --tcp-option 16 --tcp-flags SYN FIN -j ACCEPT
    ]]
  M.parameters = {
    "table",
    "chain",
    "source",
    "destination",
    "protocol",
    "target",
    "options",
    "match",
    "in",
    "out",
    "ipv6",
    "ipv4"
  }
  M.report = {
    repaired = "iptables.append: Successfully appended rule.",
    kept = "iptables.append: Rule already present.",
    failed = "iptables.append: Failed to append rule."
  }
  return function(P)
    P.tag = S -- currently unused
    local F, R = cfg.init(P, M)
    if R.kept then
      return F.kept(P.tag)
    end
    local mask = function (ip)
      if ip and not string.find(ip, "/", -3) and not string.find(ip, "/", -2) then
        ip = ip .. "/32"
      end
      return ip
    end
    P:set_if_not("ipv4", true) -- on by default
    P.chain = P.chain or "INPUT"
    P.table = P.table or "filter"
    P:set_if("source", mask(P.source))
    P:set_if("destination", mask(P.destination))
    local rule = { "", string.upper(P.chain), "-j", string.upper(P.target) }
    table.insert_if(P.options, rule, 3, string.to_array(P.options))
    table.insert_if(P.protocol, rule, 3, { "-p", P.protocol })
    table.insert_if(P.out, rule, 3, { "-o", P.out})
    table.insert_if(P["in"], rule, 3, { "-i", P["in"]})
    table.insert_if(P.destination, rule, 3, { "-d", P.destination })
    table.insert_if(P.source, rule, 3, { "-s", P.source })
    local ipt = {}
    table.insert_if(P.ipv4, ipt, 1, "iptables")
    table.insert_if(P.ipv6, ipt, 1, "iptables6")
    local skip = false
    for n = 1, #ipt do
      skip = false -- reset
      rule[1] = "-C"
      if cmd[ipt[n]](rule) then
        skip = true
      else
        rule[1] = "-A"
        if not F.run(cmd[ipt[n]], rule) then
          return F.result("iptables.append")
        end
      end
    end
    if skip == true then
      return F.kept("iptables.append")
    end
    return F.result("iptables.append", true)
  end
end

--- Disable iptables.
-- Flush, zero out counters and remove user-defined chains.
-- @Promiser tag
-- @param NONE
-- @usage iptables.disable("comment")()
function iptables.disable(S)
  M.report = {
    repaired = "iptables.disable: Successfully disabled iptables.",
    failed = "iptables.disable: Error disabling iptables."
  }
  return function(P)
    P.chain = "iptables.disable"
    P.tag = S -- currently unused
    local F, R = cfg.init(P, M)
    if R.kept then
      return F.kept(P.tag)
    end
    local disable = function(tables)
      local ipt
      if tables == "/proc/net/ip_tables_names" then
        ipt = "-iptables"
      else
        ipt = "-ip6tables"
      end
      cmd[ipt]{ "-P", "INPUT", "ACCEPT" }
      cmd[ipt]{ "-P", "OUTPUT", "ACCEPT" }
      cmd[ipt]{ "-P", "FORWARD", "ACCEPT" }
      local ok
      local cmds = { "-F", "-X", "-Z" }
      for t in io.lines(tables) do
        for n = 1, #cmds do
          if F.run(cmd[ipt], { "-t", t, cmds[n] }) then
            ok = true
          else
            return
          end
        end
      end
      return ok
    end
    local ip, ip6
    if stat.stat("/proc/net/ip_tables_names") then
      ip = disable("/proc/net/ip_tables_names")
    else
      ip = true
    end
    if stat.stat("/proc/net/ip6_tables_names") then
      ip6 = disable("/proc/net/ip6_tables_names")
    else
      ip6 = true
    end
    return F.result("iptables.disable", (ip and ip6) or nil)
  end
end

--- Default deny but allow incoming connections to port 22.
-- @Promiser tag
-- @Note IPv4 only at the moment.
-- @param host IP of the local host [DEFAULT: 0.0.0.0]
-- @param source IP of host to white list [DEFAULT: 0.0.0.0]
-- @param ssh SSH port [DEFAULT: 22]
-- @usage iptables.default("comment")()
function iptables.default(S)
  M.parameters = { "source", "host", "ssh" }
  M.report = {
    repaired = "iptables.default: Successfully added rules.",
    kept = "iptables.default: Rules already present",
    failed = "iptables.default: Error adding rules."
  }
  return function(P)
    local F, R = cfg.init(P, M)
    P.source = P.source or "0/0"
    P.host = P.host or "0/0"
    P.ssh = P.ssh or "22"
    P.tag = S
    if R.kept then
      return F.kept(P.tag)
    end
    local args = {
      { "-F" },
      { "-X" },
      { "-P", "INPUT", "DROP" },
      { "-P", "OUTPUT", "DROP" },
      { "-P", "FORWARD", "DROP" },
      { "-A", "INPUT", "-i", "lo", "-j", "ACCEPT" },
      { "-A", "OUTPUT", "-o", "lo", "-j", "ACCEPT" },
      { "-A", "INPUT", "-s", "127.0.0.0/8", "-j", "DROP" },
      { "", "INPUT", "-p", "tcp", "-s", P.source, "-d", P.host, "--sport", "513:65535", "--dport", P.ssh,
        "-m", "state", "--state", "NEW,ESTABLISHED", "-j", "ACCEPT" },
      { "", "OUTPUT", "-p", "tcp", "-s", P.host, "-d", P.source, "--sport", P.ssh, "--dport", "513:65535",
        "-m", "state", "--state", "ESTABLISHED", "-j", "ACCEPT" }
    }
    args[9][1] = "-C"
    args[10][1] = "-C"
    if cmd.iptables(args[8]) and cmd.iptables(args[9]) then
      return F.kept("iptables.default")
    else
      args[9][1] = "-A"
      args[10][1] = "-A"
      for n = 1, #args do
        cmd.iptables(args[n])
      end
    end
  end
end
return iptables
