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
---**EN**
---
---Description: Escapes a string for a Lua string literal (control characters, quotes, backslash).
---
---──────────────────────────────
---
---**FR**
---
---Description: Échappe une chaîne pour un littéral Lua (caractères de contrôle, guillemets, barre oblique inverse).
---@param s string
---@return string
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
---**EN**
---
---Description: Escapes a string for JSON (\uXXXX for control characters).
---
---──────────────────────────────
---
---**FR**
---
---Description: Échappe une chaîne pour le JSON (\uXXXX pour les caractères de contrôle).
---@param s string
---@return string
local esc_json = function(s)
  return (s:gsub('[%c\\"]', function(c)
    return json_escapes[c] or string.format('\\u%04x', c:byte())
  end))
end

---**EN**
---
---Description: Special numbers in Lua: infinity and NaN have no literal form
---
---──────────────────────────────
---
---**FR**
---
---Description: Nombres spéciaux en Lua : l'infini et NaN n'ont pas d'écriture littérale
---@param n number
---@return string
local number_to_lua = function(n)
  if n ~= n then return '0/0' end
  if n == math.huge then return 'math.huge' end
  if n == -math.huge then return '-math.huge' end
  return tostring(n)
end

---**EN**
---
---Description: Special numbers in JSON: infinity and NaN do not exist, write null
---
---──────────────────────────────
---
---**FR**
---
---Description: Nombres spéciaux en JSON : l'infini et NaN n'existent pas, on écrit null
---@param n number
---@return string
local number_to_json = function(n)
  if n ~= n or n == math.huge or n == -math.huge then return 'null' end
  return tostring(n)
end

---**EN**
---
---Description: Lua key name: as is if it is a valid identifier, otherwise `["..."]` (reserved words included).
---
---──────────────────────────────
---
---**FR**
---
---Description: Nom de clé Lua : tel quel si c'est un identifiant valide, sinon `["..."]` (mots réservés compris).
---@param k string
---@return string
local keyname = function(k)
  if k ~= k:match('^[%a_][%a%d_]*') or lua_keywords[k] then
    return '["'..k..'"]'
  end
  return k
end

-- FR : Texte affiché à la place d'une table déjà en cours de conversion (référence circulaire)
-- EN : Text shown instead of a table already being converted (circular reference)
local recursive_text = '<recursive table>'

---**EN**
---
---Description: Converts a value to JSON or Lua object notation (`/gdump-json`, `/gdump-luaon`).
---
---──────────────────────────────
---
---**FR**
---
---Description: Convertit une valeur en JSON ou en notation objet Lua (`/gdump-json`, `/gdump-luaon`).
---@param obj any
---@param lang "json"|"luaon"
---@return string?
Table_to_str.to_lang = function(obj, lang)
  if lang == 'json' then return Table_to_str.to_json(obj) end
  if lang == 'luaon' then return Table_to_str.to_luaon(obj) end
end

---**EN**
---
---Description: seen : tables being converted on the current path, to detect circular references
---
---──────────────────────────────
---
---**FR**
---
---Description: seen : tables en cours de conversion sur le chemin actuel, pour détecter les références circulaires
---@param obj any
---@param as_key? boolean
---@param seen? table
---@return string
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

---**EN**
---
---Description: Converts a value to Lua object notation (valid Lua: reserved keys as ["end"], inf / NaN as math.huge / 0/0,
---recursive tables as "<recursive table>").
---
---──────────────────────────────
---
---**FR**
---
---Description: Convertit une valeur en notation objet Lua (Lua valide : clés réservées en ["end"], inf / NaN en math.huge / 0/0,
---tables récursives en « <recursive table> »).
---@param obj any
---@param as_key? boolean
---@param seen? table  Tables already crossed (recursion)
---@return string
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

---**EN**
---
---Description: Raw text of a key (no rich text), used to build paths.
---
---──────────────────────────────
---
---**FR**
---
---Description: Texte brut d'une clé (sans texte enrichi), pour construire des chemins.
---@param obj any
---@return string
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

---**EN**
---
---Description: Rich text of a value or a key, as shown in the trees (colours per type).
---
---──────────────────────────────
---
---**FR**
---
---Description: Texte enrichi d'une valeur ou d'une clé, comme affiché dans les arbres (couleurs par type).
---@param obj any
---@param as_key? boolean
---@param seen? table
---@return string
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

---**EN**
---
---Description: Lua code of a tree path, e.g. `remote.call("__mod__gvv","storage").players[1]`.
---
---──────────────────────────────
---
---**FR**
---
---Description: Code Lua d'un chemin d'arbre, ex. `remote.call("__mod__gvv","storage").players[1]`.
---@param path_tbl table  Full path (first key: mod, "_G:<mod>" or "*<global>")
---@param front_to_remote_call? boolean  Start with the remote.call(...) that reads the root
---@return string
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

---**EN**
---
---Description: Short text of a key (tracking).
---
---──────────────────────────────
---
---**FR**
---
---Description: Texte court d'une clé (suivi).
---@param k any
---@return string
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

---**EN**
---
---Description: Text of a value inside a table (one level).
---
---──────────────────────────────
---
---**FR**
---
---Description: Texte d'une valeur dans une table (un niveau).
---@param v any
---@return string
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
---**EN**
---
---Description: Text of a value as shown in the tracking (tables on one level).
---
---──────────────────────────────
---
---**FR**
---
---Description: Texte d'une valeur comme affiché dans le suivi (tables sur un niveau).
---@param v any
---@return string
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
