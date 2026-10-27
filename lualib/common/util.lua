-- 유틴

local Util = {}

--접근가능한 모드 목록 얻기
Util.get_accessible_mod_list = function()
  local list = {}
  local pc, ret
  pc, ret = pcall(function() return remote.interfaces['__level__gvv']['storage'] end)
  if pc and ret then
    list[#list + 1] = 'level'
  end
  for name, ver in pairs(script.active_mods) do
    pc, ret = pcall(function() return remote.interfaces['__'..name..'__gvv']['storage'] end)
    if pc and ret then
      list[#list + 1] = name
    end
  end
  return list
end

--모든 모드 목록 얻기
Util.get_all_mod_list = function(blacklist)
  local modlist = {'level'}
  for k in pairs(script.active_mods) do
    if not blacklist[k] then modlist[#modlist + 1] = k end
  end
  return modlist
end

--LuaObject의 읽을 수 있는 프로퍼티 목록 가져오기
Util.get_property_list = require(gvv.defines.lualib.common.luaobj_prop)

--table 얕은 비교
Util.table_shallow_compare = function(tbl1, tbl2)
  for k, v in pairs(tbl1) do
    if tbl2[k] ~= v then return false end
  end
  for k, v in pairs(tbl2) do
    if tbl1[k] ~= v then return false end
  end
  return true
end

-- FR : Copie profonde de Factorio : gère les tables récursives, garde les objets Lua
--      et les métatables d'origine (les marqueurs comme storage.meta_data._nil_ restent reconnus)
-- EN : Factorio's deep copy: handles recursive tables, keeps Lua objects
--      and the original metatables (markers like storage.meta_data._nil_ stay recognised)
Util.deepcopytbl = require(gvv.defines.util).table.deepcopy

--목록 옮기기
Util.shift_checked = function(array, direction)
  local buffer
  local size = #array
  if direction < 0 then
    for i = 1, size - 1 do
      if not array[i].checked and array[i + 1].checked then
        buffer = array[i]
        array[i] = array[i + 1]
        array[i + 1] = buffer
      end
    end
  elseif direction > 0 then
    for i = size, 2, -1 do
      if not array[i].checked and array[i - 1].checked then
        buffer = array[i]
        array[i] = array[i - 1]
        array[i - 1] = buffer
      end
    end
  end
  return array
end

--목록 옮기기 가장 끝으로
Util.push_checked = function(array, direction)
  local checked, unchecked = {}, {}
  for i, v in pairs(array) do
    if v.checked then
      checked[#checked + 1] = v
    else
      unchecked[#unchecked + 1] = v
    end
  end
  if direction < 0 then
    for _, v in ipairs(unchecked) do
      checked[#checked + 1] = v
    end
    array = checked
  elseif direction > 0 then
    for _, v in ipairs(checked) do
      unchecked[#unchecked + 1] = v
    end
    array = unchecked
  end
  return array
end

return Util
