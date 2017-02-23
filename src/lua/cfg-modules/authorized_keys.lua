--- Ensure that an SSH key is present or absent in a specified user's authorized_keys file.
-- @module authorized_keys
-- @author Eduardo Tongson <propolice@gmail.com>
-- @license MIT <http://opensource.org/licenses/MIT>
-- @added 0.9.0

local ENV, M, authorized_keys = {}, {}, {}
local ipairs, string, table = ipairs, string, table
local cfg = require"cfg-core.lib"
local stat = require"posix.sys.stat"
local pwd = require"posix.pwd"
local factid = require"factid"
local lib = require"lib"
local fact = {}
_ENV = ENV

fact.osfamily = factid.osfamily()

M.required = { "type", "key" }
M.alias = {}
M.alias.user = { "login" }

local keyfile = function(P)
    local user, file, dir
    P:set_if_not("user", lib.ename())
    if fact.osfamily == "openwrt" then
        file = "/etc/dropbear/authorized_keys"
        dir = "/etc/dropbear"
    else
        user = pwd.getpwnam(P.user)
        if not user then
            return nil, "Couldn't find user: " .. P.user
        end
        file = user.pw_dir .. "/.ssh/authorized_keys"
        dir = user.pw_dir .. "/.ssh"
    end
    local ret = stat.stat(file)
    if ret then
        return file
    elseif not ret and (P.create == false) then -- `create "yes"` is default
        return nil, "File: " .. file .. " exists and create is false"
    end
    if not stat.stat(dir) then
        if not stat.mkdir(dir, 496) then
            return nil, "Couldn't stat or create parent directory: " .. dir
        end
    end
    if lib.fwrite(file, "") then
        return file
    else
        return nil, "Couldn't write to file: " .. file
    end
end

local found = function(P)
    local file = keyfile(P)
    file = lib.file_to_tbl(file)
    local id = P.id or ""
    local line
    if P.options then
        line = string.format("%s %s %s %s", P.options, P["type"], P.key, id)
    else
        line = string.format("%s %s %s", P["type"], P.key, id)
    end
    if lib.find_string(file, line, true) then
        return true
    end
end

--- Add key to a user's authorized_keys file.
-- <br />
-- All matching base64 encoded keys are removed first before adding the specificied key.
-- See the AUTHORIZED_KEYS FILE FORMAT section in sshd(8)
-- @Subject base64 encoded key
-- @Note this note
-- @param user user to operate on [ALIAS: login] [DEFAULT: Effective user ID]
-- @param id a string usually used to comment or identify a key
-- @param type SSH key type [REQUIRED]
-- @param options a comma-separated options specifications
-- @param create create ~/.ssh directory or not [DEFAULT: "yes", true]
-- @usage authorized_keys.present("AAAAA....")
--     options: "yaaaya"
--     user: "ed"
--     id: "etongson"
--     type: "ssh-rsa"
--     create: false
function authorized_keys.present(S)
    M.parameters = { "user", "options", "id", "create" }
    M.report = {
            repaired = "authorized_keys.present: Key successfully added.",
                kept = "authorized_keys.present: Key already present.",
              failed = "authorized_keys.present: Error adding key.",
    }
    return function(P)
        if fact.osfamily == "openwrt" then
            P.type = "ssh-dss"
        end
        P.key = S
        local F, R = cfg.init(P, M)
        local item = P["type"]  .. " key"
        if P.create == nil then
            P.create = true -- default: create "yes"
        end
        local file, err = keyfile(P)
        if not file then
            F.msg("authorized_keys file", "authorized_keys.present: " .. err)
            return F.result(item)
        end
        if found(P) then
            return F.kept(item)
        end
        -- first remove any matching key
        local tfile = lib.filter_tbl_value(lib.file_to_tbl(file), P.key, true)
        local id = P.id or ""
        if P.options then
            tfile[#tfile + 1] = string.format("%s %s %s %s", P.options, P["type"], P.key, id)
        else
            tfile[#tfile + 1] = string.format("%s %s %s", P["type"], P.key, id)
        end
        tfile[#tfile] = tfile[#tfile] .. "\n"
        return F.result(item, F.run(lib.awrite, file, table.concat(tfile), 384))
    end
end

--- Remove key from a user's authorized_keys file.
-- @Subject base64 encoded key
-- @param user user to operate on
-- [ALIAS: login] [DEFAULT: Effective user ID]
-- @param type SSH key type
-- @usage authorized_keys.absent"AAAAA..."
--     user: "ed"
--     type: "ssh-rsa"
function authorized_keys.absent(S)
    M.parameters =  { "user", "options", "id", "create" } -- make it easier to toggle a key
    M.report = {
        repaired = "authorized_keys.absent: Key successfully removed.",
            kept = "authorized_keys.absent: Key already absent.",
          failed = "authorized_keys.absent: Error removing key."
    }
    return function(P)
        if fact.osfamily == "openwrt" then
            P.type = "ssh-dss"
        end
        P.key = S
        local F, R = cfg.init(P, M)
        local item = P["type"]  .. " key"
        P.create = false
        local file = keyfile(P)
        if not file or not found(P) then
            return F.kept(item)
        end
        local tfile = lib.filter_tbl_value(lib.file_to_tbl(file), P.key, true)
        return F.result(item, F.run(lib.awrite, file, table.concat(tfile), 384))
    end
end

return authorized_keys
