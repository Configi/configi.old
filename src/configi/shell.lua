local Lib = require"libconfigi"
local Lc = require"cimicida"
local Pexec = require"pexec"
local Posix = require"posix"
local execute, gmatch, find, unpack = os.execute, string.gmatch, string.find, table.unpack
local pcall = pcall
local shell = {}
local ENV = {} ;_ENV = ENV

local main = function (M, S)
  local C = Lib.configi.start(M, S)
  C.required = { "string" }
  C.valid = { "cwd", "creates", "removes", "expects" }
  C.alias.cwd = { "chdir" }
  C.alias.string = { "command", "script" }
  C.alias.expects = { "match" }
  return Lib.configi.finish(C)
end

local rc = function (F, P)
  local created, removed
  if P.removes then
    if not Posix.stat(P.removes) then
      F.msg(P.removes, "removes", true)
      removed = true
    else
      F.msg(P.removes, "removes", false)
    end
  end
  if P.creates then
    if Posix.stat(P.creates) then
      F.msg(P.creates, "creates", true)
      created = true
    else
      F.msg(P.creates, "creates", false)
    end
  end
  if P.removes and P.creates then
    if removed and created then
      return true
    end
  elseif P.removes then
    if removed then
      return true
    end
  elseif P.creates then
    if created then
      return true
    end
  else
    return false
  end
end

function shell.command (S)
  local M = { "cwd", "creates", "removes" }
  local ok, err, sec, F, P, R = nil, nil, nil, main(M, S)
  if rc(F, P) then
    return R
  end
  ok, err, sec = F.run(Pexec.command, P.string, P.cwd)
  F.msg(P.string, "shell.command", err, sec)
  if ok then
    R.changed = true
  else
    R.failed = true
  end
  return R
end

function shell.system (S)
  local M = { "creates", "removes" }
  local ok, err, sec, F, P, R = nil, nil, nil, main(M, S)
  local script = Lc.fopen(P.string)
  if not script then
    F.msg(P.string, "shell.system", "script not found")
    R.failed = true
    return R
  end
  if rc(F, P) then return R end
  ok, err, sec = F.run(Lc.execute, script)
  F.msg(P.string, "shell.system", err, sec)
  if ok then
    R.changed = true
  else
    R.failed = true
  end
  return R
end

function shell.popen (S)
  local M = { "cwd", "creates", "removes", "expects" }
  local ok, err, sec, F, P, R = nil, nil, nil, main(M, S)
  if rc(F, P) then
    return R
  end
  local str = Lc.fopen(P.string) or P.string
  str, err, sec = F.run(Lc.popen, str, P.cwd)
  F.msg("script/command", "Lc.popen", err, sec)
  local res = nil
  if P.expects then
    if P.test then
      F.msg(P.expects, "expects", "Would expect from Lc.popen")
    else
      if Lc.tfind(str, P.expects) then
        res = true
        F.msg(P.expects, "expects", true)
      end
      if not res then
        F.msg(P.expects, "expects", false)
      end
    end
  else
    F.msg(P.string, "shell.popen", err)
    res = str
  end
  if P.test then
    ok = true
  else
    ok = res
  end
  if ok then
    R.changed = true
  else
    R.failed = true
  end
  return R
end

shell.script = shell.system
return shell
