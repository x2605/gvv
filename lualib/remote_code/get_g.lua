---**EN**
---
---Description: Template of the code that returns a transportable copy of `_G` (console / copy_code).
---
---──────────────────────────────
---
---**FR**
---
---Description: Modèle du code qui renvoie une copie transportable de `_G` (console / copy_code).
---@return string  Lua code starting with "=function"
return function() return [[=function()
  local G,_,s,cp,wr,kn=_G,true,{}
  local B={_G=_,assert=_,collectgarbage=_,error=_,getmetatable=_,ipairs=_,load=_,loadstring=_,next=_,pairs=_,pcall=_,print=_,rawequal=_,rawlen=_,rawget=_,rawset=_,select=_,setmetatable=_,tonumber=_,tostring=_,type=_,xpcall=_,_VERSION=_,unpack=_,table=_,string=_,bit32=_,math=_,debug=_,serpent=_,log=_,localised_print=_,table_size=_,package=_,require=_,storage=_,remote=_,commands=_,settings=_,rcon=_,rendering=_,script=_,defines=_,game=_,}
  local N={LuaGameScript=_,LuaBootstrap=_,LuaRemote=_,LuaCommandProcessor=_,LuaSettings=_,LuaRCON=_,LuaRendering=_,LuaLazyLoadedValue=_,LuaCustomTable=_,LuaDifficultySettings=_,LuaFlowStatistics=_,LuaPrototypes=_,LuaHelpers=_,LuaDebugAdapter=_,}
  ]]--[[ G:_G, s:returning table, kn:numbered key name per table (J:counters of the table) --]]..[[
  kn=function(J,n)
    J[n]=(J[n] or 0)+1
    return '<'..n..'_'..J[n]..'>'
  end
  ]]--[[ B:_G blacklist, N:object blacklist --]]..[[
  cp=function(o,p,a,J)
    local c,r=pcall(wr,o,p,a,J)
    if c then return r
    else return {['<ERROR>'] = '<'..r..'>'} end
  end
  wr=function(o,p,a,J)
    ]]--[[ o:object, p:parent_list, a:as key? --]]..[[
    local t,r=type(o)
    if t=='userdata' and getmetatable(o)=='private' and o.object_name then
      if a then
        r=kn(J,o.object_name)
      elseif N[o.object_name] or o.object_name:match('^LuaMapSettings') then
        r='<'..o.object_name..'>'
      else
        r=o
      end
    elseif t=='table' then
      if a then
        r=kn(J,'table')
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
          local K={}
          for k,v in next,o,nil do
            r[cp(k,q,true,K)]=cp(v,q)
          end
        end
      end
    elseif t=='function' or t=='userdata' or t=='thread' or t=='nil' then
      if a then
        r=kn(J,t)
      else
        r='<'..t..'>'
      end
    else
      r=o
    end
    return r
  end
  local J={}
  for k,v in next,G,nil do
    if not B[k] then
      s[cp(k,{_G},true,J)]=cp(v,{_G})
    end
  end
  return s
end,
]] end

-- _G variable copy code, _G 변수 복사 코드
