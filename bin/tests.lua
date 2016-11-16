local factid = require"factid"
local lib = require"lib"
local cmd = lib.cmd
local crc = require"crc32".crc32_string
local stat, pwd, grp = require"posix.sys.stat", require"posix.pwd", require"posix.grp"
local ct = require"cwtest"
local T, N=ct.new(), nil
local osfamily = factid.osfamily()
local testdir = "test/tmp/"
local cfg = cmd["bin/cfg"]

if not lib.is_dir(testdir) then
    stat.mkdir(testdir)
end

T:start"Lua tests"
    do
        local Lua = dofile("test/lua.lua")
        T:eq(Lua.sequence(), "12345")
        T:eq(Lua.ipairsnil(), "123")
        T:eq(Lua.forloopnil(), "1235")
        T:eq(Lua.nextsequence(), "1235")
        T:eq(Lua.multiplereturn(), "145")
        T:eq(Lua.updatetable1(), "12345")
        T:eq(Lua.updatetable2(), "12345")
        T:eq(Lua.mixedtable1(), "012")
        T:eq(Lua.mixedtable2(), "123")
    end
T:done(N)

T:start"debug test/core-debug.lua"
    do
        local debug = function(policy)
            local _, out = cfg{ "-f", policy }
            out = table.concat(out.stderr, "\n")
            T:eq(string.find(out, "TESTDEBUG", 1, true), 75)
        end
        debug"test/core-debug.lua"
    end
T:done(N)

T:start"log test/core-log.lua"
    do
        local log = function(policy)
            local log = "test/tmp/_test_configi.log"
            cfg{ "-f", policy }
            T:yes(stat.stat(log))
            os.remove(log)
        end
        log"test/core-log.lua"
    end
T:done(N)

T:start"fact test/core-fact.lua"
    do
        local fact = function(policy)
            local _, out = cfg{ "-f", policy }
            T:eq(out.code, 0)
        end
        fact"test/core-fact.lua"
    end
T:done(N)

T:start"test test/core-test.lua"
    do
        local test = function(policy)
            local tempname = testdir .. "core-test.txt"
            lib.fwrite(tempname, "test")
            cfg{ "-f", policy}
            T:eq(lib.fopen(tempname), "test")
            os.remove(tempname)
        end
        test"test/core-test.lua"
    end
T:done(N)

T:start"module test/core-module.lua"
    do
        local module = function(policy)
            T:eq(cfg{ "-f", policy }, true)
        end
        module"test/core-module.lua"
    end
T:done(N)

T:start"include test/core-include1.lua, test/core-include2.lua"
    do
        local include = function(first, second)
            local dir = testdir .. "CONFIGI_TEST_INCLUDE"
            cfg{ "-f", first }
            T:yes(lib.is_dir(dir))
            cfg{ "-f", second }
            T:no(stat.stat(dir))
        end
        include("test/core-include1.lua", "test/core-include2.lua")
    end
T:done(N)

T:start"handler,notify test/core-handler.lua"
    do
        local h = function(handler, handler_include, handler2)
            cfg{ "-f", handler }
            local _, r = cfg{"-v", "-f", handler_include }
            T:no(lib.find_string(r.stdout, "core-handler-file"))
            local xfile, file = "test/tmp/core-handler2-xfile", "test/tmp/core-handler2-file"
            cfg{ "-g", "testhandle", "-f",  handler2 }
            T:no(stat.stat(xfile))
            T:yes(stat.stat(file))
            os.remove(file)
        end
        h("test/core-handler.lua", "test/core-handler_include.lua", "test/core-handler2.lua")
    end
T:done(N)

T:start"context test/core-context.lua"
    do
        cfg{ "-f", "test/core-context.lua"}
        T:no(stat.stat("test/tmp/core-context"))
    end
T:done(N)

T:start"comment test/core-comment.lua"
    do
        local comment = function(policy)
            local _, out = cfg{ "-v", "-f", policy }
            out = table.concat(out.stderr, "\n")
            T:eq(string.find(out, "TEST COMMENT", 1, true), 55)
        end
        comment"test/core-comment.lua"
    end
T:done(N)

T:start"list test/core-list.lua"
    do
        local list = function(policy)
            T:yes(stat.mkdir(testdir .. "core-list.xxx"))
            T:yes(stat.mkdir(testdir .. "core-list.yyy"))
            cfg{ "-f", policy }
            T:no(lib.is_dir(testdir .. "core-list.xxx"))
            T:no(lib.is_dir(testdir .. "core-list.yyy"))
        end
        list"test/core-list.lua"
    end
T:done(N)

T:start"each test/core-each.lua"
    do
        local each = function(policy)
	    cmd.mkdir{ "-p", testdir .. "core-each.xxx" }
	    cmd.mkdir{ "-p", testdir .. "core-each.yyy" }
            cfg{ "-f", policy }
            T:no(lib.is_dir(testdir .. "core-each.xxx"))
            T:no(lib.is_dir(testdir .. "core-each.yyy"))
        end
        each"test/core-each.lua"
    end
T:done(N)

T:start"hostname.set (modules/hostname.lua)"
    do
        if lib.bin_path"hostnamectl" then
            -- XXX duplicate copy from module.hostname
            local current_hostnames = function()
                local _, hostnamectl = cmd.hostnamectl{}
                local hostnames = {
                    Pretty = false,
                    Static = false,
                    Transient = false
                }
                local _k, _v
                for ln = 1, #hostnamectl.stdout do
                    for type, _ in next, hostnames do
                        _k, _v = string.match(hostnamectl.stdout[ln], "^%s*(" .. type .. " hostname):%s([%g%s]*)$")
                        if _k then
                            -- New keys that starts with lower case characters.
                            hostnames[string.lower(type)] = _v
                        end
                    end
                end
                return hostnames
            end
            local hostnames = current_hostnames()
            local before = {
                transient = hostnames.transient,
                pretty = hostnames.pretty,
                static = hostnames.static
            }
            local hostname = function(policy)
                cfg{ "-f", policy }
                local after = current_hostnames()
                T:eq(after.transient, "testing.configi.org")
                T:eq(after.pretty, "Testing Configi")
                T:eq(after.static, "static")
                for type, hostname in next, before do
                    cmd.hostnamectl{ "--" .. type, "set-hostname", hostname }
                end
            end
            hostname"test/hostname_set.lua"
        else
            local _, out = cmd.hostname{}
            local before = out.stdout[1]
            local hostname = function(policy)
                cfg{ "-f", policy }
                _, out = cmd.hostname{}
                T:eq(out.stdout[1], "testing")
                cmd.hostname{ before }
                _, out = cmd.hostname{}
                T:eq(out.stdout[1], before)
            end
            hostname"test/hostname_set.lua"
        end
    end
T:done(N)

T:start"cron.present (modules/cron.lua) test/cron_present.lua"
    do
        local cron = function(policy)
            -- Restore root crontab file on OpenWRT
            if osfamily == "openwrt" then
                T:yes(cmd.touch{ "/etc/crontabs/root" })
            end
            cmd.crontab{ "-r" }
            cmd.crontab{ "-d" }
            cfg{ "-f", policy }
            local _, r = cmd.crontab{ "-l" }
            local t = lib.filter_tbl_value(r.stdout, "^#[%C]+") -- Remove comments
            t[#t] = t[#t] .. "\n" -- Add trailing newline
            T:eq(crc(lib.fopen("test/cron_present.out")), crc(table.concat(t, "\n")))
            cmd.crontab{ "-r" }
            cmd.crontab{ "-d" }
        end
        cron"test/cron_present.lua"
    end
T:done(N)

T:start"template.render (modules/template.lua) test/template_render.lua"
    do
        local template = function(policy)
            local out = testdir .. "template_render_test.txt"
            cfg{ "-f", policy }
            T:eq(crc(lib.fopen("test/template_render.txt")), crc(lib.fopen(out)))
            os.remove(out)
        end
        template"test/template_render.lua"
    end
T:done(N)

T:start"template.insert_line (modules/template.lua) test/template_insert.lua"
    do
        local template = function(p1, p2)
            local out = testdir .. "template_insert_test.txt"
            cfg{ "-f", "test/template_insert.lua"}
            T:eq(crc(lib.fopen("test/template_insert.txt")), crc(lib.fopen(out)))
            cfg{ "-f", "test/template_insert_inserts.lua"}
            T:eq(crc(lib.fopen("test/template_insert.txt")), crc(lib.fopen(out)))
            os.remove(out)
        end
        template("test/template_insert.lua", "test/template_insert_inserts.lua")
    end
T:done(N)

T:start"template.insert_line_before (modules/template.lua) test/template_insert_line_before.lua"
    do
        local template = function(policy)
            cfg{ "-f", policy }
            T:eq(crc(lib.fopen("test/template_insert_line_before.txt")),
                crc(lib.fopen("test/tmp/template_insert_line_test.txt")))
        end
        template"test/template_insert_line_before.lua"
    end
T:done(N)

T:start"template.insert_line_after (modules/template.lua) test/template_insert_line_after.lua"
    do
        local template = function(policy)
            cfg{ "-f", policy }
            T:eq(crc(lib.fopen("test/template_insert_line_after.txt")),
                crc(lib.fopen("test/tmp/template_insert_line_test.txt")))
            cmd.rm { "-f", testdir .. "template_insert_line_test.txt" }
            cmd.rm { "-f", testdir .. "._configi_template_insert_line_test.txt" }
        end
        template"test/template_insert_line_after.lua"
    end
T:done(N)

T:start"template.remove_line (modules/template.lua) test/template_remove_line.lua"
    do
        local template = function(policy)
            cfg{ "-f", policy }
            T:eq(crc(lib.fopen("test/template_remove_line.txt")),
                crc(lib.fopen("test/tmp/template_remove_line_test.txt")))
            cmd.rm { "-f", testdir .. "template_remove_line_test.txt" }
        end
        template"test/template_remove_line.lua"
    end
T:done(N)

T:start"shell.command (modules/shell.lua)"
    do
        local shell = function(policy)
            cfg{ "-f", policy }
            T:yes(lib.is_file(testdir .. "shell_command.txt"))
            os.remove(testdir .. "shell_command.txt")
        end
        shell"test/shell_command.lua"
    end
T:done(N)

T:start"shell.system (modules/shell.lua)"
    do
        local shell = function(policy)
            cfg{ "-f", policy }
            T:yes(lib.is_file(testdir .. "shell_system.txt"))
            os.remove(testdir .. "shell_system.txt")
        end
        shell"test/shell_system.lua"
    end
T:done(N)

T:start"shell.popen (modules/shell.lua)"
    do
        local shell = function(p1, p2)
            cfg{ "-f", p1 }
            T:yes(lib.is_file(testdir .. "shell_popen.txt"))
            os.remove(testdir .. "shell_popen.txt")
            cmd.touch{ testdir .. "The wizard quickly jinxed the gnomes before they vaporized" }
            T:eq(cfg{ "-f", p2 }, true)
            os.remove(testdir .. "The wizard quickly jinxed the gnomes before they vaporized")
        end
        shell("test/shell_popen.lua", "test/shell_popen_expects.lua")
    end
T:done(N)

T:start"shell.popen3 (modules/shell.lua)"
    do
        local shell = function(p1, p2, p3)
            T:eq(cfg{ "-f", p1 }, true)
            T:eq(cfg{ "-f", p2 }, true)
            T:eq(cfg{ "-f", p3 }, true)
        end
        shell("test/shell_popen3_stdin.lua", "test/shell_popen3_stdout.lua", "test/shell_popen3_stderr.lua")
    end
T:done(N)

T:start"user.present (modules/user.lua)"
    do
        local user = function(policy)
            T:eq(cfg{ "-f", policy }, true)
        end
        user"test/user_present.lua"
    end
T:done(N)

T:start"user.absent (modules/user.lua)"
    do
        local user = function(policy)
            T:eq(cfg{ "-f", policy }, true)
        end
        user"test/user_absent.lua"
    end
T:done(N)

if lib.bin_path"apt-get" then
    T:start"apt.present (modules/apt.lua)"
        do
            local apt = function(policy)
                T:eq(cfg{ "-f", policy }, true)
            end
            apt"test/apt_present.lua"
        end
    T:done(N)
    T:start"apt.absent (modules/apt.lua)"
        do
            local apt = function(policy)
                T:eq(cfg{ "-f", policy }, true)
            end
            apt"test/apt_absent.lua"
        end
    T:done(N)
end

if lib.bin_path"yum" then
    T:start"yum.present (modules/yum.lua)"
        do
            local yum = function(policy)
                T:eq(cfg{ "-f", policy }, true)
            end
            yum"test/yum_present.lua"
        end
    T:done(N)
    T:start"yum.absent (modules/yum.lua)"
        do
            local yum = function(policy)
                T:eq(cfg{ "-f", policy }, true)
            end
            yum"test/yum_absent.lua"
        end
    T:done(N)
end

if lib.bin_path"systemctl" then
    T:start"systemd.started (modules/systemd.lua)"
        do
            local systemd = function(policy)
                T:eq(cfg{ "-f", policy }, true)
            end
            systemd"test/systemd_started.lua"
        end
    T:done(N)
    T:start"systemd.restart (modules/systemd.lua)"
        do
            local systemd = function(policy)
                local ok, pgrep = cmd.pgrep{ "lighttpd" }
		        T:yes(ok)
                local first = pgrep.stdout[1]
                cfg{ "-f", policy }
                ok, pgrep = cmd.pgrep{ "lighttpd" }
		        T:yes(ok)
                local second = pgrep.stdout[1]
                if first == second then
                    ok = false
                end
                T:yes(ok)
            end
            systemd"test/systemd_restart.lua"
        end
    T:done(N)
    T:start"systemd.reload (modules/systemd.lua)"
        do
            local systemd = function(policy)
                T:eq(cfg{ "-f", policy }, true)
            end
            systemd"test/systemd_reload.lua"
        end
    T:done(N)
    T:start"systemd.stopped (modules/systemd.lua)"
        do
            local systemd = function(policy)
                cfg{ "-f", policy }
                T:eq(cmd.pgrep{ "lighttpd" }, nil)
            end
            systemd"test/systemd_stopped.lua"
        end
    T:done(N)
    T:start"systemd.enabled (modules/systemd.lua)"
        do
            local systemd = function(policy)
                T:eq(cfg{ "-f", policy }, true)
            end
            systemd"test/systemd_enabled.lua"
        end
    T:done(N)
    T:start"systemd.disabled (modules/systemd.lua)"
        do
            local systemd = function(policy)
                T:eq(cfg{ "-f", policy }, true)
            end
            systemd"test/systemd_disabled.lua"
        end
    T:done(N)
end

if osfamily == "openwrt" then
    T:start"opkg.present (modules/opkg.lua)"
        do
            local opkg = function(policy)
                T:eq(cfg{ "-f", policy }, true)
            end
            opkg"test/opkg_present.lua"
        end
    T:done(N)
    T:start"opkg.absent (modules/opkg.lua)"
        do
            local opkg = function(policy)
                T:eq(cfg{ "-f", policy }, true)
            end
            opkg"test/opkg_absent.lua"
        end
    T:done(N)
    T:start"sysvinit.started (modules/sysvinit.lua)"
        do
            local sysvinit = function(policy)
                cfg{ "-f", policy }
                T:eq(cmd.pgrep{ "uhttpd" }, true)
            end
            sysvinit"test/sysvinit_started.lua"
        end
    T:done(N)
    T:start"sysvinit.restart (modules/sysvinit.lua)"
        do
            local sysvinit = function(policy)
                local ok, cmd = cmd.pgrep{ "uhttpd" }
                local first = cmd.stdout[1]
                T:yes(ok)
                cfg{ "-f", policy }
                ok, cmd = cmd.pgrep{ "uhttpd" }
                local second = cmd.stdout[1]
                T:yes(ok)
                if first == second then
                    ok = false
                end
                T:yes(ok)
            end
            sysvinit"test/sysvinit_restart.lua"
        end
    T:done(N)
    T:start"sysvinit.reload (modules/sysvinit.lua)"
        do
            local sysvinit = function(policy)
                T:eq(cfg{ "-f", policy }, true)
            end
            sysvinit"test/sysvinit_reload.lua"
        end
    T:done(N)
    T:start"sysvinit.stopped (modules/sysvinit.lua)"
        do
            local sysvinit = function(policy)
                cfg{ "-f", policy }
                T:no(cmd.pgrep{ "uhttpd" })
            end
            sysvinit"test/sysvinit_stopped.lua"
        end
    T:done(N)
    T:start"sysvinit.enabled (modules/sysvinit.lua)"
        do
            local sysvinit = function(policy)
                T:eq(cfg{ "-f", policy }, true)
            end
            sysvinit"test/sysvinit_enabled.lua"
        end
    T:done(N)
    T:start"sysvinit.disabled (modules/sysvinit.lua)"
        do
            local sysvinit = function(policy)
                T:eq(cfg{ "-f", policy }, true)
            end
            sysvinit"test/sysvinit_disabled.lua"
        end
    T:done(N)
end

if osfamily == "gentoo" then
    T:start"portage.present (modules/portage.lua)"
        do
            local portage = function(policy)
                T:eq(cfg{ "-f", policy }, true)
            end
            portage"test/portage_present.lua"
        end
    T:done(N)
    T:start"portage.absent (modules/portage.lua)"
        do
            local portage = function(policy)
                T:eq(cfg{ "-f", policy }, true)
            end
            portage"test/portage_absent.lua"
        end
    T:done(N)
end

if osfamily == "alpine" then
    T:start"apk.present (modules/apk.lua)"
        do
            local apk = function(policy)
                T:eq(cfg{ "-v", "-f", policy }, true)
            end
            apk"test/apk_present.lua"
        end
    T:done(N)
    T:start"apk.absent (modules/apk.lua)"
        do
            local apk = function(policy)
                T:eq(cfg{ "-v", "-f", policy }, true)
            end
            apk"test/apk_absent.lua"
        end
    T:done(N)
end

if osfamily == "gentoo" or osfamily == "alpine" then
    T:start"openrc.started (modules/openrc.lua)"
        do
            local openrc = function(policy)
                cfg{ "-f", policy }
                T:eq(cmd.pgrep{ "rsync" }, true)
            end
            openrc"test/openrc_started.lua"
        end
    T:done(N)
    T:start"openrc.restart (modules/openrc.lua)"
        do
            local openrc = function(policy)
                local ok, res = cmd.pgrep{ "rsync" }
                local first = res.stdout
                T:yes(ok)
                cfg{ "-f", policy }
                ok, res = cmd.pgrep{ "rsync" }
                local second = res.stdout
                T:yes(ok)
                if first == second then
                    ok = false
                end
                T:yes(ok)
            end
            openrc"test/openrc_restart.lua"
        end
    T:done(N)
    T:start"openrc.reload (modules/openrc.lua)"
        do
            local openrc = function(policy)
                T:eq(cfg{ "-f", policy }, true)
            end
            openrc"test/openrc_reload.lua"
        end
    T:done(N)
    T:start"openrc.stopped (modules/openrc.lua)"
        do
            local openrc = function(policy)
                cfg{ "-f", policy }
                T:eq(cmd.pgrep{ "rsync" }, nil)
            end
            openrc"test/openrc_stopped.lua"
        end
    T:done(N)
    T:start"openrc.add (modules/openrc.lua)"
        do
            local openrc = function(policy)
                T:eq(cfg{ "-f", policy }, true)
            end
            openrc"test/openrc_add.lua"
        end
    T:done(N)
    T:start"openrc.delete (modules/openrc.lua)"
        do
            local openrc = function(policy)
                T:eq(cfg{ "-f", policy }, true)
            end
            openrc"test/openrc_del.lua"
        end
    T:done(N)
end

T:start"file.attributes (module/file.lua)"
    do
        local attributes = function(policy)
            local nobody = pwd.getpwnam("nobody")
            local nogroup = grp.getgrnam("nobody")
            cfg{ "-f", policy }
            local stat1 = stat.stat(testdir .. "file_attributes1")
            T:eq(stat1.st_uid, nobody.pw_uid)
            T:eq(stat1.st_gid, nogroup.gr_gid)
            T:eq(string.format("%o", stat1.st_mode), "100600")
            os.remove(testdir .. "file_attributes1")
            local stat2 = stat.stat(testdir .. "file_attributes2")
            T:eq(string.format("%o", stat2.st_mode), "100755")
            os.remove(testdir .. "file_attributes2")
            local stat3 = stat.stat(testdir .. "file_attributes3")
            T:eq(string.format("%o", stat3.st_mode), "100444")
            os.remove(testdir .. "file_attributes3")

        end
        attributes"test/file_attributes.lua"
    end
T:done(N)

T:start"file.link (module/file.lua)"
        do
                local link = function(policy)
                        T:eq(cfg{ "-f", policy}, true)
                        local info = stat.lstat(testdir .. "file_link")
                        T:neq(stat.S_ISLNK(info.st_mode), 0)
                        T:eq(lib.execute("rm -f " .. testdir .. "file_link"), true)
                end
                link"test/file_link.lua"
        end
T:done(N)

T:start"file.hard (module/file.lua)"
        do
                local hard = function(policy)
                        T:eq(cfg{ "-f", policy}, true)
                        local stat1 = stat.stat(testdir .. "file_hard_src")
                        local stat2 = stat.stat(testdir .. "file_hard_link")
                        T:eq(stat1.st_ino, stat2.st_ino)
                        T:eq(lib.execute("rm -f " .. testdir .. "file_hard_src"), true)
                        T:eq(lib.execute("rm -f " .. testdir .. "file_hard_link"), true)
                end
                hard"test/file_hard.lua"
        end
T:done(N)

T:start"file.directory (module/file.lua)"
        do
                local directory = function(policy)
                        T:eq(cfg{ "-f", policy }, true)
                        local info = stat.stat(testdir .. "file_directory")
                        T:neq(stat.S_ISDIR(info.st_mode), 0)
                        T:yes(os.remove(testdir .. "file_directory"))
                end
                directory"test/file_directory.lua"
        end
T:done(N)

T:start"file.touch (module/file.lua)"
        do
                local touch = function(policy)
                        T:eq(cfg{ "-f", policy }, true)
                        local info = stat.stat(testdir .. "file_touch")
                        T:neq(stat.S_ISREG(info.st_mode), 0)
                        T:yes(os.remove(testdir .. "file_touch"))
                end
                touch"test/file_touch.lua"
        end
T:done(N)

T:start"file.absent (module/file.lua)"
        do
                local absent = function(policy)
                        T:eq(cfg{ "-f", policy }, true)
                        T:no(stat.stat(testdir .. "file_absent"))
                end
                absent"test/file_absent.lua"
        end
T:done(N)

T:start"file.copy (module/file.lua)"
        do
                local copy = function(policy)
                        T:eq(cfg{ "-f", policy }, true)
                        local _, ls = cmd.ls{ "-1", testdir .. "file_copy_dest" }
                        local stdout = table.concat(ls.stdout, "\n")
                        T:yes(lib.fwrite(testdir .. "file_copy.tmp", stdout))
                        T:eq(crc(lib.fopen("test/file_copy.out")), crc(lib.fopen(testdir .. "file_copy.tmp")))
                        T:eq(cmd.rm{ "-rf", testdir .. "file_copy_dest" }, true)
                        T:eq(cmd.rm{ "-rf", testdir .. "file_copy_src" }, true)
                        T:eq(cmd.rm{ "-f", testdir .. "file_copy.tmp" }, true)
                end
                copy"test/file_copy.lua"
        end
T:done(N)

T:start"authorized_keys.present (modules/authorized_keys.lua)"
    do
        local authorized_keys = function(policy)
            T:eq(cfg{ "-f", policy }, true)
        end
        authorized_keys"test/authorized_keys_present.lua"
    end
T:done(N)

T:start"authorized_keys.absent (modules/authorized_keys.lua)"
    do
        local authorized_keys = function(policy)
            T:eq(cfg{ "-f", policy }, true)
        end
        authorized_keys"test/authorized_keys_absent.lua"
    end
T:done(N)

T:start"unarchive.unpack (modules/unarchive.lua)"
    do
        local unarchive = function(policy)
            cfg{ "-f", "test/unarchive_unpack.lua" }
            T:yes(stat.stat(testdir .. "unarchive_unpack.lua"))
            cmd.rm{ "-f", testdir .. "unarchive_unpack.lua"}
        end
        unarchive"test/unarchive_unpack.lua"
    end
T:done(N)

if lib.bin_path("git") then
    T:start"git.clone (modules/git.lua)"
        do
            local git = function(policy)
                cmd.rm{ "-rf", testdir .. "git" }
                cfg{ "-f", policy }
                T:yes(stat.stat(testdir .. "git/.git/config"))
            end
            git"test/git_clone.lua"
        end
    T:done(N)

    T:start"git.pull (modules/git.lua)"
        do
            local git = function(policy)
                local _, out = cfg{ "-vf", policy }
                out = table.concat(out.stderr, "\n")
                T:eq(string.find(out, "Already up-to-date.", 1, true), 78)
            end
            git"test/git_pull.lua"
        end
    T:done(N)
end

T:start"sha256.verify (modules/sha256.lua)"
    do
        local sha256 = function(policy)
            T:eq(cfg{ "-f", policy }, true)
        end
        sha256"test/sha256_verify.lua"
    end
T:done(N)

T:start"iptables.append (modules/iptables.lua)"
    do
        local iptables = function(policy)
            cfg{ "-f", policy }
            local a = lib.str_to_tbl"_ INPUT -s 6.6.6.6/32 -p tcp -m tcp --sport 31337 --dport 31337 -m comment --comment 'Configi' -j ACCEPT"
            a[1] = "-A"
            T:eq(cmd.iptables(a), true)
            a[1] = "-D"
            T:eq(cmd.iptables(a), true)
            cmd.iptables{ "-F" }
        end
        iptables"test/iptables_append.lua"
    end
T:done(N)

T:start"iptables.disable (modules/iptables.lua)"
    do
        local iptables = function(p1, p2)
            cfg{ "-f", p1 }
            local _, res = cmd.iptables{ "--list-rules" }
            T:eq(#res.stdout, 4)
            cfg{ "-f", p2 }
            _, res = cmd.iptables{ "--list-rules" }
            T:eq(#res.stdout, 3)
        end
        iptables("test/iptables_append.lua", "test/iptables_disable.lua")
    end
T:done(N)

T:start"make.install (modules/make.lua)"
    do
        local make = function(policy)
            cfg{ "-f", policy }
            T:eq(cmd.rm{ "-f", "test/tmp/root/bin/exe" }, true)
            T:eq(cmd.rm{ "-r", "-f", "test/tmp/root" }, true)
            T:eq(cmd.rm{ "-r", "-f", "test/tmp/make_install" }, true)
        end
        make"test/make_install.lua"
    end
T:done(N)

--c.printf("\n  Summary: \n")
--c.printf("        %s Passed\n", N.successes)
--c.printf("        %s Failures\n\n", N.failures)
