--- Ensure that a user-login is present or absent
-- @module user
-- @author Eduardo Tongson <propolice@gmail.com>
-- @license MIT <http://opensource.org/licenses/MIT>
-- @added 0.9.0

local ENV, M, user = {}, {}, {}
local next, tostring, string = next, tostring, string
local pwd = require"posix.pwd"
local cfg = require"configi"
local lib = require"lib"
local cmd = lib.cmd
_ENV = ENV

M.required = { "login" }
M.alias = {}
M.alias.login = { "username", "user" }

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
-- @usage user.present("ed")
--     uid: "666"
--     gid: "777"
--     shell: "/usr/bin/mksh"
--     groups: "kvm"
function user.present(S)
    M.report = {
         repaired = "user.present: Successfully created user login.",
             kept = "user.present: User login exists.",
           failed = "user.present: Error creating user login.",
        mod_shell = "user.present: Modified shell.",
         mod_home = "user.present: Modified home directory.",
          mod_uid = "user.present: Modified uid.",
          mod_gid = "user.present: Modified gid."
    }
    M.parameters = { "uid", "gid", "shell", "home", "create_home", "description",
              "expire_date", "groups", "user_group", "no_user_group" }
    return function(P)
        P.login = S
        local F, R = cfg.init(P, M)
        local user = pwd.getpwnam(P.login)
        if not (P.shell or P.uid or P.gid or P.home) then
            if user then
                return F.kept(P.login)
            end
        elseif user then
            if P.shell and user.pw_shell ~= P.shell then
                if F.run(cmd.usermod, { "-s", P.shell, P.login}) then
                    F.msg(P.login, G.mod_shell, true, 0, string.format("From: %s To: %s", user.shell, P.shell))
                    R.notify = P.notify
                    R.repaired = true
                end
            end
            if P.uid and tostring(user.pw_uid) ~= P.uid then
                if F.run(cmd.usermod, { "-u", P.uid, P.login}) then
                    F.msg(P.login, G.mod_uid, true, 0, string.format("From: %s To: %s", user.uid, P.uid))
                    R.notify = P.notify
                    R.repaired = true
                end
            end
            if P.gid and tostring(user.pw_gid) ~= P.gid then
                if F.run(cmd.usermod, { "-g", P.gid, P.login }) then
                    F.msg(P.login, G.mod_gid, true, 0, string.format("From: %s To: %s", user.gid, P.gid))
                    R.notify = P.notify
                    R.repaired = true
                end
            end
            if P.home and user.dir ~= P.home then
                if F.run(cmd.usermod, { "-m", "-d", P.home, P.login}) then
                    F.msg(P.login, G.mod_home, true, 0, string.format("From: %s To: %s", user.dir, P.home))
                    R.notify = P.notify
                    R.repaired = true
                end
            end
            return R
        end
        local set, args, ret
        if lib.binpath"useradd" then
            args = { P.login }
            set = {
                   user_group = "-U",
                  create_home = "-m",
                no_user_group = "-N"
            }
            P:insert_if(set, args, 1)
            lib.insert_if(P.uid, args, 1, { "-u ", P.uid })
            lib.insert_if(P.gid, args, 1, { "-g ", P.gid })
            lib.insert_if(P.shell, args, 1, { "-s ", P.shell })
            lib.insert_if(P.home, args, 1, { "-d ", P.home })
            lib.insert_if(P.description, args, 1, { "-c ", P.description })
            lib.insert_if(P.expire_date, args, 1, { "-e ", P.expire_date })
            lib.insert_if(P.groups, args, 1, { "-G ", P.groups })
            ret = F.run(cmd.useradd, args)
        else -- busybox systems such as Alpine Linux
            args = { "-D", P.login }
            lib.insert_if(P.uid, args, 1, { "-u ", P.uid })
            lib.insert_if(P.gid, args, 1, { "-g ", P.gid })
            lib.insert_if(P.shell, args, 1, { "-s ", P.shell })
            lib.insert_if(P.home, args, 1, { "-d ", P.home })
            ret = F.run(cmd.adduser, args)
        end
        return F.result(P.login, ret)
    end
end

--- Remove a system user account.
-- @aliases remove
-- @param remove delete home directory [CHOICES: "yes","no"]
-- @param login username of the user account [REQUIRED]
-- @usage user.absent("ed")
--     remove: "yes"
function user.absent(S)
    M.parameters = { "remove" }
    M.report = {
        repaired = "user.absent: Successfully deleted user login.",
            kept = "user.absent: User login already absent.",
          failed = "user.absent: Error deleting user login"
    }
    return function(P)
        P.login = S
        local F, R = cfg.init(P, M)
        if not pwd.getpwnam(P.login) then
            return F.kept(P.login)
        end
        local ret
        local args = { P.login }
        if lib.binpath"userdel" then
            lib.insert_if(P.remove, args, 1, "-r")
            ret = F.run(cmd.userdel, args)
        else
            ret = F.run(cmd.deluser, args)
        end
        return F.result(P.login, ret)
    end
end

user.remove = user.absent
user.add = user.present
return user
