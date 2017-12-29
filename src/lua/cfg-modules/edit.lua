--- Text file line editing.
-- @module edit
-- @author Eduardo Tongson <propolice@gmail.com>
-- @license MIT <http://opensource.org/licenses/MIT>
-- @added 2.0.0

local M, edit = {}, {}
local table, os, require = table, os, require
local cfg = require"cfg-core.lib"
local lib = require"lib"
local path, file, string = lib.path, lib.file, lib.string
local stat = require"posix.sys.stat"
local cmd = lib.cmd
_ENV = nil

M.required = { "path" }
M.alias = {}
M.alias.line = { "content" }
M.alias.pattern = { "match" }

-- XXX: Duplicated in the template module
local write = function(F, P)
  -- ignore P.diff if diffutils is not found
  if not path.bin"diff" then P.diff = false end
  if (P.debug or P.test) and P.diff then
    local temp = os.tmpname()
    if file.atomic_write(temp, P._input, 384) then
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
  return F.result(P.path, file.atomic_write(P.path, P._input, P._mode))
end

--- Insert lines into an existing file.
-- @Promiser path of text file to modify
-- @param line to insert [REQUIRED] [ALIAS: content]
-- @param pattern line is added before or after this pattern [ALIAS: match]
-- @param plain turn on or off pattern matching facilities [DEFAULT: "yes", true]
-- @param before [DEFAULT: "no", false]
-- @param after [DEFAULT: "yes", true]
-- @usage edit.insert_line("/etc/sysctl.conf"){
--   pattern = "# http://cr.yp.to/syncookies.html",
--   content = "net.ipv4.tcp_syncookies = 1",
--   after = true,
--   plain  = true
-- }
function edit.insert_line(S)
  M.parameters = { "diff", "line", "plain", "pattern", "before_pattern", "after_pattern" }
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
    local tf = file.to_table(P.path, "L")
    if not tf then return F.result(P.path, nil, M.report.missing) end
    if table.find(tf, P.line, true) then
      return F.kept(P.path)
    end
    P.plain = P.plain or true
    if not P.pattern then
      tf[#tf + 1] = P.line.."\n"
    else
      local x, n, nf = 1, 1, #tf
      if P.before_pattern then -- after_pattern "yes" is default
        x = 0
      end
      repeat
        if string.find(tf[n], P.pattern, 1, P.plain) then
          table.insert(tf, n + x, P.line.."\n")
          nf = nf + 1
          n = n + 2
        else
          n = n + 1
        end
      until n == nf
    end
    P._input = table.concat(tf)
    P._mode = stat.stat(P.path).st_mode
    return write(F, P)
  end
end

--- Remove lines from an existing file.
-- @Promiser path of text file to modify
-- @param pattern text pattern to remove [REQUIRED] [ALIAS: match]
-- @param plain turn on or off pattern matching facilities [DEFAULT: "yes"]
-- @usage edit.remove_line("/etc/sysctl.conf"){
--   match = "net.ipv4.ip_forward = 1",
--   plain = true
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
      pattern = string.escape_pattern(P.pattern)
    else
      pattern = P.pattern
    end
    local tf = file.to_table(P.path, "L")
    if not tf then
      return F.result(P.path, nil, M.report.missing)
    end
    if not table.find(tf, pattern, P.plain) then
      return F.kept(P.path)
    end
    P._input = table.concat(table.filter(tf, pattern, P.plain))
    P._mode = stat.stat(P.path).st_mode
    return write(F, P)
  end
end

return edit
