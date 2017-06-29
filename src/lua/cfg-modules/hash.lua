--- Verify the hash of a file
-- @module hash
-- @author Eduardo Tongson <propolice@gmail.com>
-- @license MIT <http://opensource.org/licenses/MIT>
-- @added 2.0.0

local M, hash = {}, {}
local string = string
local file = require "lib".file
local cfg = require "cfg-core.lib"
local bin = require "plc.bin"
local sha2 = require "plc.sha2"
local stat = require "posix.sys.stat"
_ENV = nil

M.required = { "path", "hash" }
M.alias = {}
M.alias.hash = { "digest", "signature" }

--- Check that a given hash value matches the actual hash value of a file.
-- Useful for alerting on changed hashes.
-- @Promiser path of file to hash
-- @Aliases sha256
-- @param hash the alphanumeric string to match for [ALIAS: digest, signature] [REQUIRED]
-- @usage hash.sha2("/etc/passwd"){
--     hash = "09e40b7b232c4abb427f1344e636e44ebf5684f70fb6cd67507e88955064255d"
-- }
function hash.sha2(S)
  M.report = {
    repaired = "hash.sha2: Digests matched.",
    kept = "hash.sha2: Digests matched.",
    failed = "hash.sha2: Mismatched digests.",
    missing = "hash.sha2: Missing path."
  }
  return function(P)
    P.path = S
    local F, R = cfg.init(P, M)
    P.hash = string.lower(P.hash)
    if R.kept then return F.kept(P.path) end
    if not stat.stat(P.path) then
      return F.result(P.path, nil, M.report.missing)
    end
    if P.hash == bin.stohex(sha2.hash256(file.read_to_string(P.path))) then
      return F.kept(P.path)
    else
      return F.result(P.path)
    end
  end
end

hash.sha256 = hash.sha2
return hash
