C = require "configi"
type, tostring, pairs = type, tostring, pairs
S = {}
export _ENV = nil
test_fail = (t) ->
    return (p) ->
        C["test.test_fail :: #{t}"] = ->
            C.equal(0, 1, "Did not match")
            C.print "prints someting"
            return C.pass if p

test = (t) ->
    return (p) ->
        C["test.test :: #{t}"] = ->
            C.equal(0, 0, "Did not match")
            C.print "prints someting"
            return C.pass if p
register_table = (t) ->
    return (p) ->
        C["test.register_table :: #{t}"] = ->
            C.equal(0, 0, "Did not match")
            for k, v in pairs p.register
                C.register(k, v)
register_value = (t) ->
    return (p) ->
        C["test.register_value :: #{t}"] = ->
            C.equal(0, 0, "Did not match")
            C.register(p.register, "value")
S["test"] = test
S["test_fail"] = test_fail
S["register_table"] = register_table
S["register_value"] = register_value
S
