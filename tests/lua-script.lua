local lua = {}
if not table.pack then
  function table.pack (...)
		return {n=select('#',...); ...}
  end
end
function lua.sequence()
  local tbl={"1", "2", "3", "4", "5"}
  local result={}
  for _,n in ipairs(tbl) do
    result[#result+1]=n
  end
  return table.concat(result)
end
function lua.ipairsnil()
  local tbl={"1", "2", "3", "4", "5"}
  local result={}
  tbl[4]=nil
  for _,n in ipairs(tbl) do
    result[#result+1]=n
  end
  return table.concat(result)
end
function lua.forloopnil()
  local tbl={"1", "2", "3", "4", "5"}
  local result={}
  tbl[4]=nil
  for n=1,#tbl do
    result[#result+1]=tbl[n]
  end
  -- returns 123 on Lua 5.1, LuaJIT
  -- returns 1235 on Lua 5.2+
  return table.concat(result)
end
function lua.nextsequence()
  local tbl={"1", "2", "3", "4", "5"}
  tbl[4]=nil
  local result={}
  local n = 0
  while next(tbl) do
    n = n + 1
    result[#result+1]=tbl[n]
    tbl[n]=nil
  end
  return table.concat(result)
end
function lua.multiplereturn()
  local test = function()
    return 1, 2, 3
  end
  local a, b, c, d, e = test(), 4, 5
  local result = table.pack(a, b, c, d, e)
  return table.concat(result)
end
function lua.updatetable1()
  local tbl={1}
  local result={}
  for k,v in ipairs(tbl) do
    tbl[k+1]=k+1
    result[#result+1]=tbl[k]
    if k==5 then break end
  end
  return table.concat(result)
end
function lua.updatetable2()
  local tbl={1}
  local result={}
  for k,v in pairs(tbl) do
    tbl[k+1]=k+1
    result[#result+1]=tbl[k]
    if k==5 then break end
  end
  return table.concat(result)
end
function lua.mixedtable1()
  local tbl={e=true,1,2}
  table.insert(tbl, 1, 0)
  return table.concat(tbl)
end
function lua.mixedtable2()
  local tbl={e=true,1,2}
  table.insert(tbl, 3, 3)
  return table.concat(tbl)
end
return lua

