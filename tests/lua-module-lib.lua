package.path="vendor/lua/?.lua"
local C = require "lib"
local T = require "u-test"

T["All tests"] = function()
  do
    local func = C.func
    --[[T.func.retry_f = function()
      local b = 0
      local r = func.retry_f(function() b = b + 1 end, 1, 2)
      r(string.find, "xxx", "XXX")
      T.equal(b, 2)
      b = 0
      r(string.find, "xxx", "xxx")
      T.equal(b, 0)
    end]]
    T.func.pcall_f = function()
      local fn
      local r = function(str)
        error(str)
      end
      fn = func.pcall_f(r)
      local one, two = fn("message")
      T.is_nil(one)
      T.equal(string.match(two, ".*(message)$"), "message")
    end
    T.func.try_f = function()
      local a, fn
      local finalizer = function()
        a = true
      end
      fn = func.try_f(finalizer)
      local x, y = fn(true, "good")
      T.is_nil(a)
      T.is_true(x)
      T.equal(y, "good")
      pcall(fn, false, "error")
      T.is_true(a)
    end
    T.func.catch_f = function()
      local a, fn
      local finalizer = function()
        return -1
      end
      fn = func.catch_f(finalizer)
      local x, y = fn(true, "good")
      T.is_nil(a)
      T.is_true(x)
      T.equal(y, "good")
      local x = fn(false, "error")
      T.equal(-1, x)
    end
    T.func.time = function()
      local fn, bool, str, elapsed
      fn = function(s)
        return true, s
      end
      bool, str, elapsed = func.time(fn, "string")
      T.is_true(bool)
      T.equal(str, "string")
      T.is_number(elapsed)
      T.equal(elapsed, 0.0)
    end
  end
  do
    local fmt = C.fmt
    T.fmt.skip = true
    T.fmt.printf = function()
    end
    T.fmt.fprintf = function()
    end
    T.fmt.warnf = function()
    end
    T.fmt.errorf = function()
    end
    T.fmt.panicf =function()
    end
    T.fmt.assertf = function()
    end
  end
  do
    local string = C.string
    local text = "one"
    T.string.append = function()
      local s = string.append(text, "two")
      T.equal(s, "one\ntwo")
    end
    T.string.line_to_table = function()
      local tbl = string.line_to_table("one\ntwo\nthree")
      T.equal(tbl[1], "one")
      T.equal(tbl[2], "two")
      T.equal(tbl[3], "three")
    end
    T.string.word_to_table = function()
      local tbl = string.word_to_table("one!two.three")
      T.equal(tbl[1], "one")
      T.equal(tbl[2], "two")
      T.equal(tbl[3], "three")
    end
    T.string.to_table = function()
      local tbl = string.to_table("one\ntwo three")
      T.equal(tbl[1], "one")
      T.equal(tbl[2], "two")
      T.equal(tbl[3], "three")
    end
    T.string.escape_pattern = function()
      local str = string.escape_pattern("%s\n")
      T.equal("%%s\n", str)
    end
    T.string.template = function()
      local str = "My name is ${n}"
      local tbl = { n = "Ed" }
      T.equal("My name is Ed", string.template(str, tbl))
    end
    T.string.escape_quotes = function()
      local str = string.escape_quotes([['test' and "TEST"]])
      T.equal([[\'test\' and \"TEST\"]], str)
    end
    T.string.hexdump = function()
    end
  end
  do
    local time = C.time
    T.time.hm = function()
      T.is_string(time.hm())
    end
    T.time.ymd = function()
      T.is_string(time.ymd())
    end
    T.time.stamp = function()
      T.is_string(time.stamp())
    end
  end
  do
    local table = C.table
    local t = { "one", "two", "three" }
    T.table.find = function()
      T.is_true(table.find(t, "two"))
      T.is_nil(table.find(t, "xxx"))
    end
    T.table.to_dict = function()
      local nt = table.to_dict(t)
      T.equal(nt.one, true)
      T.equal(nt.two, true)
      T.equal(nt.three, true)
      nt = table.to_dict(t, 1)
      T.equal(nt.one, 1)
      T.equal(nt.two, 1)
      T.equal(nt.three, 1)
    end
    T.table.to_seq = function()
      local xt = {one=1,two=2}
      local nt = table.to_seq(xt)
      T.equal(nt[1], "one")
      T.equal(nt[2], "two")
    end
    T.table.uniq = function()
      local xt = {one="x",two="x",three="y",four="y"}
      local nt = table.uniq(xt)
      local et = table.to_dict(nt)
      T.is_not_nil(et["y"])
      T.is_not_nil(et["x"])
    end
    T.table.filter = function()
      local t = { "one", "two", "three" }
      local nt = table.filter(t, "two")
      T.equal(#nt, 2)
      T.equal(nt[1], "one")
      T.equal(nt[2], "three")
    end
    T.table.clone = function()
      t[4] = { "x", "y", "z", { "1", "2", "3"} }
      t.x = { "xxx" }
      local nt = table.clone(t)
      T.equal(nt[1], "one")
      T.equal(nt[2], "two")
      T.equal(nt[3], "three")
      T.equal(nt[4][1], "x")
      T.equal(nt[4][2], "y")
      T.equal(nt[4][3], "z")
      T.equal(nt[4][4][1], "1")
      T.equal(nt[4][4][2], "2")
      T.equal(nt[4][4][3], "3")
      T.equal(nt.x[1], "xxx")
    end
    T.table.insert_if = function()
      table.insert_if(true, t, 4, false)
      T.is_false(t[4])
      T.is_table(t[5])
    end
    T.table.auto = function()
      table.auto(t)
      T.is_table(t[6])
      T.is_table(t[6][1][2][3].xxx)
    end
    T.table.count = function()
      local nt = { "x", "y", "z", "y" }
      local n = table.count(nt, "z")
      T.equal(n, 1)
      n = table.count(nt, "y")
      T.equal(n, 2)
    end
  end
  do
    local file = C.file
    T.file.start_up = function()
      os.execute[[
        mkdir tmp
        touch tmp/flopen
        touch tmp/stat
        ln -s tmp/stat tmp/symlink
        /bin/echo -e "one\ntwo\nthree" > tmp/file
      ]]
    end
    T.file.tear_down = function()
      os.execute[[
        rm tmp/file
        rm tmp/flopen
        rm tmp/stat
        unlink tmp/symlink
        rmdir tmp
      ]]
    end
    --[==[T.file.atomic_write = function()
      local r = file.atomic_write("tmp/atomic_write", "two three")
      T.is_true(r)
      for s in io.lines("tmp/atomic_write") do
        T.equal("two three", s)
      end
      os.execute[[
        rm tmp/atomic_write
      ]]
    end]==]
    T.file.find = function()
      T.is_true(file.find("tmp/file", "two"))
      T.is_nil(file.find("tmp/file", "xxx"))
    end
    T.file.match = function()
      T.equal(file.match("tmp/file", "o.."), "one")
      T.is_nil(file.match("tmp/file", "o..[%S]"))
      T.equal(file.match("tmp/file", "o..[%s]"), "one\n")
    end
    T.file.to_table = function()
      local t = file.to_table("tmp/file", "l")
      T.is_table(t)
      T.equal(t[1], "one")
      T.equal(t[2], "two")
      T.equal(t[3], "three")
    end
    T.file.test = function()
      T.is_true(file.test("tmp/file"))
      T.is_nil(file.test("tmp/xxx"))
    end
    T.file.read = function()
      local s = file.read("tmp/file")
      T.equal(s, "one\ntwo\nthree\n")
    end
    T.file.write = function()
      T.is_true(file.write("tmp/file.write", "one"))
      for s in io.lines("tmp/file.write") do
        T.equal(s, "one")
      end
      os.execute[[
        rm tmp/file.write
      ]]
    end
    T.file.line = function()
      T.equal(file.line("tmp/file", 2), "two")
    end
    T.file.truncate = function()
      os.execute[[
        echo "one" > tmp/file.truncate
      ]]
      T.is_true(file.truncate("tmp/file.truncate"))
      for s in io.lines("tmp/file.truncate") do
        T.equal(s, "")
      end
      os.execute[[
        rm tmp/file.truncate
      ]]
    end
    T.file.read_all = function()
      T.equal(file.read_all("tmp/file"), "one\ntwo\nthree\n")
    end
    T.file.head = function()
      T.equal(file.head("tests/Lua.lua"), [[package.path="vendor/lua/?.lua"]])
    end
  end
  do
    local exec = C.exec
    T.exec.start_up = function()
      os.execute[[
        mkdir tmp
      ]]
    end
    T.exec.tear_down = function()
      os.execute[[
        rmdir tmp
      ]]
    end
    T.exec.popen = function()
      os.execute[[
        touch tmp/one
        touch tmp/two
      ]]
      local t, r = exec.popen("ls", "bin")
      T.equal(t, 0)
      T.is_table(r)
      T.equal(r.exe, "io.popen")
      T.equal(r.status, "exit")
      T.equal(r.output[1], "cfg")
      T.is_nil(r.output[7])
      t, r = exec.popen("xxx")
      T.is_nil(t)
      T.equal(r.exe, "io.popen")
      T.equal(r.status, "exit")
      t, r = exec.popen("xxx", ".", true)
      T.equal(t, 127)
      T.equal(r.output[1], "sh: xxx: not found")
      os.execute[[
        rm tmp/one
        rm tmp/two
      ]]
    end
    T.exec.pwrite = function()
      local t, r = exec.pwrite("cat>pwrite", "written", "tmp")
      T.equal(t, 0)
      T.equal(r.exe, "io.popen")
      T.equal(r.status, "exit")
      for s in io.lines("tmp/pwrite") do
        T.equal(s, "written")
      end
      os.execute[[
        rm tmp/pwrite
      ]]
    end
    T.exec.system = function()
      local t, r = exec.system("ls", "tmp")
      T.equal(t, 0)
      T.equal(r.exe, "os.execute")
      T.equal(r.status, "exit")
      t, r = exec.system("ls XXX")
      T.is_nil(t)
      t, r = exec.system("ls XXX", ".", true)
      T.equal(t, 1)
    end
    T.exec.script = function()
      local t, r = exec.script("tests/lua-module-lib-exec.script1.sh")
      T.equal(t, 0)
      T.equal(r.exe, "io.popen")
      T.equal(r.status, "exit")
      t, r = exec.script("tests/lua-module-lib-exec.script2.sh", true)
      T.equal(t, 1)
    end
    T.exec.pipe_args = function()
      local t, r = exec.pipe_args("popen", "ls", "cat>tmp/pipe_args")
      T.equal(t, 0)
      T.is_table(r)
      for s in io.lines("tmp/pipe_args") do
        T.is_string(s)
      end
      T.equal(r.exe, "io.popen")
      T.equal(r.status, "exit")
      os.execute[[
        rm tmp/pipe_args
      ]]
    end
  end
  do
    local log = C.log
    T.log.start_up = function()
      os.execute[[
        mkdir tmp
      ]]
    end
    T.log.tear_down = function()
      os.execute[[
        rmdir tmp
      ]]
    end
    T.log.file = function()
      T.is_true(log.file("tmp/log", "T", "Ting one two three") )
      for s in io.lines("tmp/log") do
        T.equal(string.find(s, ".+Ting%sone%stwo%sthree"), 1)
      end
      os.execute[[
        rm tmp/log
      ]]
    end
  end
	do
    local path = C.path
 		T.path.split = function()
      local dir, base = path.split("tmp/one")
      T.equal(dir, "tmp")
      T.equal(base, "one")
      dir, base = path.split("/tmp/one")
      T.equal(dir, "/tmp")
      T.equal(base, "one")
      dir, base = path.split("/home/ed/one")
      T.equal(dir, "/home/ed")
      T.equal(base, "one")
      dir, base = path.split("one")
      T.equal(dir, "")
      T.equal(base, "one")
    end
	end
  do
    local util = C.util
    T.util.truthy = function()
      T.is_true(util.truthy("yes"))
      T.is_true(util.truthy("Yes"))
      T.is_true(util.truthy("true"))
      T.is_true(util.truthy("True"))
      T.is_true(util.truthy("on"))
      T.is_true(util.truthy("On"))
    end
    T.util.falsy = function()
      T.is_true(util.falsy("no"))
      T.is_true(util.falsy("No"))
      T.is_true(util.falsy("false"))
      T.is_true(util.falsy("False"))
      T.is_true(util.falsy("off"))
      T.is_true(util.falsy("Off"))
    end
    T.util.return_if = function()
      T.is_not_nil(util.return_if(true, 1))
      T.is_nil(util.return_if(false, 1))
    end
    T.util.return_if_not = function()
      T.is_not_nil(util.return_if_not(false, 1))
      T.is_nil(util.return_if_not(true, 1))
    end
  end
end
T.summary()
