--- Ensure a Linux kernel module is inserted or removed
-- @module lkm
-- @author Eduardo Tongson <propolice@gmail.com>
-- @license MIT <http://opensource.org/licenses/MIT>
-- @added 2.0.0
local ENV, M, lkm = {}, {}, {}
local ipairs, string = ipairs, string
local cfg = require"cfg-core.lib"
local lib = require"lib"
local table, util = lib.table, lib.util
local cmd = lib.exec.cmd
local fact = require"cfg-core.fact"
_ENV = ENV

M.required = { "dir" }

--- Relkm a filesystem with specified options
-- @Promiser lkm lkm point to relkm
-- @param value value to write
-- @usage lkm.opts"/tmp"{
--    nodev = true
-- }
function lkm.opts(S)
  M.parameters = {
  }
  M.report = {
    repaired = "lkm.insert: Successfully relkmed lkm point.",
      kept = "lkm.relkm: lkm option already set.",
      failed = "lkm.relkm: Error relkming lkm point.",
     unlkmed = "lkm.relkm: Error relkming unlkmed lkm point."
  }
  return function(P)
    P.dir = S
    local F, R = cfg.init(P, M)
    if R.kept then
      return F.kept(P.dir)
    end
    if fact.lkm[P.dir] == false then
      return F.result(P.dir, nil, M.report.unlkmed)
    end
    local tmp = {}
    for _, o in ipairs(M.parameters) do
      table.insert_if(P[o], tmp, -1, o)
    end
    local to = {}
    for _, o in ipairs(tmp) do
      if P[o] == true or util.truthy(P[o]) then
        to[#to+1] = o
      elseif P[o] then
        to[#to+1] = o.."="..P[o]
      end
    end
    local co
    for _, o in ipairs(fact.lkm.table) do
      if P.dir == o.dir then
        co = o.opts
        break
      end
    end
    local st
    for _, o in ipairs(to) do
      st = string.find(co, o, 1, true)
      if st == nil then
        local r = F.run(cmd.lkm, { "-o", "relkm,"..table.concat(to, ","), P.dir })
        return F.result(P.dir, r)
      end
    end
    if st then
      return F.kept(P.dir)
    end
  end
end

function lkm.insert(S)
  M.parameters = {
  }
  M.alias = {}
  M.alias.dev = { "device" }
  M.report = {
    repaired = "lkm.insert: Successfully inserted Linux kernel module.",
      kept = "lkm.insert: Linux kernel module already inserted.",
      failed = "lkm.insert: Failed to insert module."
  }
  return function(P)
    P.dir = S
    local F, R = cfg.init(P, M)
    if R.kept or fact.lkm[P.dir] then
      return F.kept(P.dir)
    else
      local a = { P.dir }
      table.insert_if(P.dev, a, 1, P.dev)
      local r = F.run(cmd.lkm, a)
      return F.result(P.dir, r)
    end

  end
end

function lkm.unlkmed(S)
  M.report = {
    repaired = "lkm.umlkmed: Successfully unlkmed.",
      kept = "lkm.unlkmed: Already unlkmed.",
      failed = "lkm.unlkmed: Failed to unlkm."
  }
  return function(P)
    P.dir = S
    local F, R = cfg.init(P, M)
    if R.kept or fact.lkm[P.dir] == false then
      return F.kept(P.dir)
    else
      local r = F.run(cmd.ulkm, { P.dir })
      return F.result(P.dir, r)
    end
  end
end


cmd.modprobe{"-q", "--first-time" }
lkm.loaded = lkm.inserted
lkm.unloaded = lkm.removed
return lkm
