C = require "configi"
tostring = tostring
{:file} = require "lib"
bin = require "plc.bin"
shasum = require "plc.sha2"
H = {}
export _ENV = nil
-- Author: Eduardo Tongson <propolice@gmail.com>
-- License: MIT <http://opensource.org/licenses/MIT>
--
-- hash.sha2
--
-- Check that a given sha256 hash value matches the actual hash value of a file.
-- Useful for alerting on changed hashes.
--
-- Argument:
--     (string) = The path of the file.
--
-- Parameters:
--     (table)
--         digest = The expected hash digest of the specified file.
--
-- Results:
--     Pass = Hash digest matched.
--     Fail = Hash digest did not match.
--
-- Examples:
--     hash.sha2("/usr/local/bin/woah"){
--        digest =
--     }
sha2 = (path) ->
    return (p) ->
        digest = p.digest
        C["hash.sha2 :: #{path}: #{digest}"] = ->
            unless file.stat(path) == nil
                hash256 = bin.stohex(shasum.hash256(file.read_to_string(path)))
                if digest == hash256
                    C.pass!
                else
                    C.fail "Unexpected hash digest: #{hash256} for #{path}."
            else
                C.fail "File (#{path}) not found."
H["sha2"] = sha2
H
