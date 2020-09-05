-- 컨트롤

require('modules.register_event')

--[[
download :
https://mods.factorio.com/mod/gvv

github :
https://github.com/x2605/gvv

--]]

-- Copy & paste following code at the end of empty line of "control.lua" file of other mod or savefile or scenario.
-- 다음 코드를 다른 모드나 세이브파일, 또는 시나리오에 있는 "control.lua" 파일의 마지막 빈 줄에 복사&붙여넣기 하세요.

--
-- This is a part of "gvv", "Lua API global Variable Viewer" mod.
-- It makes possible to read sandboxed variables in the map or other mod if following code is inserted at the end of empty line of "control.lua" of each.

remote.add_interface("__"..script.mod_name.."__gvv",{global=function() return global end, diag=function() local rm,po,mt,c,e,p,l,j,it={},{},{},0,0,0,0,0 local du=function(b,m) local n={} for i,v in ipairs(b) do n[#n+1]=v end n[#n+1]=m return n end local va=function(v) local s,a=pcall(function()return v.valid end) if s then return a else return end end local u={LuaGameScript=true,LuaBootstrap=true,LuaRemote=true,LuaCommandProcessor=true,LuaSettings=true,LuaRCON=true,LuaRendering=true} it=function(b,pth,o) local t for k,v in pairs(b) do t=type(k) y=type(v) if t=='function' or t=='userdata' or t=='thread' or y=='function' or y=='userdata' or y=='thread' then if o then return true else j=j+1 rm[#rm+1]=du(pth,t..j) e=e+1 end elseif t=='nil' then if o then if y=='table' and getmetatable(v)=='private' and v.object_name then if u[v.object_name] then return true else return false end elseif y=='table' then return it(v,nil,true) end else j=j+1 rm[#rm+1]=du(pth,t..j) e=e+1 end elseif t=='table' and getmetatable(k)=='private' and k.object_name then if o then if u[k.object_name] then return true end else if va(k) and not u[k.object_name] then if y=='table' and getmetatable(v)=='private' and v.object_name then if u[v.object_name] then j=j+1 rm[#rm+1]=du(pth,k.object_name..j) e=e+1 else j=j+1 po[#po+1]=du(pth,k.object_name..j) p=p+1 end elseif y=='table' and getmetatable(v) then j=j+1 po[#po+1]=du(pth,k.object_name..j) p=p+1 mt[#mt+1]=du(pth,k.object_name..j) l=l+1 it(v,du(pth,k.object_name..j)) elseif y=='table' then j=j+1 po[#po+1]=du(pth,k.object_name..j) p=p+1 it(v,du(pth,k.object_name..j)) else j=j+1 po[#po+1]=du(pth,k.object_name..j) p=p+1 end elseif u[k.object_name] then j=j+1 rm[#rm+1]=du(pth,k.object_name..j) e=e+1 else j=j+1 rm[#rm+1]=du(pth,k.object_name..j) e=e+1 end end elseif t=='table' then if o then return it(k,nil,true) else if it(k,nil,true) then j=j+1 rm[#rm+1]=du(pth,t..j) e=e+1 else if y=='table' and getmetatable(v)=='private' and v.object_name then if u[v.object_name] then j=j+1 rm[#rm+1]=du(pth,t..j) e=e+1 else j=j+1 po[#po+1]=du(pth,t..j) p=p+1 end elseif y=='table' and getmetatable(v) then j=j+1 po[#po+1]=du(pth,t..j) p=p+1 mt[#mt+1]=du(pth,t..j) l=l+1 it(v,du(pth,t..j)) elseif y=='table' then j=j+1 po[#po+1]=du(pth,t..j) p=p+1 it(v,du(pth,t..j)) else j=j+1 po[#po+1]=du(pth,t..j) p=p+1 end end end elseif y=='table' and getmetatable(v)=='private' and v.object_name then if u[v.object_name] then if o then return true else rm[#rm+1]=du(pth,k) e=e+1 end elseif o then else c=c+1 end elseif y=='table' then if o then return it(v,nil,true) elseif getmetatable(v) then mt[#mt+1]=du(pth,k) l=l+1 it(v,du(pth,k)) else it(v,du(pth,k)) c=c+1 end elseif o then else c=c+1 end end end it(global,{}) return {trouble=rm,meta=mt,m_count=l,n_count=c,e_count=e,potential=po,p_count=p} end, fix=function() local rm,po,mt,c,e,p,l,j,it={},{},{},0,0,0,0,0 local du=function(b,m) local n={} for i,v in ipairs(b) do n[#n+1]=v end n[#n+1]=m return n end local va=function(v) local s,a=pcall(function()return v.valid end) if s then return a else return end end local u={LuaGameScript=true,LuaBootstrap=true,LuaRemote=true,LuaCommandProcessor=true,LuaSettings=true,LuaRCON=true,LuaRendering=true} it=function(b,pth,o) local t for k,v in pairs(b) do t=type(k) y=type(v) if t=='function' or t=='userdata' or t=='thread' or y=='function' or y=='userdata' or y=='thread' then if o then return true else j=j+1 rm[#rm+1]=du(pth,t..j) b[k]=nil e=e+1 end elseif t=='nil' then if o then if y=='table' and getmetatable(v)=='private' and v.object_name then if u[v.object_name] then return true else return false end elseif y=='table' then return it(v,nil,true) end else j=j+1 rm[#rm+1]=du(pth,t..j) b[k]=nil e=e+1 end elseif t=='table' and getmetatable(k)=='private' and k.object_name then if o then if u[k.object_name] then return true end else if va(k) and not u[k.object_name] then if y=='table' and getmetatable(v)=='private' and v.object_name then if u[v.object_name] then j=j+1 rm[#rm+1]=du(pth,k.object_name..j) b[k]=nil e=e+1 else j=j+1 po[#po+1]=du(pth,k.object_name..j) p=p+1 end elseif y=='table' and getmetatable(v) then j=j+1 po[#po+1]=du(pth,k.object_name..j) p=p+1 mt[#mt+1]=du(pth,k.object_name..j) l=l+1 it(v,du(pth,k.object_name..j)) elseif y=='table' then j=j+1 po[#po+1]=du(pth,k.object_name..j) p=p+1 it(v,du(pth,k.object_name..j)) else j=j+1 po[#po+1]=du(pth,k.object_name..j) p=p+1 end elseif u[k.object_name] then j=j+1 rm[#rm+1]=du(pth,k.object_name..j) b[k]=nil e=e+1 else j=j+1 rm[#rm+1]=du(pth,k.object_name..j) b[k]=nil e=e+1 end end elseif t=='table' then if o then return it(k,nil,true) else if it(k,nil,true) then j=j+1 rm[#rm+1]=du(pth,t..j) b[k]=nil e=e+1 else if y=='table' and getmetatable(v)=='private' and v.object_name then if u[v.object_name] then j=j+1 rm[#rm+1]=du(pth,t..j) b[k]=nil e=e+1 else j=j+1 po[#po+1]=du(pth,t..j) p=p+1 end elseif y=='table' and getmetatable(v) then j=j+1 po[#po+1]=du(pth,t..j) p=p+1 mt[#mt+1]=du(pth,t..j) l=l+1 it(v,du(pth,t..j)) elseif y=='table' then j=j+1 po[#po+1]=du(pth,t..j) p=p+1 it(v,du(pth,t..j)) else j=j+1 po[#po+1]=du(pth,t..j) p=p+1 end end end elseif y=='table' and getmetatable(v)=='private' and v.object_name then if u[v.object_name] then if o then return true else rm[#rm+1]=du(pth,k) b[k]=nil e=e+1 end elseif o then else c=c+1 end elseif y=='table' then if o then return it(v,nil,true) elseif getmetatable(v) then mt[#mt+1]=du(pth,k) l=l+1 it(v,du(pth,k)) else it(v,du(pth,k)) c=c+1 end elseif o then else c=c+1 end end end it(global,{}) return {trouble=rm,meta=mt,m_count=l,n_count=c,e_count=e,potential=po,p_count=p} end, })

-- Anyway, other mods or console command can also access it via following examples if this code is set.
-- global_of_map = remote.call('__level__gvv','global')
-- global_of['My-Mod 1'] = remote.call('__My-Mod 1__gvv','global')
-- global_of[mod_name] = remote.call('__'..mod_name..'__gvv','global')
-- This trick can be used without gvv mod. gvv uses only global for reading.
-- Only "fix" function included here can modify the mod or map's global table.
-- "fix" removes entries which LuaRemote can't handle.
--

--
-- 이 코드는 "gvv", "Lua API global Variable Viewer" 모드의 일부입니다.
-- 다른 모드나 지도의 "control.lua" 빈 줄 끝에 삽입하면 맵이나 다른 모드에서 샌드박스처리된 global 변수를 읽을 수 있습니다.

-- 아무튼, 이 코드가 설정되어 있으면 다른 모드나 콘솔 명령도 다음 예제를 통해서 액세스 할 수 있습니다.
-- 지도의 global 변수 = remote.call('__level__gvv','global')
-- 'My-Mod 1'의 global 변수 = remote.call('__My-Mod 1__gvv','global')
-- mod_name의 global 변수 = remote.call('__'..mod_name..'__gvv','global')
-- 이 트릭은 gvv 모드없이 사용할 수 있습니다. gvv는 읽기를 위해서 global을 사용합니다.
-- 오직 여기에 포함된 "fix" 함수만이 모드나 지도의 global 테이블을 변경할 수 있습니다.
-- "fix"는 LuaRemote가 처리하지 못하는 항목을 삭제합니다.
--
