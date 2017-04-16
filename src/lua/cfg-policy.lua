local policy = {["."]={},attributes={},includes={},handlers={}}
policy.attributes.test = [[
    var="test"
]]
policy.includes.test = [[
file.touch"test/tmp/core-embedded-structure"{
    comment = _"${var} includes",
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
