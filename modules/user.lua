--- Ensure that a user-login is present or absent
-- @module user
-- @author Eduardo Tongson <propolice@gmail.com>
-- @license MIT <http://opensource.org/licenses/MIT>
-- @added 0.9.0

local Lua = {
  tostring = tostring
}
local Configi = require"configi"
local Ppwd = require"posix.pwd"
local Lc = require"cimicida"
local Px = require"px"
local Cmd = Px.cmd
local user = {}
local ENV = {}
_ENV = ENV

local main = function (S, M, G)
  local C = Configi.start(S, M, G)
  C.required = { "login" }
  C.alias.login = { "username", "user" }
  return Configi.finish(C)
end

--- Add a system user account.
-- @aliases add
-- @note On OpenWRT: requires the shadow-useradd package
-- @note This module can only check attributes returned by posix.getpasswd.
-- @note Available parameters limited when used on Busybox systems such as Alpine Linux.
-- @param login username of the user account [REQUIRED]
-- @param uid uid of the new user account
-- @param gid gid of the new user account
-- @param shell shell of the new user account
-- @param home home directory of the new user account
-- @param create_home whether to create the home directory of not [CHOICES: "yes","no"] [DEFAULT: "yes"]
-- @param description decription field for the new user account
-- @param expire_date the date on which the account will be disabled [FORMAT: YYYY-MM-DD]
-- @param groups supplementary groups for the user account
-- @param user_group whether to create a new group with the same name as the user account [CHOICES: "yes","no"]
-- @usage user.present [[
--   login "ed"
--   uid "666"
--   gid "777"
--   shell "/usr/bin/mksh"
--   groups "kvm"
-- ]]
function user.present (S)
  local G = {
    ok = "user.present: Successfully created user login.",
    skip = "user.present: User login exists.",
    fail = "user.present: Error creating user login.",
    mod_shell = "user.present: Modified shell.",
    mod_home = "user.present: Modified home directory.",
    mod_uid = "user.present: Modified uid.",
    mod_gid = "user.present: Modified gid."
  }
  local M = { "uid", "gid", "shell", "home", "create_home", "description",
              "expire_date", "groups", "user_group", "no_user_group" }
  local F, P, R = main(S, M, G)
  local user = Ppwd.getpwnam(P.login)
  if not (P.shell or P.uid or P.gid or P.home) then
    if user then
      return F.skip(P.login)
    end
  elseif user then
    if P.shell and user.pw_shell ~= P.shell then
      if F.run(Cmd.usermod, { "-s", P.shell, P.login}) then
        F.msg(P.login, G.mod_shell, true, 0, Lc.strf("From: %s To: %s", user.shell, P.shell))
        R.notify = P.notify
        R.repaired = true
        R.changed = true
      end
    end
    if P.uid and Lua.tostring(user.pw_uid) ~= P.uid then
      if F.run(Cmd.usermod, { "-u", P.uid, P.login}) then
        F.msg(P.login, G.mod_uid, true, 0, Lc.strf("From: %s To: %s", user.uid, P.uid))
        R.notify = P.notify
        R.repaired = true
        R.changed = true
      end
    end
    if P.gid and Lua.tostring(user.pw_gid) ~= P.gid then
      if F.run(Cmd.usermod, { "-g", P.gid, P.login }) then
        F.msg(P.login, G.mod_gid, true, 0, Lc.strf("From: %s To: %s", user.gid, P.gid))
        R.notify = P.notify
        R.repaired = true
        R.changed = true
      end
    end
    if P.home and user.dir ~= P.home then
      if F.run(Cmd.usermod, { "-m", "-d", P.home, P.login}) then
        F.msg(P.login, G.mod_home, true, 0, Lc.strf("From: %s To: %s", user.dir, P.home))
        R.notify = P.notify
        R.repaired = true
        R.changed = true
      end
    end
    return R
  end
  local args, ret
  if Px.binpath"useradd" then
    args = { P.login }
    Lc.insertif(P.uid, args, 1, "-u", P.uid)
    Lc.insertif(P.gid, args, 1, "-g", P.gid)
    Lc.insertif(P.shell, args, 1, "-s", P.shell)
    Lc.insertif(P.home, args, 1, "-d", P.home)
    Lc.insertif(P.user_group, 1, "-U")
    Lc.insertif(P.create_home, 1, "-m")
    Lc.insertif(P.description, 1, "-c", P.description)
    Lc.insertif(P.expire_date, 1, "-e", P.expire_date)
    Lc.insertif(P.groups, 1, "-G", P.groups)
    Lc.insertif(P.no_user_group, 1, "-N")
    ret = F.run(Cmd.useradd, args)
  else -- busybox systems such as Alpine Linux
    args = { "-D", P.login }
    Lc.insertif(P.uid, args, 1, "-u" .. P.uid)
    Lc.insertif(P.gid, args, 1, "-g" .. P.gid)
    Lc.insertif(P.shell, args, 1, "-s" .. P.shell)
    Lc.insertif(P.home, args, 1, "-d" .. P.home)
    Lc.insertif(P.user_group, 1, "-U")
    ret = F.run(Cmd.adduser, args)
  end
  return F.result(ret, P.login)
end

--- Remove a system user account.
-- @aliases remove
-- @param remove delete home directory [CHOICES: "yes","no"]
-- @param login username of the user account [REQUIRED]
-- @usage user.absent [[
--   login "ed"
--   remove "yes"
-- ]]
function user.absent (S)
  local M = { "remove" }
  local G = {
    ok = "user.absent: Successfully deleted user login.",
    skip = "user.absent: User login already absent.",
    fail = "user.absent: Error deleting user login"
  }
  local F, P, R = main(S, M, G)
  if not Ppwd.getpwnam(P.login) then
    return F.skip(P.login)
  end
  local ret
  local args = { P.login }
  if Px.binpath"userdel" then
    Lc.insertif(P.remove, args, 1, "-r")
    ret = F.run(Cmd.userdel, args)
  else
    ret = F.run(Cmd.deluser, args)
  end
  return F.result(ret, P.login)
end

user.remove = user.absent
user.add = user.present
return user
