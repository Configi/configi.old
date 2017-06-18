local strings = require"cfg-core.strings"
local unistd = require"posix.unistd"
local opts = {}
for _, la in ipairs(strings.long_args) do
  opts[la[3]] = false
end
for r, oarg, _, _ in unistd.getopt(arg, strings.short_args) do
  if opts[r] == false then
    opts[r] = oarg or true
  end
end
return opts
