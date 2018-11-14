-- Author: Eduardo Tongson <propolice@gmail.com>
-- License: MIT <http://opensource.org/licenses/MIT>
C = require "configi"
tostring = tostring
{:file} = require "lib"
bin = require "plc.bin"
shasum = require "plc.sha2"
H = {}
export _ENV = nil
----
--  ### hash.sha2
--
--  Ensure that a given sha256 hash value matches the actual hash value of the specified file.
--  Useful for alerting on changed hashes.
--
--  #### Argument:
--      (string) = The path of the file.
--
--  #### Parameters:
--      (table)
--          digest = The expected hash digest of the specified file (string)
--
--  #### Results:
--      Pass = Hash digest matched.
--      Fail = Hash digest did not match.
--
--  #### Examples:
--  ```
--  hash.sha2("/usr/local/bin/woah"){
--    digest =
--  }
--  ```
----
sha2 = (path) ->
    return (p) ->
        digest = p.digest
        C["hash.sha2 :: #{path}: #{digest}"] = ->
            return C.fail "File (#{path}) not found." if not file.stat path
            hash256 = bin.stohex(shasum.hash256(file.read(path)))
            if digest == hash256
                return C.pass!
            else
                return C.fail "Unexpected hash digest: #{hash256} for #{path}."
H["sha2"] = sha2
H
