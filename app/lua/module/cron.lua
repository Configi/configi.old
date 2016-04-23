--- Ensure that a cron job is present or absent in a user's crontab.
-- <br />
-- Only tested with vixie-cron and Busybox cron.
-- @module cron
-- @author Eduardo Tongson <propolice@gmail.com>
-- @license MIT <http://opensource.org/licenses/MIT>
-- @added 0.9.0

local ipairs, pcall, next = ipairs, pcall, next
local string, table = string, table
local fn = {}
local cfg = require"configi"
local lib = require"lib"
local cmd = lib.cmd
local cron = {}
local tag = "#" .. string.char(9) .. "Configi: " -- hackish anti-match tech.
local ENV = {}
_ENV = ENV

local main = function (S, M, G)
  local C = cfg.start(S, M, G)
  C.required = { "name", "job" }
  return cfg.finish(C)
end

local genjob = function (P)
  local minute, hour, day, month, weekday = P.minute or "*", P.hour or "*", P.day or "*", P.month or "*", P.weekday or "*"
  return string.format("%s %s %s %s %s %s", minute, hour, day, month, weekday, P.job)
end

local list = function (P)
  local t, r = cmd["crontab"]{ "-u", P.user, "-l" }
  if t then
    -- filter out comments except for Configi tag names
    return lib.filter_tbl_value(r.stdout, "^#[%C]+")
  else
    return {}
  end
end

local find_name = function (jobs, cronjob)
  for line, v in next, jobs do
    if v == cronjob then return true, line end
  end
  return false, 0
end

local listed = function (P)
  local jobs = list(P)
  local name = string.format("%s%s", tag, P.name)
  local n, l = find_name(jobs, name)
  local _, j = pcall(string.find, jobs[l+1], P.job, 1, true) 
  if n and j then return true end
end

local remove = function (tbl, name)
  local s, c = #tbl, 0
  local ok, found
  for n = 1, s do
    ok, found = pcall(string.find, tbl[n], "^" .. name .. "$", 1)
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
    repaired = "cron.present: Successfully added Cron job.",
    kept = "cron.present: Cron job already present.",
    failed = "cron.present: Error adding Cron job"
  }
  local F, P, R = main(S, M, G)
  if P.user == nil then
    P.user = lib.getename()
  end
  local jobs = list(P)
  P.cronjob = genjob(P) -- Replace P.job with prepended scheduling info. This is used by Func.listed
  local islisted = listed(P)
  if islisted == true then
    return F.kept(P.name)
  end
  jobs[#jobs + 1] = string.format("%s%s", tag, P.name)
  jobs[#jobs + 1] = P.cronjob
  jobs = table.concat(jobs, "\n") -- tostring(jobs)
  jobs = jobs .. "\n" -- vixie-cron needs a blank line at the end. Complains about a premature EOF.
  return F.result(P.name, F.run(cmd["crontab"], { _stdin = jobs, "-u", P.user, "-" }))
end

--- Remove a job from a user's crontab.
-- @param name tag string [REQUIRED]
-- @param job the command or job string [REQUIRED]
-- @param user user login to operate on [DEFAULT: "root"]
-- @usage cron.absent [[
--   name "example"
--   job "/bin/ls"
--   user "ed"
-- ]]
function cron.absent (S)
  local M = { "minute", "hour", "day", "weekday", "month", "user" }
  local G = {
    repaired = "cron.absent: Successfully removed Cron job.",
    kept = "cron.absent: Cron job already absent.",
    failed = "cron.absent: Error removing Cron job."
  }
  local F, P, R = main(S, M, G)
  if P.user == nil then
    P.user = lib.getename()
  end
  local jobs = list(P)
  if not next(jobs) or not listed(P) then
    return F.kept(P.name)
  end
  P.cronjob = genjob(P)
  jobs = table.concat(remove(jobs, string.format("%s%s", tag, P.name)), "\n")
  jobs = jobs .. "\n"
  return F.result(P.name, F.run(cmd["crontab"], { _stdin = jobs, "-u", P.user, "-"}))
end

return cron

