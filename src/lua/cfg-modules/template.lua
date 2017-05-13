--- Render a template.
-- @module template
-- @author Eduardo Tongson <propolice@gmail.com>
-- @license MIT <http://opensource.org/licenses/MIT>
-- @added 0.9.0

local ENV, M, template = {}, {}, {}
local ipairs, io, tonumber, table, os, string, require =
      ipairs, io, tonumber, table, os, string, require
local cfg = require"cfg-core.lib"
local std = require"cfg-core.std"
local roles = require"cfg-core.roles"
local lib = require"lib"
local crc = require"crc32"
local stat = require"posix.sys.stat"
local cmd = lib.cmd
_ENV = ENV

M.required = { "path" }
M.alias = {}
M.alias.src = { "template" }
M.alias.table = { "view" }

-- XXX: Duplicated in the edit module
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

--- Render a template.
-- @Promiser output file
-- @Note Requires the diffutils package for the diff parameter to work
-- @param src source template [REQUIRED] [ALIAS: template]
-- @param table [REQUIRED] [ALIAS: view]
-- @param lua [ALIAS: data]
-- @param mode mode bits for output file [DEFAULT: 0600]
-- @param diff show diff [DEFAULT: false]
-- @usage template.render("/etc/something/config"){
--     template = "etc/something/config.template",
--         view = "view_model",
--         data = "/etc/something/config.lua"
-- }
function template.render(S)
    M.parameters = { "src", "lua", "table", "mode", "diff" }
    M.report = {
          repaired = "template.render: Successfully rendered textfile.",
              kept = "template.render: No difference detected, not overwriting existing destination.",
            failed = "template.render: Error rendering textfile.",
        missingsrc = "template.render: Can't access or missing source file.",
    }
    return function(P)
        P.path = S
        local F, R = cfg.init(P, M)
        local ppath = std.path()
        local from_templates = ppath.."/templates/"..P.src
        if stat.stat(from_templates) then
            P.src = from_templates
        elseif #roles > 0 then
            for _, r in ipairs(roles) do
                from_templates = ppath.."/roles/"..r.."/templates/"..P.src
                if stat.stat(from_templates) then
                    P.src = from_templates
                    break
                end
            end
        end
        if R.kept then
            return F.kept(P.path)
        end
        P.mode = P.mode or "0600"
        P.mode = tonumber(P.mode, 8)
        local ti = lib.fopen(P.src)
        if not ti then
            return F.result(P.src, nil, M.report.missingsrc)
        end
        P._input = lib.sub(ti, P.table)
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

return template
