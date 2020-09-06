-- command 커맨드

-- 추가 인수를 arg[1], arg[2]... 으로 소환할 수 있다.

return function() return [[=function(t,...)
  local i = #global+1
  global[i]=table.pack(...)
  local m = setmetatable({},global[i])
  local pc, ret = pcall(function() assert(loadstring('local arg=global['..i..'] global['..i..']=nil '..t))() end)
  if not pc then
    if getmetatable(m)==global[i] then global[i]=nil end
  end
  return pc, ret
end,
]] end
