--- File operations.
-- @module file
-- @author Eduardo Tongson <propolice@gmail.com>
-- @license MIT <http://opensource.org/licenses/MIT>
-- @added 0.9.0
--
local Str = {}
Str.file_owner_ok = "file.owner: Owner/uid corrected."
Str.file_owner_skip = "file.owner: Owner/uid already matches "
Str.file_owner_fail = "file.owner: Error setting owner/uid."
Str.file_group_ok = "file.group: Group/gid corrected."
Str.file_group_skip = "file.group: Group/gid already matches "
Str.file_group_fail = "file.group: Error setting group/gid."
Str.file_mode_ok = "file.mode: Mode corrected."
Str.file_mode_skip = "file.mode: Mode matched."
Str.file_mode_fail = "file.mode: Error setting mode."
Str.file_link_ok = "file.link: Symlink created."
Str.file_link_skip = "file.link: Already a symlink."
Str.file_link_fail = "file.link: Error creating symlink."
Str.file_hard_ok = "file.hard: Hardlink created."
Str.file_hard_skip = "file.hard: Already a hardlink."
Str.file_hard_fail = "file.hard: Error creating hardlink."
local Lua = {
  tostring = tostring,
  rename = os.rename,
  format = string.format,
  sub = string.sub
}
local Configi = require"configi"
local Lc = require"cimicida"
local Px = require"px"
local Cmd = Px.cmd
local Pstat = require"posix.sys.stat"
local Punistd = require"posix.unistd"
local Ppwd = require"posix.pwd"
local Pgrp = require"posix.grp"
local file = {}
local ENV = {}
_ENV = ENV

local main = function (S, M, G)
  local C = Configi.start(S, M, G)
  C.required = { "path" }
  C.alias.path = { "name", "link", "dest", "target" }
  C.alias.src = { "source" }
  C.alias.owner = { "uid" }
  C.alias.group = { "gid" }
  return Configi.finish(C)
end

local owner = function (F, P, R)
  local stat = Pstat.stat(P.path)
  local u = Ppwd.getpwuid(stat.st_uid)
  local uid = Lc.strf("%s(%s)", u.pw_uid, u.pw_name)
  if P.owner == u.pw_name or P.owner == Lua.tostring(u.pw_uid) then
    F.msg(P.path, Str.file_owner_skip .. uid .. ".", nil)
    if not R.changed then
      R.notify_kept = P.notify_kept
    end
    return R
  end
  local args = { "-h", P.owner, P.path }
  Lc.insertif(P.recurse, args, 2, "-R")
  if F.run(Cmd.chown, args) then
    F.msg(P.path, Str.file_owner_ok, true)
    R.notify = P.notify
    R.repaired = true
  else
    F.msg(P.path, Str.file_owner_fail, false)
    R.notify_failed = P.notify_failed
    R.failed = true
  end
  return R
end

local group = function (F, P, R)
  local stat = Pstat.stat(P.path)
  local g = Pgrp.getgrgid(stat.st_gid)
  local cg = Lc.strf("%s(%s)", g.gr_gid, g.gr_name)
  if P.group == g.gr_name or P.group == Lua.tostring(g.gr_gid) then
    F.msg(P.path, Str.file_group_skip .. cg .. ".", nil)
    if not R.changed then
      R.notify_kept = P.notify_kept
    end
    return R
  end
  local args = { "-h", ":" .. P.group, P.path }
  Lc.insertif(P.recurse, args, 2, "-R")
  if F.run(Cmd.chown, args) then
    F.msg(P.path, Str.file_group_ok, true)
    R.notify = P.notify
    R.repaired = true
  else
    F.msg(P.path, Str.file_group_fail, false)
    R.notify_failed = P.notify_failed
    R.failed = true
  end
  return R
end

local mode = function (F, P, R)
  local stat = Pstat.stat(P.path)
  local mode = Lua.sub(Lua.tostring(Lua.format("%o", stat.st_mode)), -3, -1)
  if mode == Lua.sub(P.mode, -3, -1) then
    F.msg(P.path, Str.file_mode_skip, nil)
    if not R.changed then
      R.notify_kept = P.notify_kept
    end
    return R
  end
  local args = { P.mode, P.path }
  Lc.insertif(P.recurse, args, 1, "-R")
  if F.run(Cmd.chmod, args) then
    F.msg(P.path, Str.file_mode_ok, true)
    R.notify = P.notify
    R.repaired = true
  else
    F.msg(P.path, Str.file_mode_fail, false)
    R.notify_failed = P.notify_failed
    R.failed = true
  end
  return R
end

local attrib = function (F, P, R)
  if not (P.owner or P.group or P.mode) then
    R.notify = P.notify
    R.repaired = true
    return R
  end
  if P.owner then
    R = owner(F, P, R)
  end
  if P.group then
    R = group(F, P, R)
  end
  if P.mode then
    R = mode (F, P, R)
  end
  return R
end

--- Set path attributes such as the mode, owner or group.
-- @param path path to modify [REQUIRED]
-- @param mode set the file mode bits
-- @param owner set the uid/owner [ALIAS: uid]
-- @param group set the gid/group [ALIAS: gid]
-- @usage file.attributes [[
--   path "/etc/shadow"
--   mode "0600"
--   owner "root"
--   group "root"
-- ]]
function file.attributes (S)
  local M = { "mode", "owner", "group" }
  local F, P, R = main(S, M)
  if not P.test then
    if not Pstat.stat(P.path) then
      F.msg(P.path, "Missing path", false)
      R.notify_failed = P.notify_failed
      R.failed = true
      return R
    end
  end
  return attrib(F, P, R)
end

--- Create a symlink.
-- @param src path where the symlink points to [REQUIRED]
-- @param path the symlink [REQUIRED] [ALIAS: link]
-- @param force remove existing symlink [CHOICES: "yes","no"]
-- @usage file.link [[
--   src "/"
--   path "/home/ed/root"
-- ]]
function file.link (S)
  local M = { "src", "force", "owner", "group", "mode" }
  local F, P, R = main(S, M)
  local symlink = Punistd.readlink(P.path)
  if symlink == P.src then
    F.msg(P.src, Str.file_link_skip, nil)
    return attrib(F, P, R)
  end
  local args = { "-s", P.src, P.path }
  Lc.insertif(P.force, args, 2, "-f")
  if F.run(Cmd.ln, args) then
    F.msg(P.path, Str.file_link_ok, true)
    R.changed = true
    return attrib(F, P, R)
  else
    F.msg(P.path, Str.file_link_fail, false)
    R.notify_failed = P.notify_failed
    R.failed = true
  end
  return R
end

--- Create a hard link.
-- @param src path where the hard link points to [REQUIRED]
-- @param path the hard link [REQUIRED] [ALIAS: link]
-- @param force remove existing hard link [CHOICES: "yes","no"]
-- @usage file.hard [[
--   src "/"
--   path "/home/ed/root"
-- ]]
function file.hard (S)
  local M = { "src", "force", "owner", "group", "mode" }
  local F, P, R = main(S, M)
  local source = Pstat.stat(P.src)
  local link = Pstat.stat(P.path) or nil
  if not source then
    F.msg(P.path, Lc.strf(" '%s' is missing", source), false)
    R.notify_failed = P.notify_failed
    R.failed = true
    return R
  end
  if source and link and (source.st_ino == link.st_ino) then
    F.msg(P.path, Str.file_hard_skip, nil)
    return attrib(F, P, R)
  end
  local args = { P.src, P.path }
  Lc.insertif(P.force, args, 1, "-f")
  if F.run(Cmd.ln, args) then
    F.msg(P.path, Str.file_hard_ok, true)
    R.changed = true
    return attrib(F, P, R)
  else
    F.msg(P.path, Str.file_hard_fail, false)
    R.notify_failed = P.notify_failed
    R.failed = true
  end
  return R
end

--- Create a directory.
-- @param path path of the directory [REQUIRED]
-- @param mode set the file mode bits
-- @param owner set the uid/owner [ALIAS: uid]
-- @param group set the gid/group [ALIAS: gid]
-- @param force remove existing path before creating directory [CHOICES: "yes","no"] [DEFAULT: "no"]
-- @param backup rename existing path and prepend '._configi_' to the name [CHOICES: "yes","no"] [DEFAULT: "no"]
-- @usage file.directory [[
--   path "/usr/portage"
-- ]]
function file.directory (S)
  local M = { "mode", "owner", "group", "force", "backup" }
  local G = {
    ok = "file.directory: Directory created.",
    skip = "file.directory: Already a directory.",
    fail = "file.directory: Error creating directory."
  }
  local F, P, R = main(S, M, G)
  local stat = Pstat.stat(P.path)
  if stat and (Pstat.S_ISDIR(stat.st_mode) ~= 0 )then
    F.msg(P.path, G.skip, nil)
    return attrib(F, P, R)
  end
  if P.force then
    if P.backup then
      local dir, file = Lc.splitp(P.path)
      F.run(Lua.rename, P.path, dir .. "/._configi_" .. file)
    end
    F.run(Cmd.rm, { "-r", "-f", P.path })
  end
  if F.run(Cmd.mkdir, { "-p", P.path }) then
    F.msg(P.path, G.ok, true)
    return attrib(F, P, R)
  else
    F.msg(P.path, G.fail, false)
    R.notify_failed = P.notify_failed
    R.failed = true
  end
  return R
end

--- Touch a path.
-- @param path path to 'touch' [REQUIRED]
-- @param mode set the file mode bits
-- @param owner set the uid/owner [ALIAS: uid]
-- @param group set the gid/group [ALIAS: gid]
-- @usage file.touch [[
--   path "/srv/.keep"
-- ]]
function file.touch (S)
  local M = { "mode", "owner", "group" }
  local G = {
    ok = "file.touch: touch(1) succeeded.",
    fail = "file.touch: touch(1) failed."
  }
  local F, P, R = main(S, M, G)
  if F.run(Cmd.touch, { P.path }) then
    F.msg(P.path, G.ok, true)
    return attrib(F, P, R)
  else
    F.msg(P.path, G.failed, false)
    R.notify_failed = P.notify_failed
    R.failed = true
    return R
  end
end

--- Remove a path.
-- @param path path to delete [REQUIRED]
-- @usage file.absent [[
--   path "/home/ed/.xinitrc"
-- ]]
function file.absent (S)
  local G = {
    ok = "file.absent: Successfully removed.",
    skip = "file.absent: Already absent.",
    fail = "file.absent: Error removing path.",
  }
  local F, P, R = main(S, M, G)
  if not Pstat.stat(P.path) then
    return F.skip(P.path)
  end
  return F.result(F.run(Cmd.rm, { "-r", "-f", P.path }), P.path)
end

--- Copy a path.
-- @param path destination path [REQUIRED] [ALIAS: dest,target]
-- @param src source path to copy [REQUIRED]
-- @param recurse recursively copy source [CHOICES: "yes","no"] [DEFAULT: "no"]
-- @param force remove existing destination before copying [CHOICES: "yes","no"] [DEFAULT: "no"]
-- @param backup rename existing path and prepend '._configi_' to the name [CHOICES: "yes","no"] [DEFAULT: "no"]
-- @usage file.copy [[
--   src "/home/ed"
--   dest "/mnt/backups"
-- ]]
function file.copy (S)
  local M = { "src", "path", "recurse", "force", "backup" }
  local G = {
    ok = "file.copy: Copy succeeded.",
    skip = "file.copy: Not copying over destination.",
    fail = "file.copy: Error copying."
  }
  local F, P, R = main(S, M, G)
  local dir, file = Lc.splitp(P.path)
  local backup = dir .. "/._configi_" .. file
  local present = Pstat.stat(P.path)
  if present and P.backup and (not Pstat.stat(backup)) then
    if not F.run(Cmd.mv, { P.path, backup }) then
      return F.result(false, P.path)
    end
  elseif not P.force and present then
    return F.skip(P.path)
  end
  local args = { "-P", P.src, P.path }
  Lc.insertif(P.recurse, args, 2, "-R")
  Lc.insertif(P.force, args, 2, "-f")
  if F.run(Cmd.cp, args) then
    F.msg(P.path, Str.file_copy_ok, true)
    R.notify = P.notify
    R.repaired = true
    return F.result(true, P.path)
  else
    F.run(Cmd.rm, { "-r", "-f", P.path }) -- clean up incomplete copy
    return F.result(false, P.path)
  end
end

return file


