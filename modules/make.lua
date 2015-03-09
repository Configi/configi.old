--- The `configure; make; make install` sequence.
-- @module make
-- @author Eduardo Tongson <propolice@gmail.com>
-- @license MIT <http://opensource.org/licenses/MIT>
-- @added 0.9.7

local Lua = {
  insert = table.insert,
  pcall = pcall
}
local Configi = require"configi"
local Cmd = require"px".cmd
local Pstat = require"posix.sys.stat"
local Lc = require"cimicida"
local make = {}
local ENV = {}
_ENV = ENV

local main = function (S, M, G)
  local C = Configi.start(S, M, G)
  C.required = { "directory" }
  C.alias.configure = { "options" }
  C.alias.directory = { "dir", "build" }
  C.alias.make = { "defines" }
  C.alias.installs = { "creates" }
  C.alias.environment = { "env" }
  return Configi.finish(C)
end

--- Install a program via the `configure; make; make install` sequence of commands.
-- @param directory path to directory containing the root of the configure script [REQUIRED]
-- @param configure options to pass to `./configure` [ALIAS: options]
-- @param make usually DEFINES that it passed to `make` [ALIAS: defines]
-- @param installs path of installed executable. Considered kept if it exists [ALIAS: creates]
-- @param environment space delimited string that contains environment variables passed to `./configure` and `make` [ALIAS: env]
function make.install (S)
  local M = { "configure", "make", "installs", "environment" }
  local G = {
    repaired = "make.install: Successfully installed.",
    kept = "make.install: Already installed.",
    failed = "make.install: Error installing."
  }
  local F, P, R = main(S, M, G)
  if Lua.pcall(Pstat.stat, P.installs) then
    return F.kept(P.directory)
  end
  if P.environment then
    P.environment = Lc.strtotbl(P.environment)
  end
  local args, result
  if Pstat.stat(P.directory .. "/configure") then
    if P.configure then
      args = { _env = P.environment, _cwd = P.directory }
      Lc.insertif(P.configure, args, 1, Lc.strtotbl(P.configure))
      result = F.run(Cmd["./configure"], args)
    else
      result = F.run(Cmd["./configure"], { _env = P.environment, _cwd = P.directory })
    end
    if not result then
      return F.result(P.directory, false, "`./configure` step failed")
    end
  end
  if P.make then
    args = { _env = P.environment, _cwd = P.directory }
    Lc.insertif(P.make, args, 1, Lc.strtotbl(P.make))
    result = F.run(Cmd.make, args)
  else
    result = F.run(Cmd.make, { _env = P.environment, _cwd = P.directory })
  end
  if not result then
    return F.result(P.directory, false, "`make` step failed")
  end
  if P.make then
    args = { _env = P.environment, _cwd = P.directory }
    Lua.insert(args, 1, "install")
    Lc.insertif(P.make, args, 1, Lc.strtotbl(P.make))
    result = F.run(Cmd.make, args)
  else
    result = F.run(Cmd.make, { "install",  _env = P.environment, _cwd = P.directory })
  end
  if not result then
    return F.result(P.directory, false, "`make install` step failed")
  end
  return F.result(P.directory, true)
end

return make
