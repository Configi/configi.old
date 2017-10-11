--- Ensure that an Ubuntu PPA repository is present or absent
-- @module ppa
-- @author Eduardo Tongson <propolice@gmail.com>
-- @license MIT <http://opensource.org/licenses/MIT>
-- @added 2.0.0

local M, ppa = {}, {}
local cfg = require"cfg-core.lib"
local lib = require"lib"
local os = lib.os
local exec = lib.exec
local file = lib.file
local path = lib.path
local dirent = require"posix.dirent"
local string = string
_ENV = nil

M.required = {"repository"}
M.parameters = {"proxy"}
M.alias = {}
M.alias.repository = {"repo"}

local found = function(repo)
  local u, p = string.match(repo, "([^%G/]+)/([^$G/]+)")
  local r =  dirent.dir("/etc/apt/sources.list.d")
    for n = 1, #r do
      if string.find(r[n], u.."%-[%l]+%-"..p) then
        return true
      end
    end
end

local install = function(P)
  local get = exec.ctx("apt-get")
  if P.proxy then
    get.env = {"http_proxy="..P.proxy}
  end
  return (get("-q", "-y", "install", "software-properties-common"))
end

local update = function(P)
  local get = exec.ctx("apt-get")
  if P.proxy then
    get.env = {"http_proxy="..P.proxy}
  end
  return (get("-q", "-y", "update"))
end

--- Add a repository
-- @Promiser repository
-- @param None
-- @usage ppa.present("stefansundin/truecrypt")()
function ppa.present(S)
  M.report = {
    repaired = "ppa.present: Successfully added repository.",
    kept = "ppa.present: Repository already present.",
    failed = "ppa.present: Error adding repository.",
    failed_install = "ppa.present: Error installing dependency `software-properties-common` package."
  }
  return function(P)
    P.repository = S
    local F, R = cfg.init(P, M)
    if R.kept or found(S) then
      return F.result(S, false)
    end
    if not path.bin("apt-add-repository") then
      if install(P) == nil then return F.result(S, nil, M.report.failed_install) end
    end
    local add = exec.ctx("apt-add-repository")
    if P.proxy then
      add.env = {"http_proxy="..P.proxy}
    end
    local res = F.run(add, "-y", "ppa:"..S)
    if not res then
      return F.result(S)
    end
    if P.update then
      return F.result(S, update(P))
    end
    return F.result(S, true)
  end
end

--- Remove a repository
-- @Promiser repository
-- @param None
-- @usage ppa.absent("stefansundin/truecrypt")()
function ppa.absent(S)
  M.report = {
    repaired = "ppa.absent: Successfully removed repository.",
    kept = "ppa.absent: Repository already absent.",
    failed = "ppa.absent: Error removing repository.",
    failed_install = "ppa.absent: Error installing dependency `software-properties-common` package."
  }
  return function(P)
    P.repository = S
    local F, R = cfg.init(P, M)
    if R.kept or not found(S) then
      return F.result(S, false)
    end
    if not path.bin("apt-add-repository") then
      if install(P) == nil then return F.result(S, nil, M.report.failed_install) end
    end
    local codename = file.match("/etc/os-release", [[^UBUNTU_CODENAME=[%p]*(%w+)[%p]*]])
    local del = exec.ctx("apt-add-repository")
    if not F.run(del, "-r", "-y", "ppa:"..S) then return F.result(S) end
    local u, p = string.match(S, "([^%G/]+)/([^$G/]+)")
    if not u or not p then return F.result(S) end
    local src = "/etc/apt/sources.list.d/"..u.."-ubuntu-"..p.."-"..codename..".list"
    os.remove(src..".save")
    if not os.remove(src) then return F.result(S) end
    local gpg = "/etc/apt/trusted.gpg.d/"..u.."_ubuntu_"..p..".gpg"
    os.remove(gpg.."~")
    if not os.remove(gpg) then return F.result(S) end
    return F.result(S, true)
  end
end

ppa.add = ppa.present
ppa.remove = ppa.absent
return ppa
