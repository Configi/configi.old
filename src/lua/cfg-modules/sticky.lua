--- Ensure world-writable directories have the sticky bit set.
-- Requires the xargs(1) and find(1) utilities.
-- @module sticky
-- @author Eduardo Tongson <propolice@gmail.com>
-- @license MIT <http://opensource.org/licenses/MIT>
-- @added 2.0.0

local M, sticky = {}, {}
local table = table
local cfg = require"cfg-core.lib"
local exec = require"lib".exec
_ENV = nil

local function local_0777(b)
  local dirs = table.concat(factid.local_fs(), "\n")
  local xargs = exec.context"xargs"
  xargs.stdin = dirs
  if not b then
    return xargs("-I", "'{}'",
      "find", "'{}'", "-xdev", "-type", "d", "(","-perm", "-0002", "-a", "!", "-perm", "-1000", ")")
  else
    return xargs("-I", "'{}'",
      "find", "'{}'", "-xdev", "-type", "d", "(","-perm", "-0002", "-a", "!", "-perm", "-1000", ")", "-exec",
      "chmod", "a+t", "{}", "+")
  end
end
--- Find world writable directories and set the sticky bit if not already.
-- @Promiser string
-- @usage sticky.set"whatever"()
function sticky.set(S)
  M.report = {
    repaired = "sticky.set: Sticky bit successfully set on directories.",
    kept = "sticky.set: No world-writable directories without sticky bit set found.",
    failed = "sticky.set: Failure setting sticky bit.",
    xargs_failed = "sticky.set: xargs(1) command failed."
  }
  return function(P)
    P.dummy = S or "sticky"
    local F, R = cfg.init(P, M)
    local xargs, found = local_0777()
    if not xargs then
      return F.result(P.dummy, nil, M.report.xargs_failed)
    end
    if R.kept or (#found.stdout == 0)then
      return F.kept(P.dummy)
    end
    if not local_0777(true) then
      return F.result(P.dummy, nil)
    end
    return F.result(P.dummy, true)
  end
end
return sticky
