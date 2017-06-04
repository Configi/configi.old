--- Perform mount(8) operations
-- @module mount
-- @author Eduardo Tongson <propolice@gmail.com>
-- @license MIT <http://opensource.org/licenses/MIT>
-- @added 2.0.0
local ENV, M, mount = {}, {}, {}
local ipairs, table, string = ipairs, table, string
local cfg = require"cfg-core.lib"
local lib = require"lib"
local cmd = lib.cmd
local fact = require"cfg-core.fact"
_ENV = ENV

M.required = { "dir" }

--- Remount a filesystem with specified options
-- @Promiser mount mount point to remount
-- @param value value to write
-- @usage mount.opts"/tmp"{
--    nodev = true
-- }
function mount.opts(S)
    M.parameters = {
        "async",
        "atime",
        "noatime",
        "dev",
        "nodev",
        "diratime",
        "nodiratime",
        "dirsync",
        "exec",
        "noexec",
        "iversion",
        "noiversion",
        "mand",
        "nomand",
        "relatime",
        "norelatime",
        "strictatime",
        "nostrictatime",
        "suid",
        "nosuid",
        "owner",
        "ro",
        "rw",
        "sync",
        "uid",
        "gid",
        "seclabel",
        "context",
        "fscontext",
        "defcontext",
        "rootcontext",
        "size",
        "mode"
    }
    M.report = {
        repaired = "mount.remount: Successfully remounted mount point.",
            kept = "mount.remount: Mount option already set.",
          failed = "mount.remount: Error remounting mount point.",
       unmounted = "mount.remount: Error remounting unmounted mount point."
    }
    return function(P)
        P.dir = S
        local F, R = cfg.init(P, M)
        if R.kept then
            return F.kept(P.dir)
        end
        if fact.mount[P.dir] == false then
            return F.result(P.dir, nil, M.report.unmounted)
        end
        local tmp = {}
        for _, o in ipairs(M.parameters) do
            lib.insert_if(P[o], tmp, -1, o)
        end
        local to = {}
        for _, o in ipairs(tmp) do
            if P[o] == true or lib.truthy(P[o]) then
                to[#to+1] = o
            elseif P[o] then
                to[#to+1] = o.."="..P[o]
            end
        end
        local co
        for _, o in ipairs(fact.mount.table) do
            if P.dir == o.dir then
                co = o.opts
                break
            end
        end
        local st
        for _, o in ipairs(to) do
            st = string.find(co, o, 1, true)
            if st == nil then
                local r = F.run(cmd.mount, { "-o", "remount,"..table.concat(to, ","), P.dir })
                return F.result(P.dir, r)
            end
        end
        if st then
            return F.kept(P.dir)
        end
    end
end

function mount.mounted(S)
    M.parameters = {
        "dev"
    }
    M.alias = {}
    M.alias.dev = { "device" }
    M.report = {
        repaired = "mount.mounted: Successfully mounted.",
            kept = "mount.mounted: Already mounted.",
          failed = "mount.mounted: Failed to mount."
    }
    return function(P)
        P.dir = S
        local F, R = cfg.init(P, M)
        if R.kept or fact.mount[P.dir] then
            return F.kept(P.dir)
        else
            local a = { P.dir }
            lib.insert_if(P.dev, a, 1, P.dev)
            local r = F.run(cmd.mount, a)
            return F.result(P.dir, r)
        end

    end
end

function mount.unmounted(S)
    M.report = {
        repaired = "mount.ummounted: Successfully unmounted.",
            kept = "mount.unmounted: Already unmounted.",
          failed = "mount.unmounted: Failed to unmount."
    }
    return function(P)
        P.dir = S
        local F, R = cfg.init(P, M)
        if R.kept or fact.mount[P.dir] == false then
            return F.kept(P.dir)
        else
            local r = F.run(cmd.umount, { P.dir })
            return F.result(P.dir, r)
        end
    end
end

mount.remount = mount.opts
return mount