-- Ensure that a Git repository is cloned or pull.
-- @moduleg git
-- @author Eduardo Tongson <propolice@gmail.com>
-- @license MIT <http://opensource.org/licenses/MIT>
-- @added 0.9.0

local Func = {}
local Configi = require"configi"
local Px = require"px"
local Pstat = require"posix.sys.stat"
local Cmd = Px.cmd
local Lc = require"cimicida"
local git = {}
_ENV = nil

local main = function (S, M, G)
  local C = Configi.start(S, M, G)
  C.required = { "path" }
  C.alias.repository = { "repo", "url" }
  return Configi.finish(C)
end

Func.found = function (P)
  local gitconfig = P.path .. "/.git/config"
  if not Pstat.stat(gitconfig) then
    return nil
  else
    local config = Lc.file2tbl(gitconfig)
    P.repository = P.repository or "" -- to accomodate git.pull
    -- confident that Git URLs do not contain Lua magic characters
    if Lc.tfind(config, "url = " .. P.repository, true) then
      return true
    else
      return false
    end
  end
end

--- Ensure that a Git repository is cloned into a specified path.
-- @aliases repo
-- @aliases cloned
-- @param repository The URL of the repository. [ALIAS: url,repo] [REQUIRED]
-- @param path absolute path where to clone the repository [REQUIRED]
-- @usage git.repo [[
--   repo "https://github.com/torvalds/linux.git"
--   path "/home/user/work"
-- ]]
function git.clone (S)
  local M = { "repository" }
  local G = {
    ok = "git.clone: Successfully cloned Git repository.",
    skip = "git.clone: Already a git repository.",
    fail = "git.clone: Error running `git clone`."
  }
  local F, P, R = main(S, M, G)
  local ret = Func.found(P)
  if ret then
    return F.skip(P.repository)
  elseif ret == nil then
    local dir, res = Cmd.mkdir{ "-p", P.path }
    local err = Lc.exitstr(res.bin, res.status, res.bin)
    if not dir then
      F.msg(P.path, err, false)
      R.notify_failed = P.notify_failed
      R.failed = true
      return R
    end
  elseif ret == false then
    F.msg(P.path, "Directory not empty", false)
    R.notify_failed = P.notify_failed
    R.failed = true
    return R
  end
  local args = { "clone", P.repository, P.path }
  return F.result(F.run(Cmd["/usr/bin/git"], args), P.repository)
end

--- Run `git pull` for a repository.
-- This always attempts to run the command. Useful as a handler.
-- @param repository The URL of the repository. [ALIAS: url,repo] [REQUIRED]
-- @param path absolute path where to run the pull command [REQUIRED]
-- @usage git.pull [[
--   repo "https://github.com/torvalds/linux.git"
--   path "/home/user/work"
-- ]]
function git.pull (S)
  local G = {
    ok = "git.pull: Successfully pulled Git repository.",
    skip = "git.pull: Path is non-existent or not a Git repository.",
    fail = "git.pull: Error running `git pull`."
  }
  local F, P, R = main(S, M, G)
  if not Func.found(P) then
    return F.skip(P.path) -- piggyback on skip()
  end
  local args = { _cwd = P.path, "pull" }
  return F.result(F.run(Cmd["/usr/bin/git"], args), P.path)
end

git.cloned = git.clone
git.repo = git.clone
return git
