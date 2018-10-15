C = require "configi"
P = {}
lsocket = require "lsocket"
base64 = require "plc.base64"
tostring = tostring
tolower = string.lower
string = require"lib".string
export _ENV = nil
scan = (p) ->
    conn, err = lsocket.connect(p.protocol, p.host, p.port)
    unless conn return nil, err
    lsocket.select(nil, {conn})
    ok, err = conn\status!
    unless ok return nil, err
    if p.payload
        sent = 0
        while sent != #p.payload
            lsocket.select(nil, {conn})
            sent += conn\send(string.sub(p.payload, sent, -1))
    if p.response
        if p.protocol == "udp"
            lsocket.select({conn})
            reply, err = conn\recv 1024
            if err
                conn\close!
                return nil, err
            conn\close!
            return {response:reply, size:string.len(reply)}
        if p.protocol == "tcp"
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
            return {response:reply, size:string.len(reply)}
    else
        conn\close!
        return {response:true, size:0}
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
--         host            = IP or hostname (string)
--         protocol        = TCP or UDP (string)
--         payload         = Payload to send when connecting to the port (string)
--         response        = Expect a string returned from the port connection (string)
--         size            = Expect a response length of this size (number)
--         base64_payload  = Base64 encoded payload (string)
--         base64_response = Base64 encoded expected response (string)
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
        C.parameter(p)
        if p.base64_payload then p.payload = base64.decode p.base64_payload
        if p.base64_response then p.response = base64.decode p.base64_response
        -- Default is TCP to localhost and expect boolean true from scan()
        p\set_if_not("protocol", "tcp")
        p\set_if_not("host", "127.0.0.1")
        p\set_if_not("response", true)
        p\set_if_not("size", 0)
        p.port = tostring port
        p.protocol = tolower p.protocol
        C["port.open :: #{p.host}:#{p.protocol}:#{p.port}"] = ->
            unless port return C.fail "Required `port` argument not set."
            ret, err  = scan(p)
            if ret == nil return C.fail err
            if p.response == ret.response or p.size == ret.size
                return C.pass!
            else
                if p.response != true
                    x = string.hexdump p.response
                    y = string.hexdump ret.response
                    return C.fail "Expected:\n#{x}\nGot:\n#{y}\n"
                if p.size != 0 return C.fail "Expected response size (#{p.size}), got (#{ret.size})."
                return C.fail "Expected response or response size not found."
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
        C.parameter(p)
        p.port = tostring port
        p\set_if_not("host", "127.0.0.1")
        p\set_if_not("protocol", "tcp")
        C["port.close :: #{p.host}:#{p.protocol}:#{p.port}"] = ->
            return C.fail "Required `port` argument not set." unless port
            ret, err  = scan(p)
            return C.fail "lsocket ERROR: #{err}" if err
            return C.pass! unless ret
            return C.fail "Port is open!" if ret.response == true
P.open = open
P.opened = open
P.close = close
P.closed = close
P
