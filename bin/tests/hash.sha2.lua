local hash = require "cfg-modules.hash"
local C = require "u-cfg"
_ENV = nil
hash.sha2("tmp/____configi_test_hash_sha2"){
  digest = "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855"
}
C.summary()
