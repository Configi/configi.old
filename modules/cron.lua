--- Ensure that a cron job is present or absent in a user's crontab.
-- <br />
-- Only tested with vixie-cron and Busybox cron.
-- @module cron
-- @author Eduardo Tongson <propolice@gmail.com>
-- @license MIT <http://opensource.org/licenses/MIT>
-- @added 0.9.0

local Lua = {
  ipairs = ipairs,
  pcall = pcall,
  next = next,
  char = string.char,
  concat = table.concat,
  remove = table.remove,
  find = string.find
}
local Func = {}
local Configi = require"configi"
local Lc = require"cimicida"
local Px = require"px"
local Cmd = Px.cmd
local cron = {}
local tag = "#" .. Lua.char(9) .. "Configi: " -- hackish anti-match tech.
local ENV = {}
_ENV = ENV

local main = function (S, M, G)
  local C = Configi.start(S, M, G)
  C.required = { "name", "job" }
  return Configi.finish(C)
end

Func.genjob = function (P)
  local minute, hour, day, month, weekday =
        P.minute or "*", P.hour or "*", P.day or "*", P.month or "*", P.weekday or "*"
  return Lc.strf("%s %s %s %s %s %s", minute, hour, day, month, weekday, P.job)
end

Func.list = function (P)
  local t, _, r = Cmd["crontab"]{ "-u", P.user, "-l" }
  if t then
    -- filter out comments except for Configi tag-names
    return Lc.filtertval(r.stdout, "^#[%C]+")
  else
    return {}
  end
end

Func.listed = function (P)
  local jobs = Func.list(P)
  local name = Lc.strf("%s%s", tag, P.name)
  local n = Lc.tfind(jobs, "^" .. name .. "$", false)
  if n and jobs[n + 1] == P.job then
    return true
  else
    return n
  end
end

Func.remove = function (tbl, name)
  local s, c = #tbl, 0
  local ok, found
  for n = 1, s do
    ok, found = Lua.pcall(Lua.find, tbl[n], "^" .. name .. "$", 1)
    if ok and found then
      -- delete name and job
      tbl[n] = nil
      tbl[n + 1] = nil
    end
  end
  for n = 1, s do
    if tbl[n] ~= nil then
      c = c + 1
      tbl[c] = tbl[n]
    end
  end
  for n = c + 1, s do
    tbl[n] = nil
  end
  return tbl
end


--- Add a job to a user's crontab. <br />
-- Cron jobs that does not match its tag are replaced. <br />
-- See crontab(5)
-- @param name tag to track jobs [REQUIRED]
-- @param job the command or job to add [REQUIRED]
-- @param user user login to operate on [DEFAULT: "root"]
-- @param minute minute value [DEFAULT: "*"]
-- @param hour hour value [DEFAULT: "*"]
-- @param day day value [DEFAULT: "*"]
-- @param weekday weekday value [DEFAULT: "*"]
-- @param month month value [DEFAULT: "*"]
-- @usage cron.present [[
--   name "example"
--   job "/bin/ls"
--   minute "5"
--   hour "3"
--   day "2"
--   weekday "2"
--   month "5"
--   user "ed"
-- ]
function cron.present (S)
  local M = { "minute", "hour", "day", "weekday", "month", "user" }
  local G = {
    ok = "cron.present: Successfully added Cron job.",
    skip = "cron.present: Cron job already present.",
    fail = "cron.present: Error adding Cron job"
  }
  local F, P, R = main(S, M, G)
  if P.user == nil then
    P.user = Px.getename()
  end
  local jobs = Func.list(P)
  P.job = Func.genjob(P) -- Replace P.job with prepended scheduling info. This is used by Func.listed
  local listed = Func.listed(P)
  if listed == true then
    return F.skip(P.name)
  end
  -- Removes jobs[listed] (name) and the unmatching jobs[listed+1] (job)
  if listed then
    Func.remove(jobs, Lc.strf("%s%s", tag, P.name))
  end
  jobs[#jobs + 1] = Lc.strf("%s%s", tag, P.name)
  jobs[#jobs + 1] = P.job
  jobs = Lua.concat(jobs, "\n") -- tostring(jobs)
  jobs = jobs .. "\n" -- vixie-cron needs a blank line at the end. Complains about a premature EOF.
  return F.result(F.run(Cmd["crontab"], { _stdin = jobs, "-u", P.user, "-" }), P.name)
end

--- Remove a job from a user's crontab.
-- @param name tag string [REQUIRED]
-- @param job the command or job string [REQUIRED]
-- @param user user login to operate on [DEFAULT: "root"]
-- @usage cron.present [[
--   name "example"
--   job "/bin/ls"
--   user "ed"
-- ]]
function cron.absent (S)
  local M = { "minute", "hour", "day", "weekday", "month", "user" }
  local G = {
    ok = "cron.absent: Successfully removed Cron job.",
    skip = "cron.absent: Cron job already absent.",
    fail = "cron.absent: Error removing Cron job."
  }
  local F, P, R = main(S, M, G)
  if P.user == nil then
    P.user = Px.getename()
  end
  local jobs = Func.list(P)
  if not Lua.next(jobs) or not Func.listed(P) then
    return F.skip(P.name)
  end
  P.job = Func.genjob(P)
  jobs = Lua.concat(Func.remove(jobs, Lc.strf("%s%s", tag, P.name)), "\n")
  jobs = jobs .. "\n"
  return F.result(F.run(Cmd["crontab"], { _stdin = jobs, "-u", P.user, "-"}), P.name)
end

return cron

