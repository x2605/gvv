
return function()
remote.add_interface("__"..script.mod_name.."__gvv",{global=function() return global end, diag=function() local rm,po,mt,c,e,p,l,j,it={},{},{},0,0,0,0,0 local du=function(b,m) local n={} for i,v in ipairs(b) do n[#n+1]=v end n[#n+1]=m return n end local va=function(v) local s,a=pcall(function()return v.valid end) if s then return a else return end end local u={LuaGameScript=true,LuaBootstrap=true,LuaRemote=true,LuaCommandProcessor=true,LuaSettings=true,LuaRCON=true,LuaRendering=true} it=function(b,pth,o) local t for k,v in pairs(b) do t=type(k) y=type(v) if t=='function' or t=='userdata' or t=='thread' or y=='function' or y=='userdata' or y=='thread' then if o then return true else if t=='string' or t=='number' or t=='boolean' then rm[#rm+1]=du(pth,k) e=e+1 elseif t=='table' and getmetatable(k)=='private' and k.object_name then j=j+1 rm[#rm+1]=du(pth,k.object_name..j) e=e+1 else j=j+1 rm[#rm+1]=du(pth,t..j) e=e+1 end end elseif t=='nil' then if o then if y=='table' and getmetatable(v)=='private' and v.object_name then if u[v.object_name] then return true else return false end elseif y=='table' then return it(v,nil,true) end else j=j+1 rm[#rm+1]=du(pth,t..j) e=e+1 end elseif t=='table' and getmetatable(k)=='private' and k.object_name then if o then if u[k.object_name] then return true end else if va(k) and not u[k.object_name] then if y=='table' and getmetatable(v)=='private' and v.object_name then if u[v.object_name] then j=j+1 rm[#rm+1]=du(pth,k.object_name..j) e=e+1 else j=j+1 po[#po+1]=du(pth,k.object_name..j) p=p+1 end elseif y=='table' and getmetatable(v) then j=j+1 po[#po+1]=du(pth,k.object_name..j) p=p+1 mt[#mt+1]=du(pth,k.object_name..j) l=l+1 it(v,du(pth,k.object_name..j)) elseif y=='table' then j=j+1 po[#po+1]=du(pth,k.object_name..j) p=p+1 it(v,du(pth,k.object_name..j)) else j=j+1 po[#po+1]=du(pth,k.object_name..j) p=p+1 end elseif u[k.object_name] then j=j+1 rm[#rm+1]=du(pth,k.object_name..j) e=e+1 else j=j+1 rm[#rm+1]=du(pth,k.object_name..j) e=e+1 end end elseif t=='table' then if o then return it(k,nil,true) else if it(k,nil,true) then j=j+1 rm[#rm+1]=du(pth,t..j) e=e+1 else if y=='table' and getmetatable(v)=='private' and v.object_name then if u[v.object_name] then j=j+1 rm[#rm+1]=du(pth,t..j) e=e+1 else j=j+1 po[#po+1]=du(pth,t..j) p=p+1 end elseif y=='table' and getmetatable(v) then j=j+1 po[#po+1]=du(pth,t..j) p=p+1 mt[#mt+1]=du(pth,t..j) l=l+1 it(v,du(pth,t..j)) elseif y=='table' then j=j+1 po[#po+1]=du(pth,t..j) p=p+1 it(v,du(pth,t..j)) else j=j+1 po[#po+1]=du(pth,t..j) p=p+1 end end end elseif y=='table' and getmetatable(v)=='private' and v.object_name then if u[v.object_name] then if o then return true else rm[#rm+1]=du(pth,k) e=e+1 end elseif o then else c=c+1 end elseif y=='table' then if o then return it(v,nil,true) elseif getmetatable(v) then mt[#mt+1]=du(pth,k) l=l+1 it(v,du(pth,k)) else it(v,du(pth,k)) c=c+1 end elseif o then else c=c+1 end end end it(global,{}) return {trouble=rm,meta=mt,m_count=l,n_count=c,e_count=e,potential=po,p_count=p} end, fix=function() local rm,po,mt,c,e,p,l,j,it={},{},{},0,0,0,0,0 local du=function(b,m) local n={} for i,v in ipairs(b) do n[#n+1]=v end n[#n+1]=m return n end local va=function(v) local s,a=pcall(function()return v.valid end) if s then return a else return end end local u={LuaGameScript=true,LuaBootstrap=true,LuaRemote=true,LuaCommandProcessor=true,LuaSettings=true,LuaRCON=true,LuaRendering=true} it=function(b,pth,o) local t for k,v in pairs(b) do t=type(k) y=type(v) if t=='function' or t=='userdata' or t=='thread' or y=='function' or y=='userdata' or y=='thread' then if o then return true else if t=='string' or t=='number' or t=='boolean' then rm[#rm+1]=du(pth,k) b[k]=nil e=e+1 elseif t=='table' and getmetatable(k)=='private' and k.object_name then j=j+1 rm[#rm+1]=du(pth,k.object_name..j) b[k]=nil e=e+1 else j=j+1 rm[#rm+1]=du(pth,t..j) b[k]=nil e=e+1 end end elseif t=='nil' then if o then if y=='table' and getmetatable(v)=='private' and v.object_name then if u[v.object_name] then return true else return false end elseif y=='table' then return it(v,nil,true) end else j=j+1 rm[#rm+1]=du(pth,t..j) b[k]=nil e=e+1 end elseif t=='table' and getmetatable(k)=='private' and k.object_name then if o then if u[k.object_name] then return true end else if va(k) and not u[k.object_name] then if y=='table' and getmetatable(v)=='private' and v.object_name then if u[v.object_name] then j=j+1 rm[#rm+1]=du(pth,k.object_name..j) b[k]=nil e=e+1 else j=j+1 po[#po+1]=du(pth,k.object_name..j) p=p+1 end elseif y=='table' and getmetatable(v) then j=j+1 po[#po+1]=du(pth,k.object_name..j) p=p+1 mt[#mt+1]=du(pth,k.object_name..j) l=l+1 it(v,du(pth,k.object_name..j)) elseif y=='table' then j=j+1 po[#po+1]=du(pth,k.object_name..j) p=p+1 it(v,du(pth,k.object_name..j)) else j=j+1 po[#po+1]=du(pth,k.object_name..j) p=p+1 end elseif u[k.object_name] then j=j+1 rm[#rm+1]=du(pth,k.object_name..j) b[k]=nil e=e+1 else j=j+1 rm[#rm+1]=du(pth,k.object_name..j) b[k]=nil e=e+1 end end elseif t=='table' then if o then return it(k,nil,true) else if it(k,nil,true) then j=j+1 rm[#rm+1]=du(pth,t..j) b[k]=nil e=e+1 else if y=='table' and getmetatable(v)=='private' and v.object_name then if u[v.object_name] then j=j+1 rm[#rm+1]=du(pth,t..j) b[k]=nil e=e+1 else j=j+1 po[#po+1]=du(pth,t..j) p=p+1 end elseif y=='table' and getmetatable(v) then j=j+1 po[#po+1]=du(pth,t..j) p=p+1 mt[#mt+1]=du(pth,t..j) l=l+1 it(v,du(pth,t..j)) elseif y=='table' then j=j+1 po[#po+1]=du(pth,t..j) p=p+1 it(v,du(pth,t..j)) else j=j+1 po[#po+1]=du(pth,t..j) p=p+1 end end end elseif y=='table' and getmetatable(v)=='private' and v.object_name then if u[v.object_name] then if o then return true else rm[#rm+1]=du(pth,k) b[k]=nil e=e+1 end elseif o then else c=c+1 end elseif y=='table' then if o then return it(v,nil,true) elseif getmetatable(v) then mt[#mt+1]=du(pth,k) l=l+1 it(v,du(pth,k)) else it(v,du(pth,k)) c=c+1 end elseif o then else c=c+1 end end end it(global,{}) return {trouble=rm,meta=mt,m_count=l,n_count=c,e_count=e,potential=po,p_count=p} end, c=function(t,...) local i = #global+1 global[i]=table.pack(...) local m = setmetatable({},global[i]) local pc, ret = pcall(function() assert(loadstring('local arg=global['..i..'] global['..i..']=nil '..t))() end) if not pc then if getmetatable(m)==global[i] then global[i]=nil end end return pc, ret end, version=function() return '1' end, })
end
