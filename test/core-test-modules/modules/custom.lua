-- @module custom
-- @author Eduardo Tongson <propolice@gmail.com>
-- @license MIT <http://opensource.org/licenses/MIT>

local M, custom = {}, {}
local cfg = require"cfg-core.lib"
_ENV = nil

M.required = { "path" }

function custom.fail(S)
  M.report = {
    repaired = "custom.action: Success.",
    kept = "custom.action: Skipped.",
    failed = "custom.action: Failure."
  }
  return function(P)
    P.path = S
    local F, R = cfg.init(P, M)
    return F.result(P.path)
  end
end
function custom.ok(S)
  M.report={
    repaired="ok",
    kept ="pass",
    failed = "fail"
  }
  return function(P)
    P.path = S
    local F, R = cfg.init(P, M)
    return F.result(P.path, true)
  end
end
function custom.another(S)
  M.report={
    repaired="another ok",
    kept ="pass",
    failed = "fail"
  }
  return function(P)
    P.path = S
    local F, R = cfg.init(P, M)
    return F.result(P.path, true)
  end
end
return custom
