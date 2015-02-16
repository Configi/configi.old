-- IPTables.
-- This module is for configuring rules on a host. The FORWARD chain is untested.
-- @module iptables
-- @author Eduardo Tongson <propolice@gmail.com>
-- @license MIT <http://opensource.org/licenses/MIT>
-- @added 0.9.7

local Lua = {
  lines = io.lines,
  format = string.format,
  find = string.find,
  insert = table.insert,
  concat = table.concat,
  ipairs = ipairs,
  upper = string.upper
}
local Configi = require"configi"
local Px = require"px"
local Cmd = Px.cmd
local Lc = require"cimicida"
local Pstat = require"posix.sys.stat"
local iptables = {}
local ENV = {}
_ENV = ENV

local main = function (S, M, G)
  local C = Configi.start(S, M, G)
  C.required = { "chain" }
  return Configi.finish(C)
end

--- Add iptables rules.
-- @param table packet matching table [DEFAULT: filter]
-- @param chain [DEFAULT: INPUT]
-- @param source source specification. Default network mask is /32.
-- @param destination destination specification. Default network mask is /32.
-- @param protocol protocol of the rule to match for
-- @param dport destination port
-- @param sport source port
-- @param tcp-flags
-- @param tcp-option
-- @param target target of the rule
-- @param in incoming interface via which the rule to match for
-- @param out outgoing interface via which the rule to match for
-- @param ipv6 Use ip6tables
-- @param ipv4 Use iptables [DEFAULT: yes]
-- @usage iptables.append [[
--   table "filter"
--   chain "input"
--   target "accept"
--   source "6.6.6.6"
--   protocol "tcp"
--   sport "31337"
--   dport "31337"
-- ]]
function iptables.append (S)
  -- -A INPUT -s P.source -d P.destination -i lo -p tcp -m tcp --sport 31337 --dport 8080 --tcp-option 16 --tcp-flags SYN FIN -j ACCEPT
  local M = { "table", "chain", "source", "destination", "protocol",
              "dport", "sport", "tcp-flags", "tcp-option", "target",
              "in", "out", "ipv6", "ipv4" }
  local G = {
    repaired = "iptables.append: Successfully appended rule.",
    kept = "iptables.append: Rule exists.",
    failed = "iptables.append: Failed to append rule."
  }
  local F, P, R = main(S, M, G)
  local mask = function (ip)
    if not Lua.find(ip, "/", -3) and not Lua.find(ip, "/", -2) then
      ip = ip .. "/32"
    end
    return ip
  end
  if P.ipv4 == nil then
    P.ipv4 = true -- on by default
  end
  if P.chain == nil then
    P.chain = "INPUT" -- default
  end
  if P.table == nil then
    P.table = "filter" -- default
  end
  if P.source then
    P.source = mask(P.source)
  end
  if P.destination then
    P.destination = mask(P.destination)
  end
  -- ordering is prescribed
  local rule = { "-A", Lua.upper(P.chain), "-j", Lua.upper(P.target) }
  Lc.insertif(P["tcp-flags"], rule, 3, { "--tcp-flags", P["tcp-flags"] })
  Lc.insertif(P["tcp-option"], rule, 3, { "--tcp-option", P["tcp-option"] })
  Lc.insertif(P.dport, rule, 3, { "--dport", P.dport })
  Lc.insertif(P.sport, rule, 3, { "--sport", P.sport })
  Lc.insertif(P.protocol, rule, 3, { "-m", P.protocol })
  Lc.insertif(P.protocol, rule, 3, { "-p", P.protocol })
  Lc.insertif(P.out, rule, 3, { "-o", P.out})
  Lc.insertif(P["in"], rule, 3, { "-i", P["in"]})
  Lc.insertif(P.destination, rule, 3, { "-d", P.destination })
  Lc.insertif(P.source, rule, 3, { "-s", P.source })
  local rule_str = Lua.concat(rule, " ")
  local list = { iptables = {}, ip6tables = {} }
  local ipt = {}
  if P.ipv4 == true then
    ipt[#ipt + 1] = "iptables"
  end
  if P.ipv6 == true then
    ipt[#ipt + 1] = "ip6tables"
  end
  local skip = false
  for _, i in Lua.ipairs(ipt) do
    skip = false -- reset
    local _, res = Cmd[i]{ "--list-rules", Lua.upper(P.chain) }
    if Lc.tfind(res.stdout, rule_str, true) then
      skip = true
    else
      Lua.insert(rule, 1, P.table)
      Lua.insert(rule, 1, "-t")
      if not F.run(Cmd[i], rule) then
        return F.result("iptables.append", false)
      end
    end
  end
  if skip == true then
    return F.kept("iptables.append")
  end
  return F.result("iptables.append", true)
end

--- Disable IPTables.
-- Flush, zero out counters and remove user-defined chains.
-- @usage iptables.disable[[]]
function iptables.disable (S)
  S = [[ chain "dummy" ]]
  local M = {}
  local G = {
    repaired = "iptables.disable: Successfully disabled iptables.",
    failed = "iptables.disable: Error disabling iptables."
  }
  local F, P, R = main(S, M, G)
  local disable = function (tables)
    local ipt
    if tables == "/proc/net/ip_tables_names" then
      ipt = "-iptables"
    else
      ipt = "-ip6tables"
    end
    Cmd[ipt]{ "-P", "INPUT", "ACCEPT" }
    Cmd[ipt]{ "-P", "OUTPUT", "ACCEPT" }
    Cmd[ipt]{ "-P", "FORWARD", "ACCEPT" }
    local ok = false
    local cmds = { "-F", "-X", "-Z" }
    for t in Lua.lines(tables) do
      for _, c in Lua.ipairs(cmds) do
        if F.run(Cmd[ipt], { "-t", t, c }) then
          ok = true
        else
          return false
        end
      end
    end
    return ok
  end
  local ok = false
  if Pstat.stat("/proc/net/ip_tables_names") then
    ok = disable("/proc/net/ip_tables_names")
  else
    ok = true
  end
  if Pstat.stat("/proc/net/ip6_tables_names") then
    ok = false -- reset variable
    ok = disable("/proc/net/ip6_tables_names")
  else
    ok = true
  end
  return F.result("iptables.disable", ok)
end

--- Default deny but allow incoming connections to port 22
-- @param host IP of the local host [DEFAULT: 0.0.0.0]
-- @param source IP of host to white list [DEFAULT: 0.0.0.0]
-- @param ssh SSH port [DEFAULT: 22]
-- @usage iptables.default[[]]
function iptables.default (S)
  local M = { "source", "host", "ssh" }
  local G = {
    repaired = "iptables.default: Successfully added rules.",
    failed = "iptables.default: Error adding rules."
  }
  local F, P, R = main(S, M, G)
  if P.source == nil then
    P.source = "0/0"
  end
  if P.host == nil then
    P.host = "0/0"
  end
  if P.ssh == nil then
    P.ssh = "22"
  end
  local args = {
    { "-F" },
    { "-X" },
    { "-P", "INPUT", "DROP" },
    { "-P", "OUTPUT", "DROP" }
    { "-P", "FORWARD", "DROP" }
    { "-A", "INPUT", "-i", "lo", "-j", "ACCEPT" },
    { "-A", "OUTPUT", "-o", "lo", "-j", "ACCEPT" },
    { "-A", "INPUT", "-p", "tcp", "-s", P.source, "-d", P.host, "--sport", "513:65535", "--dport", P.ssh,
      "-m", "state", "--state", "NEW,ESTABLISHED", "-j", "ACCEPT" },
    { "-A", "OUTPUT", "-p", "tcp", "-s", P.host, "-d", P.source, "--sport", P.ssh, "--dport", "513:65535",
      "-m", "state", "--state", "ESTABLISHED", "-j", "ACCEPT" }
  }
  for _, a in Lua.ipairs(args) do
    Cmd.iptables(a)
  end
end

return iptables
