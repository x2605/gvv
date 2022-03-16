return function(nilstr) return [[=function()

  local rm,po,mt,c,e,p,l,j,it={},{},{},0,0,0,0,0
  ]]--[[ rm:trouble path, po:potentially trouble path --]]..[[
  ]]--[[ c:normal count, e:error count, p:potential count --]]..[[
  ]]--[[ mt:metatable, l:metatable count, j:namespace count --]]..[[

  local du=function(b,m)
    ]]--[[ duplicator --]]..[[
    local n={}
    for i,v in ipairs(b) do n[#n+1]=v end
    n[#n+1]=m
    return n
  end

  local va=function(v)
    ]]--[[ LuaObject.valid for n/a to call .valid --]]..[[
    local s,a=pcall(function()return v.valid end)
    if s then return a else return end
  end
  local u={LuaGameScript=true,LuaBootstrap=true,LuaRemote=true,LuaCommandProcessor=true,LuaSettings=true,LuaRCON=true,LuaRendering=true,LuaLazyLoadedValue=true}
  ]]--[[ blacklisted --]]..[[

  it=function(b,pth,pa,o)
    ]]--[[ iterator --]]..[[
    ]]--[[ b = table, pth = path table, pa = parent table, o = table as key deep search mode boolean --]]..[[
    local t, y, pc
    for k,v in pairs(b) do
      t=type(k)
      y=type(v)
      if t=='function' or t=='userdata' or t=='thread' or y=='function' or y=='userdata' or y=='thread' then
        if o then return true
        else
          if t=='string' or t=='number' or t=='boolean' then
            rm[#rm+1]=du(pth,k) ]]..nilstr..[[ e=e+1
          elseif t=='table' and getmetatable(k)=='private' and k.object_name then
            j=j+1
            rm[#rm+1]=du(pth,k.object_name..j) ]]..nilstr..[[ e=e+1
          else
            j=j+1
            rm[#rm+1]=du(pth,t..j) ]]..nilstr..[[ e=e+1
          end
        end
      elseif t=='nil' then
        if o then
          if y=='table' and getmetatable(v)=='private' and v.object_name then
            if u[v.object_name] then return true
            else return false
            end
          elseif y=='table' then
            return it(v,nil,pa,true)
          end
        else
          j=j+1
          rm[#rm+1]=du(pth,t..j) ]]..nilstr..[[ e=e+1
        end
      elseif t=='table' and getmetatable(k)=='private' and k.object_name then
        if o then
          if u[k.object_name] then return true end
        else
          if va(k) and not u[k.object_name] then
            if y=='table' and getmetatable(v)=='private' and v.object_name then
              if u[v.object_name] then
                j=j+1
                rm[#rm+1]=du(pth,k.object_name..j) ]]..nilstr..[[ e=e+1
              else
                j=j+1
                po[#po+1]=du(pth,k.object_name..j) p=p+1
              end
            elseif y=='table' and getmetatable(v) then
              j=j+1
              po[#po+1]=du(pth,k.object_name..j) p=p+1
              mt[#mt+1]=du(pth,k.object_name..j) l=l+1
              ]]..--[[it(v,du(pth,k.object_name..j),pa)]][[
            elseif y=='table' then
              j=j+1
              po[#po+1]=du(pth,k.object_name..j) p=p+1
              it(v,du(pth,k.object_name..j),pa)
            else
              j=j+1
              po[#po+1]=du(pth,k.object_name..j) p=p+1
            end
          elseif u[k.object_name] then
            j=j+1
            rm[#rm+1]=du(pth,k.object_name..j) ]]..nilstr..[[ e=e+1
          else
            j=j+1
            rm[#rm+1]=du(pth,k.object_name..j) ]]..nilstr..[[ e=e+1
          end
        end
      elseif t=='table' then
        if o then
          return it(k,nil,pa,true)
        else
          if it(k,nil,pa,true) then
            j=j+1
            rm[#rm+1]=du(pth,t..j) ]]..nilstr..[[ e=e+1
          else
            if y=='table' and getmetatable(v)=='private' and v.object_name then
              if u[v.object_name] then
                j=j+1
                rm[#rm+1]=du(pth,t..j) ]]..nilstr..[[ e=e+1
              else
                j=j+1
                po[#po+1]=du(pth,t..j) p=p+1
              end
            elseif y=='table' and getmetatable(v) then
              j=j+1
              po[#po+1]=du(pth,t..j) p=p+1
              mt[#mt+1]=du(pth,t..j) l=l+1
              ]]..--[[it(v,du(pth,t..j),pa)]][[
            elseif y=='table' then
              j=j+1
              po[#po+1]=du(pth,t..j) p=p+1
              it(v,du(pth,t..j),pa)
            else
              j=j+1
              po[#po+1]=du(pth,t..j) p=p+1
            end
          end
        end
      elseif y=='table' and getmetatable(v)=='private' and v.object_name then
        if u[v.object_name] then
          if o then
            return true
          else
            rm[#rm+1]=du(pth,k) ]]..nilstr..[[ e=e+1
          end
        elseif o then
        else
          c=c+1
        end
      elseif y=='table' then
        if o then
          return it(v,nil,pa,true)
        elseif getmetatable(v) then
          mt[#mt+1]=du(pth,k) l=l+1
          ]]..--[[it(v,du(pth,pa,k))]][[
        else
          for k2,v2 in pairs(pa) do
            if v2==v then
              pc=true
              break
            end
          end
          if pc then
            c=c+1
          else
            local q={}
            ]]--[[ q:copy of p(parent) --]]..[[
            for k2,v2 in pairs(pa) do
              q[k2]=v2
            end
            q[#q+1]=v
            it(v,du(pth,k),q) c=c+1
          end
        end
      elseif o then
      else
        c=c+1
      end
    end
  end

  it(global,{},{global})

  return {trouble=rm,meta=mt,m_count=l,n_count=c,e_count=e,potential=po,p_count=p}
end,
]] end

-- global variable diagnose code 전역 변수 진단 코드
