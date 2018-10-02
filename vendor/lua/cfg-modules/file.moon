require, pairs, tostring = require, pairs, tostring
C = require "configi"
F = {}
{:string, :os, :exec, :file} = require "lib"
stat = require "posix.sys.stat"
Ppwd = require "posix.pwd"
Pgrp = require "posix.grp"
export _ENV = nil
owner = (path) ->
    return C.fail "chown(1) executable not found." if nil == exec.path "chown"
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
            return C.pass! if user == pw_name or user == tostring pw_uid
            return C.equal(0, exec.ctx("chown")(user, path), "Failure running chown(1).")
group = (path) ->
    return C.fail "chgrp(1) executable not found." if nil == exec.path "chgrp"
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
            return C.pass! if grp == gr_name or grp == tostring gr_gid
            return C.equal(0, exec.ctx("chgrp")(grp, path), "Failure running chgrp(1).")
directory = (d) ->
    return C.fail "mkdir(1) executable not found." if nil == exec.path "mkdir"
    C["file.directory :: #{d}"] = ->
        return C.pass! if os.is_dir d
        return C.equal(0, exec.ctx("mkdir")("-p", d), "Failure creating directory #{d}.")
absent = (f) ->
    return C.fail "rm(1) executable not found." if nil == exec.path "rm"
    C["file.absent :: #{f}"] = ->
        return C.pass! if nil == stat.stat f
        return C.equal(0, exec.ctx("rm")("-r", "-f", f), "Failure deleting #{f}.")
managed = (f) ->
    m = require "files.#{f}"
    return C.fail "Source not found." if nil == m
    for k, v in pairs m
        C["file.managed :: #{k}: #{v.path}"] = ->
            contents = file.read_to_string v.path
            return C.pass! if contents == v.contents
            return C.equal(true, file.write(v.path, v.contents), "Failure writing contents to #{v.path}.")
templated = (f) ->
    m = require "files.#{f}"
    return C.fail "Source not found." if nil == m
    return (p) ->
        for k, v in pairs m
            C["file.templated :: #{k}: #{v.path}"] = ->
                payload = string.template(v.contents, p)
                return C.pass! if file.read_to_string(v.path) == payload
                return C.equal(true, file.write(v.path, payload), "Failure writing contents to #{v.path}.")
chmod = (f) ->
    return C.fail "chmod(1) executable not found" if nil == exec.path "chmod"
    return (p) ->
        mode_arg = tostring p.mode
        info = stat.stat f
        len = 0 - string.len mode_arg
        current_mode = string.sub(tostring(string.format("%o", info.st_mode)), len, -1)
        C["file.mode :: #{f}: #{current_mode} -> #{mode_arg}"] = ->
            return C.pass! if current_mode == string.sub(mode_arg, len, -1)
            return C.equal(0, exec.ctx("chmod")(mode_arg, f), "Failure running chmod(1) on #{f}.")
copy = (f) ->
    return C.fail "cp(1) executable not found" if nil == exec.path "cp"
    return (p) ->
        destination = p.target
        force = p.force or p.overwrite
        C["file.copy :: #{f} -> #{destination}"] = ->
            return C.pass! if file.stat destination and not force
            if nil == file.stat destination or force
                return C.equal(0, exec.ctx("cp")("-R", "-f", f, destination), "Failure copying #{f} to #{destination}.")
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
