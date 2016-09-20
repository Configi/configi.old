local policy = { moon = {} }
policy.moon.init = [[
include"include.moon"
file.touch"test/tmp/core-embedded.txt"
    mode: "0777"
]]
policy.moon.include = [[
file.touch"test/tmp/core-include.txt"!
]]
return policy
