local exec = require "cfg-modules.exec"
local f = "tmp/touch"
exec.simple("/bin/touch"){
  args = f,
  expects = f
}
