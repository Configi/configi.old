--- The `configure; make; make install` sequence.
-- @module make
-- @author Eduardo Tongson <propolice@gmail.com>
-- @license MIT <http://opensource.org/licenses/MIT>
-- @added 0.9.7

local ENV, M, make = {}, {}, {}
local table, pcall = table, pcall
local cfg = require"configi"
local stat = require"posix.sys.stat"
local lib = require"lib"
local cmd = lib.cmd
_ENV = ENV

M.required = { "directory" }
M.alias = {}
M.alias.configure = { "options" }
M.alias.directory = { "dir", "build" }
M.alias.make = { "defines" }
M.alias.installs = { "creates" }
M.alias.environment = { "env" }

--- Install a program via the `configure; make; make install` sequence of commands.
-- @Subject path to directory containing the root of the configure script
-- @param configure options to pass to `./configure` [ALIAS: options]
-- @param make usually DEFINES that it passed to `make` [ALIAS: defines]
-- @param installs path of installed executable. Considered kept if it exists [ALIAS: creates]
-- @param environment space delimited string that contains environment variables passed to `./configure` and `make` [ALIAS: env]
-- @usage make.install"/home/ed/Downloads/something-1.0.0"
--     make: "-DNDEBUG"
function make.install(S)
    M.parameters = { "configure", "make", "installs", "environment" }
    M.report = {
        repaired = "make.install: Successfully installed.",
            kept = "make.install: Already installed.",
          failed = "make.install: Error installing."
    }
    return function(P)
        P.directory = S
        local F, R = cfg.init(P, M)
        if pcall(stat.stat, P.installs) then
            return F.kept(P.directory)
        end
        if P.environment then
            P.environment = lib.str_to_tbl(P.environment)
        end
        local args, result
        if stat.stat(P.directory .. "/configure") then
            if P.configure then
                args = { _env = P.environment, _cwd = P.directory }
                lib.insertif(P.configure, args, 1, lib.str_to_tbl(P.configure))
                result = F.run(cmd["./configure"], args)
            else
                result = F.run(cmd["./configure"], { _env = P.environment, _cwd = P.directory })
            end
            if not result then
                return F.result(P.directory, false, "`./configure` step failed")
            end
        end
        if P.make then
            args = { _env = P.environment, _cwd = P.directory }
            lib.insert_if(P.make, args, 1, lib.str_to_tbl(P.make))
            result = F.run(cmd.make, args)
        else
            result = F.run(cmd.make, { _env = P.environment, _cwd = P.directory })
        end
        if not result then
            return F.result(P.directory, false, "`make` step failed")
        end
        if P.make then
            args = { _env = P.environment, _cwd = P.directory }
            table.insert(args, 1, "install")
            lib.insert_if(P.make, args, 1, lib.str_to_tbl(P.make))
            result = F.run(cmd.make, args)
        else
            result = F.run(cmd.make, { "install",  _env = P.environment, _cwd = P.directory })
        end
        if not result then
            return F.result(P.directory, false, "`make install` step failed")
        end
        return F.result(P.directory, true)
    end
end

return make
