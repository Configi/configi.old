#!bin/lua
package.path = "../cwtest/?.lua"
local Lc, Px, Factid = require"cimicida", require"px", require"factid"
local Cmd = Px.cmd
local Psysstat, Ppwd, Pgrp = require"posix.sys.stat", require"posix.pwd", require"posix.grp"

local Ct = require"cwtest"
local T, N = Ct.new(), { failures = 0, successes = 0 }


local osfamily = Factid.osfamily()
local diff = function (from, to)
  local res, _, _ = Cmd.diff{ "-N", "-a", "-u", from, to }
  return res
end

local bin = "bin/cfg -vf test/"
local testdir = "test/tmp/"
if not Px.isdir(testdir) then
  Psysstat.mkdir(testdir)
end
local cfg = Cmd["bin/cfg"]
T:start"debug test/core-debug.lua"
 do
   local _, _, out = cfg{ "-v",  "-f", "test/core-debug.lua"}
   out = table.concat(out.stdout, "\n")
   T:eq(string.find(out, "Started run", 1, true), 1)
   T:eq(string.find(out, "Running", 1, true), 42)
   T:eq(string.find(out, "Finished run", 1, true), 102)
 end
T:done(N)

T:start"log test/core-log.lua"
  do
    local log = "test/tmp/_test_configi.log"
    T:yes(cfg{ "-l", log, "-f", "test/core-log.lua" })
    T:yes(Psysstat.stat(log))
    T:yes(os.remove(log))
  end
T:done(N)

T:start"fact test/core-fact.lua"
  do
   local _, _, out = cfg{ "-f", "test/core-fact.lua" }
   out = table.concat(out.stderr, "\n")
   T:eq(string.find(out, "Command successfully executed", 1, true), 114)
  end
T:done(N)

T:start"test test/core-test.lua"
 do
   local tempname = testdir .. "core-test.txt"
   T:yes(Lc.fwrite(tempname, "test"))
   T:yes(cfg{ "-f", "test/core-test.lua"})
   T:eq(Lc.fopen(tempname), "test")
   T:yes(os.remove(tempname))
 end
T:done(N)

T:start"module test/core-module.lua"
  do
    T:yes(cfg{ "-f", "test/core-module.lua"})
  end
T:done(N)

T:start"include test/core-include1.lua, test/core-include2.lua"
  do
    local dir = testdir .. "CONFIGI_TEST_INCLUDE"
    T:yes(cfg{ "-f", "test/core-include1.lua"})
    T:yes(Px.isdir(dir))
    T:yes(cfg{ "-f", "test/core-include2.lua"})
    T:no(Psysstat.stat(dir))
  end
T:done(N)

T:start"handler,notify test/core-handler.lua"
  do
    T:yes(cfg{ "-f", "test/core-handler.lua"})
    local _, _, r = cfg{"-v", "-f", "test/core-handler_include.lua"}
    T:yes(Lc.tfind(r.stdout, "Kept: true"))
    local xfile, file = "test/tmp/core-handler2-xfile", "test/tmp/core-handler2-file"
    T:yes(cfg{ "-g", "testhandle", "-f",  "test/core-handler2.lua" })
    T:no(Psysstat.stat(xfile))
    T:yes(Psysstat.stat(file))
    T:yes(os.remove(file))
  end
T:done(N)

T:start"context test/core-context.lua"
  do
    T:yes(cfg{ "-f", "test/core-context.lua"})
    T:no(Psysstat.stat("test/tmp/core-context"))
  end
T:done(N)

T:start"comment test/core-comment.lua"
  do
    local _, _, out = cfg{ "-v", "-f", "test/core-comment.lua" }
    out = table.concat(out.stderr, "\n")
    T:eq(string.find(out, "TEST COMMENT", 1, true), 55)
  end
T:done(N)

T:start"list test/core-list.lua"
  do
    T:yes(Psysstat.mkdir(testdir .. "core-list.xxx"))
    T:yes(Psysstat.mkdir(testdir .. "core-list.yyy"))
    T:yes(cfg{ "-f", "test/core-list.lua"})
    T:no(Px.isdir(testdir .. "core-list.xxx"))
    T:no(Px.isdir(testdir .. "core-list.yyy"))
  end
T:done(N)

T:start"cron.present (modules/cron.lua) test/cron_present.lua"
  do
    local temp = os.tmpname()
    -- Restore root crontab file on OpenWRT
    if osfamily == "openwrt" then
      T:yes(Cmd.touch{ "/etc/crontabs/root" })
    end
    T:yes(cfg{ "-f", "test/cron_present.lua"})
    local _, _, r = Cmd.crontab{ "-l" }
    local t = Lc.filtertval(r.stdout, "^#[%C]+") -- Remove comments
    t[#t] = t[#t] .. "\n" -- Add trailing newline
    T:yes(Lc.fwrite(temp, table.concat(t, "\n")))
    T:yes(diff("test/cron_present.out", temp))
    T:yes(Cmd.crontab{ "-r" })
    T:yes(os.remove(temp))
  end
T:done(N)

T:start"cron.absent (modules/cron.lua) test/cron_absent.lua"
  do
    local temp = os.tmpname()
    T:yes(cfg{ "-f", "test/cron_present.lua"})
    T:yes(cfg{ "-f", "test/cron_absent.lua"})
    local _, _, r = Cmd.crontab{ "-l" }
    local t = Lc.filtertval(r.stdout, "^#%s%g+") -- Remove comments
    local crontab = table.concat(t, "\n")
    T:no(string.find(crontab, "6 7 * * * /bin/ls", 1, true))
    T:yes(Cmd.crontab{ "-r" })
    T:yes(os.remove(temp))
  end
T:done(N)

T:start"textfile.render (modules/textfile.lua) test/textfile_render.lua"
  do
    local out = testdir .. "textfile_render_test.txt"
    T:yes(cfg{ "-f", "test/textfile_render.lua"})
    T:yes(diff("test/textfile_render.txt", out))
    T:yes(os.remove(out))
  end
T:done(N)

T:start"textfile.insert_line (modules/textfile.lua) test/textfile_insert.lua"
  do
    local out = testdir .. "textfile_insert_test.txt"
    T:yes(cfg{ "-f", "test/textfile_insert.lua"})
    T:yes(diff("test/textfile_insert.txt", out))
    T:yes(cfg{ "-f", "test/textfile_insert_inserts.lua"})
    T:yes(diff("test/textfile_insert.txt", out))
    T:yes(os.remove(out))
  end
T:done(N)

T:start"textfile.insert_line_before (modules/textfile.lua) test/textfile_insert_line_before.lua"
  do
    T:yes(cfg{ "-f", "test/textfile_insert_line_before.lua"})
    T:yes(diff("test/textfile_insert_line_before.txt", "test/tmp/textfile_insert_line_test.txt"))
 end
T:done(N)

T:start"textfile.insert_line_after (modules/textfile.lua) test/textfile_insert_line_after.lua"
  do
    T:yes(cfg{ "-f", "test/textfile_insert_line_after.lua"})
    T:yes(diff("test/textfile_insert_line_after.txt", "test/tmp/textfile_insert_line_test.txt"))
    T:yes(Cmd.rm { testdir .. "textfile_insert_line_test.txt"} )
    T:yes(Cmd.rm { testdir .. "._configi_textfile_insert_line_test.txt" })
 end
T:done(N)

T:start"textfile.remove_line (modules/textfile.lua) test/textfile_remove_line.lua"
 do
   T:yes(cfg{ "-f", "test/textfile_remove_line.lua"})
   T:yes(diff("test/textfile_remove_line.txt", "test/tmp/textfile_remove_line_test.txt"))
   T:yes(Cmd.rm { testdir .. "textfile_remove_line_test.txt" } )
 end
T:done(N)

T:start"shell.command (modules/shell.lua)"
  do
    T:yes(cfg{ "-f", "test/shell_command.lua"})
    T:yes(Px.isfile(testdir .. "shell_command.txt"))
    T:yes(os.remove(testdir .. "shell_command.txt"))
  end
T:done(N)

T:start"shell.system (modules/shell.lua)"
  do
    T:yes(cfg{ "-f", "test/shell_system.lua"})
    T:yes(Px.isfile(testdir .. "shell_system.txt"))
    T:yes(os.remove(testdir .. "shell_system.txt"))
  end
T:done(N)

T:start"shell.popen (modules/shell.lua)"
  do
    T:yes(cfg{ "-f", "test/shell_popen.lua"})
    T:yes(Px.isfile(testdir .. "shell_popen.txt"))
    T:yes(os.remove(testdir .. "shell_popen.txt"))
    T:yes(Cmd.touch{ testdir .. "The wizard quickly jinxed the gnomes before they vaporized"})
    T:yes(cfg{ "-f", "test/shell_popen_expects.lua"})
    T:yes(os.remove(testdir .. "The wizard quickly jinxed the gnomes before they vaporized"))
  end
T:done(N)

T:start"shell.popen3 (modules/shell.lua)"
  do
    T:yes(cfg{ "-f", "test/shell_popen3_stdin.lua"})
    T:yes(cfg{ "-f", "test/shell_popen3_stdout.lua"})
    T:yes(cfg{ "-f", "test/shell_popen3_stderr.lua"})
  end
T:done(N)

T:start"user.present (modules/user.lua)"
  do
    T:yes(cfg{ "-f", "test/user_present.lua"})
  end
T:done(N)

T:start"user.absent (modules/user.lua)"
  do
    T:yes(cfg{ "-f", "test/user_absent.lua" })
  end
T:done(N)

if osfamily == "centos" then
  T:start"yum.present (modules/yum.lua)"
    do
      T:yes(cfg{ "-f", "test/yum_present.lua" })
    end
  T:done(N)
  T:start"yum.absent (modules/yum.lua)"
    do
      T:yes(cfg{ "-f", "test/yum_absent.lua" })
    end
  T:done(N)
  T:start"systemd.started (modules/systemd.lua)"
    do
      T:yes(cfg{ "-f", "test/systemd_started.lua"})

    end
  T:done(N)
  T:start"systemd.restart (modules/systemd.lua)"
    do
      local ok, _, cmd = Cmd.pgrep{ "tuned" }
      local first = cmd.stdout[1]
      T:yes(ok)
      T:yes(exec(bin .. "systemd_restart.lua"))
      T:yes(cfg{ "-f", "test/systemd_restart.lua" })
      ok, _, cmd = Cmd.pgrep{ "tuned" }
      local second = cmd.stdout[1]
      T:yes(ok)
      if first == second then
        ok = false
      end
      T:yes(ok)
    end
  T:done(N)
  T:start"systemd.reload (modules/systemd.lua)"
    do
      T:yes(cfg{ "-f", "test/systemd_reload.lua"})
    end
  T:done(N)
  T:start"systemd.stopped (modules/systemd.lua)"
    do
      T:yes(cfg{ "-f", "test/systemd_stopped.lua"})
      T:no(Cmd.pgrep{ "tuned" })
    end
  T:done(N)
  T:start"systemd.enabled (modules/systemd.lua)"
    do
      T:yes(cfg{ "-f", "test/systemd_enabled.lua"})
    end
  T:done(N)
  T:start"systemd.disabled (modules/systemd.lua)"
    do
      T:yes(cfg{ "-f", "test/systemd_disabled.lua"})
    end
  T:done(N)
end

if osfamily == "openwrt" then
  T:start"opkg.present (modules/opkg.lua)"
    do
      T:yes(cfg{ "-f", "test/opkg_present.lua"})
    end
  T:done(N)
  T:start"opkg.absent (modules/opkg.lua)"
    do
      T:yes(cfg{ "-f", "test/opkg_absent.lua"})
    end
  T:done(N)
  T:start"sysvinit.started (modules/sysvinit.lua)"
    do
      T:yes(cfg{ "-f", "test/sysvinit_started.lua"})
      T:yes(Cmd.pgrep{ "uhttpd" })
    end
  T:done(N)
  T:start"sysvinit.restart (modules/sysvinit.lua)"
    do
      local ok, _, cmd = Cmd.pgrep{ "uhttpd" }
      local first = cmd.stdout[1]
      T:yes(ok)
      T:yes(cfg{ "-f", "test/sysvinit_restart.lua"})
      ok, _, cmd = Cmd.pgrep{ "uhttpd" }
      local second = cmd.stdout[1]
      T:yes(ok)
      if first == second then
        ok = false
      end
      T:yes(ok)
    end
  T:done(N)
  T:start"sysvinit.reload (modules/sysvinit.lua)"
    do
      T:yes(cfg{ "-f", "test/sysvinit_reload.lua"})
    end
  T:done(N)
  T:start"sysvinit.stopped (modules/sysvinit.lua)"
    do
      T:yes(cfg{ "-f", "test/sysvinit_stopped.lua"})
      T:no(Cmd.pgrep{ "uhttpd" })
    end
  T:done(N)
  T:start"sysvinit.enabled (modules/sysvinit.lua)"
    do
      T:yes(cfg{ "-f", "test/sysvinit_enabled.lua"})
    end
  T:done(N)
  T:start"sysvinit.disabled (modules/sysvinit.lua)"
    do
      T:yes(cfg{ "-f", "test/sysvinit_disabled.lua"})
    end
  T:done(N)
end

if osfamily == "gentoo" then
  T:start"portage.present (modules/portage.lua)"
    do
      T:yes(cfg{ "-f", "test/portage_present.lua"})
    end
  T:done(N)
  T:start"portage.absent (modules/portage.lua)"
    do
      T:yes(cfg{ "-f", "test/portage_absent.lua"})
    end
  T:done(N)
end

if osfamily == "alpine" then
  T:start"apk.present (modules/apk.lua)"
    do
      T:yes(cfg{ "-v", "-f", "test/apk_present.lua" })
    end
  T:done(N)
  T:start"apk.absent (modules/apk.lua)"
    do
      T:yes(cfg{ "-v", "-f", "test/apk_absent.lua" })
    end
  T:done(N)
end

if osfamily == "gentoo" or osfamily == "alpine" then
  T:start"openrc.started (modules/openrc.lua)"
    do
      T:yes(cfg{ "-f", "test/openrc_started.lua"})
      T:yes(Cmd.pgrep{ "rsync" })
    end
  T:done(N)
  T:start"openrc.restart (modules/openrc.lua)"
    do
      local ok, _, cmd = Cmd.pgrep{ "rsync" }
      local first = cmd.stdout
      T:yes(ok)
      T:yes(cfg{ "-f", "test/openrc_restart.lua"})
      ok, _, cmd = Cmd.pgrep{ "rsync" }
      local second = cmd.stdout
      T:yes(ok)
      if first == second then
        ok = false
      end
      T:yes(ok)
    end
  T:done(N)
  T:start"openrc.reload (modules/openrc.lua)"
    do
      T:yes(cfg{ "-f", "test/openrc_reload.lua"})
    end
  T:done(N)
  T:start"openrc.stopped (modules/openrc.lua)"
    do
      T:yes(cfg{ "-f", "test/openrc_stopped.lua"})
      T:no(Cmd.pgrep{ "rsync" })
    end
  T:done(N)
  T:start"openrc.add (modules/openrc.lua)"
    do
      T:yes(cfg{ "-f", "test/openrc_add.lua"})
    end
  T:done(N)
  T:start"openrc.delete (modules/openrc.lua)"
    do
      T:yes(cfg{ "-f", "test/openrc_del.lua"})
    end
  T:done(N)
end

T:start"file.attributes (modules/file.lua)"
  do
    local nobody = Ppwd.getpwnam("nobody")
    local nogroup = Pgrp.getgrnam("nogroup")
    T:yes(cfg{ "-f", "test/file_attributes1.lua"})
    local stat = Psysstat.stat(testdir .. "file_attributes1")
    T:eq(stat.st_uid, nobody.pw_uid)
    T:eq(stat.st_gid, nogroup.gr_gid)
    T:eq(Lc.strf("%o", stat.st_mode), "100600")
    T:yes(os.remove(testdir .. "file_attributes1"))
  end
T:done(N)

T:start"file.link (modules/file.lua)"
  do
    T:yes(cfg{ "-f", "test/file_link.lua"})
    local stat = Psysstat.lstat(testdir .. "file_link")
    T:neq(Psysstat.S_ISLNK(stat.st_mode), 0)
    T:yes(Lc.execute("rm " .. testdir .. "file_link"))
  end
T:done(N)

T:start"file.hard (modules/file.lua)"
  do
    T:yes(cfg{ "-f", "test/file_hard.lua" })
    local stat1 = Psysstat.stat(testdir .. "file_hard_src")
    local stat2 = Psysstat.stat(testdir .. "file_hard_dest")
    T:eq(stat1.st_ino, stat2.st_ino)
    T:yes(Lc.execute("rm " .. testdir .. "file_hard_src"))
    T:yes(Lc.execute("rm " .. testdir .. "file_hard_dest"))
  end
T:done(N)

T:start"file.directory (modules/file.lua)"
  do
    T:yes(cfg{ "-f", "test/file_directory.lua" })
    local stat = Psysstat.stat(testdir .. "file_directory")
    T:neq(Psysstat.S_ISDIR(stat.st_mode), 0)
    T:yes(os.remove(testdir .. "file_directory"))
  end
T:done(N)

T:start"file.touch (modules/file.lua)"
  do
    T:yes(cfg{ "-f", "test/file_touch.lua"})
    local stat = Psysstat.stat(testdir .. "file_touch")
    T:neq(Psysstat.S_ISREG(stat.st_mode), 0)
    T:yes(os.remove(testdir .. "file_touch"))
  end
T:done(N)

T:start"file.absent (modules/file.lua)"
  do
    T:yes(cfg{ "-f", "test/file_absent.lua" })
    local stat = Psysstat.stat(testdir .. "file_absent")
    T:no(stat)
  end
T:done(N)

T:start"file.copy (modules/file.lua)"
  do
    T:yes(cfg{ "-f", "test/file_copy.lua" })
    local _, _, ls = Cmd.ls{ "-1", testdir .. "file_copy_dest" }
    local stdout = table.concat(ls.stdout, "\n")
    T:yes(Lc.fwrite(testdir .. "file_copy.tmp", stdout))
    T:yes(diff("test/file_copy.out", testdir .. "file_copy.tmp"))
    T:yes(Cmd.rm{ "-r", testdir .. "file_copy_dest" })
    T:yes(Cmd.rm{ "-r", testdir .. "file_copy_src" })
    T:yes(Cmd.rm{ testdir .. "file_copy.tmp" })
  end
T:done(N)

T:start"authorized_keys.present (modules/authorized_keys.lua)"
  do
    T:yes(cfg{ "-f", "test/authorized_keys_present.lua"})
  end
T:done(N)

T:start"authorized_keys.absent (modules/authorized_keys.lua)"
  do
    T:yes(cfg{ "-f", "test/authorized_keys_absent.lua"})
  end
T:done(N)

T:start"unarchive.unpack (modules/unarchive.lua)"
  do
    T:yes(cfg{ "-f", "test/unarchive_unpack.lua" })
    T:yes(Psysstat.stat(testdir .. "unarchive_unpack.lua"))
    T:yes(Cmd.rm{ testdir .. "unarchive_unpack.lua"})
  end
T:done(N)

if Px.binpath("git") then
  T:start"git.clone (modules/git.lua)"
    do
      T:yes(cfg{ "-f", "test/git_clone.lua" })
      T:yes(Psysstat.stat(testdir .. "git/.git/config"))
    end
  T:done(N)

  T:start"git.pull (modules/git.lua)"
    do
      T:yes(cfg{ "-f", "test/git_pull.lua" })
      T:yes(Cmd.rm{ "-r", testdir .. "git"})
    end
  T:done(N)
end

Lc.printf("\n  Summary: \n")
Lc.printf("    %s Passed\n", N.successes)
Lc.printf("    %s Failures\n\n", N.failures)
