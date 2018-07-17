local T = {
  "file_directory",
  "file_absent",
  "file_managed",
  "exec_simple"
}
os.execute "mkdir tmp"
local CFG = require "u-cfg"
for _, t in ipairs(T) do
  require("tests."..t)
end
os.execute "rmdir tmp"
CFG.summary()
