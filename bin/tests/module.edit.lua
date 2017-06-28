_ENV = require "bin/tests/ENV"
function insert_line(p1, p2)
  local o = dir.."edit_insert_test.txt"
  T.policy = function()
    T.equal(cfg("-f", p1), 0)
  end
  T.insert = function()
    T.equal(crc32(file.read_all("test/edit_insert.txt")), crc32(file.read_all(o)))
  end
  T.inserts = function()
    local r, t = cfg("-m", "-f", p2)
    T.equal(r, 0)
    T.is_not_nil(string.find(t.stderr[1], ".+[PASS]*"))
    T.equal(crc32(file.read_all("test/edit_insert.txt")), crc32(file.read_all(o)))
    os.remove(o)
  end
end
insert_line("test/edit_insert.lua", "test/edit_insert_inserts.lua")
function insert_line_before(p)
  T.policy = function()
    T.equal(cfg("-f", p), 0)
  end
  T.before = function()
    T.equal(crc32(file.read_all("test/edit_insert_line_before.txt")),
      crc32(file.read_all(dir.."edit_insert_line_test.txt")))
  end
end
insert_line_before("test/edit_insert_line_before.lua")
function insert_line_after(p)
  T.policy = function()
    T.equal(cfg("-f", p), 0)
  end
  T.after = function()
    T.equal(crc32(file.read_all("test/edit_insert_line_after.txt")),
      crc32(file.read_all(dir.."/edit_insert_line_test.txt")))
    os.remove(dir.."edit_insert_line_test.txt")
    os.remove(dir.."._configi_edit_insert_line_test.txt")
  end
end
insert_line_after("test/edit_insert_line_after.lua")
function remove_line(p)
  T.policy = function()
    T.equal(cfg("-f", p), 0)
  end
  T.remove = function()
    T.equal(crc32(file.read_all("test/edit_remove_line.txt")),
      crc32(file.read_all(dir.."edit_remove_line_test.txt")))
    os.remove(dir.."edit_remove_line_test.txt")
  end
end
remove_line("test/edit_remove_line.lua")
T.summary()


