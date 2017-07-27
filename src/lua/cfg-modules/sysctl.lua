--- Kernel paramater modification through sysctl as implemented in procfs.
-- @module sysctl
-- @author Eduardo Tongson <propolice@gmail.com>
-- @license MIT <http://opensource.org/licenses/MIT>
-- @added 2.0.0

local ENV, M, sysctl = {}, {}, {}
local string = string
local tostring = tostring
local cfg = require"cfg-core.lib"
local lib = require"lib"
local file = lib.file
_ENV = ENV

M.required = { "value" }

--- Write value to a sysctl key
-- @Promiser key sysctl key to write to
-- @param value value to write
-- @usage sysctl.write"vm.swappiness"{
--   value = 0
-- }
function sysctl.write(S)
  M.report = {
    repaired = "sysctl.write: Successfully wrote value.",
      kept = "sysctl.write: Value already set.",
      failed = "sysctl.write: Error writing value.",
     not_found = "sysctl.write: Sysctl key not found."
  }
  return function(P)
    P.key = S
    local F, R = cfg.init(P, M)
    if R.kept then
      return F.kept(P.key)
    end
    local write_key = function()
      local key = string.gsub(P.key, "%.", "/")
      key = "/proc/sys/"..key
      if file.stat(key) then
        local write = tostring(P.value)
        if file.read_all(key) == write then
          return false
        end
        return file.write_all(key, write)
      else
        -- Key not found
        return 0
      end
    end
    local r = write_key()
    if r == false then
      return F.kept(P.key)
    elseif r == 0 then
      return F.result(P.key, nil, M.report.not_found)
    else
      return F.result(P.key, r)
    end
  end
end
--- Read value from a sysctl key then compare from expected value.
-- @Promiser key sysctl key to read from
-- @param value expected value
-- @usage sysctl.read"vm.swappiness"{
--   value = 0
-- }
function sysctl.read(S)
  M.report = {
    kept = "sysctl.read: ",
    failed = "systctl.read: ",
    not_found = "sysctl.read:"
  }
  return function(P)
    P.key = S
    local F, R = cfg.init(P, M)
    if R.kept then
      return F.kept(P.key)
    end
    local key = string.gsub(P.key, "%.", "/")
    key = "/proc/sys/"..key
    if not file.stat(key) then
      return F.result(P.key, nil, M.report.not_found)
    end
    if file.read(key) ~= tostring(P.value) then
      return F.result(P.key)
    end
    return F.result(P.key, true)
  end
end

return sysctl
