local policy = {["."]={},attributes={},policies={},handlers={}}
policy.attributes.test = [[
 file="test"
]]
policy.policies.test = [[
file.touch"test/tmp/core-embedded-structure"{
    comment = _"{{file}} policies",
    notify = "embedded"
}
]]
policy.handlers.test = [[
file.touch"test/tmp/core-embedded-handlers"{
    comment = _"{{file}} handlers",
    handle = "embedded"
]]
policy["."]["init"] = [[
include"include.lua"
file.touch"test/tmp/core-embedded.txt" {
    mode = "0777"
}
]]
policy["."]["include"] = [[
file.touch"test/tmp/core-include.txt"()
]]
return policy
