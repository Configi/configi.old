_ENV = require "bin/tests/ENV"
function mounted(p)
  local r, t
  T.mount["mounted policy"] = function()
    r, t = cfg("-m", "-f", p)
    T.equal(r, 0)
  end
  T.mount["mounted ok"] = function()
    T.equal(string.find(t.stderr[3], ".+%[%sOK%s%].*"), 1)
  end
  T.mount["mounted check"] = function()
    T.is_true(file.find("/proc/mounts", "/configi-test-mount", true))
  end
end
mounted("test/mount_mounted.lua")
function opts(p)
  local r, t
  T.mount["opts policy"] = function()
    r, t = cfg("-m", "-f", p)
    T.equal(r, 0)
  end
  T.mount["opts ok"] = function()
    T.equal(OK(t), 1)
  end
  T.mount["opts check"] = function()
    local s = file.match("/proc/mounts", "tmpfs.+/configi%-test%-mount.*")
    T.is_number(string.find(s, "nodev"))
  end
end
opts("test/mount_opts.lua")
function unmounted(p)
  local r, t
  T.mount["unmounted policy"] = function()
    r, t = cfg("-m", "-f", p)
    T.equal(r, 0)
  end
  T.mount["unmounted ok"] = function()
    T.equal(OK(t), 1)
  end
  T.mount["unmounted check"] = function()
    T.is_nil(file.find("/proc/mounts", "/configi-test-mount", true))
  end
end
unmounted("test/mount_unmounted.lua")
