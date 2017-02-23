--- Verify the SHA256 hash of a file.
-- @module sha256
-- @author Eduardo Tongson <propolice@gmail.com>
-- @license MIT <http://opensource.org/licenses/MIT>
-- @added 0.9.6

local ENV, M, sha256 = {}, {}, {}
local io = io
local cfg = require"cfg-core.lib"
local sha2 = require"sha2"
local stat = require"posix.sys.stat"
local lib = require"lib"
_ENV = ENV

M.required = { "path", "hash" }
M.alias = {}
M.alias.hash = { "digest", "signature" }

--- Check that a given hash matches the actual SHA256 hash of a file.
-- Useful for alerting on changed hashes.
-- @Subject path of file to hash
-- @Aliases check
-- @param hash the 32-byte alphanumeric string to match for [ALIAS: digest,signature] [REQUIRED]
-- @usage sha256.verify("/etc/passwd")
--     hash: "09e40b7b232c4abb427f1344e636e44ebf5684f70fb6cd67507e88955064255d"
function sha256.verify(S)
    M.report = {
        repaired = "sha256.verify: Hash matched.",
            kept = "sha256.verify: Hash matched.",
          failed = "sha256.verify: Hash mismatch.",
         missing = "sha256.verify: Missing path."
    }
    return function(P)
        P.path = S
        local F, R = cfg.init(P, M)
        if not stat.stat(P.path) then
            return F.result(P.path, nil, M.report.missing)
        end
        local S = sha2.new256()
        for f in io.lines(P.path, 2^12) do
            S:add(f)
        end
        if S:close() ==  P.hash then
            return F.kept(P.path)
        else
            return F.result(P.path)
        end
    end
end

sha256.check = sha256.verify
return sha256
