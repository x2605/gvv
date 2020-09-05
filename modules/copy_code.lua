--복사 가능한 코드

local Copy_Code = {}

local codes = {}

local version_code = function() return [[version=function()
  return '1'
end,
]] end

local fix_code = function(nilstr) return [[=function()
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
  local u={LuaGameScript=true,LuaBootstrap=true,LuaRemote=true,LuaCommandProcessor=true,LuaSettings=true,LuaRCON=true,LuaRendering=true}
  it=function(b,pth,o)
    ]]--[[ iterator --]]..[[
    ]]--[[ b = table, pth = path table, o = table as key deep search mode boolean --]]..[[
    local t
    for k,v in pairs(b) do
      t=type(k)
      y=type(v)
      if t=='function' or t=='userdata' or t=='thread' or y=='function' or y=='userdata' or y=='thread' then
        if o then return true
        else
          j=j+1
          rm[#rm+1]=du(pth,t..j) ]]..nilstr..[[ e=e+1
        end
      elseif t=='nil' then
        if o then
          if y=='table' and getmetatable(v)=='private' and v.object_name then
            if u[v.object_name] then return true
            else return false
            end
          elseif y=='table' then
            return it(v,nil,true)
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
              it(v,du(pth,k.object_name..j))
            elseif y=='table' then
              j=j+1
              po[#po+1]=du(pth,k.object_name..j) p=p+1
              it(v,du(pth,k.object_name..j))
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
          return it(k,nil,true)
        else
          if it(k,nil,true) then
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
              it(v,du(pth,t..j))
            elseif y=='table' then
              j=j+1
              po[#po+1]=du(pth,t..j) p=p+1
              it(v,du(pth,t..j))
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
          return it(v,nil,true)
        elseif getmetatable(v) then
          mt[#mt+1]=du(pth,k) l=l+1
          it(v,du(pth,k))
        else
          it(v,du(pth,k)) c=c+1
        end
      elseif o then
      else
        c=c+1
      end
    end
  end
  it(global,{})
  return {trouble=rm,meta=mt,m_count=l,n_count=c,e_count=e,potential=po,p_count=p}
end,
]] end


codes.in_control_lua = [[
if script.active_mods["gvv"] then require("__gvv__.gvv")() end
]]


codes.in_console_enable = [[/c
remote.add_interface("__level__gvv",{global=function() return global end,
diag]]..fix_code('')..[[
fix]]..fix_code('b[k]=nil')..[[
]]..version_code()..[[
})
]]


codes.in_console_disable = [[/c
remote.remove_interface("__level__gvv")
]]


for k,code in pairs(codes) do
  codes[k] = code:gsub('^\n',''):gsub('\n$',''):gsub('\n',' '):gsub('%s+',' ')
end

Copy_Code.in_control_lua = function()
  return codes.in_control_lua
end

Copy_Code.in_console_enable = function()
  return codes.in_console_enable
end

Copy_Code.in_console_disable = function()
  return codes.in_console_disable
end

return Copy_Code
