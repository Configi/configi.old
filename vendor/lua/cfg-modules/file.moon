-- Author: Eduardo Tongson <propolice@gmail.com>
-- License: MIT <http://opensource.org/licenses/MIT>
require, pairs, tostring = require, pairs, tostring
C = require "configi"
F = {}
{:string, :os, :exec, :file} = require "lib"
stat = require "posix.sys.stat"
Ppwd = require "posix.pwd"
Pgrp = require "posix.grp"
export _ENV = nil
----
--  ### file.owner
--
--  Ensure the owner attribute of a path is the specified user or uid.
--  Wraps the chown(1) command or program.
--
--  #### Arguments:
--      (string) = Complete path of file.
--
--  #### Parameters:
--      (table)
--          user = owner or uid (string/number)
--
--  #### Results:
--      Repaired = Successfully changed owner attribute to the correct user.
--      Fail     = Error encountered when running chown(1) against the path.
--      Pass     = The owner attribute of the path is already the expected user.
--
--  #### Examples:
--  ```
--  file.owner("/etc/passwd"){
--    user = "root"
--  }
--  ```
----
owner = (path) ->
    return (p) ->
        user = tostring p.user
        info = stat.stat path
        uid = tostring info.st_uid
        pw_uid = tostring info.st_uid
        pw_name = tostring info.st_uid
        if u = Ppwd.getpwuid info.st_uid
            uid = string.format("%s(%s)", u.pw_uid, u.pw_name)
            pw_uid = u.pw_uid
            pw_name = u.pw_name
        C["file.owner :: #{path} #{uid} -> #{user}"] = ->
            return C.fail "chown(1) executable not found." if nil == exec.path "chown"
            return C.pass! if user == pw_name or user == tostring pw_uid
            C.equal(0, exec.ctx("chown")(user, path), "Failure running chown(1).")
----
--  ### file.group
--
--  Ensure the group attribute of a path is the specified group or gid.
--  Wraps the chgrp(1) command or program.
--
--  #### Arguments:
--      (string) = Complete path of file.
--
--  #### Parameters:
--      (table)
--          group = group or gid (string/number)
--
--  #### Results:
--      Repaired = Successfully changed group attribute to the correct group.
--      Fail     = Error encountered when running chgrp(1) against the path.
--      Pass     = The group attribute of the path is already the expected group.
--
--  #### Examples:
--  ```
--  file.group("/etc/passwd"){
--    group = "root"
--  }
--  ```
----
group = (path) ->
    return (p) ->
        grp = tostring p.group
        info = stat.stat path
        cg = tostring info.st_gid
        gr_gid = tostring info.st_gid
        gr_name = tostring info.st_gid
        if g = Pgrp.getgrgid info.st_gid
            cg = string.format("%s(%s)", g.gr_gid, g.gr_name)
            gr_gid = g.gr_gid
            gr_name = g.gr_name
        C["file.group :: #{path} #{cg} -> #{grp}"] = ->
            return C.fail "chgrp(1) executable not found." if nil == exec.path "chgrp"
            return C.pass! if grp == gr_name or grp == tostring gr_gid
            C.equal(0, exec.ctx("chgrp")(grp, path), "Failure running chgrp(1).")
----
--  ### file.directory
--
--  Ensure the specified directory is present.
--  Wraps the mkdir(1) command or program.
--
--  #### Arguments:
--      (string) = Complete path of directory.
--
--  #### Results:
--      Repaired = Successfully created directory.
--      Fail     = Error encountered when running mkdir(1).
--      Pass     = Directory already present.
--
--  #### Examples:
--  ```
--  file.directory("/srv/configi")
--  ```
----
directory = (d) ->
    C["file.directory :: #{d}"] = ->
        return C.fail "mkdir(1) executable not found." if nil == exec.path "mkdir"
        return C.pass! if os.is_dir d
        C.equal(0, exec.ctx("mkdir")("-p", d), "Failure creating directory #{d}.")
----
--  ### file.absent
--
--  Ensure the specified path is absent.
--  Wraps the rm(1) command or program.
--
--  #### Arguments:
--      (string) = Path to remove.
--
--  #### Results:
--      Repaired = Successfully removed path.
--      Fail     = Error encountered when running rm(1).
--      Pass     = Path already absent.
--
--  #### Examples:
--  ```
--  file.absent("/srv/configi")
--  ```
----
absent = (f) ->
    C["file.absent :: #{f}"] = ->
        return C.fail "rm(1) executable not found." if nil == exec.path "rm"
        return C.pass! if nil == stat.stat f
        C.equal(0, exec.ctx("rm")("-r", "-f", f), "Failure deleting #{f}.")
----
--  ### file.managed
--
--  Manage a specified file's contents.
--
--  #### Arguments:
--      (string) = Name of key to load from the files module hierarchy.
--
--  #### Results:
--      Repaired = Successfully written file.
--      Fail     = Error encountered when writing file.
--      Pass     = File already has expected contents.
--
--  #### Examples:
--  ```
--  file.managed("testing")
--  ```
----
managed = (f) ->
    m = require "files.#{f}"
    for k, v in pairs m
        C["file.managed :: #{k}: #{v.path}"] = ->
            return C.fail "Source not found." if nil == m
            contents = file.read v.path
            return C.pass! if contents == v.contents
            C.is_true(file.write(v.path, v.contents), "Failure writing contents to #{v.path}.")
----
--  ### file.templated
--
--  Manage a specified file's contents through a template.
--
--  #### Arguments:
--      (string) = Name of key to load from the files module hierarchy.
--
--  #### Parameters:
--      (table) = Key-value pairs to interpolate from the file.
--
--  #### Results:
--      Repaired = Successfully written file.
--      Fail     = Error encountered when writing file.
--      Pass     = File already has expected contents.
--
--  #### Examples:
--  ```
--  file.templated("testing"){
--    user = "tongson",
--    uid = "11111"
--  }
--  ```
----
templated = (f) ->
    m = require "files.#{f}"
    return (p) ->
        for k, v in pairs m
            C["file.templated :: #{k}: #{v.path}"] = ->
                return C.fail "Source not found." if nil == m
                payload = string.template(v.contents, p)
                return C.pass! if payload == file.read v.path
                C.is_true(file.write(v.path, payload), "Failure writing contents to #{v.path}.")
----
--  ### file.chmod
--
--  Wraps the chmod(1) command or program.
--
--  #### Arguments:
--      (string) = Complete path of file.
--
--  #### Parameters:
--      (table)
--          mode = mode
--
--  #### Results:
--      Repaired = Successfully changed owner attribute to the correct user.
--      Fail     = Error encountered when running chown(1) against the path.
--      Pass     = The owner attribute of the path is already the expected user.
--
--  #### Examples:
--  ```
--  file.chmod("/etc/passwd"){
--    mode = "0660"
--  }
--  ```
----
chmod = (f) ->
    return (p) ->
        mode_arg = tostring p.mode
        info = stat.stat f
        len = 0 - string.len mode_arg
        current_mode = string.sub(tostring(string.format("%o", info.st_mode)), len, -1)
        C["file.mode :: #{f}: #{current_mode} -> #{mode_arg}"] = ->
            return C.fail "chmod(1) executable not found" if nil == exec.path "chmod"
            return C.pass! if current_mode == string.sub(mode_arg, len, -1)
            C.equal(0, exec.ctx("chmod")(mode_arg, f), "Failure running chmod(1) on #{f}.")
----
--  ### file.copy
--
--  Copy a file to the specified destination
--  Wraps the cp(1) command or program.
--
--  #### Arguments:
--      (string) = Complete path of file.
--
--  #### Parameters:
--      (table)
--          target = path to copy file into
--          force  = overwrite destination
--
--  #### Results:
--      Repaired = Successfully copied source file into destination.
--      Fail     = Error encountered when running cp(1).
--      Pass     = Destination path already present.
--
--  #### Examples:
--  ```
--  file.copy("/etc/passwd"){
--    target = "/root/backup"
--    force = true
--  }
--  ```
----
copy = (f) ->
    return (p) ->
        destination = p.target
        force = p.force or p.overwrite
        C["file.copy :: #{f} -> #{destination}"] = ->
            return C.fail "cp(1) executable not found" if nil == exec.path "cp"
            return C.pass! if file.stat destination and not force
            if nil == file.stat destination or force
                C.equal(0, exec.ctx("cp")("-R", "-f", f, destination), "Failure copying #{f} to #{destination}.")
F["directory"] = directory
F["absent"] = absent
F["managed"] = managed
F["templated"] = templated
F["owner"] = owner
F["chown"] = owner
F["group"] = group
F["chgrp"] = group
F["chmod"] = chmod
F["access"] = chmod
F["copy"] = copy
F
