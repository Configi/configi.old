--- Ensure that a yum managed package is present, absent or updated.
-- @module yum
-- @author Eduardo Tongson <propolice@gmail.com>
-- @license MIT <http://opensource.org/licenses/MIT>
-- @added 0.9.0

local cfg = require"configi"
local lib = require"lib"
local cmd = lib.cmd
local yum = {}
local ENV = {}
_ENV = ENV

local main = function (S, M, G)
  local C = cfg.start(S, M, G)
  C.required = { "package" }
  C.alias.package = { "option" } -- for clean mode
  return cfg.finish(C)
end

local found = function (package)
  local _, ret = cmd.yum{ command = "info", package = package, cacheonly = true }
  if lib.find_string(ret.stdout, "Installed Packages", true) then
    return true
  end
end

--- Run clean mode.
-- See yum(8) for possible options.
-- @param option option to pass to `yum clean`
-- @usage yum.clean [[
--   option "all"
-- ]]
function yum.clean (S)
  local G = {
    repaired = "yum.clean: Successfully executed `yum clean`.",
    failed = "yum.clean: Error running `yum clean`."
  }
  local F, P, R = main(S, M, G)
  return F.result(P.package, F.run(cmd.yum, { command = "clean", package = P.package }))
end

--- Install a package via the Yum package manager.
-- See yum(8) for full description of options and parameters
-- @aliases installed
-- @aliases install
-- @param package name of the package to install [REQUIRED]
-- @param cleanall run `yum clean all` before proceeding [CHOICES: "yes", "no"]
-- @param config yum config file location
-- @param nogpgcheck disable GPG signature checking [CHOICES: "yes","no"]
-- @param security include packages with security related errata (yum-plugin-security) [CHOICES: "yes","no"]
-- @param bugfix include packages with bugfix related updates (yum-plugin-security) [CHOICES: "yes","no"]
-- @param proxy HTTP proxy to use for connections. Passed as an environment variable.
-- @param update update all packages to the latest version [CHOICES: "yes","no"]
-- @param update_minimal only update to the version with a bugfix or security errata [CHOICES: "yes","no"]
-- @usage yum.present [[
--   package "strace"
--   update "yes"
-- ]]
function yum.present (S)
  local M =  { "clean_all", "config", "nogpgcheck", "security", "bugfix", "proxy", "update", "update_minimal" }
  local G = {
    repaired = "yum.present: Successfully installed package.",
    kept = "yum.present: Package already installed.",
    failed = "yum.present: Error installing package."
  }
  local F, P, R = main(S, M, G)
  local env, command
  if P.proxy then
    env = { "http_proxy=" .. P.proxy }
  end
  -- Update mode
  if P.update == true or P.update_minimal == true then
    if P.update_minimal == true then
      command = "update-minimal"
    elseif P.update == true then
      command = "update"
    end
    return F.result(P.package, F.run(cmd.yum, { _env = env, assumeyes = true, command = command, config = P.config,
                        nogpgcheck = P.nogpgcheck, security = P.security,
                        bugfix = P.bugfix, package = P.package }))
  end
  -- Install mode
  if Func.found(P.package) then
    return F.kept(P.package)
  end
  return F.result(P.package, F.run(cmd.yum, { env = env, assumeyes = true, command = "install", config = P.config,
                      nogpgcheck = P.nogpgcheck, security = P.security,
                      bugfix = P.bugfix, package = P.package }))
  end

--- Remove a package via the Yum package manager.
-- @aliases removed
-- @aliases remove
-- @param package name of the package to remove [REQUIRED]
-- @param config yum config file location
function yum.absent (S)
  local M = { "config" }
  local G = {
    repaired = "yum.absent: Successfully removed package.",
    kept = "yum.absent: Package not installed.",
    failed = "yum.absent: Error removing package."
  }
  local F, P, R = main(S, M, G)
  if not Func.found(P.package) then
    F.kept(P.package)
  end
  return F.result(P.package, F.run(cmd.yum, { assumeyes = true, command = "erase", package = P.package }))
end

yum.installed = yum.present
yum.install = yum.present
yum.removed = yum.absent
yum.remove = yum.absent
return yum
