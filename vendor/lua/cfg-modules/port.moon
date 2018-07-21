C = require "configi"
P = {}
S = require "qsocket"
tostring = tostring
export _ENV = nil
scan = (p) ->
    if not p.payload
        return S[p.protocol]("-"..p.host, p.port)
    else
        return S[p.protocol](p.host, p.port, p.payload)
-- Module: port
-- Function: open
-- Author: Eduardo Tongson <propolice@gmail.com>
-- License: MIT <http://opensource.org/licenses/MIT>
--
-- port.open(string, string/number)
--
-- Audit a port by determining if it is open or closed.
-- IPv4-only.
--
-- Argument:
--     (string/number) = port to check
--
-- Parameters:
--     (table)
--         host     = IP or hostname (string)
--         protocol = TCP or UDP (string)
--         payload  = Payload to send when connecting to the port (string)
--         expect   = Expect a string returned from the port connection (string)
--
-- Results:
--     Pass = Port is open and expected response received
--     Fail = Port is closed or expected response not received
--
-- Examples:
--     port.open(22){
--        hostname = "test.internal.net"
--     }
open = (port) ->
    return (p) ->
        p.port = tostring(port)
        C.parameter(p)
        p\set_if_not("protocol", "tcp")
        p\set_if_not("host", "127.0.0.1")
        p\set_if_not("expect", true)
        C["port.open :: #{p.host}:#{p.port}"] = ->
            if p.expect == scan(p)
                C.pass!
            else
                C.fail("Port is closed or expected response not received.")
P.open = open
P
