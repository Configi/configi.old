--- Render a template.
-- @module template
-- @author Eduardo Tongson <propolice@gmail.com>
-- @license MIT <http://opensource.org/licenses/MIT>
-- @added 0.9.0

local template, M = {}, {}
local ipairs, tonumber, table, os, require =
  ipairs, tonumber, table, os, require
local cfg = require"cfg-core.lib"
local std = require"cfg-core.std"
local roles = require"cfg-core.roles"
local lib = require"lib"
local path, file, string = lib.path, lib.file, lib.string
local crc32 = require"plc.checksum".crc32
local stat = require"posix.sys.stat"
local cmd = lib.exec.cmd
_ENV = nil

M.required = { "path" }
M.alias = {}
M.alias.src = { "template" }
M.alias.table = { "view" }

-- XXX: Duplicated in the edit module
local write = function(F, P)
  -- ignore P.diff if diffutils is not found
  if not path.bin"diff" then P.diff = false end
  if (P.debug or P.test) and P.diff then
    local temp = os.tmpname()
    if file.atomic_write(temp, P._input) then
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
  return F.result(P.path, file.atomic_write(P.path, P._input), P.mode)
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
--       view = "view_model",
--       data = "/etc/something/config.lua"
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
    if R.kept then return F.kept(P.path) end
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
    P.mode = P.mode or "0600"
    local mode = tonumber(P.mode, 8)
    if mode then P.mode = mode end
    local ti = file.read_to_string(P.src)
    if not ti then
      return F.result(P.src, nil, M.report.missingsrc)
    end
    P._input = string.template(ti, P.table)
    if stat.stat(P.path) then
      if crc32(file.read_to_string(P.path)) == crc32(P._input) then
        return F.kept(P.path)
      end
    end
    return write(F, P, R)
  end
end

return template
