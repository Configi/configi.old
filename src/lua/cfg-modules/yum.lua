--- Ensure that a yum managed package is present, absent or updated.
-- @module yum
-- @author Eduardo Tongson <propolice@gmail.com>
-- @license MIT <http://opensource.org/licenses/MIT>
-- @added 0.9.0

local ENV, M, yum = {}, {}, {}
local string = string
local stat = require"posix.sys.stat"
local cfg = require"cfg-core.lib"
local lib = require"lib"
local cmd = lib.cmd
_ENV = ENV

M.required = { "package" }
M.alias = {}
M.alias.package = { "option" } -- for clean mode

local found = function(package)
    local _, ret = cmd.yum{ "--cacheonly", "info", package }
    if lib.find_string(ret.stdout, "Installed Packages", true) then
        return true
    end
end

local found_group  = function(group)
    local _, ret = cmd.yum{ "--cacheonly", "groups", "list", group }
    if lib.find_string(ret.stdout, "Installed Groups", true) then
        return true
    end
end

--- Add custom repository.
-- See yum-config-manager(1).
-- @Subject Location (file or URL) of the repository
-- @param None
-- @usage yum.add_repo("http://openresty.org/yum/centos/OpenResty.repo")
function yum.add_repo(S)
    M.parameters = { "repo" }
    M.report = {
        repaired = "yum.add_repo: Successfully added repository.",
            kept = "yum.add_repo: Repository already present.",
          failed = "yum.add_repo: Error adding repository."
    }
    return function(P)
        P.package = ""
        P.repo = S
        local F, R = cfg.init(P, M)
        local file = string.match(P.repo, "^.*/(.*)$")
        if stat.stat("/etc/yum.repos.d/" .. file) then
            return F.kept(P.repo)
        end
        return F.result(P.repo, F.run(cmd["yum-config-manager"], { "--add-repo", P.repo }))
    end
end

--- Run clean mode.
-- See yum(8) for possible options.
-- @Subject option to pass to `yum clean`
-- @param None
-- @usage yum.clean("all")!
function yum.clean(S)
    M.report = {
        repaired = "yum.clean: Successfully executed `yum clean`.",
          failed = "yum.clean: Error running `yum clean`."
    }
    return function(P)
        P.option = S
        local F, R = cfg.init(P, M)
        return F.result(P.package, F.run(cmd.yum, { "--quiet", "--assumeyes", "clean", P.option }))
    end
end

--- Install a package via the Yum package manager.
-- See yum(8) for full description of options and parameters
-- @Subject package
-- @Aliases installed
-- @Aliases install
-- @param cleanall run `yum clean all` before proceeding [CHOICES: "yes", "no"]
-- @param config yum config file location
-- @param nogpgcheck disable GPG signature checking [CHOICES: "yes","no"]
-- @param security include packages with security related errata (yum-plugin-security) [CHOICES: "yes","no"]
-- @param bugfix include packages with bugfix related updates (yum-plugin-security) [CHOICES: "yes","no"]
-- @param proxy HTTP proxy to use for connections. Passed as an environment variable.
-- @param update update all packages to the latest version [CHOICES: "yes","no"]
-- @param update_minimal only update to the version with a bugfix or security errata [CHOICES: "yes","no"]
-- @usage yum.present("strace")
--     update: "yes"
function yum.present(S)
    M.parameters = {
        "config", "nogpgcheck", "security", "bugfix", "proxy", "update", "update_minimal"
    }
    M.report = {
        repaired = "yum.present: Successfully installed package.",
            kept = "yum.present: Package already installed.",
          failed = "yum.present: Error installing package."
    }
    return function(P)
        P.package = S
        local F, R = cfg.init(P, M)
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
            local args = { _env = env, "--quiet", "--assumeyes", command, P.package }
            local set = {
                nogpgcheck = "--nogpgcheck",
                  security = "--security",
                    bugfix = "--bugfix"
            }
            P:insert_if(set, args, 3)
            if P.config then
                lib.insert_if(P.config, args, 3, "--config=" .. P.config)
            end
            return F.result(P.package, F.run(cmd.yum, args))
        end
        -- Install mode
        if not string.find(P.package, "^@") then
            if found(P.package) then
                return F.kept(P.package)
            end
        else
            if found_group(P.package) then
                return F.kept(P.package)
            end
        end
        local args = { _env = env, "--quiet", "--assumeyes", "install", P.package }
        local set = {
            nogpgcheck = "--nogpgcheck"
        }
        P:insert_if(set, args, 3)
        if P.config then
            lib.insert_if(P.config, args, 3,  "--config=" .. P.config )
        end
        return F.result(P.package, F.run(cmd.yum, args))
    end
end

--- Remove a package via the Yum package manager.
-- @Subject package
-- @Aliases removed
-- @Aliases remove
-- @param config yum config file location
-- @usage yum.absent("strace")
--     config: "/etc/yum.conf"
function yum.absent(S)
    M.parameters = { "config" }
    M.report = {
        repaired = "yum.absent: Successfully removed package.",
            kept = "yum.absent: Package not installed.",
          failed = "yum.absent: Error removing package."
    }
    return function(P)
        P.package = S
        local F, R = cfg.init(P, M)
        if not found(P.package) then
            return F.kept(P.package)
        end
        local args = { _env = env, "--quiet", "--assumeyes", "remove", P.package }
        local set = {
            nogpgcheck = "--nogpgcheck"
        }
        P:insert_if(set, args, 3)
        if P.config then
            lib.insert_if(P.config, args, 3, "--config=" .. P.config)
        end
        return F.result(P.package, F.run(cmd.yum, args))
    end
end

yum.installed = yum.present
yum.install = yum.present
yum.removed = yum.absent
yum.remove = yum.absent
return yum
