--- Ensure that a package managed by Portage is installed or absent.
-- @module portage
-- @author Eduardo Tongson <propolice@gmail.com>
-- @license MIT <http://opensource.org/licenses/MIT>
-- @added 0.9.0

local Lua = {
  find = string.find,
  match = string.match,
  insert = table.insert
}
local Func = {}
local Configi = require"configi"
local Px = require"px"
local Cmd = Px.cmd
local Lc = require"cimicida"
local Pstat = require"posix.sys.stat"
local Pdirent = require"posix.dirent"
local portage = {}
local ENV = {}
_ENV = ENV

local main = function (S, M, G)
  local C = Configi.start(S, M, G)
  C.required = { "atom" }
  C.alias.atom = { "package" }
  return Configi.finish(C)
end

Func.decompose = function (P)
  local A = {}
  if Lua.find(P.atom, "^[%<%>%=]+%g*$") then
    -- package ">=net-misc/rsync-3.0.9-r3"
    A.lead = Lua.match(P.atom, "[%<%>%=]+") -- >=
    A.category, A.package = Lc.splitp(P.atom) -- >=net-misc, rsync-3.0.9-r3
    A.category = Lua.match(A.category, "[%<%>%=]+([%w%-]+)") -- net-misc
    A.version = "" -- version is already at the end of A.package
    --[[
    A.revision = Lua.match(A.package, "%-(r[%d]+)", -3) -- r3
    A.version = Lua.match(A.package, "[%w%-]+%-([%d%._]+)%-" .. A.revision) -- 3.0.9
    A.package = Lua.match(A.package, "([%w%-]+)" .. "%-" .. A.version .. "%-" .. A.revision) -- rsync
    ]]
  elseif P.version then
    --[[
      package "net-misc/rsync"
      version ">=3.0.9-r3"
    ]]
    A.lead = Lua.match(P.version, "[%<%>%=]+")
    A.category, A.package = Lc.splitp(P.atom)
    A.version = Lua.match(P.version, "[%<%>%=]+([%g]+)")
    A.version = "-" .. A.version
    if A.lead == nil then
      A.lead = "="
    end
  else
    -- package "net-misc/rsync"
    A.category, A.package = Lc.splitp(P.atom)
    A.lead, A.version = "", ""
  end
  return A
end

Func.found = function (P)
  local A = Func.decompose(P)
  if Px.isdir("/var/db/pkg/" .. A.category) then
    if A.lead == "" then
      -- package "net-misc/rsync"
      for packages in Pdirent.files("/var/db/pkg/" .. A.category) do
        if Lua.find(packages, "^" .. A.package .. "%-%g*$") then
          return true
        end
      end
    else
      if Pstat.stat(Lc.strf("/var/db/pkg/%s/%s%s", A.category, A.package, A.version)) then
        return true
      end
    end
  end
end

--- Install package atom.
--- See emerge(1).
-- @aliases installed
-- @aliases install
-- @param atom package atom to install. Can be "category/package" or "category/package-version" [REQUIRED] [ALIAS: package]
-- @param version package version
-- @param deep evaluate entire dependency tree [CHOICES: "yes","no"]
-- @param newuse reinstall packages that had a change in its USE flags [CHOICES: "yes","no"]
-- @param nodeps do not merge dependencies [CHOICES: "yes","no"]
-- @param noreplace skip already installed packages [CHOICES: "yes","no"]
-- @param oneshot do not update the world file [CHOICES: "yes","no"] [DEFAULT: "yes"]
-- @param onlydeps only merge dependencies [CHOICES: "yes","no"]
-- @param sync perform an `emerge --sync` before installing package(s) [CHOICES: "yes","no"]
-- @param update update package to the best version [CHOICES: "yes","no"]
-- @param unmask enable auto-unmask and auto-unmask-write options [CHOICES: "yes","no"]
-- @usage portage.present [[
--   package "dev-util/strace"
--   version "4.8"
-- ]]
-- portage.present [[
--   atom "=dev-util/strace-4.8"
-- ]]
-- portage.present [[
--   package "dev-util/strace"
-- ]]
function portage.present (S)
  local M = { "deep", "newuse", "nodeps", "noreplace", "oneshot", "onlydeps", "sync", "unmask", "update", "version" }
  local G = {
    ok = "portage.present: Successfully installed package.",
    skip = "portage.present: Package already installed.",
    fail = "portage.present: Error installing package."
  }
  local F, P, R = main(S, M, G)
  if P.oneshot == nil then
    P.oneshot = true -- oneshot "yes" is default
  end
  -- `emerge --sync` mode
  if P.sync == true then
    if F.run(Cmd["/usr/bin/emerge"], { "--sync" }) then
      F.msg("sync", "Sync finished", true)
    else
      return F.result(false, "sync", "Sync failed")
    end
  end
  if Func.found(P) then
    return F.skip(P.atom)
  end
  local A = Func.decompose(P)
  local atom = Lc.strf("%s%s/%s%s", A.lead or "", A.category, A.package, A.version)
  local args = { "--quiet", "--quiet-build", atom }
  Lc.insertif(P.deep, args, 3, "--deep")
  Lc.insertif(P.newuse, args, 3, "--newuse")
  Lc.insertif(P.nodeps, args, 3, "--nodeps")
  Lc.insertif(P.noreplace, args, 3, "--noreplace")
  Lc.insertif(P.oneshot, args, 3, "-1")
  Lc.insertif(P.onlydeps, args, 3, "--onlydeps")
  if P.unmask then
    Lua.insert(args, 3, "--auto-unmask-write")
    Lua.insert(args, 3, "--auto-unmask")
  end
  return F.result(F.run(Cmd["/usr/bin/emerge"], args), atom)
end

--- Remove package atom.
-- @aliases remove
-- @param atom package atom to unmerge [REQUIRED] [ALIAS: package]
-- @param depclean Remove packages not associated with explicitly installed packages [CHOICES: "yes","no"] [DEFAULT: "no"]
-- @usage portage.absent [[
--   atom "dev-util/atom"
-- ]]
function portage.absent (S)
  local M = { "depclean" }
  local G = {
    ok = "portage.absent: Successfully removed package.",
    skip = "portage.absent: Package not installed.",
    fail = "portage.absent: Error removing package."
  }
  local F, P, R = main(S, M, G)
  if not Func.found(P) then
    return F.skip(P.atom)
  end
  local env = { "CLEAN_DELAY=0", "PATH=/bin:/usr/bin:/sbin:/usr/sbin" } -- PORTAGE_BZIP2_COMMAND needs $PATH
  local A = Func.decompose(P)
  local atom = Lc.strf("%s%s/%s%s", A.lead or "", A.category, A.package, A.version)
  local args = { _env = env, "--quiet", "-C", atom }
  Lc.insertif(P.depclean, args, 2, "--depclean")
  return F.result(F.run(Cmd["/usr/bin/emerge"], args), atom)
end

portage.installed = portage.present
portage.install = portage.present
portage.remove = portage.absent
return portage
