return function() return [[=function(t,...)
  local i=#storage+1
  storage[i]=table.pack(...)
  local m=setmetatable({},storage[i])
  local pc,ret=pcall(function() assert(loadstring('local arg=storage['..i..'] storage['..i..']=nil '..t))() end)
  if not pc then
    if getmetatable(m)==storage[i] then storage[i]=nil end
  end
  return pc,ret
end,
]] end

-- command 커맨드

-- 추가 인수를 arg[1], arg[2]... 으로 소환할 수 있다.
