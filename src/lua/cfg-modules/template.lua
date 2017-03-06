--- Render a template.
-- @module template
-- @author Eduardo Tongson <propolice@gmail.com>
-- @license MIT <http://opensource.org/licenses/MIT>
-- @added 0.9.0

local ENV, M, template = {}, {}, {}
local io, load, tonumber, pcall, table, os, string, require =
      io, load, tonumber, pcall, table, os, string, require
local cfg = require"cfg-core.lib"
local lib = require"lib"
local crc = require"crc32"
local stat = require"posix.sys.stat"
local cmd = lib.cmd
_ENV = ENV

M.required = { "path" }
M.alias = {}
M.alias.src = { "template" }
M.alias.lua = { "data" }
M.alias.table = { "view" }
M.alias.line = { "text" }
M.alias.pattern = { "match" }

local write = function(F, P, R)
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

--- Render a template.
-- @Subject output file
-- @Note Requires the diffutils package for the diff parameter to work
-- @param src source template [REQUIRED] [ALIAS: template]
-- @param table [REQUIRED] [ALIAS: view]
-- @param lua [ALIAS: data]
-- @param mode mode bits for output file [DEFAULT: "0600"]
-- @param diff show diff [CHOICES: "yes","no"]
-- @usage template.render("/etc/something/config")
--     template: "/etc/something/config.template"
--     view: "view_model"
--     data: "/etc/something/config.lua"
function template.render(S)
    M.parameters = { "src", "lua", "table", "mode", "diff" }
    M.report = {
          repaired = "template.render: Successfully rendered textfile.",
              kept = "template.render: No difference detected, not overwriting existing destination.",
            failed = "template.render: Error rendering textfile.",
        missingsrc = "template.render: Can't access or missing source file.",
        missinglua = "template.render: Can't access or missing lua file."
    }
    return function(P)
        P.path = S
        local F, R = cfg.init(P, M)
        P.mode = P.mode or "0600"
        P.mode = tonumber(P.mode, 8)
        local ti = F.open(P.src)
        if not ti then
            return F.result(P.src, nil, M.report.missingsrc)
        end
        local lua = F.open(P.lua)
        if not lua then
            return F.result(P.lua, nil, M.report.missinglua)
        end
        local env = { require = require }
        local tbl
        local ret, chunk, err = pcall(load, lua, lua, "t", env)
        if ret and chunk then
            chunk()
            tbl = env[P.table]
        else
            return F.result(P.src, nil, err)
        end
        P._input = lib.sub(ti, tbl)
        if stat.stat(P.path) then
            do -- compare P.path and rendered text
                local i
                for b in io.lines(P.path, 2^12) do
                    if i == nil then
                        i = crc.crc32_string(b)
                    else
                        i = crc.crc32(b, crc.crc32(i))
                    end
                end
                if i == crc.crc32_string(P._input) then
                    return F.kept(P.path)
                end
            end
        end
        return write(F, P, R)
    end
end

--- Insert lines into an existing file.
-- @Subject path of text file to modify
-- @param line text to insert [REQUIRED] [ALIAS: text]
-- @param inserts a line (string) if found, skips the operation
-- @param pattern line is added before or after this pattern [ALIAS: match]
-- @param plain turn on or off pattern matching facilities [CHOICES: "yes","no"] [DEFAULT: "yes"]
-- @param before [CHOICES: "yes","no"] [DEFAULT: "no"]
-- @param after [CHOICES: "yes","no"] [DEFAULT: "yes"]
-- @usage template.insert_line("/etc/sysctl.conf")
--     pattern: "# http://cr.yp.to/syncookies.html"
--     text: "net.ipv4.tcp_syncookies = 1"
--     after: "true"
--     plain: "true"
function template.insert_line(S)
    M.parameters = { "diff", "line", "plain", "pattern", "before", "after", "inserts" }
    M.report = {
        repaired = "template.insert_line: Successfully inserted line.",
        kept = "template.insert_line: Insert cancelled, found a matching line.",
        failed = "template.insert_line: Error inserting line.",
        missing = "template.insert_line: Can't access or missing file."
    }
    return function(P)
        P.path = S
        local F, R = cfg.init(P, M)
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
            if P.before then -- after "yes" is default
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
-- @param plain turn on or off pattern matching facilities [CHOICES: "yes","no"] [DEFAULT: "yes"]
-- @usage template.remove_line("/etc/sysctl.conf")
--     match: "net.ipv4.ip_forward = 1"
--     plain: "true"
function template.remove_line(S)
    M.parameters = { "pattern", "plain", "diff" }
    M.report = {
        repaired = "template.remove_line: Successfully removed line.",
            kept = "template.remove_line: Line not found.",
          failed = "template.remove_line: Error removing line.",
         missing = "template.remove_line: Can't access or missing file."
    }
    return function(P)
        P.path = S
        local F, R = cfg.init(P, M)
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

return template
