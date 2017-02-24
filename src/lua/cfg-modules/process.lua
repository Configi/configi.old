--- Various process helpers on Linux compatible systems.
-- @module process
-- @author Eduardo Tongson <propolice@gmail.com>
-- @license MIT <http://opensource.org/licenses/MIT>
-- @added 2.0.0

local ENV, M, process = {}, {}, {}
local cfg = require"cfg-core.lib"
local lib = require"lib"
local dirent = require"posix.dirent"
local unistd = require"posix.unistd"
local signal = require"posix.signal"
local string = string
local cmd = lib.cmd
_ENV = ENV

-- We do not check if the PID of exe, cmdline and name are the same.
-- In some cases different PIDs can have the same exe symlink, cmdline string and Name in status.
local find_proc = function(exe, cmdline, name)
    local E, C, N
    local pid = dirent.dir("/proc")
    for n = 1, #pid do
        if string.find(pid[n], "%d+") then
            local proc_exe = unistd.readlink("/proc/"..pid[n].."/exe") or ""
            local proc_cmdline = lib.fopen("/proc/"..pid[n].."/cmdline") or ""
            local proc_name = lib.fopen("/proc/"..pid[n].."/status") or ""
            if E == nil then
                E = exe or proc_exe
                E = string.find(proc_exe, E, 1, true) and pid[n]
            end
            if C == nil then
                C = cmdline or proc_cmdline
                C = string.find(proc_cmdline, C, 1, true) and pid[n]
            end
            -- We are looking in the Name field so special case for a set name parameter.
            -- Plain string matching would match other fields.
            if N == nil then
                if name then
                    N = "Name:%s"..name
                    N = string.find(proc_name, N) and pid[n]
                else
                    N = true
                end
            end
        end
        if (E and C and N) then
            break
        end
    end
    -- First return value is NOT a boolean. The last evaluated pid[n] is not nil but not equal to true.
    return (E and C and N), E, C, N
end

--- Send a signal to a specified process.
-- Note: Can only be used as a handler.
-- @Subject Handler name (string)
-- @param signal signal to send eg. "SIGHUP"
-- @param exe the /proc/$pid/exe symlink
-- @param cmdline the string in /proc/$pid/cmdline
-- @param name the Name field in /proc/$pid/status
-- @usage process.signal"nginx-sighup"{
--     signal = "SIGHUP",
--     exe = "/usr/sbin/nginx"
-- }
function process.signal(S)
    M.parameters = {"signal", "exe", "cmdline", "name"}
    M.report = {
        repaired = "process.signal: Successfully sent signal to process.",
          failed = "process.signal: Error sending signal to process --",
         missing = "process.signal: Missing required parameter."
        }
    return function(P)
        P.handle = S
        local F, R = cfg.init(P, M)
        if not (P.exe or P.cmdline or P.name) or not P.signal then
            return F.result(P.handle, false, M.report.missing)
        end
        local _, exe, cmdline, name = find_proc(P.exe, P.cmdline, P.name)
        local kill, err
        -- Only send the signal once according to the order here.
        if P.exe then
            kill, err = signal.kill(exe, signal[P.signal])
        elseif P.cmdline then
            kill, err = signal.kill(cmdline, signal[P.signal])
        elseif P.name then
            kill, err = signal.kill(name, signal[P.signal])
        end
        if kill == 0 then
            return F.result(P.handle, true)
        else
            return F.result(P.handle, nil, M.report.failed .. err)
        end
    end
end

--- Check if a specified process is running.
-- You can pinpoint a process by also specifying the cmdline and name parameters.
-- @Subject executable where /proc/$pid/exe points to
-- @param cmdline string from /proc/$pid/cmdline
-- @param name Name field in /proc/$pid/status
-- @usage process.running("/usr/bin/rsyncd"){
--     notify_failed = "start-rsyncd"
-- }
function process.running(S)
    M.parameters = { "exe", "cmdline", "name" }
    M.report = {
          kept = "process.running: Process found.",
        failed = "process.running: Process not found"
    }
    return function(P)
        P.exe = S
        local F, R = cfg.init(P, M)
        return F.result(P.exe, find_proc(P.exe, P.cmdline, P.name))
    end
end

return process
