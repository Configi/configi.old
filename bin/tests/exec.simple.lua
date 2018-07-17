local U = require "u-test"
local T = {}
local exec = require "cfg-modules.exec"
local os = require"lib".os
_ENV = nil
local f = "tmp/touch"
exec.simple("/bin/touch"){
  args = f,
  expects = f
}
U["exec.simple"] = function()
  U.equal(f, os.is_file(f))
end
os.execute("rm -f tmp/touch")
return T
