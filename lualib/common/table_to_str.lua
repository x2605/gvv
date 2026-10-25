-- 테이블을 문자열로

local Table_to_str = {}

-- FR : Mots réservés de Lua : ils ne peuvent pas servir de nom de clé sans crochets
-- EN : Lua reserved words: they cannot be used as key names without brackets
local lua_keywords = {
  ['and'] = true, ['break'] = true, ['do'] = true, ['else'] = true, ['elseif'] = true,
  ['end'] = true, ['false'] = true, ['for'] = true, ['function'] = true, ['goto'] = true,
  ['if'] = true, ['in'] = true, ['local'] = true, ['nil'] = true, ['not'] = true,
  ['or'] = true, ['repeat'] = true, ['return'] = true, ['then'] = true, ['true'] = true,
  ['until'] = true, ['while'] = true,
}

-- FR : Échappement d'une chaîne pour du code Lua (les autres caractères de contrôle deviennent \ddd)
-- EN : String escaping for Lua code (other control characters become \ddd)
local lua_escapes = {
  ['\\'] = '\\\\', ['"'] = '\\"', ["'"] = "\\'", ['\a'] = '\\a', ['\b'] = '\\b',
  ['\f'] = '\\f', ['\n'] = '\\n', ['\r'] = '\\r', ['\t'] = '\\t', ['\v'] = '\\v',
}
local esc = function(s)
  return (s:gsub('[%c\\"\']', function(c)
    return lua_escapes[c] or string.format('\\%03d', c:byte())
  end))
end

-- FR : Échappement d'une chaîne pour du JSON (\' \a \v n'existent pas en JSON)
-- EN : String escaping for JSON (\' \a \v do not exist in JSON)
local json_escapes = {
  ['\\'] = '\\\\', ['"'] = '\\"', ['\b'] = '\\b', ['\f'] = '\\f',
  ['\n'] = '\\n', ['\r'] = '\\r', ['\t'] = '\\t',
}
local esc_json = function(s)
  return (s:gsub('[%c\\"]', function(c)
    return json_escapes[c] or string.format('\\u%04x', c:byte())
  end))
end

-- FR : Nombres spéciaux en Lua : l'infini et NaN n'ont pas d'écriture littérale
-- EN : Special numbers in Lua: infinity and NaN have no literal form
local number_to_lua = function(n)
  if n ~= n then return '0/0' end
  if n == math.huge then return 'math.huge' end
  if n == -math.huge then return '-math.huge' end
  return tostring(n)
end

-- FR : Nombres spéciaux en JSON : l'infini et NaN n'existent pas, on écrit null
-- EN : Special numbers in JSON: infinity and NaN do not exist, write null
local number_to_json = function(n)
  if n ~= n or n == math.huge or n == -math.huge then return 'null' end
  return tostring(n)
end

local keyname = function(k)
  if k ~= k:match('^[%a_][%a%d_]*') or lua_keywords[k] then
    return '["'..k..'"]'
  end
  return k
end

-- FR : Texte affiché à la place d'une table déjà en cours de conversion (référence circulaire)
-- EN : Text shown instead of a table already being converted (circular reference)
local recursive_text = '<recursive table>'

Table_to_str.to_lang = function(obj, lang)
  if lang == 'json' then return Table_to_str.to_json(obj) end
  if lang == 'luaon' then return Table_to_str.to_luaon(obj) end
end

-- FR : seen : tables en cours de conversion sur le chemin actuel, pour détecter les références circulaires
-- EN : seen : tables being converted on the current path, to detect circular references
Table_to_str.to_json = function(obj, as_key, seen)
  local s = {}
  local t = type(obj)
  if t == 'userdata' and obj.object_name then
    return '"'..obj.object_name..'"'
  elseif t == 'table' and not as_key then
    seen = seen or {}
    if seen[obj] then return '"'..recursive_text..'"' end
    seen[obj] = true
    s[#s + 1] = '{'
    for k, v in pairs(obj) do
      if #s > 1 then s[#s + 1] = ', ' end
      s[#s + 1] = Table_to_str.to_json(k, true, seen)
      s[#s + 1] = ': '
      s[#s + 1] = Table_to_str.to_json(v, false, seen)
    end
    s[#s + 1] = '}'
    seen[obj] = nil
    return table.concat(s)
  elseif t == 'string' then
    return '"'..esc_json(obj)..'"'
  elseif t == 'number' then
    if as_key then return '"'..tostring(obj)..'"' end
    return number_to_json(obj)
  elseif t == 'boolean' then
    if as_key then return '"'..tostring(obj)..'"' end
    return tostring(obj)
  elseif t == 'nil' then
    if as_key then return '"null"' end
    return 'null'
  else
    return '"'..t..'"'
  end
end

Table_to_str.to_luaon = function(obj, as_key, seen)
  local s = {}
  local t = type(obj)
  if t == 'userdata' and obj.object_name then
    if as_key then return '["'..obj.object_name..'"]' end
    return '"'..obj.object_name..'"'
  elseif t == 'table' then
    seen = seen or {}
    if seen[obj] then
      if as_key then return '["'..recursive_text..'"]' end
      return '"'..recursive_text..'"'
    end
    seen[obj] = true
    if as_key then s[#s + 1] = '[' end
    s[#s + 1] = '{'
    for k, v in pairs(obj) do
      if #s > 1 then s[#s + 1] = ', ' end
      s[#s + 1] = Table_to_str.to_luaon(k, true, seen)
      s[#s + 1] = '= '
      s[#s + 1] = Table_to_str.to_luaon(v, false, seen)
    end
    s[#s + 1] = '}'
    if as_key then s[#s + 1] = ']' end
    seen[obj] = nil
    return table.concat(s)
  elseif t == 'string' then
    if as_key then return keyname(esc(obj)) end
    return '"'..esc(obj)..'"'
  elseif t == 'number' then
    if as_key then return '['..number_to_lua(obj)..']' end
    return number_to_lua(obj)
  elseif t == 'boolean' then
    if as_key then return '['..tostring(obj)..']' end
    return tostring(obj)
  elseif t == 'nil' then
    if as_key then return '[nil]' end
    return 'nil'
  else
    -- FR : function, thread... ne s'écrivent pas en Lua : on écrit leur type en texte
    -- EN : function, thread... cannot be written in Lua: write their type as text
    if as_key then return '["'..t..'"]' end
    return '"'..t..'"'
  end
end

Table_to_str.to_key_raw_string = function(obj)
  local s = {}
  local t = type(obj)
  if t == 'userdata' and obj.object_name then
    return obj.object_name
  elseif t == 'table' then
    local seen = {[obj] = true}
    s[#s + 1] = '{'
    for k, v in pairs(obj) do
      if #s > 1 then s[#s + 1] = ', ' end
      s[#s + 1] = Table_to_str.to_luaon(k, true, seen)
      s[#s + 1] = '= '
      s[#s + 1] = Table_to_str.to_luaon(v, false, seen)
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

Table_to_str.to_richtext = function(obj, as_key, seen)
  local s = {}
  local t = type(obj)
  if t == 'userdata' and obj.object_name then
    if as_key then return '[[color=blue]'..obj.object_name..'[/color]]' end
    return '[color=blue]'..obj.object_name..'[/color]'
  elseif t == 'table' then
    seen = seen or {}
    if seen[obj] then
      if as_key then return '[[color=0.7,0.7,0.7,1]'..recursive_text..'[/color]]' end
      return '[color=0.7,0.7,0.7,1]'..recursive_text..'[/color]'
    end
    seen[obj] = true
    if as_key then s[#s + 1] = '[' end
    s[#s + 1] = '{'
    for k, v in pairs(obj) do
      if #s > 1 then s[#s + 1] = ', ' end
      s[#s + 1] = Table_to_str.to_richtext(k, true, seen)
      s[#s + 1] = '='
      s[#s + 1] = Table_to_str.to_richtext(v, false, seen)
    end
    s[#s + 1] = '}'
    if as_key then s[#s + 1] = ']' end
    seen[obj] = nil
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
      elseif v:match('^_G:()') then
        s[#s + 1] = 'remote.call("__'..v:match('^_G:(.*)')..'__gvv","_G")'
      else
        s[#s + 1] = 'remote.call("__'..v..'__gvv","storage")'
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
        s[#s + 1] = '['..number_to_lua(v)..']'
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
    return '['..number_to_lua(k)..']'
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
  if t == 'userdata' and v.object_name then
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
