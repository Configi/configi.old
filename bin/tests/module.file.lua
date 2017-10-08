_ENV = require "bin/tests/ENV"
local pwd = require "posix.pwd"
local grp = require "posix.grp"
function attributes(p)
  local nobody = pwd.getpwnam("nobody")
  local nogroup = grp.getgrnam("nobody") or grp.getgrnam("nogroup")
  local r, t
  T.file["attributes policy"] = function()
    r, t = cfg("-m", "-f", p)
    T.equal(r, 0)
  end
  T.file["attributes ok"] = function()
    T.is_not_nil(OK(t))
  end
  T.file["attributes check"] = function()
    local f1 = dir.."file_attributes1"
    local st1 = stat.stat(f1)
    T.equal(st1.st_uid, nobody.pw_uid)
    T.equal(st1.st_gid, nogroup.gr_gid)
    T.equal(util.octal(st1.st_mode), 100600)
    os.remove(f1)
    local f2 = dir.."file_attributes2"
    local st2 = stat.stat(f2)
    T.equal(util.octal(st2.st_mode), 100755)
    os.remove(f2)
    local f3 = dir.."file_attributes3"
    local st3 = stat.stat(f3)
    T.equal(util.octal(st3.st_mode), 100444)
    os.remove(f3)
  end
end
attributes("test/file_attributes.lua")
function link(p)
  local r, t
  T.file["link policy"] = function()
    r, t = cfg("-m", "-f", p)
    T.equal(r, 0)
  end
  T.file["link ok"] = function()
    T.is_not_nil(OK(t))
  end
  T.file["link check"] = function()
    local l = dir.."file_link"
    local st = stat.lstat(l)
    T.not_equal(stat.S_ISLNK(st.st_mode), 0)
    os.remove(l)
  end
end
link("test/file_link.lua")
function hard(p)
  local r, t
  T.file["hard policy"] = function()
    r, t = cfg("-m", "-f", p)
    T.equal(r, 0)
  end
  T.file["hard ok"] = function()
    T.is_not_nil(OK(t))
  end
  T.file["hard check"] = function()
    local src = dir.."file_hard_src"
    local link = dir.."file_hard_link"
    local st1 = stat.stat(src)
    local st2 = stat.stat(link)
    T.equal(st1.st_ino, st2.st_ino)
    os.remove(src)
    os.remove(link)
  end
end
hard("test/file_hard.lua")
function directory(p)
  local r, t
  T.file["directory policy"] = function()
    r, t = cfg("-m", "-f", p)
    T.equal(r, 0)
  end
  T.file["directory ok"] = function()
    T.is_not_nil(OK(t))
  end
  T.file["directory check"] = function()
    local d = dir.."file_directory"
    local st = stat.stat(d)
    T.not_equal(stat.S_ISDIR(st.st_mode), 0)
    os.remove(d)
  end
end
directory("test/file_directory.lua")
function touch(p)
  local r, t
  T.file["touch policy"] = function()
    r, t = cfg("-m", "-f", p)
    T.equal(r, 0)
  end
  T.file["touch ok"] = function()
    T.is_not_nil(OK(t))
  end
  T.file["touch check"] = function()
    local f = dir.."file_touch"
    local st = stat.stat(f)
    T.not_equal(stat.S_ISREG(st.st_mode), 0)
    os.remove(f)
  end
end
touch("test/file_touch.lua")
function absent(p)
  local r, t
  T.file["absent policy"] = function()
    r, t = cfg("-m", "-f", p)
    T.equal(r, 0)
  end
  T.file["absent pass"] = function()
    T.is_not_nil(PASS(t))
  end
  T.file["absent check"] = function()
    T.is_nil(stat.stat(dir.."file_absent"))
  end
end
absent("test/file_absent.lua")
function copy(p)
  local r, t
  T.file["copy policy"] = function()
    r, t = cfg("-m", "-f", p)
    T.equal(r, 0)
  end
  T.file["copy ok"] = function()
    T.is_not_nil(OK(t))
  end
  T.file["copy check"] = function()
    local dest = dir.."file_copy_dest"
    local src = dir.."file_copy_src"
    local tmp = dir.."file_copy.tmp"
    local _, ls = cmd.ls("-1", dest)
    local stdout = table.concat(ls.stdout, "\n")
    T.is_true(file.write_all(tmp, stdout))
    T.equal(crc32(file.read_all("test/file_copy.out")),
      crc32(file.read_all(tmp)))
    cmd.rm("-r", "-f", dest)
    cmd.rm("-r", "-f", src)
    os.remove(tmp)
  end
end
copy("test/file_copy.lua")
T.summary()

