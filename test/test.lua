#!bin/lua
package.path = "vendor/cwtest/?.lua"
local Lc, Px, Factid = require"cimicida", require"px", require"factid"
local Cmd = Px.cmd
local crc = require"crc32".crc32_string
local Psysstat, Ppwd, Pgrp = require"posix.sys.stat", require"posix.pwd", require"posix.grp"
local Ct = require"cwtest"
local T, N = Ct.new(), { failures = 0, successes = 0 }
local osfamily = Factid.osfamily()
local testdir = "test/tmp/"
local cfg = Cmd["bin/cfg"]

if not Px.isdir(testdir) then
  Psysstat.mkdir(testdir)
end

T:start"debug test/core-debug.lua"
 do
   local _, out = cfg{ "-v",  "-f", "test/core-debug.lua"}
   out = table.concat(out.stdout, "\n")
   T:eq(string.find(out, "Started run", 1, true), 1)
   T:eq(string.find(out, "Running", 1, true), 42)
   T:eq(string.find(out, "Finished run", 1, true), 102)
 end
T:done(N)

T:start"log test/core-log.lua"
  do
    local log = "test/tmp/_test_configi.log"
    T:eq(cfg{ "-f", "test/core-log.lua" }, true)
    T:yes(Psysstat.stat(log))
    T:yes(os.remove(log))
  end
T:done(N)

T:start"fact test/core-fact.lua"
  do
   local _, out = cfg{ "-f", "test/core-fact.lua" }
   T:eq(out.code, 0)
  end
T:done(N)

T:start"test test/core-test.lua"
 do
   local tempname = testdir .. "core-test.txt"
   T:yes(Lc.fwrite(tempname, "test"))
   T:eq(cfg{ "-f", "test/core-test.lua"}, true)
   T:eq(Lc.fopen(tempname), "test")
   T:yes(os.remove(tempname))
 end
T:done(N)

T:start"module test/core-module.lua"
  do
    T:eq(cfg{ "-f", "test/core-module.lua"}, true)
  end
T:done(N)

T:start"include test/core-include1.lua, test/core-include2.lua"
  do
    local dir = testdir .. "CONFIGI_TEST_INCLUDE"
    T:eq(cfg{ "-f", "test/core-include1.lua"}, true)
    T:yes(Px.isdir(dir))
    T:eq(cfg{ "-f", "test/core-include2.lua"}, true)
    T:no(Psysstat.stat(dir))
  end
T:done(N)

T:start"handler,notify test/core-handler.lua"
  do
    T:eq(cfg{ "-f", "test/core-handler.lua"}, true)
    local _, r = cfg{"-v", "-f", "test/core-handler_include.lua"}
    T:yes(Lc.tfind(r.stdout, "Kept: true"))
    local xfile, file = "test/tmp/core-handler2-xfile", "test/tmp/core-handler2-file"
    T:eq(cfg{ "-g", "testhandle", "-f",  "test/core-handler2.lua" }, true)
    T:no(Psysstat.stat(xfile))
    T:yes(Psysstat.stat(file))
    T:yes(os.remove(file))
  end
T:done(N)

T:start"context test/core-context.lua"
  do
    T:eq(cfg{ "-f", "test/core-context.lua"}, true)
    T:no(Psysstat.stat("test/tmp/core-context"))
  end
T:done(N)

T:start"comment test/core-comment.lua"
  do
    local _, out = cfg{ "-v", "-f", "test/core-comment.lua" }
    out = table.concat(out.stderr, "\n")
    T:eq(string.find(out, "TEST COMMENT", 1, true), 30)
  end
T:done(N)

T:start"list test/core-list.lua"
  do
    T:yes(Psysstat.mkdir(testdir .. "core-list.xxx"))
    T:yes(Psysstat.mkdir(testdir .. "core-list.yyy"))
    T:eq(cfg{ "-f", "test/core-list.lua"}, true)
    T:no(Px.isdir(testdir .. "core-list.xxx"))
    T:no(Px.isdir(testdir .. "core-list.yyy"))
  end
T:done(N)

T:start"map test/core-map.lua"
  do
    T:yes(Psysstat.mkdir(testdir .. "core-map.xxx"))
    T:yes(Psysstat.mkdir(testdir .. "core-map.yyy"))
    T:eq(cfg{ "-f", "test/core-map.lua"}, true)
    T:no(Px.isdir(testdir .. "core-map.xxx"))
    T:no(Px.isdir(testdir .. "core-map.yyy"))
  end
T:done(N)

T:start"cron.present (modules/cron.lua) test/cron_present.lua"
  do
    local temp = os.tmpname()
    -- Restore root crontab file on OpenWRT
    if osfamily == "openwrt" then
      T:yes(Cmd.touch{ "/etc/crontabs/root" })
    end
    T:eq(cfg{ "-f", "test/cron_present.lua"}, true)
    local _, r = Cmd.crontab{ "-l" }
    local t = Lc.filtertval(r.stdout, "^#[%C]+") -- Remove comments
    t[#t] = t[#t] .. "\n" -- Add trailing newline
    T:eq(crc(Lc.fopen("test/cron_present.out")), crc(table.concat(t, "\n")))
    T:eq(Cmd.crontab{ "-r" }, true)
    T:yes(os.remove(temp))
  end
T:done(N)

T:start"cron.absent (modules/cron.lua) test/cron_absent.lua"
  do
    local temp = os.tmpname()
    T:eq(cfg{ "-f", "test/cron_present.lua"}, true)
    T:eq(cfg{ "-f", "test/cron_absent.lua"}, true)
    local _, r = Cmd.crontab{ "-l" }
    local t = Lc.filtertval(r.stdout, "^#%s%g+") -- Remove comments
    local crontab = table.concat(t, "\n")
    T:no(string.find(crontab, "6 7 * * * /bin/ls", 1, true))
    T:eq(Cmd.crontab{ "-r" }, true)
    T:yes(os.remove(temp))
  end
T:done(N)

T:start"textfile.render (modules/textfile.lua) test/textfile_render.lua"
  do
    local out = testdir .. "textfile_render_test.txt"
    T:eq(cfg{ "-f", "test/textfile_render.lua"}, true)
    T:eq(crc(Lc.fopen("test/textfile_render.txt")), crc(Lc.fopen(out)))
    T:yes(os.remove(out))
  end
T:done(N)

T:start"textfile.insert_line (modules/textfile.lua) test/textfile_insert.lua"
  do
    local out = testdir .. "textfile_insert_test.txt"
    T:eq(cfg{ "-f", "test/textfile_insert.lua"}, true)
    T:eq(crc(Lc.fopen("test/textfile_insert.txt")), crc(Lc.fopen(out)))
    T:eq(cfg{ "-f", "test/textfile_insert_inserts.lua"}, true)
    T:eq(crc(Lc.fopen("test/textfile_insert.txt")), crc(Lc.fopen(out)))
    T:yes(os.remove(out))
  end
T:done(N)

T:start"textfile.insert_line_before (modules/textfile.lua) test/textfile_insert_line_before.lua"
  do
    T:eq(cfg{ "-f", "test/textfile_insert_line_before.lua"}, true)
    T:eq(crc(Lc.fopen("test/textfile_insert_line_before.txt")), crc(Lc.fopen("test/tmp/textfile_insert_line_test.txt")))
 end
T:done(N)

T:start"textfile.insert_line_after (modules/textfile.lua) test/textfile_insert_line_after.lua"
  do
    T:eq(cfg{ "-f", "test/textfile_insert_line_after.lua"}, true)
    T:eq(crc(Lc.fopen("test/textfile_insert_line_after.txt")), crc(Lc.fopen("test/tmp/textfile_insert_line_test.txt")))
    T:eq(Cmd.rm { testdir .. "textfile_insert_line_test.txt"}, true)
    T:eq(Cmd.rm { testdir .. "._configi_textfile_insert_line_test.txt" }, true)
 end
T:done(N)

T:start"textfile.remove_line (modules/textfile.lua) test/textfile_remove_line.lua"
 do
   T:eq(cfg{ "-f", "test/textfile_remove_line.lua"}, true)
   T:eq(crc(Lc.fopen("test/textfile_remove_line.txt")), crc(Lc.fopen("test/tmp/textfile_remove_line_test.txt")))
   T:eq(Cmd.rm { testdir .. "textfile_remove_line_test.txt" }, true)
 end
T:done(N)

T:start"shell.command (modules/shell.lua)"
  do
    T:eq(cfg{ "-f", "test/shell_command.lua"}, true)
    T:yes(Px.isfile(testdir .. "shell_command.txt"))
    T:yes(os.remove(testdir .. "shell_command.txt"))
  end
T:done(N)

T:start"shell.system (modules/shell.lua)"
  do
    T:eq(cfg{ "-f", "test/shell_system.lua"}, true)
    T:yes(Px.isfile(testdir .. "shell_system.txt"))
    T:yes(os.remove(testdir .. "shell_system.txt"))
  end
T:done(N)

T:start"shell.popen (modules/shell.lua)"
  do
    T:eq(cfg{ "-f", "test/shell_popen.lua"}, true)
    T:yes(Px.isfile(testdir .. "shell_popen.txt"))
    T:yes(os.remove(testdir .. "shell_popen.txt"))
    T:eq(Cmd.touch{ testdir .. "The wizard quickly jinxed the gnomes before they vaporized"}, true)
    T:eq(cfg{ "-f", "test/shell_popen_expects.lua"}, true)
    T:yes(os.remove(testdir .. "The wizard quickly jinxed the gnomes before they vaporized"))
  end
T:done(N)

T:start"shell.popen3 (modules/shell.lua)"
  do
    T:eq(cfg{ "-f", "test/shell_popen3_stdin.lua"}, true)
    T:eq(cfg{ "-f", "test/shell_popen3_stdout.lua"}, true)
    T:eq(cfg{ "-f", "test/shell_popen3_stderr.lua"}, true)
  end
T:done(N)

T:start"user.present (modules/user.lua)"
  do
    T:eq(cfg{ "-f", "test/user_present.lua"}, true)
  end
T:done(N)

T:start"user.absent (modules/user.lua)"
  do
    T:eq(cfg{ "-f", "test/user_absent.lua" }, true)
  end
T:done(N)

if osfamily == "centos" then
  T:start"yum.present (modules/yum.lua)"
    do
      T:eq(cfg{ "-f", "test/yum_present.lua" }, true)
    end
  T:done(N)
  T:start"yum.absent (modules/yum.lua)"
    do
      T:eq(cfg{ "-f", "test/yum_absent.lua" }, true)
    end
  T:done(N)
  T:start"systemd.started (modules/systemd.lua)"
    do
      T:eq(cfg{ "-f", "test/systemd_started.lua"}, true)

    end
  T:done(N)
  T:start"systemd.restart (modules/systemd.lua)"
    do
      local ok, cmd = Cmd.pgrep{ "tuned" }
      local first = cmd.stdout[1]
      T:yes(ok)
      T:eq(cfg{ "-f", "test/systemd_restart.lua" }, true)
      ok, cmd = Cmd.pgrep{ "tuned" }
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
      T:eq(cfg{ "-f", "test/systemd_reload.lua"}, true)
    end
  T:done(N)
  T:start"systemd.stopped (modules/systemd.lua)"
    do
      T:eq(cfg{ "-f", "test/systemd_stopped.lua"}, true)
      T:eq(Cmd.pgrep{ "tuned" }, nil)
    end
  T:done(N)
  T:start"systemd.enabled (modules/systemd.lua)"
    do
      T:eq(cfg{ "-f", "test/systemd_enabled.lua"}, true)
    end
  T:done(N)
  T:start"systemd.disabled (modules/systemd.lua)"
    do
      T:eq(cfg{ "-f", "test/systemd_disabled.lua"}, true)
    end
  T:done(N)
end

if osfamily == "openwrt" then
  T:start"opkg.present (modules/opkg.lua)"
    do
      T:eq(cfg{ "-f", "test/opkg_present.lua"}, true)
    end
  T:done(N)
  T:start"opkg.absent (modules/opkg.lua)"
    do
      T:eq(cfg{ "-f", "test/opkg_absent.lua"}, true)
    end
  T:done(N)
  T:start"sysvinit.started (modules/sysvinit.lua)"
    do
      T:eq(cfg{ "-f", "test/sysvinit_started.lua"}, true)
      T:eq(Cmd.pgrep{ "uhttpd" }, true)
    end
  T:done(N)
  T:start"sysvinit.restart (modules/sysvinit.lua)"
    do
      local ok, cmd = Cmd.pgrep{ "uhttpd" }
      local first = cmd.stdout[1]
      T:yes(ok)
      T:eq(cfg{ "-f", "test/sysvinit_restart.lua"}, true)
      ok, cmd = Cmd.pgrep{ "uhttpd" }
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
      T:eq(cfg{ "-f", "test/sysvinit_reload.lua"}, true)
    end
  T:done(N)
  T:start"sysvinit.stopped (modules/sysvinit.lua)"
    do
      T:eq(cfg{ "-f", "test/sysvinit_stopped.lua"}, true)
      T:no(Cmd.pgrep{ "uhttpd" })
    end
  T:done(N)
  T:start"sysvinit.enabled (modules/sysvinit.lua)"
    do
      T:eq(cfg{ "-f", "test/sysvinit_enabled.lua"}, true)
    end
  T:done(N)
  T:start"sysvinit.disabled (modules/sysvinit.lua)"
    do
      T:eq(cfg{ "-f", "test/sysvinit_disabled.lua"}, true)
    end
  T:done(N)
end

if osfamily == "gentoo" then
  T:start"portage.present (modules/portage.lua)"
    do
      T:eq(cfg{ "-f", "test/portage_present.lua"}, true)
    end
  T:done(N)
  T:start"portage.absent (modules/portage.lua)"
    do
      T:eq(cfg{ "-f", "test/portage_absent.lua"}, true)
    end
  T:done(N)
end

if osfamily == "alpine" then
  T:start"apk.present (modules/apk.lua)"
    do
      T:eq(cfg{ "-v", "-f", "test/apk_present.lua" }, true)
    end
  T:done(N)
  T:start"apk.absent (modules/apk.lua)"
    do
      T:eq(cfg{ "-v", "-f", "test/apk_absent.lua" }, true)
    end
  T:done(N)
end

if osfamily == "gentoo" or osfamily == "alpine" then
  T:start"openrc.started (modules/openrc.lua)"
    do
      T:eq(cfg{ "-f", "test/openrc_started.lua"}, true)
      T:eq(Cmd.pgrep{ "rsync" }, true)
    end
  T:done(N)
  T:start"openrc.restart (modules/openrc.lua)"
    do
      local ok, cmd = Cmd.pgrep{ "rsync" }
      local first = cmd.stdout
      T:yes(ok)
      T:eq(cfg{ "-f", "test/openrc_restart.lua"}, true)
      ok, cmd = Cmd.pgrep{ "rsync" }
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
      T:eq(cfg{ "-f", "test/openrc_reload.lua"}, true)
    end
  T:done(N)
  T:start"openrc.stopped (modules/openrc.lua)"
    do
      T:eq(cfg{ "-f", "test/openrc_stopped.lua"}, true)
      T:eq(Cmd.pgrep{ "rsync" }, nil)
    end
  T:done(N)
  T:start"openrc.add (modules/openrc.lua)"
    do
      T:eq(cfg{ "-f", "test/openrc_add.lua"}, true)
    end
  T:done(N)
  T:start"openrc.delete (modules/openrc.lua)"
    do
      T:eq(cfg{ "-f", "test/openrc_del.lua"}, true)
    end
  T:done(N)
end

T:start"file.attributes (modules/file.lua)"
  do
    local nobody = Ppwd.getpwnam("nobody")
    local nogroup = Pgrp.getgrnam("nogroup")
    T:eq(cfg{ "-f", "test/file_attributes1.lua"}, true)
    local stat = Psysstat.stat(testdir .. "file_attributes1")
    T:eq(stat.st_uid, nobody.pw_uid)
    T:eq(stat.st_gid, nogroup.gr_gid)
    T:eq(string.format("%o", stat.st_mode), "100600")
    T:yes(os.remove(testdir .. "file_attributes1"))
  end
T:done(N)

T:start"file.link (modules/file.lua)"
  do
    T:eq(cfg{ "-f", "test/file_link.lua"}, true)
    local stat = Psysstat.lstat(testdir .. "file_link")
    T:neq(Psysstat.S_ISLNK(stat.st_mode), 0)
    T:eq(Lc.execute("rm " .. testdir .. "file_link"), true)
  end
T:done(N)

T:start"file.hard (modules/file.lua)"
  do
    T:eq(cfg{ "-f", "test/file_hard.lua" }, true)
    local stat1 = Psysstat.stat(testdir .. "file_hard_src")
    local stat2 = Psysstat.stat(testdir .. "file_hard_link")
    T:eq(stat1.st_ino, stat2.st_ino)
    T:eq(Lc.execute("rm " .. testdir .. "file_hard_src"), true)
    T:eq(Lc.execute("rm " .. testdir .. "file_hard_link"), true)
  end
T:done(N)

T:start"file.directory (modules/file.lua)"
  do
    T:eq(cfg{ "-f", "test/file_directory.lua" }, true)
    local stat = Psysstat.stat(testdir .. "file_directory")
    T:neq(Psysstat.S_ISDIR(stat.st_mode), 0)
    T:yes(os.remove(testdir .. "file_directory"))
  end
T:done(N)

T:start"file.touch (modules/file.lua)"
  do
    T:eq(cfg{ "-f", "test/file_touch.lua"}, true)
    local stat = Psysstat.stat(testdir .. "file_touch")
    T:neq(Psysstat.S_ISREG(stat.st_mode), 0)
    T:yes(os.remove(testdir .. "file_touch"))
  end
T:done(N)

T:start"file.absent (modules/file.lua)"
  do
    T:eq(cfg{ "-f", "test/file_absent.lua" }, true)
    local stat = Psysstat.stat(testdir .. "file_absent")
    T:no(stat)
  end
T:done(N)

T:start"file.copy (modules/file.lua)"
  do
    T:eq(cfg{ "-f", "test/file_copy.lua" }, true)
    local _, ls = Cmd.ls{ "-1", testdir .. "file_copy_dest" }
    local stdout = table.concat(ls.stdout, "\n")
    T:yes(Lc.fwrite(testdir .. "file_copy.tmp", stdout))
    T:eq(crc(Lc.fopen("test/file_copy.out")), crc(Lc.fopen(testdir .. "file_copy.tmp")))
    T:eq(Cmd.rm{ "-r", testdir .. "file_copy_dest" }, true)
    T:eq(Cmd.rm{ "-r", testdir .. "file_copy_src" }, true)
    T:eq(Cmd.rm{ testdir .. "file_copy.tmp" }, true)
  end
T:done(N)

T:start"authorized_keys.present (modules/authorized_keys.lua)"
  do
    T:eq(cfg{ "-f", "test/authorized_keys_present.lua"}, true)
  end
T:done(N)

T:start"authorized_keys.absent (modules/authorized_keys.lua)"
  do
    T:eq(cfg{ "-f", "test/authorized_keys_absent.lua"}, true)
  end
T:done(N)

T:start"unarchive.unpack (modules/unarchive.lua)"
  do
    T:eq(cfg{ "-f", "test/unarchive_unpack.lua" }, true)
    T:yes(Psysstat.stat(testdir .. "unarchive_unpack.lua"))
    T:eq(Cmd.rm{ testdir .. "unarchive_unpack.lua"}, true)
  end
T:done(N)

if Px.binpath("git") then
  T:start"git.clone (modules/git.lua)"
    do
      T:eq(cfg{ "-f", "test/git_clone.lua" }, true)
      T:yes(Psysstat.stat(testdir .. "git/.git/config"))
    end
  T:done(N)

  T:start"git.pull (modules/git.lua)"
    do
      T:eq(cfg{ "-f", "test/git_pull.lua" }, true)
      T:eq(Cmd.rm{ "-r", testdir .. "git"}, true)
    end
  T:done(N)
end

T:start"sha256.verify (modules/sha256.lua)"
  do
    T:eq(cfg{ "-f", "test/sha256_verify.lua"}, true)
  end
T:done(N)

Lc.printf("\n  Summary: \n")
Lc.printf("    %s Passed\n", N.successes)
Lc.printf("    %s Failures\n\n", N.failures)
