C = require "configi"
P = {}
lsocket = require "lsocket"
tostring = tostring
tolower = string.lower
export _ENV = nil
scan = (p) ->
	conn = lsocket.connect(p.protocol, p.host, p.port)
	lsocket.select(nil, {conn})
	ok, err = conn\status!
	return nil, err unless ok
	if p.payload
		sent = 0
		while sent != #p.payload
			lsocket.select(nil, {conn})
			sent += conn\send(string.sub(p.payload, sent, -1))
	if p.expect
		reply = ""
		str = ""
		while nil != str
			lsocket.select({conn})
			str, err = conn\recv!
			reply ..= str if str
			if err
				conn\close!
				return nil, err
		conn\close!
		return reply
	else
		conn\close!
		return true
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
--        host = "test.internal.net"
--     }
open = (port) ->
    return (p) ->
        return C.fail "Required `port` argument not set." unless port
        C.parameter(p)
        -- Default is TCP to localhost and expect boolean true from scan()
        p\set_if_not("protocol", "tcp")
        p\set_if_not("host", "127.0.0.1")
        p\set_if_not("expect", true)
        p.port = tostring port
		p.protocol = tolower p.protocol
        C["port.open :: #{p.host}: #{p.protocol}:#{p.port}"] = ->
			ret, err  = scan(p)
            return C.pass! if p.expect == ret
            return C.equal(p.expect, ret, "Port is closed or expected response not received. lsocket ERROR: #{err}.")
-- Author: Eduardo Tongson <propolice@gmail.com>
-- License: MIT <http://opensource.org/licenses/MIT>
--
-- port.close(string, string/number)
--
-- Audit a port by determining if it is closed.
-- IPv4-only.
--
-- Argument:
--     (string/number) = port to check
--
-- Parameters:
--     (table)
--         host = IP or hostname (string)
--
-- Results:
--     Pass = Port is closed
--     Fail = Port is open
--
-- Examples:
--     port.close(22){
--        host = "test.internal.net"
--     }
close = (port) ->
    return (p) ->
        return C.fail "Required `port` argument not set." unless port
        C.parameter(p)
        p\set_if_not("host", "127.0.0.1")
        p.port = tostring port
        C["port.close :: #{p.host}:#{p.port}"] = ->
			ret, err  = scan(p)
            return C.fail "lsocket ERROR: #{err}" if err
            return C.pass! unless ret
            return C.fail "Port is open!" if ret == true
P.open = open
P.opened = open
P.close = close
P.closed = close
P
