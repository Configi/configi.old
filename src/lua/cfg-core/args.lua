local strings = require"cfg-core.strings"
local getopt = require"posix.getopt"
local opts = {}
for _, la in ipairs(strings.long_args) do
    opts[la[3]] = false
end
for r, oarg, _, _ in getopt.getopt(arg, strings.short_args, strings.long_args) do
    if opts[r] == false then
        opts[r] = oarg or true
    end
end
return opts
