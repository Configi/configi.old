local lua = {}
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
return lua

