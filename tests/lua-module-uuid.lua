package.path="vendor/lua/?.lua;lib/?.lua;lib/?/init.lua"
local uuid = require "uuid"
local T = require "u-test"
T["uuid.new"] = function()
  uuid.seed()
  local first = uuid.new()
  local second = uuid.new()
  T.not_equal(first, second)
end
T["uuid"] = function()
  local first = uuid()
  local second = uuid()
  T.not_equal(first, second)
end
