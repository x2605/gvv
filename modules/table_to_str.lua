-- 테이블을 문자열로

local Table_to_str = {}

local esc = function(s)
  local ic = {'\\', '"', "'", '\a', '\b', '\f', '\n', '\r', '\t', '\v'}
  local oc = {'\\', '"', "'", 'a', 'b', 'f', 'n', 'r', 't', 'v'}
  for i, c in ipairs(ic) do
    s = s:gsub(c, '\\'..oc[i])
  end
  return s
end

local keyname = function(k)
  if k ~= k:match('^[%a_][%a%d_]*') then
    return '["'..k..'"]'
  end
  return k
end

Table_to_str.to_lang = function(obj, lang)
  if lang == 'json' then return Table_to_str.to_json(obj) end
  if lang == 'luaon' then return Table_to_str.to_luaon(obj) end
end

Table_to_str.to_json = function(obj, as_key)
  local s = {}
  local t = type(obj)
  if t == 'table' and type(obj.__self) == 'userdata' and obj.object_name then
    return '"'..obj.object_name..'"'
  elseif t == 'table' and not as_key then
    s[#s + 1] = '{'
    for k, v in pairs(obj) do
      if #s > 1 then s[#s + 1] = ', ' end
      s[#s + 1] = Table_to_str.to_json(k, true)
      s[#s + 1] = ': '
      s[#s + 1] = Table_to_str.to_json(v)
    end
    s[#s + 1] = '}'
    return table.concat(s)
  elseif t == 'string' then
    return '"'..esc(obj)..'"'
  elseif t == 'number' then
    if as_key then return '['..tostring(obj)..']' end
    return tostring(obj)
  elseif t == 'boolean' then
    if as_key then return '['..tostring(obj)..']' end
    return tostring(obj)
  elseif t == 'nil' then
    if as_key then return '[null]' end
    return 'null'
  else
    if as_key then return '['..t..']' end
    return t
  end
end

Table_to_str.to_luaon = function(obj, as_key)
  local s = {}
  local t = type(obj)
  if t == 'table' and type(obj.__self) == 'userdata' and obj.object_name then
    if as_key then return '["'..obj.object_name..'"]' end
    return '"'..obj.object_name..'"'
  elseif t == 'table' then
    if as_key then s[#s + 1] = '[' end
    s[#s + 1] = '{'
    for k, v in pairs(obj) do
      if #s > 1 then s[#s + 1] = ', ' end
      s[#s + 1] = Table_to_str.to_luaon(k, true)
      s[#s + 1] = '= '
      s[#s + 1] = Table_to_str.to_luaon(v)
    end
    s[#s + 1] = '}'
    if as_key then s[#s + 1] = ']' end
    return table.concat(s)
  elseif t == 'string' then
    if as_key then return keyname(esc(obj)) end
    return '"'..esc(obj)..'"'
  elseif t == 'number' then
    if as_key then return '['..tostring(obj)..']' end
    return tostring(obj)
  elseif t == 'boolean' then
    if as_key then return '['..tostring(obj)..']' end
    return tostring(obj)
  elseif t == 'nil' then
    if as_key then return '[nil]' end
    return 'nil'
  else
    if as_key then return '['..t..']' end
    return t
  end
end

Table_to_str.to_key_raw_string = function(obj)
  local s = {}
  local t = type(obj)
  if t == 'table' and type(obj.__self) == 'userdata' and obj.object_name then
    return obj.object_name
  elseif t == 'table' then
    s[#s + 1] = '{'
    for k, v in pairs(obj) do
      if #s > 1 then s[#s + 1] = ', ' end
      s[#s + 1] = Table_to_str.to_luaon(k, true)
      s[#s + 1] = '= '
      s[#s + 1] = Table_to_str.to_luaon(v)
    end
    s[#s + 1] = '}'
    return table.concat(s)
  elseif t == 'string' then
    return obj
  elseif t == 'number' then
    return tostring(obj)
  elseif t == 'boolean' then
    return tostring(obj)
  elseif t == 'nil' then
    return 'nil'
  else
    return t
  end
end

Table_to_str.to_richtext = function(obj, as_key)
  local s = {}
  local t = type(obj)
  if t == 'table' and type(obj.__self) == 'userdata' and obj.object_name then
    if as_key then return '[[color=blue]'..obj.object_name..'[/color]]' end
    return '[color=blue]'..obj.object_name..'[/color]'
  elseif t == 'table' then
    if as_key then s[#s + 1] = '[' end
    s[#s + 1] = '{'
    for k, v in pairs(obj) do
      if #s > 1 then s[#s + 1] = ', ' end
      s[#s + 1] = Table_to_str.to_richtext(k, true)
      s[#s + 1] = '='
      s[#s + 1] = Table_to_str.to_richtext(v)
    end
    s[#s + 1] = '}'
    if as_key then s[#s + 1] = ']' end
    return table.concat(s)
  elseif t == 'string' then
    if as_key then return keyname(esc(obj)) end
    return '"[color=1,0.7,1,1]'..esc(obj)..'[/color]"'
  elseif t == 'number' then
    if as_key then return '[[color=1,1,0.7,1]'..tostring(obj)..'[/color]]' end
    return '[color=1,1,0.7,1]'..tostring(obj)..'[/color]'
  elseif t == 'boolean' then
    if as_key then return '[[color=0.7,1,0.7,1]'..tostring(obj)..'[/color]]' end
    return '[color=0.7,1,0.7,1]'..tostring(obj)..'[/color]'
  elseif t == 'nil' then
    if as_key then return '[[color=0.7,0.7,0.7,1]nil[/color]]' end
    return '[color=0.7,0.7,0.7,1]nil[/color]'
  else
    if as_key then return '[[color=1,0.3,0.3,1]'..t..'[/color]]' end
    return '[color=1,0.3,0.3,1]'..t..'[/color]'
  end
end

Table_to_str.path_to_lua_prop_path = function(path_tbl, front_to_remote_call)
  local s = {}
  local t
  local key_name
  for i, v in ipairs(path_tbl) do
    if front_to_remote_call and i == 1 then
      if v:match('^[*]()') then
        s[#s + 1] = v:match('^[*](.*)')..''
      else
        s[#s + 1] = 'remote.call("__'..v..'__gvv","global")'
      end
    else
      t = type(v)
      if t == 'table' then
        s[#s + 1] = Table_to_str.to_luaon(v, true)
      elseif t == 'string' then
        key_name = keyname(esc(v))
        if not key_name:match('^[[]') and i > 1 then s[#s + 1] = '.' end
        s[#s + 1] = key_name
      elseif t == 'number' then
        s[#s + 1] = '['..tostring(v)..']'
      elseif t == 'boolean' then
        s[#s + 1] = '['..tostring(v)..']'
      elseif t == 'nil' then
        s[#s + 1] = '[nil]'
      else
        s[#s + 1] = '['..t..']'
      end
    end
  end
  return table.concat(s)
end

Table_to_str.key_to_str = function(k)
  local t = type(k)
  if t == 'table' then
    return Table_to_str.to_luaon(k, true)
  elseif t == 'string' then
    return keyname(esc(k))
  elseif t == 'number' then
    return '['..tostring(k)..']'
  elseif t == 'boolean' then
    return '['..tostring(k)..']'
  elseif t == 'nil' then
    return '[nil]'
  else
    return '['..t..']'
  end
end

local table_part_value_to_str = function(v)
  local s = {'{'}
  for k in pairs(v) do
    local kt = type(k)
    if #s > 1 then s[#s + 1] = ', ' end
    if kt == 'string' then s[#s + 1] = keyname(esc(k))
    elseif kt == 'number' then s[#s + 1] = '['..tostring(k)..']'
    elseif kt == 'boolean' then s[#s + 1] = '['..tostring(k)..']'
    elseif kt == 'nil' then s[#s + 1] = '['..tostring(k)..']'
    else s[#s + 1] = '['..tostring(k)..']'
    end
  end
  s[#s + 1] = '}'
  return table.concat(s)
end
Table_to_str.value_to_str = function(v)
  local t = type(v)
  if t == 'table' and type(v.__self) == 'userdata' and v.object_name then
    local name = v.object_name
    if name == 'LuaCustomTable' then
      return name..' #'..tostring(#v)..' '..table_part_value_to_str(v)
    elseif name == 'LuaFluidBox' or name == 'LuaInventory' or name == 'LuaTransportLine' then
      return name..' #'..tostring(#v)
    elseif name == 'LuaLazyLoadedValue' and v.valid then
      return name..' '..Table_to_str.value_to_str(v.get())
    end
    return name
  elseif t == 'table' then
    return '#'..tostring(table_size(v))..' '..table_part_value_to_str(v)
  elseif t == 'string' then
    return '“'..v..'”'
  elseif t == 'number' then
    return tostring(v)
  elseif t == 'boolean' then
    return tostring(v)
  elseif t == 'nil' then
    return 'nil'
  else
    return t
  end
end

return Table_to_str
