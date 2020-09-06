-- GUI 이벤트

local Util = require('modules.util')
local Gui = require('modules.gui')
local Tree = require('modules.tree')
local Table_to_str = require('modules.table_to_str')
local Tracking = require('modules.tracking')
local Help_Menu = require('modules.help_menu')
local Doctor = require('modules.doctor')

local Gui_Event = {}

local simple_frame_names = {
  ['_gvv-mod_dump_frame_'] = true,
  ['_gvv-mod_anycode_frame_'] = true,
  ['_gvv-mod_copy_tracking_code_frame_'] = true,
}
local other_frames_to_close_when_focusing_main = {
  --['_gvv-mod_anycode_frame_'] = true,
  ['_gvv-mod_copy_tracking_code_frame_'] = true,
}

Gui_Event.on_gui_click = function(event)
  if not event.element then return end
  if event.element.player_index ~= event.player_index then return end
  local player = game.players[event.player_index]
  local topframe = Util.get_top_frame(event.element)
  if event.element.name == 'closebtn' and topframe and simple_frame_names[topframe.name] then
    topframe.destroy()
    return
  end

  if not global.players then return end
  local g = global.players[event.player_index]
  if not g or not g.gui.frame or not g.gui.frame.valid then return end

  --트래킹 간격 편집하다가 딴거 누를 때
  if event.element ~= g.gui.track_inter_edit and g.gui.track_inter_edit.visible then
    if g.gui.track_inter_edit.text ~= '' then g.track_interval_tick = g.gui.track_inter_edit.text + 0 end
    if g.track_interval_tick < 1 then g.track_interval_tick = 1 end
    g.gui.track_inter_edit.visible = false
    if g.gui.tabpane.selected_tab_index == 1 then g.gui.track_inter_show.visible = true end
    g.gui.track_inter_show.caption = g.track_interval_tick
    g.gui.track_inter_slider.slider_value = g.track_interval_tick
  end

  --닫기 버튼
  if event.element == g.gui.closebtn then
    Gui.close_main(g)

  --추적 항목 삭제 버튼
  elseif event.element == g.gui.remove_checked_btn then
    local panel = g.gui.tracking_panel
    local list = g.data.tracking_list
    for _, elem in pairs(panel.children) do
      if elem.header.check_to_remove.state then
        list[elem.name] = nil
        elem.destroy()
      end
    end

  --추적 갱신
  elseif event.element == g.gui.track_refresh_btn then
    Tracking.refresh_value(g)

  --진단
  elseif event.element.name == '_gvv-mod_fix_diagnose_btn_' then
    local mod_name = event.element.parent.parent['_gvv-mod_fix_mod_name_input_'].text
    Doctor.take_a_look(g, mod_name, 'diag')

  --정리
  elseif event.element.name == '_gvv-mod_fix_fix_btn_' then
    local mod_name = event.element.parent.parent['_gvv-mod_fix_mod_name_input_'].text
    Doctor.take_a_look(g, mod_name, 'fix')

  --global.report 비우기
  elseif event.element.name == '_gvv-mod_fix_clear_report_btn_' then
    global.report = {}
    player.print('(gvv) global.report is cleared.')

  --추적 간격 숫자 누를때
  elseif event.element == g.gui.track_inter_show and event.button == defines.mouse_button_type.left then
    g.gui.track_inter_show.visible = false
    g.gui.track_inter_edit.visible = true
    g.gui.track_inter_edit.text = g.track_interval_tick
    g.gui.track_inter_edit.focus()
    g.gui.track_inter_edit.select_all()

  --트리 항목 라벨을 좌클릭으로 선택할 때
  elseif event.element.name == '_gvv-mod_key_label' and event.button == defines.mouse_button_type.left then
    if Tree.ignore_in_help_page(g, event.element) then return end
    local category = Tree.get_tree_category(event.element)
    local tree_data
    if category == 'glob' then
      tree_data = g.data.tree_item_glob
    elseif category == 'prop' then
      tree_data = g.data.tree_item_prop
    elseif category == 'gobj' then
      tree_data = g.data.tree_item_gobj
    end
    local succ, tree_path = Tree.track_path(tree_data, event.element, {})
    if succ then
      local data
      data = Tree.get_tree_data(tree_data, event.element)
      -- tree_data keys : {parent, object, key, is_folder, is_root}
      if data.is_folder then
        if tree_path[1] == 'gvv' and tree_path[2] == 'players' and tree_path[4] == 'data' then return end
        if event.element.parent.parent.content_container then
          local content_container = event.element.parent.parent.content_container
          content_container.visible = not content_container.visible
          local folder = event.element.parent.parent.content_container.folder
          if table_size(folder.children) == 0 then
            if category == 'glob' then
              local tbl = Tree.get_global(event.element)
              for i = 2, #tree_path do
                tbl = tbl[tree_path[i]]
              end
              Tree.draw(g, tree_data, {}, tbl, folder, event.element, false)
            elseif category == 'prop' then
              local top = Tree.get_top_parent(event.element)
              local obj_index = top.caption:match('^[(](%d+)[)] ') + 0
              local obj = g.data.docked_luaobj[obj_index].luaobj
              for i = 2, #tree_path do
                obj = obj[tree_path[i]]
              end
              if type(obj) == 'table' and type(obj.__self) == 'userdata' and obj.object_name then
                local props = Util.get_property_list(obj, true)
                Tree.draw(g, tree_data, {}, props, folder, event.element, true)
              else
                Tree.draw(g, tree_data, {}, obj, folder, event.element, true)
              end
            elseif category == 'gobj' then
              local top = Tree.get_top_parent(event.element)
              local gobj_name = top.caption:match('^[%a_][%a%d_]*')
              local obj = assert(loadstring('return '..gobj_name))()
              for i = 2, #tree_path do
                obj = obj[tree_path[i]]
              end
              if type(obj) == 'table' and type(obj.__self) == 'userdata' and obj.object_name then
                local props = Util.get_property_list(obj, true)
                Tree.draw(g, tree_data, {}, props, folder, event.element, true)
              else
                Tree.draw(g, tree_data, {}, obj, folder, event.element, true)
              end
            end
          end
          if content_container.visible then
            data.object.parent.folder_sprite.sprite = 'gvv-mod_folder-opened'
          else
            data.object.parent.folder_sprite.sprite = 'gvv-mod_folder-closed'
          end
        end
      end
    end

  --트리 항목 라벨을 우클릭으로 등록할 때
  elseif event.element.name == '_gvv-mod_key_label' and event.button == defines.mouse_button_type.right then
    if event.element.style.name == 'tree-item_gvv-mod' then
      event.element.style = 'tracked-tree-item_gvv-mod'
      if Tree.ignore_in_help_page(g, event.element) then return end
      local full_path = Tree.track_full_path(g, event.element)
      Tracking.add(g, full_path)
    elseif event.element.style.name == 'tracked-tree-item_gvv-mod' then
      event.element.style = 'tree-item_gvv-mod'
    elseif event.element.style.name == 'tree-item-folder_gvv-mod' then
      event.element.style = 'tracked-tree-item-folder_gvv-mod'
      if Tree.ignore_in_help_page(g, event.element) then return end
      local full_path = Tree.track_full_path(g, event.element)
      Tracking.add(g, full_path)
    elseif event.element.style.name == 'tracked-tree-item-folder_gvv-mod' then
      event.element.style = 'tree-item-folder_gvv-mod'
    end

  --트리 항목 값을 우클릭으로 등록할 때
  elseif event.element.name == '_gvv-mod_key_value' and event.button == defines.mouse_button_type.right then
    if event.element.style.name == 'tree-item-luaobj_gvv-mod' then
      event.element.style = 'tracked-tree-item-luaobj_gvv-mod'
      if Tree.ignore_in_help_page(g, event.element) then return end
      Tree.register_object(g, event.element.parent['_gvv-mod_key_label'])
    elseif event.element.style.name == 'tracked-tree-item-luaobj_gvv-mod' then
      event.element.style = 'tree-item-luaobj_gvv-mod'
    end

  --sub_objlist 의 좌측 항목을 클릭할 때
  elseif event.element.name:match('^_gvv[-]mod_c_sub_obj_%d+$') and event.element.parent and event.element.parent.name == '_gvv-mod_sub_objlist_' then
    local index = event.element.name:match('^_gvv[-]mod_c_sub_obj_(%d+)$') + 0
    if event.button == defines.mouse_button_type.left then
      Tree.draw_proptree(g, index)
    elseif event.button == defines.mouse_button_type.right then
      Tree.remove_prop_tree(g, index)
    end

  --sub_modlist 의 좌측 항목을 클릭할 때
  elseif event.element.name:match('^_gvv[-]mod_c_sub_mod_%d+$') and event.element.parent and event.element.parent.name == '_gvv-mod_sub_modlist_' then
    Tree.draw_globtree(g, event.element.caption)

  --sub_gobjlist 의 좌측 항목을 클릭할 때
  elseif event.element.name:match('^_gvv[-]mod_c_sub_obj_%d+$') and event.element.parent and event.element.parent.name == '_gvv-mod_sub_gobjlist_' then
    local index = event.element.name:match('^_gvv[-]mod_c_sub_obj_(%d+)$') + 0
    Tree.draw_gobjtree(g, event.element.caption)

  --sub_helplist 의 좌측 항목을 클릭할 때
  elseif event.element.name:match('^_gvv[-]mod_c_sub_help_/') and event.element.parent and event.element.parent.name == '_gvv-mod_sub_helplist_' then
    local page_name = event.element.name:match('^_gvv[-]mod_c_sub_help_/(.+)$')
    Help_Menu.draw_page(g, page_name)

  -- _gvv-mod_anycode_frame_ 의 입력버튼을 클릭할 때
  elseif g.gui.icconf and g.gui.icconf.valid and event.element == g.gui.icconf then
    local code = event.element.parent.parent['_gvv-mod_anycode_code_']
    Tracking.add(g, code.text)
    local top = Util.get_top_frame(event.element)
    if top and top.valid then
      top.destroy()
    end
    Gui.change_tab(g, 1)

  --tracking_panel 의 경로를 우클릭할 때
  elseif event.element.name == '_gvv-mod_tracking_path_str_' and event.button == defines.mouse_button_type.right then
    Gui.copyable_tracking_code(player, event.element.caption)

  --tracking_panel 의 결과값을 우클릭할 때
  elseif event.element.name == '_gvv-mod_tracking_output_' and event.button == defines.mouse_button_type.right then
    Gui.copyable_tracking_code(player, event.element.caption)

  --tracking_panel 의 빈 공간을 우클릭할 때 (이 조건은 가능한한 뒤에)
  elseif g.gui.tracking_panel and Util.find_parent_gui(event.element, g.gui.tracking_panel.parent) and event.button == defines.mouse_button_type.right then
    Gui.put_anycode_in_tracking(g)

  --메인 프레임을 클릭할 때 (이 조건은 가장 마지막에)
  elseif Util.find_parent_gui(event.element, g.gui.frame) then
    local frame
    for frame_name in pairs(other_frames_to_close_when_focusing_main) do
      frame = player.gui.screen[frame_name]
      if frame and frame.valid then
        frame.destroy()
      end
    end

  end
end

Gui_Event.on_gui_closed = function(event)
  if event.element then
    if event.element.player_index ~= event.player_index then return end
    if simple_frame_names[event.element.name] then
      event.element.destroy()
      return
    end
  end

  if not global.players then return end
  local g = global.players[event.player_index]
  if not g or not g.gui.frame or not g.gui.frame.valid then return end
end

Gui_Event.on_gui_value_changed = function(event)
  if not event.element then return end
  if event.element.player_index ~= event.player_index then return end
  if not global.players then return end
  local g = global.players[event.player_index]
  if not g or not g.gui.frame or not g.gui.frame.valid then return end
  if event.element == g.gui.xresize then
    g.last_width = g.gui.xresize.slider_value
    g.gui.frame.style.width = g.last_width
  elseif event.element == g.gui.yresize then
    g.last_height = g.gui.yresize.slider_value
    g.gui.frame.style.height = g.last_height
  elseif event.element == g.gui.track_inter_slider then
    g.track_interval_tick = g.gui.track_inter_slider.slider_value
    g.gui.track_inter_show.caption = g.track_interval_tick
  end
end

Gui_Event.on_gui_confirmed = function(event)
  if not event.element then return end
  if event.element.player_index ~= event.player_index then return end
  if not global.players then return end
  local g = global.players[event.player_index]
  if not g or not g.gui.frame or not g.gui.frame.valid then return end
  local player = game.players[event.player_index]

  if event.element == g.gui.track_inter_edit then
    if g.gui.track_inter_edit.text ~= '' then g.track_interval_tick = g.gui.track_inter_edit.text + 0 end
    if g.track_interval_tick < 1 then g.track_interval_tick = 1 end
    g.gui.track_inter_edit.visible = false
    if g.gui.tabpane.selected_tab_index == 1 then g.gui.track_inter_show.visible = true end
    g.gui.track_inter_show.caption = g.track_interval_tick
    g.gui.track_inter_slider.slider_value = g.track_interval_tick
  elseif event.element.name == '_gvv-mod_anycode_code_' then
    Tracking.add(g, event.element.text)
    local top = Util.get_top_frame(event.element)
    if top and top.valid then
      top.destroy()
    end
    Gui.change_tab(g, 1)
  end
end

Gui_Event.on_gui_selected_tab_changed = function(event)
  if not event.element then return end
  if event.element.player_index ~= event.player_index then return end
  if not global.players then return end
  local g = global.players[event.player_index]
  if not g or not g.gui.frame or not g.gui.frame.valid then return end

  if event.element == g.gui.tabpane then
    Gui.change_tab(g, event.element.selected_tab_index)
  end
end

Gui_Event.on_gui_checked_state_changed = function(event)
  if not event.element then return end
  if event.element.player_index ~= event.player_index then return end
  if not global.players then return end
  local g = global.players[event.player_index]
  if not g or not g.gui.frame or not g.gui.frame.valid then return end

  if event.element == g.gui.chk_show_na then
    g.show_na = event.element.state
    Tree.set_visible_item('na', g.gui.sub_proptree, g.show_na)
    Tree.set_visible_item('na', g.gui.sub_gobjtree, g.show_na)
  elseif event.element == g.gui.chk_show_func then
    g.show_func = event.element.state
    Tree.set_visible_item('func', g.gui.sub_proptree, g.show_func)
    Tree.set_visible_item('func', g.gui.sub_gobjtree, g.show_func)
  end
end

Gui_Event.on_gui_text_changed = function(event)
  if not event.element then return end
  if event.element.player_index ~= event.player_index then return end

  if event.element.name == '_gvv-mod_uneditable_text_' then
    if event.element.parent['_gvv-mod_uneditable_text_buffer_'] then
      event.element.text = event.element.parent['_gvv-mod_uneditable_text_buffer_'].caption
      event.element.select_all()
    end
  end
end

Gui_Event.on_gui_selection_state_changed = function(event)
  if not event.element then return end
  if event.element.player_index ~= event.player_index then return end

  if event.element.name == '_gvv-mod_help_copy_mod_global_code_' then
    local copybox = event.element.parent['_gvv-mod_copyable_']
    copybox['_gvv-mod_uneditable_text_buffer_'].caption = 'remote.call("__'..event.element.items[event.element.selected_index]..'__gvv","global")'
    copybox['_gvv-mod_uneditable_text_'].text = copybox['_gvv-mod_uneditable_text_buffer_'].caption
    copybox['_gvv-mod_uneditable_text_'].focus()
    copybox['_gvv-mod_uneditable_text_'].select_all()
  end
end

Gui_Event['toggle-main-frame_gvv-mod'] = function(event)
  local player = game.players[event.player_index]
  if not player.admin and game.is_multiplayer() then return end
  if player then Gui.open_main(event.player_index) end
end

return Gui_Event
