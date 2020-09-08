-- 유틴

local Util = {}


--닫기 버튼이 있는 프레임 만들기
Util.create_frame_w_closebtn = function(player, frame_name, title)
  local frame = player.gui.screen.add{type = 'frame', name = frame_name, direction = 'vertical'}
  frame.add{type = 'flow', name = 'header', direction = 'horizontal'}
  frame.header.drag_target = frame
  local tit = frame.header.add{type = 'label', caption = title, style = 'frame_title'}
  tit.drag_target = frame
  local drag = frame.header.add{type = 'empty-widget', name = 'dragspace', style = 'draggable_space_header'}
  drag.drag_target = frame
  drag.style.right_margin = 8
  drag.style.height = 24
  drag.style.horizontally_stretchable = true
  local closebtn = frame.header.add{type = 'sprite-button', name = 'closebtn', sprite = 'utility/close_white', style = 'frame_action_button', mouse_button_filter = {'left'}}
  local innerframe = frame.add{type = 'flow', direction = 'vertical'}
  frame.auto_center = true
  return frame, closebtn, innerframe
end

--최상위 프레임 검색
Util.get_top_frame = function(gui_elem)
  local parent = gui_elem.parent
  if parent and parent.valid and parent.parent and parent.parent.valid then
    return Util.get_top_frame(parent)
  elseif parent and parent.valid then
    return gui_elem
  else
    return nil
  end
end

Util.find_parent_gui = function(elem, finding_elem)
  if not finding_elem or not finding_elem.valid then return end
  if elem.parent and elem.parent == finding_elem then
    return true
  elseif elem.parent and elem.parent.valid then
    return Util.find_parent_gui(elem.parent, finding_elem)
  else
    return false
  end
end

--접근가능한 모드 목록 얻기
Util.get_accessible_mod_list = function()
  local list = {}
  local pc, ret
  pc, ret = pcall(function() return remote.interfaces['__level__gvv']['global'] end)
  if pc and ret then
    list[#list + 1] = 'level'
  end
  for name, ver in pairs(script.active_mods) do
    pc, ret = pcall(function() return remote.interfaces['__'..name..'__gvv']['global'] end)
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
Util.get_property_list = require('modules.luaobj_prop')

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

--깊은 테이블 복사
Util.deepcopytbl = function(ori)
  local t = type(ori)
  local ret
  if t == 'table' and type(ori.__self) == 'userdata' and ori.object_name then
    ret = ori
  elseif t == 'table' then
    ret = {}
    for k, v in next, ori, nil do
      ret[Util.deepcopytbl(k)] = Util.deepcopytbl(v)
    end
    setmetatable(ret, Util.deepcopytbl(getmetatable(ori)))
  else
    ret = ori
  end
  return ret
end

return Util
