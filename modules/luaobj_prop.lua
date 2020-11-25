-- Util.get_property_list 함수

local manual_api_list = require('modules.manual_api_list')

local normal_table = function(obj, add_value)
  if add_value then
    return obj
  else
    local tbl = {}
    for k in pairs(obj) do
      tbl[k] = true
    end
    return tbl
  end
end

local alt_prop = function(obj, add_value)
  local tbl = {}
  for k, v in pairs(obj) do
    tbl[k] = v
  end
  return tbl -- 지금은 아무것도 없음. nothing now.
end

--[[
local crash_condition
  LuaObjectName
    크래시를 일으키는 프로퍼티
      크래시를 일으키는 프로퍼티가 안전한 것을 확인해주는 프로퍼티 (or logic)
--]]

local crash_condition = {
  LuaItemStack = {
    blueprint_icons = {
      'is_blueprint',
      'is_blueprint_book',
    },
  },
}

-- 값을 함께 리턴할 경우 add_value에 true
return function(obj, add_value)
  local pc, rv, help_str
  if type(obj) == 'table' and type(obj.__self) == 'userdata' and obj.object_name then
  elseif type(obj) == 'table' then
    return normal_table(obj, add_value)
  else
    return error('given value is not even table.')
  end
  local name = obj.object_name
  pc, help_str = pcall(function() return obj.help() end)
  local no_help = not pc
  local include_na = true
  if no_help then
    if name == 'LuaMapSettings' or name:match('^LuaMapSettings[.]') then
      name = 'LuaMapSettings'
      include_na = false
    end
    help_str = manual_api_list(name)
    if not help_str then return alt_prop(obj, add_value) end
  end
  local r, list = true, {}
  local c, prop = 0, ''
  local skip = false --크래시 스킵
  local logic = true

  if name == 'LuaCustomTable' then
    if add_value then
      for k, v in pairs(obj) do
        list[k] = v
      end
    else
      for k, v in pairs(obj) do
        list[k] = true
      end
    end
  elseif name == 'LuaGuiElement' then
    if add_value then
      for i, v in ipairs(obj.children_names) do
        if v == '' then
          list[i] = 'use .children['..i..'] instead.'
        else
          list[v] = obj[v]
        end
      end
    else
      for i, v in ipairs(obj.children_names) do
        if v == '' then
          list[i] = true
        else
          list[v] = true
        end
      end
    end
  elseif name == 'LuaFluidBox' or name == 'LuaInventory' or name == 'LuaTransportLine' then
    if add_value then
      for i = 1, #obj do
        list[i] = obj[i]
      end
    else
      for i = 1, #obj do
        list[i] = true
      end
    end
  elseif name == 'LuaMapSettings' then
    include_na = false
  end

  while r do
    skip = false
    prop = help_str:match('[%a_][%a%d_]* [[]R')
    if not prop then break end
    prop = prop:gsub(' [[]R','')
    help_str, c = help_str:gsub('[%a_][%a%d_]* [[]R','',1)
    if c == 0 then r = false break end

    if crash_condition[name] and crash_condition[name][prop] then
      logic = false
      for _, v in pairs(crash_condition[name][prop]) do
        logic = logic or obj[v]
      end
      skip = not logic
    end

    if not skip then
      pc, rv = pcall(function(a, b) return a[b] end, obj, prop)
      if pc then
        if add_value then
          if rv == nil then
            local n = {}
            setmetatable(n, global.meta_data._nil_)
            list[prop] = n
          else
            list[prop] = rv
          end
        else
          list[prop] = true
        end
      else
        if add_value and include_na then
          local n = {}
          setmetatable(n, global.meta_data._na_)
          list[prop] = n
        end
      end
    else
      if add_value and include_na then
        local n = {}
        setmetatable(n, global.meta_data._na_)
        list[prop] = n
      end
    end
  end
  if add_value then
    local func = ''
    r = true
    while r do
      skip = false
      func = help_str:match('[%a_][%a%d_]*[(]')
      if not func then break end
      func = func:gsub('[(]','')
      help_str, c = help_str:gsub('[%a_][%a%d_]*[(]','',1)
      if c == 0 then r = false break end

      pc, rv = pcall(function(a, b) return a[b] end, obj, func)
      if pc then
        local n = {}
        setmetatable(n, global.meta_data._function_)
        list[func] = n
      end
    end
  end
  return list
end