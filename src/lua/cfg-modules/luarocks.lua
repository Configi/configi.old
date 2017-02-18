--- Ensure that a Lua module (rock) managed by the LuaRocks rock manager is present or absent.
-- @module luarocks
-- @author Eduardo Tongson <propolice@gmail.com>
-- @license MIT <http://opensource.org/licenses/MIT>
-- @added 2.0.0

local ENV, M, luarocks = {}, {}, {}
local cfg = require"cfg-core.lib"
local lib = require"lib"
local cmd = lib.cmd
_ENV = ENV

M.required = { "rock" }
M.alias = {}
M.alias.rock = { "module" }

local found = function(rock)
    local _, ret = cmd.luarocks{ "list" }
    if lib.find_string(ret.stdout, "^" .. rock .. "$", true) then
        return true
    end
end

--- Install a rock.
-- See `luarocks --help`
-- @Aliases installed
-- @Aliases install
-- @Subject rock
-- @usage luarocks.present("luacheck")()
function luarocks.present(S)
    M.parameters = { "proxy" }
    M.report = {
        repaired = "luarocks.present: Successfully installed rock.",
            kept = "luarocks.present: Rock already installed.",
          failed = "luarocks.present: Error installing rock."
    }
    return function(P)
        P.rock = S
        local F, R = cfg.init(P, M)
        local env
        if P.proxy then
            env = { "http_proxy=" .. P.proxy }
        end
        if found(P.rock) then
            return F.kept(P.rock)
        end
        return F.result(P.rock, F.run(cmd.luarocks, { _env = env, "install", P.rock }))
    end
end

--- Uninstall a rock.
-- @Subject rock
-- @Aliases removed
-- @Aliases remove
-- @usage luarocks.absent("luarocks")()
function luarocks.absent(S)
    M.report = {
        repaired = "luarocks.absent: Successfully removed rock.",
            kept = "luarocks.absent: Rock not installed.",
          failed = "luarocks.absent: Error removing rock."
    }
    return function(P)
        P.rock = S
        local F, R = cfg.init(P, M)
        if not found(P.rock) then
            return F.kept(P.rock)
        end
        return F.result(P.rock, F.run(cmd.luarocks, { "remove", P.rock }))
    end
end

luarocks.installed = luarocks.present
luarocks.install = luarocks.present
luarocks.removed = luarocks.absent
luarocks.remove = luarocks.absent
return luarocks
