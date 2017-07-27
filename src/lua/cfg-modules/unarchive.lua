--- Unpack an archive.
-- @module unarchive
-- @author Eduardo Tongson <propolice@gmail.com>
-- @license MIT <http://opensource.org/licenses/MIT>
-- @added 0.9.0

local M, unarchive = {}, {}
local string = string
local cfg = require"cfg-core.lib"
local lib = require"lib"
local cmd = lib.exec.cmd
_ENV = nil

M.required = { "src", "dest" }
M.alias = {}
M.alias.dest = { "directory" }

local extension = function(filename)
  local ext = string.sub(string.lower(filename), -7)
  if ext == ".tar.xz" or
    ext == ".tar.gz" or
    ext == ".tar.lz" or
    ext == "tar.bz2" or
    ext == "tar.lzo" or
    ext == "tar.lz4" or
    ext == "ar.lzma" then
    ext = "tar"
  else
    ext = string.sub(string.lower(filename), -3)
  end
  return ext
end

--- Unpack a tar, zip or rar archive.
-- @Promiser path of archive
-- @Aliases untar
-- @Aliases unzip
-- @Aliases unrar
-- @Note detects archive type using the 3 letter filename extension e.g. tar, zip, rar
-- @param dest path where the archive should unpacked [REQUIRED] [ALIAS: directory]
-- @param creates path to a file, if already existing will skip the unpacking step
-- @usage unarchive.unpack("/tmp/file.tar"){
--   dest = "/tmp/test"
--   creates = "/tmp/test/file.1"
-- }
function unarchive.unpack(S)
  M.report = {
    repaired = "unarchive.unpack: Successfully unpacked archive.",
    kept = "unarchive.unpack: Archive already unpacked.",
    failed = "unarchive.unpack: Error unpacking archive.",
  }
  return function(P)
    P.src = S
    local F, R = cfg.init(P, M)
    -- Use built-in P.creates test in cfg.init()
    if R.kept then
      return F.kept(P.src)
    end
    local code
    if extension(P.src) == "tar" then
      code = F.run(cmd.tar, { "-x", "-C", P.dest, "-f", P.src })
    elseif extension(P.src) == "zip" then
      code = F.run(cmd.unzip, { "-qq", P.src, "-d", P.dest })
    elseif extension(P.src) == "rar" then
      code = F.run(cmd.unrar, { "x", P.src, "-inul", P.dest })
    end
    return F.result(P.src, (code == 0))
  end
end

unarchive.unzip = unarchive.unpack
unarchive.unrar = unarchive.unpack
unarchive.untar = unarchive.unpack
return unarchive
