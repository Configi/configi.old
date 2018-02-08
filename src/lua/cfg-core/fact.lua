local auto
function auto()
  return setmetatable({}, {__index = auto})
end
return setmetatable({}, {__index = auto})
