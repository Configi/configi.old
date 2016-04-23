--- IPTables.
-- This module is for configuring rules on a host. Warning: the FORWARD chain is untested.
-- @module iptables
-- @author Eduardo Tongson <propolice@gmail.com>
-- @license MIT <http://opensource.org/licenses/MIT>
-- @added 0.9.7

local io, string, table, ipairs = io, string, table, ipairs
local Configi = require"configi"
local cfg = require"configi"
local lib = require"lib"
local cmd = lib.cmd
local stat = require"posix.sys.stat"
local iptables = {}
local ENV = {}
_ENV = ENV

local main = function (S, M, G)
  local C = cfg.start(S, M, G)
  C.required = { "chain" }
  C.alias.match = { "module" }
  return cfg.finish(C)
end

--- Add iptables rules.
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
-- @param ipv4 Use iptables [DEFAULT: yes]
-- @usage iptables.append [[
--   table "filter"
--   chain "input"
--   target "accept"
--   source "6.6.6.6"
--   protocol "tcp"
--   options "-m tcp --sport 31337 --dport 31337"
-- ]]
function iptables.append (S)
  -- -A INPUT -s P.source -d P.destination -i lo -p tcp -m tcp --sport 31337 --dport 8080 --tcp-option 16 --tcp-flags SYN FIN -j ACCEPT
  local M = { "table", "chain", "source", "destination", "protocol", "target", "options", "match", "in", "out", "ipv6", "ipv4" }
  local G = {
    repaired = "iptables.append: Successfully appended rule.",
    kept = "iptables.append: Rule already present.",
    failed = "iptables.append: Failed to append rule."
  }
  local F, P, R = main(S, M, G)
  local mask = function (ip)
    if not string.find(ip, "/", -3) and not string.find(ip, "/", -2) then
      ip = ip .. "/32"
    end
    return ip
  end
  if P.ipv4 == nil then
    P.ipv4 = true -- on by default
  end
  P.chain = P.chain or "INPUT"
  P.table = P.table or "filter"
  if P.source then
    P.source = mask(P.source)
  end
  if P.destination then
    P.destination = mask(P.destination)
  end
  local rule = { "", string.upper(P.chain), "-j", string.upper(P.target) }
  lib.insert_if(P.options, rule, 3, lib.str_to_tbl(P.options))
  lib.insert_if(P.protocol, rule, 3, { "-p", P.protocol })
  lib.insert_if(P.out, rule, 3, { "-o", P.out})
  lib.insert_if(P["in"], rule, 3, { "-i", P["in"]})
  lib.insert_if(P.destination, rule, 3, { "-d", P.destination })
  lib.insert_if(P.source, rule, 3, { "-s", P.source })
  local list = { iptables = {}, ip6tables = {} }
  local ipt = {}
  if P.ipv4 == true then
    ipt[#ipt + 1] = "iptables"
  end
  if P.ipv6 == true then
    ipt[#ipt + 1] = "ip6tables"
  end
  local skip = false
  for _, i in ipairs(ipt) do
    skip = false -- reset
    rule[1] = "-C"
    if cmd[i](rule) then
      skip = true
    else
      rule[1] = "-A"
      if not F.run(cmd[i], rule) then
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
-- @param NONE
-- @usage iptables.disable[[]]
function iptables.disable (S)
  local S = { chain = "iptables.disable" }
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
    cmd[ipt]{ "-P", "INPUT", "ACCEPT" }
    cmd[ipt]{ "-P", "OUTPUT", "ACCEPT" }
    cmd[ipt]{ "-P", "FORWARD", "ACCEPT" }
    local ok = false
    local cmds = { "-F", "-X", "-Z" }
    for t in io.lines(tables) do
      for _, c in ipairs(cmds) do
        if F.run(cmd[ipt], { "-t", t, c }) then
          ok = true
        else
          return false
        end
      end
    end
    return ok
  end
  local ok = false
  if stat.stat("/proc/net/ip_tables_names") then
    ok = disable("/proc/net/ip_tables_names")
  else
    ok = true
  end
  if stat.stat("/proc/net/ip6_tables_names") then
    ok = false -- reset variable
    ok = disable("/proc/net/ip6_tables_names")
  else
    ok = true
  end
  return F.result("iptables.disable", ok)
end

--- Default deny but allow incoming connections to port 22.
-- @note IPv4 only at the moment.
-- @param host IP of the local host [DEFAULT: 0.0.0.0]
-- @param source IP of host to white list [DEFAULT: 0.0.0.0]
-- @param ssh SSH port [DEFAULT: 22]
-- @usage iptables.default[[]]
function iptables.default (S)
  local M = { "source", "host", "ssh" }
  local G = {
    repaired = "iptables.default: Successfully added rules.",
    kept = "iptables.default: Rules already present",
    failed = "iptables.default: Error adding rules."
  }
  local F, P, R = main(S, M, G)
  P.source = P.source or "0/0"
  P.host = P.host or "0/0"
  P.ssh = P.ssh or "22"
  local args = {
    { "-F" },
    { "-X" },
    { "-P", "INPUT", "DROP" },
    { "-P", "OUTPUT", "DROP" },
    { "-P", "FORWARD", "DROP" },
    { "-A", "INPUT", "-i", "lo", "-j", "ACCEPT" },
    { "-A", "OUTPUT", "-o", "lo", "-j", "ACCEPT" },
    { "", "INPUT", "-p", "tcp", "-s", P.source, "-d", P.host, "--sport", "513:65535", "--dport", P.ssh,
      "-m", "state", "--state", "NEW,ESTABLISHED", "-j", "ACCEPT" },
    { "", "OUTPUT", "-p", "tcp", "-s", P.host, "-d", P.source, "--sport", P.ssh, "--dport", "513:65535",
      "-m", "state", "--state", "ESTABLISHED", "-j", "ACCEPT" }
  }
  args[8][1] = "-C"
  args[9][1] = "-C"
  if cmd.iptables(args[8]) and cmd.iptables(args[9]) then
    return F.kept("iptables.default")
  else
    args[8][1] = "-A"
    args[9][1] = "-A"
    for _, a in ipairs(args) do
      cmd.iptables(a)
    end
  end
end

return iptables
