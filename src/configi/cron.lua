local Lib = require"libconfigi"
local Lc = require"cimicida"
local Cmd = require"cmd"
local pcall, concat, remove, find = pcall, table.concat, table.remove, string.find
local cron = {}
local tag = "#Configi: "
local ENV = {} ;_ENV = ENV

local main = function (M, S)
  local C = Lib.configi.start(M, S)
  C.required = { "job", "name" }
  C.valid = { "minute", "hour", "day", "weekday", "month", "user", "file" }
  return Lib.configi.finish(C)
end

local list = function (F, P)
   return Cmd.crontab{ user = P.user, list = true, file = P.file }
end

local listed = function (F, P)
  local jobs = list(F, P)
  local ok, found
  local name = Lc.strf("%s%s", tag, P.name)
  if Lc.tfind(list(F, P), name, true) then
    F.msg(P.name, "cron.present", true)
    return true
  end
  return false
end

function cron.present (S)
  local M = { "minute", "hour", "day", "weekday", "month", "user", "file" }
  local ok, err, sec, F, P, R = nil, nil, nil, main(M, S)
  if listed(F, P) then
    return R
  else
    F.msg(P.name, "cron.present", false)
  end
  local minute, hour, day, month, weekday =
        P.minute or "*", P.hour or "*", P.day or "*", P.month or "*", P.weekday or "*"
  local job = Lc.strf("%s %s %s %s %s %s", minute, hour, day, month, weekday, P.job)
  local jobs = list(F, P)
  jobs[#jobs + 1] = Lc.strf("%s%s", tag, P.name)
  jobs[#jobs + 1] = job
  jobs = concat(jobs, "\n")
  ok, err, sec = F.run(Cmd.crontab, { _write = true, _input = jobs, user = P.user, file = P.file or "-" })
  F.msg(P.name, "cron.present", err, sec)
  if ok then
    F.msg(P.name, "cron.present", true)
    R.changed = true
  else
    R.failed = true
  end
  return R
end

function cron.absent (S)
  local M = { "user", "file" }
  local ok, err, sec, F, P, R = nil, nil, nil, main(M, S)
  if not listed(F, P) then
    F.msg(P.name, "cron.absent", true)
    return R
  else
    F.msg(P.name, "cron.absent", false)
  end
  local jobs = list(F, P)
  local name = Lc.strf("%s%s", tag, P.name)
  local ok, found
  for n, j in ipairs(jobs) do
    ok, found = pcall(find, j, name, 1, true)
    if ok and found then
      name = remove(jobs, n)
      remove(jobs, n)
    end
  end
  jobs = concat(jobs, "\n")
  ok, err, sec = F.run(Cmd.crontab, { _write = true, _input = jobs, user = P.user, file = P.file or "-" })
  F.msg(P.name, "cron.absent", err, sec)
  if ok then
    F.msg(P.name, "cron.absent", true)
    R.changed = true
  else
    R.failed = true
  end
  return R
end

return cron

