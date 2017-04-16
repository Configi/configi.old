--- Text file line editing.
-- @module edit
-- @author Eduardo Tongson <propolice@gmail.com>
-- @license MIT <http://opensource.org/licenses/MIT>
-- @added 2.0.0

local ENV, M, edit = {}, {}, {}
local table, os, string, require =
      table, os, string, require
local cfg = require"cfg-core.lib"
local lib = require"lib"
local stat = require"posix.sys.stat"
local cmd = lib.cmd
_ENV = ENV

M.required = { "path" }
M.alias = {}
M.alias.line = { "content" }
M.alias.pattern = { "match" }

-- XXX: Duplicated in the template module
local write = function(F, P)
    -- ignore P.diff if diffutils is not found
    if not lib.bin_path"diff" then P.diff = false end
    if (P.debug or P.test) and P.diff then
        local temp = os.tmpname()
        if lib.awrite(temp, P._input, 384) then
            local dtbl = {}
            local res, diff = cmd.diff{ "-N", "-a", "-u", P.path, temp }
            os.remove(temp)
            if res then
                return F.kept(P.path)
            else
                for n = 1, #diff.stdout do
                   dtbl[n] = string.match(diff.stdout[n], "[%g%s]+") or ""
                end
                F.msg(P.path, "Showing changes", 0, 0,
                    string.format("Diff:%s%s%s", "\n\n", table.concat(dtbl, "\n"), "\n"))
            end
        else
            return F.result(P.path)
        end
    end
    return F.result(P.path, lib.awrite(P.path, P._input, P.mode))
end

--- Insert lines into an existing file.
-- @Subject path of text file to modify
-- @param line to insert [REQUIRED] [ALIAS: content]
-- @param inserts a line (string) if found, skips the operation
-- @param pattern line is added before or after this pattern [ALIAS: match]
-- @param plain turn on or off pattern matching facilities [DEFAULT: "yes", true]
-- @param before [DEFAULT: "no", false]
-- @param after [DEFAULT: "yes", true]
-- @usage edit.insert_line("/etc/sysctl.conf"){
--     pattern = "# http://cr.yp.to/syncookies.html",
--     content = "net.ipv4.tcp_syncookies = 1",
--       after = true,
--      plain  = true
-- }
function edit.insert_line(S)
    M.parameters = { "diff", "line", "plain", "pattern", "before_pattern", "after_pattern", "inserts" }
    M.report = {
        repaired = "edit.insert_line: Successfully inserted line.",
        kept = "edit.insert_line: Insert cancelled, found a matching line.",
        failed = "edit.insert_line: Error inserting line.",
        missing = "edit.insert_line: Can't access or missing file."
    }
    return function(P)
        P.path = S
        local F, R = cfg.init(P, M)
        if R.kept then
            return F.kept(P.path)
        end
        P.plain = P.plain or true
        local inserts, line, pattern
        if not P.plain then
            inserts = lib.escape_pattern(P.inserts)
            line = lib.escape_pattern(P.line)
            pattern = lib.escape_pattern(P.pattern)
        else
            inserts = P.inserts
            line = P.line
            pattern = P.pattern
        end
        local file = lib.file_to_tbl(P.path)
        if not file then
            return F.result(P.path, nil, M.report.missing)
        end
        P.mode = stat.stat(P.path).st_mode
        if P.inserts then
            if lib.find_string(file, inserts, P.plain) then
                return F.kept(P.path)
            end
        end
        if not P.pattern then
            if lib.find_string(file, line, P.plain) then
                return F.kept(P.path)
            else
                file[#file + 1] = P.line .. "\n"
            end
        else
            local x, n, nf = 1, 1, #file
            if P.before_pattern then -- after_pattern "yes" is default
                x = 0
            end
            repeat
                if string.find(file[n], pattern, 1, P.plain) then
                    table.insert(file, n + x, P.line .. "\n")
                    nf = nf + 1
                    n = n + 2
                else
                    n = n + 1
                end
            until n == nf
        end
        P._input = table.concat(file)
        return write(F, P, R)
    end
end

--- Remove lines from an existing file.
-- @Subject path of text file to modify
-- @param pattern text pattern to remove [REQUIRED] [ALIAS: match]
-- @param plain turn on or off pattern matching facilities [DEFAULT: "yes"]
-- @usage edit.remove_line("/etc/sysctl.conf"){
--     match = "net.ipv4.ip_forward = 1",
--     plain = true
-- }
function edit.remove_line(S)
    M.parameters = { "pattern", "plain", "diff" }
    M.report = {
        repaired = "edit.remove_line: Successfully removed line.",
            kept = "edit.remove_line: Line not found.",
          failed = "edit.remove_line: Error removing line.",
         missing = "edit.remove_line: Can't access or missing file."
    }
    return function(P)
        P.path = S
        local F, R = cfg.init(P, M)
        if R.kept then
            return F.kept(P.path)
        end
        P.plain = P.plain or true
        local pattern
        if not P.plain then
            pattern = lib.escape_pattern(P.pattern)
        else
            pattern = P.pattern
        end
        local file = lib.file_to_tbl(P.path)
        if not file then
            return F.result(P.path, nil, M.report.missing)
        end
        P.mode = stat.stat(P.path).st_mode
        if not lib.find_string(file, pattern, P.plain) then
            return F.kept(P.path)
        end
        P._input = table.concat(lib.filter_tbl_value(file, pattern, P.plain))
        return write(F, P, R)
    end
end

return edit
