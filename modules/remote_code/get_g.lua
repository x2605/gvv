return function() return [[=function()
  local G,_,j,s,cp=_G,true,0,{}
  local B={_G=_,assert=_,collectgarbage=_,error=_,getmetatable=_,ipairs=_,load=_,loadstring=_,next=_,pairs=_,pcall=_,print=_,rawequal=_,rawlen=_,rawget=_,rawset=_,select=_,setmetatable=_,tonumber=_,tostring=_,type=_,xpcall=_,_VERSION=_,unpack=_,table=_,string=_,bit32=_,math=_,debug=_,serpent=_,log=_,localised_print=_,table_size=_,package=_,require=_,global=_,remote=_,commands=_,settings=_,rcon=_,rendering=_,script=_,defines=_,game=_,}
  local N={LuaGameScript=_,LuaBootstrap=_,LuaRemote=_,LuaCommandProcessor=_,LuaSettings=_,LuaRCON=_,LuaRendering=_,LuaLazyLoadedValue=_,LuaCustomTable=_,LuaDifficultySettings=_,LuaFlowStatistics=_,}
  ]]--[[ G:_G, j:namespace count, s:returning table --]]..[[
  ]]--[[ B:_G blacklist, N:object blacklist --]]..[[
  cp=function(o,p,a)
    ]]--[[ o:object, p:parent_list, a:as key? --]]..[[
    local t,r=type(o)
    if t=='table' and type(o.__self)=='userdata' and o.object_name then
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
  for k,v in pairs(G) do
    if not B[k] then
      s[cp(k,{_G},true)]=cp(v,{_G})
    end
  end
  return s
end,
]] end

-- _G variable copy code, _G 변수 복사 코드
