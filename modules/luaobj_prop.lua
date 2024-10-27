-- Util.get_property_list 함수

local manual_api_list = require('modules.manual_api_list')
local runtime_api = require('generated.runtime-api')

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

  -- get class definition
  local cl = runtime_api.classes[obj.object_name]
  if not cl then return { ["<unknown>"] = true } end

  -- add attributes if it's accessible
  for k, v in pairs(cl.attributes) do
    pc, value = pcall(function() return obj[k] end)
    tbl[k] = "<unknown>"
    if pc then tbl[k] = value end
  end

  -- add methods
  for k, v in pairs(cl.methods) do tbl[k] = obj[k] end

  if cl.operators.call then tbl["<callable>"] = true end
  if cl.operators.length then tbl["<iterable>"] = true end
  if cl.operators.index then
    tbl["<indexable>"] = true
    for k, v in pairs(obj) do tbl[k] = v end
  end
  return tbl -- 지금은 아무것도 없음. nothing now.
end

--[[
local crash_condition
  LuaObjectName
    크래시를 일으키는 프로퍼티
      크래시를 일으키는 프로퍼티가 안전한 것을 확인해주는 프로퍼티 (or logic)
--]]

--local crash_condition = {
--LuaItemStack = {
--  blueprint_icons = {
--    'is_blueprint',
--    'is_blueprint_book',
--  },
--},
--}

-- 값을 함께 리턴할 경우 add_value에 true
return function(obj, add_value)
  local pc, rv, help_str
  if type(obj) == 'userdata' and obj.object_name then
    return alt_prop(obj, add_value)
  elseif type(obj) == 'table' then
    return normal_table(obj, add_value)
  else
    return error('given value is not even table.')
  end
end