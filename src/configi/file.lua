local Lib = require"libconfigi"
local Lc = require"cimicida"
local Cmd = require"cmd"
local Posix = require"posix"
local tonumber, tostring = tonumber, tostring
local file = {}
local ENV = {} ;_ENV = ENV

local main = function (M, S)
  local C = Lib.configi.start(M, S)
  C.required = { "path" }
  C.valid = { "src", "mode", "force", "group", "owner", "recurse" }
  C.alias.path = { "dest", "name", "target" }
  C.alias.src = { "source" }
  C.alias.owner = { "uid" }
  C.alias.group = { "gid" }
  return Lib.configi.finish(C)
end

local owner = function (F, P, R)
  local ok, err, sec, stat = nil, nil, nil, Posix.stat(P.path)
  local u = Posix.getpasswd(stat.uid)
  local uid = Lc.strf("%s(%s)", u.uid, u.name)
  if P.owner == u.name or P.owner == tostring(u.uid) then
    F.msg(P.path, uid, true)
    return R
  else
    F.msg(P.path, uid, false)
  end
  ok, err, sec = F.run(Cmd.chown, { file = P.path, owner = P.owner, recurse = P.recurse, nodereference = true })
  F.msg(P.path, "Cmd.chown", err, sec)
  if ok then
    F.msg(P.path, P.owner, true)
    R.changed = true
  else
    R.failed = true
  end
  return R
end

local group = function (F, P, R)
  local ok, err, sec, stat = nil, nil, nil, Posix.stat(P.path)
  local g = Posix.getgroup(stat.gid)
  local cg = Lc.strf("%s(%s)", g.gid, g.name)
  if P.group == g.name or P.group == tostring(g.gid) then
    F.msg(P.path, cg, true)
    return R
  else
    F.msg(P.path, cg, false)
  end
  ok, err, sec = F.run(Cmd.chown { file = P.path, group = P.group, recurse = P.recurse, nodereference = true })
  F.msg(P.path, "Cmd.chown", err, sec)
  if ok then
    F.msg(P.path, P.group, true)
    R.changed = true
  else
    R.failed = true
  end
  return R
end

local mode = function (F, P, R)
  local ok, err, sec, stat = nil, nil, nil, Posix.stat(P.path)
  if stat.mode == tonumber(P.mode) then
    F.msg(P.path, stat.mode, true)
    return R
  else
    F.msg(P.path, stat.mode, false)
  end
  ok, err, sec = F.run(Cmd.chmod, { file = P.path, mode = P.mode, recurse = P.recurse })
  F.msg(P.path, "Cmd.chmod", err, sec)
  if ok then
    F.msg(P.path, P.mode, true)
    R.changed = true
  else
    R.failed = true
  end
  return R
end

local attrib = function (F, P, R)
  if P.owner then R = owner(F, P, R) end
  if P.group then R = group(F, P, R) end
  if P.mode then  R = mode (F, P, R) end
  return R
end

function file.attributes (S)
  local M = { "mode", "owner", "group" }
  local F, P, R = nil, nil, main(M, S)
  if not P.test then
    if not Posix.stat(P.path) then
      F.msg(P.path, "file.attributes", "Missing path")
      R.failed = true
      return R
    end
  end
  return attrib(F, P, R)
end

function file.link (S) -- P.path == symlink == target
  local M = { "src", "force" }
  local ok, err, sec, F, P, R = nil, nil, nil, main(M, S)
  local source = Posix.readlink(P.path)
  if P.src == source then
    F.msg(P.path, source, true)
    return attrib(F, P, R)
  else
    F.msg(P.path, source, false)
  end
  ok, err, sec = F.run(Cmd.ln, { target = P.path, force = P.force, source = P.src, symlink = true })
  F.msg(P.path, "Cmd.ln", err, sec)
  if ok then
    F.msg(P.path, P.src, true)
    R.changed = true
    return attrib(F, P, R)
  else
    R.failed = true
  end
  return R
end

function file.hard (S)
  local M = { "src", "force" }
  local ok, err, sec, F, P, R = nil, nil, nil, main(M, S)
  local source = Posix.stat(P.src)
  local target = Posix.stat(P.path)
  if not source then
    F.msg(P.src, Lc.strf("source '%s' is missing", source), false)
    R.failed = true
    return R
  end
  if source.ino == target.ino then
    F.msg(P.path, source, true)
    return attrib(F, P, R)
  else
    F.msg(P.path, source, false)
  end
  ok, err, sec = F.run(Cmd.ln, { target = P.path, force = P.force, source = P.src })
  F.msg(P.path, "Cmd.ln", err, sec)
  if ok then
    F.msg(P.path, P.src, true)
    R.changed = true
    return attrib(F, P, R)
  else
    R.failed = true
  end
  return R
end

function file.directory (S)
  local M = { "mode", "owner", "group", "force" }
  local ok, err, sec, F, P, R = nil, nil, nil, main(M, S)
  local stat = Posix.stat(P.path)
  if not stat then
    F.msg(P.path, "absent", false)
  elseif stat.type == "directory" then
    F.msg(P.path, "directory", true)
    return attrib(F, P, R)
  else
    F.msg(P.path, "not a directory", false)
  end
  if P.force then
    ok, err, sec = F.run(Cmd.rm, { file = P.path, recurse = true, force = true })
    F.msg(P.path, "Cmd.rm", err, sec)
  end
  ok, err, sec = F.run(Cmd.mkdir, { name = P.path, parents = true })
  F.msg(P.path, "Cmd.mkdir", err, sec)
  if ok then
    R.changed = true
    return attrib(F, P, R)
  else
    R.failed = true
  end
  return R
end

function file.touch (S)
  local M = { "mode", "owner", "group" }
  local ok, err, sec, F, P, R = nil, nil, nil, main(M, S)
  ok, err, sec = F.run(Cmd.touch, { file = P.path })
  F.msg(P.path, "Cmd.touch", err, sec)
  if ok then
    R.changed = true
    return attrib(F, P, R)
  else
    R.failed = true
    return R
  end
end

function file.absent (S)
  local ok, err, sec, F, P, R = nil, nil, nil, main(M, S)
  if not Posix.stat(P.path) then
    F.msg(P.path, "absent", true)
    return R
  else
    F.msg(P.path, "absent", false)
  end
  ok, err, sec = F.run(Cmd.rm, { file = P.path, recurse = true, force = true })
  F.msg(P.path, "file.absent", err, sec)
  if ok then
    R.changed = true
  else
    R.failed = true
  end
  return R
end

function file.copy (S)
  local M = { "src", "path", "recurse", "force" }
  local ok, err, sec, F, P, R = nil, nil, nil, main(M, S)
  local present = Posix.stat(P.path)
  if P.force and present then
    ok, err, sec = F.run(Cmd.rm, { file = P.path, recurse = true, force = true })
    F.msg(P.path, "Cmd.rm", err, sec)
  elseif not P.force and present then
    F.msg(P.path, "file.copy (present)", true)
    return R
  end
  ok, err, sec = F.run(Cmd.cp, { source = P.src, target = P.path, recurse = P.recurse, force = P.force })
  F.msg(P.path, "Cmd.cp", err, sec)
  if ok then
    R.changed = true
  else
    R.failed = true
  end
  return R
end

return file


