C = require "configi"
tostring, pairs = tostring, pairs
E = require "configi.env"
S = {}
export _ENV = nil
test = (type) ->
    return (p) ->
      C["test :: #{type}"] = ->
        C.equal(0, 1, "Did not match")
        C.print "prints someting"
        if p.register
            for k, v in pairs p.register
                E[k] = v
S["test"] = test
S
