return function() return [[=function()
  local G,_,j,s,cp,wr=storage,true,0,{}
  local B={}
  local N={LuaGameScript=_,LuaBootstrap=_,LuaRemote=_,LuaCommandProcessor=_,LuaSettings=_,LuaRCON=_,LuaRendering=_,LuaLazyLoadedValue=_,LuaCustomTable=_,LuaDifficultySettings=_,LuaFlowStatistics=_,}
  ]]--[[ G:_G, j:namespace count, s:returning table --]]..[[
  ]]--[[ B:_G blacklist, N:object blacklist --]]..[[
  cp=function(o,p,a)
    local c,r=pcall(wr,o,p,a)
    if c then return r
    else return {['<ERROR>'] = '<'..r..'>'} end
  end
  wr=function(o,p,a)
    ]]--[[ o:object, p:parent_list, a:as key? --]]..[[
    local t,r=type(o)
    if t=='userdata' and getmetatable(o)=='private' and o.object_name then
      if a or (N[o.object_name] or o.object_name:match('^LuaMapSettings')) then
        j=j+1
        r='<'..o.object_name..j..'>'
      else
        r=o
      end
    elseif t=='table' then
      if a then
        j=j+1
        r='<table'..j..'>'
      else
        local c
        ]]--[[ c:recursive? --]]..[[
        for k,v in pairs(p) do
          if v==o then
            c=true
            break
          end
        end
        if c then
          r='<recursive table>'
        else
          r={}
          local q={}
          ]]--[[ q:copy of p(parent) --]]..[[
          for k,v in pairs(p) do
            q[k]=v
          end
          q[#q+1]=o
          for k,v in next,o,nil do
            r[cp(k,q,true)]=cp(v,q)
          end
        end
      end
    elseif t=='function' or t=='userdata' or t=='thread' or t=='nil' then
      if a then
        j=j+1
        r='<'..t..j..'>'
      else
        r='<'..t..'>'
      end
    else
      r=o
    end
    return r
  end
  for k,v in next,G,nil do
    if not B[k] then
      s[cp(k,{storage},true)]=cp(v,{storage})
    end
  end
  return s
end,
]] end

-- storage variable copy code, storage 변수 복사 코드
