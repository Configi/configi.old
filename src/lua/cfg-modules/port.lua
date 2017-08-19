--- Test for listening ports.
-- @module port
-- @author Eduardo Tongson <propolice@gmail.com>
-- @license MIT <http://opensource.org/licenses/MIT>
-- @added 2.0.0

local M, port = {}, {}
local cfg = require"cfg-core.lib"
local socket = require"qsocket"
_ENV = nil

M.required = { "port", "ip" }
M.alias = {}
M.alias.protocol = { "prot" }
M.alias.payload = { "data", "send" }
M.alias.expect = { "receive" }

local scan = function(P)
  P:set_if_not("protocol", "tcp")
  if not P.payload then
    return socket[P.protocol]("-"..P.ip, P.port)
  else
    return socket[P.protocol](P.ip, P.port, P.payload)
  end
end

--- Test if something is listening on a specified port.
-- @Promiser string
-- @usage port.open"127.0.0.1"{
--   port = 80
-- }
function port.open(S)
  M.report = {
    kept = "port.open: Port open",
    failed = "port.open: Connection to port refused or timed out."
  }
  return function(P)
    P.ip = S
    local s = P.ip..":"..P.port
    local F, R = cfg.init(P, M)
    P:set_if_not("expect", true)
    if R.kept or (P.expect == scan(P)) then
      return F.kept(s)
    else
      return F.result(s, nil)
    end
  end
end
--- Test if connections to a specified port is refused.
-- @Promiser string
-- @usage port.closed"127.0.0.1"{
--   port = 23
-- }
function port.closed(S)
  M.report = {
    kept = "port.closed: Connection to port refused or timed out.",
    failed = "port.closed: Port open."
  }
  return function(P)
    P.ip = S
    local s = P.ip..":"..P.port
    local F, R = cfg.init(P, M)
    if R.kept then
      return F.kept(s)
    end
    if P.expect then
      if P.expect == scan(P) then
        return F.kept(s)
      else
        return F.result(s, nil)
      end
    else
      if not scan(P) then
        return F.kept(s)
      else
        return F.result(s, nil)
      end
    end
  end
end
port.refused = port.closed
return port
