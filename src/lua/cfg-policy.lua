local policy = {["."]={},attributes={},policies={},handlers={}}
policy.attributes.test = [[
    var="test"
]]
policy.policies.test = [[
file.touch"test/tmp/core-embedded-structure"{
    comment = _"${var} policies",
    notify = "embedded"
}
]]
policy.handlers.test = [[
file.touch"test/tmp/core-embedded-handlers"{
    comment = _"${var} handlers",
    handle = "embedded"
}
]]
policy["."]["init"] = [[
file.touch"test/tmp/core-embedded.txt" {
    mode = "0777"
}
]]
return policy
