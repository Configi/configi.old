--- Ensure that a Git repository is cloned or pull.
-- @module git
-- @author Eduardo Tongson <propolice@gmail.com>
-- @license MIT <http://opensource.org/licenses/MIT>
-- @added 0.9.0

local ENV, M, git = {}, {}, {}
local cfg = require"cfg-core.lib"
local lib = require"lib"
local file, table, exec = lib.file, lib.table, lib.exec
local stat = require"posix.sys.stat"
local cmd = exec.cmd
_ENV = ENV

M.required = { "path" }
M.alias = {}
M.alias.repository = { "repo", "url" }

local found = function(P)
  local gitconfig = P.path .. "/.git/config"
  if not stat.stat(gitconfig) then
    return nil
  else
    local config = file.to_table(gitconfig)
    P.repository = P.repository or "" -- to accomodate git.pull
    -- confident that Git URLs do not contain Lua magic characters
    if table.find(config, "url = " .. P.repository, true) or (P.repository == "") then
      return true
    else
      return false -- nil has a distinction
    end
  end
end

--- Ensure that a repository is cloned into a specified path.
-- @Promiser path where to clone the repository
-- @Aliases repo
-- @Aliases cloned
-- @param repository The URL of the repository. [ALIAS: url,repo] [REQUIRED]
-- @usage git.repo"/home/user/work"{
--     repo = "https://github.com/torvalds/linux.git"
-- }
function git.clone(S)
  M.parameters = { "repository" }
  M.report = {
    repaired = "git.clone: Successfully cloned Git repository.",
      kept = "git.clone: Already a git repository.",
      failed = "git.clone: Error running `git clone`."
  }
  return function(P)
    P.path = S
    local F, R = cfg.init(P, M)
    if R.kept then
      return F.kept(P.path)
    end
    local ret = found(P)
    local dir, res, err
    if ret then
      return F.kept(P.repository)
    elseif ret == nil then
      dir, res = cmd.mkdir{ "-p", P.path }
      err = exec.exit_string(res.exe, res.status, res.exe)
      if not dir then
        return F.result(P.path, nil, err)
      end
    elseif ret == false then
      return F.result(P.path, nil, "Directory not empty")
    end
    local args = { "clone", P.repository, P.path }
    return F.result(P.repository, F.run(cmd["/usr/bin/git"], args))
  end
end

--- Run `git pull` for a repository.
-- This always attempts to run the command. Useful as a handler.
-- @Promiser path where to clone the repository
-- @param repository The URL of the repository. [ALIAS: url,repo] [REQUIRED]
-- @usage git.pull("/home/user/work"){
--     repo = "https://github.com/torvalds/linux.git"
-- }
function git.pull(S)
  M.report = {
    repaired = "git.pull: Successfully pulled Git repository.",
      kept = "git.pull: Path is non-existent or not a Git repository.",
      failed = "git.pull: Error running `git pull`."
  }
  return function(P)
    P.path = S
    local F, R = cfg.init(P, M)
    if R.kept or not found(P) then
      return F.kept(P.path) -- piggyback on kept()
    end
    local args = { _cwd = P.path, "pull" }
    return F.result(P.path, F.run(cmd["/usr/bin/git"], args))
  end
end

git.cloned = git.clone
git.repo = git.clone
return git
