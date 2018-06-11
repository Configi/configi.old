local argparse = require("argparse")
local argparser = argparse("Configi", "Test")
argparser:argument("test")
local args = argparser:parse()
local C = require("u-cfg")
local file = require("cfg-modules.file")
if (args.test == "test") then
  C["test"] = function()
    return file.directory("xlib")
  end
end
