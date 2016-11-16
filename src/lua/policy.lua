local policy = { lua = {} }
policy.lua.init = [[
include"include.lua"
file.touch"test/tmp/core-embedded.txt" {
    mode = "0777"
}
]]
policy.lua.include = [[
file.touch"test/tmp/core-include.txt"()
]]
return policy
