_ENV = require "bin/tests/ENV"
function command(p)
  T.policy = function()
    T.equal(cfg("-f", p), 0)
  end
  T.command = function()
    local f = dir.."shell_command.txt"
    T.is_not_nil(os.is_file(f))
    os.remove(f)
  end
end
command("test/shell_command.lua")
function system(p)
  T.policy = function()
    T.equal(cfg("-f", p), 0)
  end
  T.system = function()
    local f = dir.."shell_system.txt"
    T.is_not_nil(os.is_file(f))
    os.remove(f)
  end
end
system("test/shell_system.lua")
function popen(p1, p2)
  T.policy = function()
    T.equal(cfg("-f", p1), 0)
  end
  T.popen = function()
    local f = dir.."shell_popen.txt"
    T.is_not_nil(os.is_file(f))
    os.remove(f)
  end
  T.expects = function()
    local f = dir.."The wizard quickly jinxed the gnomes before they vaporized"
    cmd.touch(f)
    T.equal(cfg("-f", p2), 0)
    os.remove(f)
  end
end
popen("test/shell_popen.lua", "test/shell_popen_expects.lua")
function popen3(p1, p2, p3)
  T.policy = function()
    T.equal(cfg("-f", p1), 0)
    T.equal(cfg("-f", p2), 0)
    T.equal(cfg("-f", p2), 0)
  end
end
popen3("test/shell_popen3_stdin.lua", "test/shell_popen3_stdout.lua", "test/shell_popen3_stderr.lua")
T.summary()
