--- File operations.
-- @module file
-- @author Eduardo Tongson <propolice@gmail.com>
-- @license MIT <http://opensource.org/licenses/MIT>
-- @added 0.9.0

local ENV, M, file = {}, {}, {}
local tostring, os, string = tostring, os, string
local cfg = require"cfg-core.lib"
local lib = require"lib"
local cmd = lib.cmd
local stat = require"posix.sys.stat"
local unistd = require"posix.unistd"
local pwd = require"posix.pwd"
local grp = require"posix.grp"
_ENV = ENV

M.required = { "path" }
M.alias = {}
M.alias.path = { "name", "link", "dest", "target" }
M.alias.src = { "source" }
M.alias.owner = { "uid" }
M.alias.group = { "gid" }

local owner = function(F, P)
    local report = {
        file_owner_ok = "file.owner: Owner/uid corrected.",
        file_owner_skip = "file.owner: Owner/uid already matches ",
        file_owner_fail = "file.owner: Error setting owner/uid."
    }
    local info = stat.stat(P.path)
    local u = pwd.getpwuid(info.st_uid)
    local uid = string.format("%s(%s)", u.pw_uid, u.pw_name)
    if P.owner == u.pw_name or P.owner == tostring(u.pw_uid) then
        return F.result(P.path, false, report.file_owner_skip .. uid .. ".")
    end
    local args = { "-h", P.owner, P.path }
    lib.insert_if(P.recurse, args, 2, "-R")
    if F.run(cmd.chown, args) then
        return F.result(P.path, true, report.file_owner_ok)
    else
        return F.result(P.path, nil, report.file_owner_fail)
    end
end

local group = function(F, P)
    local report = {
        file_group_ok = "file.group: Group/gid corrected.",
        file_group_skip = "file.group: Group/gid already matches ",
        file_group_fail = "file.group: Error setting group/gid."
    }
    local info = stat.stat(P.path)
    local g = grp.getgrgid(info.st_gid)
    local cg = string.format("%s(%s)", g.gr_gid, g.gr_name)
    if P.group == g.gr_name or P.group == tostring(g.gr_gid) then
        return F.result(P.path, false, report.file_group_skip .. cg .. ".")
    end
    local args = { "-h", ":" .. P.group, P.path }
    lib.insert_if(P.recurse, args, 2, "-R")
    if F.run(cmd.chown, args) then
        return F.result(P.path, true, report.file_group_ok)
    else
        return F.result(P.path, nil, report.file_group_fail)
    end
end

local mode = function(F, P)
    local report = {
        file_mode_ok = "file.mode: Mode corrected.",
        file_mode_skip = "file.mode: Mode matched.",
        file_mode_fail = "file.mode: Error setting mode."
    }
    local info = stat.stat(P.path)
    local mode = tostring(P.mode)
    local len = 0 - string.len(mode)
    local current_mode = string.sub(tostring(string.format("%o", info.st_mode)), len, -1)
    if current_mode == string.sub(mode, len, -1) then
        return F.result(P.path, false, report.file_mode_skip)
    end
    local args = { P.mode, P.path }
    lib.insert_if(P.recurse, args, 1, "-R")
    if F.run(cmd.chmod, args) then
        return F.result(P.path, true, report.file_mode_ok)
    else
        return F.result(P.path, nil, report.file_mode_fail)
    end
end

local attrib = function(F, P, R)
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
-- @Subject path to file
-- @param mode set the file mode bits
-- @param owner set the uid/owner [ALIAS: uid]
-- @param group set the gid/group [ALIAS: gid]
-- @usage file.attributes("/etc/shadow")
--     mode: "0600"
--     owner: "root"
--     group: "root"
function file.attributes(S)
    M.parameters = { "mode", "owner", "group" }
    return function(P)
        P.path = S
        local F, R = cfg.init(P, M)
        if R.kept then
            return F.kept(P.path)
        end
        if not P.test and not stat.stat(P.path) then
            return F.result(P.path, nil, "Missing path.")
        end
        return attrib(F, P, R)
    end
end

--- Create a symlink.
-- @Subject symlink path
-- @param src path where the symlink points to [REQUIRED]
-- @param force remove existing symlink
-- @usage file.link("/home/ed/root")
--     src: "/"
function file.link(S)
    M.parameters = { "src", "force", "owner", "group", "mode" }
    M.report = {
        repaired = "file.link: Symlink created.",
            kept = "file.link: Already a symlink.",
          failed = "file.link: Error creating symlink."
    }
    return function(P)
        P.path = S
        local F, R = cfg.init(P, M)
        if R.kept then
            return F.kept(P.path)
        end
        local symlink = unistd.readlink(P.path)
        if symlink == P.src then
            F.msg(P.src, M.report.kept, nil)
            return attrib(F, P, R)
        end
        local args = { "-s", P.src, P.path }
        lib.insert_if(P.force, args, 2, "-f")
        if F.run(cmd.ln, args) then
            F.msg(P.path, M.report.repaired, true)
            return attrib(F, P, R)
        else
            return F.result(P.path)
        end
    end
end

--- Create a hard link.
-- @Subject hard link path
-- @param src path where the hard link points to [REQUIRED]
-- @param force remove existing hard link
-- @usage file.hard("/home/ed/root")
--     src: "/"
function file.hard(S)
    M.parameters = { "src", "force", "owner", "group", "mode" }
    M.report = {
        repaired = "file.hard: Hardlink created.",
            kept = "file.hard: Already a hardlink.",
          failed = "file.hard: Error creating hardlink."
    }
    return function(P)
        P.path = S
        local F, R = cfg.init(P, M)
        if R.kept then
            return F.kept(P.path)
        end
        local source = stat.stat(P.src)
        local link = stat.stat(P.path) or nil
        if not source then
            return F.result(P.path, nil, string.format(" '%s' is missing", source))
        end
        if source and link and (source.st_ino == link.st_ino) then
            F.msg(P.path, M.report.kept, nil)
            return attrib(F, P, R)
        end
        local args = { P.src, P.path }
        lib.insert_if(P.force, args, 1, "-f")
        if F.run(cmd.ln, args) then
            F.msg(P.path, M.report.repaired, true)
            return attrib(F, P, R)
        else
            return F.result(P.path)
        end
    end
end

--- Create a directory.
-- @Subject directory path
-- @param mode set the file mode bits
-- @param owner set the uid/owner [ALIAS: uid]
-- @param group set the gid/group [ALIAS: gid]
-- @param force remove existing path before creating directory [DEFAULT: "no"]
-- @param backup rename existing path and prepend '._configi_' to the name [DEFAULT: "no"]
-- @usage file.directory("/usr/portage")!
function file.directory(S)
    M.parameters = { "mode", "owner", "group", "force", "backup" }
    M.report = {
        repaired = "file.directory: Directory created.",
            kept = "file.directory: Already a directory.",
          failed = "file.directory: Error creating directory."
    }
    return function(P)
        P.path = S
        local F, R = cfg.init(P, M)
        if R.kept then
            return F.kept(P.path)
        end
        local info = stat.stat(P.path)
        if info and (stat.S_ISDIR(info.st_mode) ~= 0 )then
            F.msg(P.path, M.report.kept, nil)
            return attrib(F, P, R)
        end
        if P.force then
            if P.backup then
                local dir, path = lib.split_path(P.path)
                F.run(os.rename, P.path, dir .. "/._configi_" .. path)
            end
            F.run(cmd.rm, { "-r", "-f", P.path })
        end
        if F.run(cmd.mkdir, { "-p", P.path }) then
            F.msg(P.path, M.report.repaired, true)
            return attrib(F, P, R)
        else
            return F.result(P.path)
        end
    end
end

--- Touch a path.
-- @Subject path
-- @param mode set the file mode bits
-- @param owner set the uid/owner [ALIAS: uid]
-- @param group set the gid/group [ALIAS: gid]
-- @usage file.touch("/srv/.keep")!
function file.touch(S)
    M.parameters = { "mode", "owner", "group" }
    M.report = {
        repaired = "file.touch: touch(1) succeeded.",
          failed = "file.touch: touch(1) failed."
    }
    return function(P)
        P.path = S
        local F, R = cfg.init(P, M)
        if R.kept then
            return F.kept(P.path)
        end
        if F.run(cmd.touch, { P.path }) then
            F.msg(P.path, M.report.repaired, true)
            return attrib(F, P, R)
        else
            return F.result(P.path)
        end
    end
end

--- Remove a path.
-- @Subject path
-- @usage file.absent("/home/ed/.xinitrc")!
function file.absent(S)
    M.report = {
        repaired = "file.absent: Successfully removed.",
            kept = "file.absent: Already absent.",
          failed = "file.absent: Error removing path.",
    }
    return function(P)
        P.path = S
        local F, R = cfg.init(P, M)
        if R.kept or not stat.stat(P.path) then
            return F.kept(P.path)
        end
        return F.result(P.path, F.run(cmd.rm, { "-r", "-f", P.path }))
    end
end

--- Copy a path.
-- @Subject path
-- @param path destination path [REQUIRED] [ALIAS: dest,target]
-- @param recurse recursively copy source [DEFAULT: "no"]
-- @param force remove existing destination before copying [DEFAULT: "no"]
-- @param backup rename existing path and prepend '._configi_' to the name [DEFAULT: "no"]
-- @usage file.copy("/home/ed")
--     dest: "/mnt/backups"
function file.copy(S)
    M.parameters = { "src", "path", "recurse", "force", "backup" }
    M.report = {
        repaired = "file.copy: Copy succeeded.",
            kept = "file.copy: Not copying over destination.",
          failed = "file.copy: Error copying."
    }
    return function(P)
        P.src = S
        local F, R = cfg.init(P, M)
        if R.kept then
            return F.kept(P.path)
        end
        local dir, path = lib.split_path(P.path)
        local backup = dir .. "/._configi_" .. path
        local present = stat.stat(P.path)
        if present and P.backup and (not stat.stat(backup)) then
            if not F.run(cmd.mv, { P.path, backup }) then
                return F.result(P.path)
            end
        elseif not P.force and present then
            return F.kept(P.path)
        end
        local args = { "-P", P.src, P.path }
        lib.insert_if(P.recurse, args, 2, "-R")
        lib.insert_if(P.force, args, 2, "-f")
        if F.run(cmd.cp, args) then
            return F.result(P.path, true)
        else
            F.run(cmd.rm, { "-r", "-f", P.path }) -- clean up incomplete copy
            return F.result(P.path)
        end
    end
end

return file

