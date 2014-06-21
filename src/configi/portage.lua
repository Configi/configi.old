local Lib = require"libconfigi"
local Cmd = require"cmd"
local Posix = require"posix"
local portage = {}
local ENV = {} ;_ENV = ENV

local main = function (M, S)
  local C = Lib.configi.start(M, S)
  C.required = { "atom" }
  C.valid = { "deep", "depclean", "newuse", "nodeps", "noreplace", "oneshot",
              "onlydeps", "quiet", "sync", "update", "verbose" }
  C.alias.atom = { "package" }
  return Lib.configi.finish(C)
end


local found = function (atom)
  local pretend = function (atom)
    local cmd = Cmd.emerge{ pretend = true, quiet = true, atom = atom }
    if Lc.tfind(cmd, "%[ebuild[%s]-R") then
      return true
    end
    return false
  end
  local d = Lc.strf("/var/db/pkg/%s/%s", Lc.splitp(atom))
  local stat = Posix.stat(d)
  if stat.type = "directory" or pretend(atom) then -- only run emerge -pq as a last resort
    return true
  end
end

function portage.present (S)
  local M = { "deep", "newuse", "nodeps", "noreplace", "oneshot",
              "onlydeps", "quiet", "sync", "update", "verbose" }
  local ok, err, sec, F, P, R = nil, nil, nil, main(M, S)
  if found(P.atom) then
    F.msg(P.atom, "portage.present", true)
    return R
  else
    F.msg(P.atom, "portage.present", false)
  end
  ok, err, sec = F.run(Cmd.emerge, { deep = P.deep, newuse = P.newuse, nodeps = P.nodeps,
                          noreplace = P.noreplace, oneshot = P.oneshot,
                          onlydeps = P.onlydeps, quiet = P.quiet, sync = P.sync,
                          update = P.update, verbose = P.verbose, atom = P.atom })
  end
  F.msg(P.atom, "Cmd.emerge", err, sec)
  if ok then
    F.msg(P.atom, "portage.present", true)
    R.changed = true
  else
    R.failed = true
  end
  return R
end

function portage.absent (S)
  local M = { "depclean", "quiet", "verbose" }
  local ok, err, sec, F, P, R = nil, nil, nil, main(M, S)
  if not found(P.atom) then
    F.msg(P.atom, "portage.absent", true)
    return R
  else
    F.msg(P.atom, "portage.absent", false)
  end
  ok, err, sec = F.run(Cmd.emerge, { depclean = P.depclean, quiet = P.quiet, verbose = P.verbose, atom = P.atom })
  F.msg(P.atom, "Cmd.emerge", err, sec)
  if ok then
    F.msg(P.atom, "portage.absent", true)
    R.changed = true
  else
    R.failed = true
  end
  return R
end

function portage.sync (S)
  S = S .. "\natom 'dummy'"
  local ok, err, sec, F, P, R = nil, nil, nil, main(M, S)
  if not P.sync then
    return R
  end
  ok, err, sec = F.run(Cmd.emerge, { sync = P.sync })
  F.msg("sync", "Cmd.emerge", err, sec)
  if ok then
    F.msg("sync", "portage.sync", true)
    R.changed = true
  else
    R.failed = true
  end
  return R
end

portage.installed = portage.present
portage.removed = portage.absent
return portage
