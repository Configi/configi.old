--- Ensure that an SSH key is present or absent in a specified user's authorized_keys file.
-- @module authorized_keys
-- @author Eduardo Tongson <propolice@gmail.com>
-- @license MIT <http://opensource.org/licenses/MIT>
-- @added 0.9.0

local Lua = {
  ipairs = ipairs,
  format = string.format,
  concat = table.concat
}
local Func = {}
local Var = {}
local Configi = require"configi"
local Lc = require"cimicida"
local Pstat = require"posix.sys.stat"
local Ppwd = require"posix.pwd"
local Factid = require"factid"
local Px = require"px"
local authorized_keys = {}
local ENV = {}
_ENV = ENV

Var.osfamily = Factid.osfamily()

local main = function (S, M, G)
  if Var.osfamily == "openwrt" then
    S = Lc.appendln(S, [[type "ssh-dss"]])
  end
  local C = Configi.start(S, M, G)
  C.required = { "type", "key" }
  C.alias.user = { "login" }
  return Configi.finish(C)
end

Func.keyfile = function (P)
  local user, file, dir
  if P.user == nil then
    P.user = Px.getename()
  end
  if Var.osfamily == "openwrt" then
    file = "/etc/dropbear/authorized_keys"
    dir = "/etc/dropbear"
  else
    user = Ppwd.getpwnam(P.user)
    file = user.pw_dir .. "/.ssh/authorized_keys"
    dir = user.pw_dir .. "/.ssh"
  end
  local stat = Pstat.stat(file)
  if stat then
    return file
  elseif not stat and (P.create == false) then -- `create "yes"` is default
    return nil
  end
  if not Pstat.stat(dir) then
    if Pstat.mkdir(dir, 496) and Lc.fwrite(file, "") then
      return file
    end
  elseif Lc.fwrite(file, "") then
    return file
  end
end

Func.found = function (P)
  local file = Func.keyfile(P)
  file = Lc.file2tbl(file)
  local id = P.id or ""
  local line
  if P.options then
    line = Lua.format("%s %s %s %s", P.options, P["type"], P.key, id)
  else
    line = Lua.format("%s %s %s", P["type"], P.key, id)
  end
  if Lc.tfind(file, line, true) then
    return true
  end
end

--- Add key to a user's authorized_keys file.
-- <br />
-- All matching base64 encoded keys are removed first before adding the specificied key.
-- See the AUTHORIZED_KEYS FILE FORMAT section in sshd(8)
-- @param user user to operate on [ALIAS: login] [DEFAULT: Effective user ID]
-- @param type SSH key type [REQUIRED]
-- @param key the actual base64 encoded key [REQUIRED]
-- @param options a comma-separated options specifications
-- @param id a string usually used to comment or identify a key
-- @param create ~/.ssh directory or not [CHOICES: "yes","no"] [DEFAULT: "yes"]
-- @usage authorized_keys.present [[
--   options "yaaaya"
--   user "ed"
--   type "ssh-rsa"
--   key "AAAA......"
--   id "etongson"
--   create "no"
-- ]]
function authorized_keys.present (S)
  local M =  { "user", "options", "id", "create" }
  local G = {
    repaired = "authorized_keys.present: Key successfully added.",
    kept = "authorized_keys.present: Key already present.",
    failed = "authorized_keys.present: Error adding key.",
    missing_fail = "authorized_keys.present: authorized_keys file missing."
  }
  local F, P, R = main(S, M, G)
  local item = P["type"]  .. " key"
  if P.create == nil then
    P.create = true -- default: create "yes"
  end
  local file = Func.keyfile(P)
  if not file then
    F.msg("authorized_keys file", G.missing_fail, false)
    return F.result(item, false)
  end
  if Func.found(P) then
    return F.kept(item)
  end
  -- first remove any matching key
  local tfile = Lc.filtertval(Lc.file2tbl(file), P.key, true)
  local id = P.id or ""
  if P.options then
    tfile[#tfile + 1] = Lua.format("%s %s %s %s", P.options, P["type"], P.key, id)
  else
    tfile[#tfile + 1] = Lua.format("%s %s %s", P["type"], P.key, id)
  end
  tfile[#tfile] = tfile[#tfile] .. "\n"
  return F.result(item, F.run(Px.awrite, file, Lua.concat(tfile), 384))
end

--- Remove key from a user's authorized_keys file.
-- @param user user to operate on
-- [ALIAS: login] [DEFAULT: Effective user ID]
-- @param type SSH key type
-- [REQUIRED]
-- @param key the actual base64 encoded key
-- [REQUIRED]
-- @usage authorized_keys.absent [[
--   user "ed"
--   type "ssh-rsa"
--   key "AAAAAA......"
-- ]]
function authorized_keys.absent (S)
  local M =  { "user", "options", "id", "create" } -- make it easier to toggle a key
  local G = {
    repaired = "authorized_keys.absent: Key successfully removed.",
    kept = "authorized_keys.absent: Key already absent.",
    failed = "authorized_keys.absent: Error removing key."
  }
  local F, P, R = main(S, M, G)
  local item = P["type"]  .. " key"
  P.create = "no"
  local file = Func.keyfile(P)
  if not file or not Func.found(P) then
    return F.kept(item)
  end
  local tfile = Lc.filtertval(Lc.file2tbl(file), P.key, true)
  return F.result(item, F.run(Px.awrite, file, Lua.concat(tfile), 384))
end

return authorized_keys

