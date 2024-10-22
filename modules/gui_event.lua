-- GUI 이벤트

local Util = require('modules.util')
local Gui = require('modules.gui')
local Tree = require('modules.tree')
local Table_to_str = require('modules.table_to_str')
local Tracking = require('modules.tracking')
local Help_Menu = require('modules.help_menu')
local Doctor = require('modules.doctor')
local Copy_Code = require('modules.copy_code')
local Search_Tree = require('modules.search_tree')

local Gui_Event = {}

local simple_frame_names = {
  ['_gvv-mod_dump_frame_'] = true,
  ['_gvv-mod_anycode_frame_'] = true,
  ['_gvv-mod_copy_tracking_code_frame_'] = true,
  ['_gvv-mod_edit_tracking_code_frame_'] = true,
  ['_gvv-mod_export_tracking_code_frame_'] = true,
  ['_gvv-mod_import_tracking_code_frame_'] = true,
}
local other_frames_to_close_when_focusing_main = {
  ['_gvv-mod_anycode_frame_'] = true,
  ['_gvv-mod_copy_tracking_code_frame_'] = true,
  ['_gvv-mod_export_tracking_code_frame_'] = true,
  ['_gvv-mod_import_tracking_code_frame_'] = true,
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

  if not storage.players then return end
  local g = storage.players[event.player_index]
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

  --추적 항목 삭제하려다 딴거 누를 때
  if event.element ~= g.gui.remove_checked_btn and g.gui.remove_confirm_frame.visible and event.element ~= g.gui.remove_confirm_frame then
    g.gui.remove_confirm_frame.visible = false
  end

  --닫기 버튼
  if event.element == g.gui.closebtn then
    Gui.close_main(g)

  --추적 항목 삭제 버튼
  elseif event.element == g.gui.remove_checked_btn then
    g.gui.remove_confirm_frame.visible = not g.gui.remove_confirm_frame.visible

  --추적 항목 삭제 버튼 - 취소
  elseif event.element == g.gui.remove_checked_cancel_btn then
    g.gui.remove_confirm_frame.visible = false

  --추적 항목 삭제 버튼 - 확인
  elseif event.element == g.gui.remove_checked_confirm_btn then
    local panel = g.gui.tracking_panel
    local list = g.data.tracking_list
    for _, elem in pairs(panel.children) do
      if elem.header.check_to_remove.state then
        list[elem.name] = nil
        elem.destroy()
      end
    end

  --추적 항목 이동 버튼
  elseif event.element == g.gui.move_up_checked_btn or event.element == g.gui.move_down_checked_btn then
    local panel = g.gui.tracking_panel
    local list = g.data.tracking_list
    local array = {}
    for i, elem in pairs(panel.children) do
      array[i] = {
        index = i,
        checked = elem.header.check_to_remove.state,
        path_str = elem.name,
        full_path = list[elem.name],
        preinput = {
          remchk = elem.header.check_to_remove.state,
          value = elem.body['_gvv-mod_tracking_output_'].caption
        }
      }
    end
    if event.element == g.gui.move_up_checked_btn then
      if event.button == defines.mouse_button_type.left then
        array = Util.shift_checked(array, -1)
      elseif event.button == defines.mouse_button_type.right then
        array = Util.push_checked(array, -1)
      end
    elseif event.element == g.gui.move_down_checked_btn then
      if event.button == defines.mouse_button_type.left then
        array = Util.shift_checked(array, 1)
      elseif event.button == defines.mouse_button_type.right then
        array = Util.push_checked(array, 1)
      end
    end
    for i, elem in pairs(panel.children) do
      elem.destroy()
    end
    for i, v in ipairs(array) do
      Tracking.draw(panel, v.path_str, v.full_path, v.preinput)
    end

  --추적 항목 체크 조정 버튼
  elseif event.element == g.gui.check_process_btn then
    local panel = g.gui.tracking_panel
    local list = g.data.tracking_list
    if event.button == defines.mouse_button_type.left then
      for i, elem in pairs(panel.children) do
        elem.header.check_to_remove.state = not elem.header.check_to_remove.state
      end
    elseif event.button == defines.mouse_button_type.right then
      local something_checked = false
      for i, elem in pairs(panel.children) do
        if elem.header.check_to_remove.state then
          something_checked = true
          break
        end
      end
      if something_checked then
        for i, elem in pairs(panel.children) do
          elem.header.check_to_remove.state = false
        end
      else
        for i, elem in pairs(panel.children) do
          elem.header.check_to_remove.state = true
        end
      end
    end

  --추적 항목 가져오기/내보내기 버튼
  elseif event.element == g.gui.export_import_btn then
    local panel = g.gui.tracking_panel
    local list = g.data.tracking_list
    if event.button == defines.mouse_button_type.left then
      Gui.export_window(g)
    elseif event.button == defines.mouse_button_type.right then
      Gui.import_window(g)
    end

  --추적 항목 가져오기 버튼 - 가져오기
  elseif event.element == g.gui.imconf then
    local raw = event.element.parent.parent['_gvv-mod_import_tracking_code_code_'].text
    local r, codes = true, {}
    local import_codes = {}
    local c = 0
    while r do
      codes[#codes + 1] = raw:match('^(.-)(%-%-%[%[%]%]%-%-)')
      raw, c = raw:gsub('^(.-)(%-%-%[%[%]%]%-%-)','')
      if c == 0 then
        codes[#codes + 1] = raw
        r = false
      end
    end
    for i, v in ipairs(codes) do
      codes[i] = v:gsub('^\n',''):gsub('\n$','')
      if codes[i]:gsub('^%s*(.-)%s*$', '%1') ~= '' then import_codes[#import_codes + 1] = codes[i] end
    end
    local panel = g.gui.tracking_panel
    local list = g.data.tracking_list
    local pnsize, imsize = #panel.children, #import_codes
    local dup_count, new_count = 0, 0
    local duplicate
    for ii = 1, pnsize do
      panel.children[ii].header.check_to_remove.state = false
    end
    for i = 1, imsize do
      duplicate = false
      for ii = 1, pnsize do
        if panel.children[ii].name == import_codes[i] then
          duplicate = true
          import_codes[i] = nil
          panel.children[ii].header.check_to_remove.state = true
          dup_count = dup_count + 1
          break
        end
      end
      if not duplicate then
        Tracking.add(g, import_codes[i])
        new_count = new_count + 1
      end
    end
    for i = pnsize + 1, #panel.children do
      panel.children[i].header.check_to_remove.state = true
    end
    local top = Util.get_top_frame(event.element)
    if top and top.valid then
      top.destroy()
    end
    Gui.change_tab(g, 1)
    game.players[g.index].print('(gvv) '..new_count..' new entries imported.  /  '..dup_count..' entries already exist.')

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

  --storage.report 비우기
  elseif event.element.name == '_gvv-mod_fix_clear_report_btn_' then
    storage.report = {}
    player.print('(gvv) storage.report is cleared.')

  --추적 간격 숫자 누를때
  elseif event.element == g.gui.track_inter_show and event.button == defines.mouse_button_type.left then
    g.gui.track_inter_show.visible = false
    g.gui.track_inter_edit.visible = true
    g.gui.track_inter_edit.text = g.track_interval_tick .. ''
    g.gui.track_inter_edit.focus()
    g.gui.track_inter_edit.select_all()

  --트리 항목 라벨을 좌클릭으로 선택할 때
  elseif event.element.name == '_gvv-mod_key_label' and event.button == defines.mouse_button_type.left then
    if Tree.ignore_in_help_page(g, event.element) then return end
    local category = Tree.get_tree_category(event.element)
    local tree_data
    if category == '_G_glob' then
      tree_data = g.data._G_tree_item_glob
    elseif category == 'glob' then
      tree_data = g.data.tree_item_glob
    elseif category == 'prop' then
      tree_data = g.data.tree_item_prop
    elseif category == 'gobj' then
      tree_data = g.data.tree_item_gobj
    end
    local succ, tree_path = Tree.track_path(tree_data, event.element, {})
    if succ then
      --clicking Continue to load. 계속 로딩하기 클릭시.
      if event.element.style.name == 'load-cont_gvv-mod' then
        local data, index
        data, index = Tree.get_tree_data(tree_data, event.element)
        local parentlabel = data.parent
        local cont_from = data.cont_from
        table.remove(tree_path, #tree_path)
        table.remove(tree_data, index)
        -- tree_data keys : {parent, object, key, is_folder, is_root, cont_from}
        local folder = parentlabel.parent.parent.content_container.folder
        event.element.parent.parent.destroy()
        if category == '_G_glob' then
          local tbl = Tree.get_storage(parentlabel)
          for i = 2, #tree_path do
            tbl = tbl[tree_path[i]]
          end
          Tree.draw(g, tree_data, {}, tbl, folder, parentlabel, false, cont_from)
        elseif category == 'glob' then
          local tbl = Tree.get_storage(parentlabel)
          for i = 2, #tree_path do
            tbl = tbl[tree_path[i]]
          end
          Tree.draw(g, tree_data, {}, tbl, folder, parentlabel, false, cont_from)
        elseif category == 'prop' then
          local top = Tree.get_top_parent(parentlabel)
          local obj_index = top.caption:match('^[(](%d+)[)] ') + 0
          local obj = g.data.docked_luaobj[obj_index].luaobj
          for i = 2, #tree_path do
            obj = obj[tree_path[i]]
          end
          if type(obj) == 'userdata' and obj.object_name then
            local props = Util.get_property_list(obj, true)
            Tree.draw(g, tree_data, {}, props, folder, parentlabel, true, cont_from)
          else
            Tree.draw(g, tree_data, {}, obj, folder, parentlabel, true, cont_from)
          end
        elseif category == 'gobj' then
          local top = Tree.get_top_parent(parentlabel)
          local gobj_name = top.caption:match('^[%a_][%a%d_]*')
          local obj = assert(loadstring('return '..gobj_name))()
          for i = 2, #tree_path do
            obj = obj[tree_path[i]]
          end
          if type(obj) == 'userdata' and obj.object_name then
            local props = Util.get_property_list(obj, true)
            Tree.draw(g, tree_data, {}, props, folder, parentlabel, true, cont_from)
          else
            Tree.draw(g, tree_data, {}, obj, folder, parentlabel, true, cont_from)
          end
        end
        if category == '_G_glob' then
          Search_Tree.refresh(g, 'glob')
        else
          Search_Tree.refresh(g, category)
        end
        return
      end --continue to load end
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
            if category == '_G_glob' then
              local tbl = Tree.get_storage(event.element)
              for i = 2, #tree_path do
                tbl = tbl[tree_path[i]]
              end
              Tree.draw(g, tree_data, {}, tbl, folder, event.element, false)
            elseif category == 'glob' then
              local tbl = Tree.get_storage(event.element)
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
              if type(obj) == 'userdata' and obj.object_name then
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
              if type(obj) == 'userdata' and obj.object_name then
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
          if category == '_G_glob' then
            Search_Tree.refresh(g, 'glob')
          else
            Search_Tree.refresh(g, category)
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
      local btn
      event.element.style = 'tracked-tree-item-luaobj_gvv-mod'
      if Tree.ignore_in_help_page(g, event.element) then return end
      btn = Tree.register_object(g, event.element.parent['_gvv-mod_key_label'])
      Search_Tree.refresh(g, 'prop')
      g.tabs.last_sub_obj = btn.caption
    elseif event.element.style.name == 'tracked-tree-item-luaobj_gvv-mod' then
      event.element.style = 'tree-item-luaobj_gvv-mod'
    end

  --sub_objlist 의 좌측 항목을 클릭할 때
  elseif event.element.name:match('^_gvv[-]mod_c_sub_obj_%d+$') and event.element.parent and event.element.parent.name == '_gvv-mod_sub_objlist_' then
    local index = event.element.name:match('^_gvv[-]mod_c_sub_obj_(%d+)$') + 0
    if event.button == defines.mouse_button_type.left then
      Tree.draw_proptree(g, index)
      Search_Tree.refresh(g, 'prop')
      g.tabs.last_sub_obj = event.element.caption
    elseif event.button == defines.mouse_button_type.right then
      Tree.remove_prop_tree(g, index)
      Search_Tree.refresh(g, 'prop')
      if g.tabs.last_sub_obj == event.element then
        g.tabs.last_sub_obj = nil
      end
    end

  --sub_modlist 의 좌측 항목을 클릭할 때
  elseif event.element.name:match('^_gvv[-]mod_c_sub_mod_%d+$') and event.element.parent and event.element.parent.name == '_gvv-mod_sub_modlist_' then
    Tree.draw_globtree(g, event.element.caption)
    Search_Tree.refresh(g, 'glob')
    g.tabs.last_sub_mod = event.element.caption

  --sub_gobjlist 의 좌측 항목을 클릭할 때
  elseif event.element.name:match('^_gvv[-]mod_c_sub_obj_%d+$') and event.element.parent and event.element.parent.name == '_gvv-mod_sub_gobjlist_' then
    local index = event.element.name:match('^_gvv[-]mod_c_sub_obj_(%d+)$') + 0
    Tree.draw_gobjtree(g, event.element.caption)
    Search_Tree.refresh(g, 'gobj')
    g.tabs.last_sub_gobj = event.element.caption

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

  -- _gvv-mod_copy_tracking_code_frame_ 의 편집버튼을 클릭할 때
  elseif g.gui.ecedit and g.gui.ecedit.valid and event.element == g.gui.ecedit then
    local name = event.element.parent.parent.entry_name_buffer.caption
    local code = event.element.parent.parent['_gvv-mod_uneditable_text_buffer_'].caption
    local succ = Gui.edit_code_in_tracking(g, code, name)
    if succ then
      local top = Util.get_top_frame(event.element)
      if top and top.valid then
        top.destroy()
      end
    end

  -- _gvv-mod_edit_tracking_code_frame_ 의 편집 확인 버튼을 클릭할 때
  elseif g.gui.ecconf and g.gui.ecconf.valid and event.element == g.gui.ecconf then
    local name = event.element.parent.parent.sc.entry_name_buffer.caption
    local code = event.element.parent.parent['_gvv-mod_edit_tracking_code_code_'].text
    local panel = g.gui.tracking_panel
    local list = g.data.tracking_list
    local buffer = {}
    local start_adding_buffer = false
    for i, elem in ipairs(panel.children) do
      if start_adding_buffer then
        buffer[#buffer + 1] = {
          path_str = elem.name,
          full_path = list[elem.name],
          preinput = {
            remchk = elem.header.check_to_remove.state,
            value = elem.body['_gvv-mod_tracking_output_'].caption
          }
        }
        elem.destroy()
      elseif elem.name == name then
        list[elem.name] = nil
        elem.destroy()
        start_adding_buffer = true
      end
    end
    Tracking.add(g, code)
    for i, v in ipairs(buffer) do
      Tracking.draw(panel, v.path_str, v.full_path, v.preinput)
    end
    local top = Util.get_top_frame(event.element)
    if top and top.valid then
      top.destroy()
    end
    Gui.change_tab(g, 1)

  --tracking_panel 의 경로를 우클릭할 때
  elseif event.element.name == '_gvv-mod_tracking_path_str_' and event.button == defines.mouse_button_type.right then
    Gui.copyable_tracking_code(g, event.element.caption, event.element.parent.parent.name)

  --tracking_panel 의 결과값을 우클릭할 때
  elseif event.element.name == '_gvv-mod_tracking_output_' and event.button == defines.mouse_button_type.right then
    Gui.copyable_tracking_code(g, event.element.caption)

  --트리 갱신 버튼
  elseif event.element == g.gui.tree_refresh_btn then
    local pane = g.gui.tabpane
    local tab = pane.selected_tab_index
    local subelem = nil
    if tab == 2 then
      if g.tabs.last_sub_mod then
        subelem = Util.get_guichild_by_caption(g.gui.sub_modlist, g.tabs.last_sub_mod)
      end
    elseif tab == 3 then
      if g.tabs.last_sub_obj then
        subelem = Util.get_guichild_by_caption(g.gui.sub_objlist, g.tabs.last_sub_obj)
      end
    elseif tab == 4 then
      if g.tabs.last_sub_gobj then
        subelem = Util.get_guichild_by_caption(g.gui.sub_gobjlist, g.tabs.last_sub_gobj)
      end
    end
    if subelem then
      Gui_Event.on_gui_click{
        element = subelem,
        player_index = event.player_index,
        button = defines.mouse_button_type.left,
        alt = false,
        control = false,
        shift = false
      }
    end

  --검색 보이기 버튼
  elseif event.element == g.gui.search_btn then
    if g.show_search then
      g.show_search = false
      g.gui.search_glob_wrap.visible = false
      g.gui.search_prop_wrap.visible = false
      g.gui.search_gobj_wrap.visible = false
    else
      local index = g.gui.tabpane.selected_tab_index
      g.show_search = true
      g.gui.search_glob_wrap.visible = true
      g.gui.search_prop_wrap.visible = true
      g.gui.search_gobj_wrap.visible = true
      if index == 2 then
        g.gui.search_glob_input.focus()
      elseif index == 3 then
        g.gui.search_prop_input.focus()
      elseif index == 4 then
        g.gui.search_gobj_input.focus()
      end
    end
    Search_Tree.refresh(g, 'glob')
    Search_Tree.refresh(g, 'prop')
    Search_Tree.refresh(g, 'gobj')

  --tracking_panel 의 빈 공간을 우클릭할 때 (이 조건은 가능한한 뒤에)
  elseif g.gui.tracking_panel and g.gui.tabpane.selected_tab_index == 1 and Util.find_parent_gui(event.element, g.gui.tracking_panel.parent) and event.button == defines.mouse_button_type.right then
    local succ = Gui.put_anycode_in_tracking(g)

  --tracking_panel 의 빈 공간을 휠클릭할 때 (이 조건은 가능한한 뒤에)
  elseif g.gui.tracking_panel and g.gui.tabpane.selected_tab_index == 1 and Util.find_parent_gui(event.element, g.gui.tracking_panel.parent) and event.button == defines.mouse_button_type.middle then
    local succ, elem = Util.find_parent_gui(event.element, g.gui.tracking_panel)
    if succ then
      elem.header.check_to_remove.state = not elem.header.check_to_remove.state
    end

  --메인 프레임을 클릭할 때 (이 조건은 가장 마지막에)
  elseif Util.find_parent_gui(event.element, g.gui.frame) then
    local frame
    for frame_name in pairs(other_frames_to_close_when_focusing_main) do
      frame = player.gui.screen[frame_name]
      if frame and frame.valid then
        if frame_name == '_gvv-mod_anycode_frame_' then
          local text = frame.innerframe['_gvv-mod_anycode_code_'].text
          if text == '' then
            frame.destroy()
          end
        --elseif frame_name == '_gvv-mod_import_tracking_code_frame_' then
          --local text = frame.innerframe['_gvv-mod_import_tracking_code_code_'].text
          --if text == '' then
          --  frame.destroy()
          --end
        else
          frame.destroy()
        end
      end
    end

  end
end

Gui_Event.on_gui_closed = function(event)
  if event.element then
    if event.element.player_index ~= event.player_index then return end
    if simple_frame_names[event.element.name] then
      if event.element.name == '_gvv-mod_anycode_frame_' then
        local text = event.element.innerframe['_gvv-mod_anycode_code_'].text
        if text == '' then
          event.element.destroy()
        end
      else
        event.element.destroy()
      end
      return
    end
  end

  if not storage.players then return end
  local g = storage.players[event.player_index]
  if not g or not g.gui.frame or not g.gui.frame.valid then return end
end

Gui_Event.on_gui_value_changed = function(event)
  if not event.element then return end
  if event.element.player_index ~= event.player_index then return end
  if not storage.players then return end
  local g = storage.players[event.player_index]
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
  if not storage.players then return end
  local g = storage.players[event.player_index]
  if not g or not g.gui.frame or not g.gui.frame.valid then return end
  local player = game.players[event.player_index]

  if event.element == g.gui.track_inter_edit then
    if g.gui.track_inter_edit.text ~= '' then g.track_interval_tick = g.gui.track_inter_edit.text + 0 end
    if g.track_interval_tick < 1 then g.track_interval_tick = 1 end
    g.gui.track_inter_edit.visible = false
    if g.gui.tabpane.selected_tab_index == 1 then g.gui.track_inter_show.visible = true end
    g.gui.track_inter_show.caption = g.track_interval_tick
    g.gui.track_inter_slider.slider_value = g.track_interval_tick
  --elseif event.element.name == '_gvv-mod_anycode_code_' then
    --Tracking.add(g, event.element.text)
    --local top = Util.get_top_frame(event.element)
    --if top and top.valid then
    --  top.destroy()
    --end
    --Gui.change_tab(g, 1)
  end
end

Gui_Event.on_gui_selected_tab_changed = function(event)
  if not event.element then return end
  if event.element.player_index ~= event.player_index then return end
  if not storage.players then return end
  local g = storage.players[event.player_index]
  if not g or not g.gui.frame or not g.gui.frame.valid then return end

  if event.element == g.gui.tabpane then
    Gui.change_tab(g, event.element.selected_tab_index)
  end
end

Gui_Event.on_gui_checked_state_changed = function(event)
  if not event.element then return end
  if event.element.player_index ~= event.player_index then return end
  if not storage.players then return end
  local g = storage.players[event.player_index]
  if not g or not g.gui.frame or not g.gui.frame.valid then return end

  if event.element == g.gui.chk_show_na then
    g.show_na = event.element.state
    Tree.set_visible_item('na', g.gui.sub_proptree, g.show_na)
    Tree.set_visible_item('na', g.gui.sub_gobjtree, g.show_na)
    Search_Tree.refresh(g, 'prop')
    Search_Tree.refresh(g, 'gobj')
  elseif event.element == g.gui.chk_show_nil then
    g.show_nil = event.element.state
    Tree.set_visible_item('nil', g.gui.sub_proptree, g.show_nil)
    Tree.set_visible_item('nil', g.gui.sub_gobjtree, g.show_nil)
    Search_Tree.refresh(g, 'prop')
    Search_Tree.refresh(g, 'gobj')
  elseif event.element == g.gui.chk_show_func then
    g.show_func = event.element.state
    Tree.set_visible_item('func', g.gui.sub_proptree, g.show_func)
    Tree.set_visible_item('func', g.gui.sub_gobjtree, g.show_func)
    Search_Tree.refresh(g, 'prop')
    Search_Tree.refresh(g, 'gobj')
  elseif event.element == g.gui.search_glob_fkey then
    g.search_settings.glob.key = event.element.state
    Search_Tree.refresh(g, 'glob')
  elseif event.element == g.gui.search_glob_fvalue then
    g.search_settings.glob.value = event.element.state
    Search_Tree.refresh(g, 'glob')
  elseif event.element == g.gui.search_glob_fregexp then
    g.search_settings.glob.regexp = event.element.state
    Search_Tree.refresh(g, 'glob')
  elseif event.element == g.gui.search_glob_fcase then
    g.search_settings.glob.case = event.element.state
    Search_Tree.refresh(g, 'glob')
  elseif event.element == g.gui.search_prop_fkey then
    g.search_settings.prop.key = event.element.state
    Search_Tree.refresh(g, 'prop')
  elseif event.element == g.gui.search_prop_fvalue then
    g.search_settings.prop.value = event.element.state
    Search_Tree.refresh(g, 'prop')
  elseif event.element == g.gui.search_prop_fregexp then
    g.search_settings.prop.regexp = event.element.state
    Search_Tree.refresh(g, 'prop')
  elseif event.element == g.gui.search_prop_fcase then
    g.search_settings.prop.case = event.element.state
    Search_Tree.refresh(g, 'prop')
  elseif event.element == g.gui.search_gobj_fkey then
    g.search_settings.gobj.key = event.element.state
    Search_Tree.refresh(g, 'gobj')
  elseif event.element == g.gui.search_gobj_fvalue then
    g.search_settings.gobj.value = event.element.state
    Search_Tree.refresh(g, 'gobj')
  elseif event.element == g.gui.search_gobj_fregexp then
    g.search_settings.gobj.regexp = event.element.state
    Search_Tree.refresh(g, 'gobj')
  elseif event.element == g.gui.search_gobj_fcase then
    g.search_settings.gobj.case = event.element.state
    Search_Tree.refresh(g, 'gobj')
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
    return
  end
  
  if not storage.players then return end
  local g = storage.players[event.player_index]
  if not g or not g.gui.frame or not g.gui.frame.valid then return end

  if event.element.name == '_gvv-mod_anycode_code_' then
    if event.element.text == '' then
      local player = game.players[event.player_index]
      if player.opened_gui_type == defines.gui_type.none then
        player.opened = Util.get_top_frame(event.element)
      end
    end
  elseif event.element == g.gui.search_glob_input then
    g.search_settings.glob.text = event.element.text
    Search_Tree.refresh(g, 'glob')
  elseif event.element == g.gui.search_prop_input then
    g.search_settings.prop.text = event.element.text
    Search_Tree.refresh(g, 'prop')
  elseif event.element == g.gui.search_gobj_input then
    g.search_settings.gobj.text = event.element.text
    Search_Tree.refresh(g, 'gobj')
  end
end

Gui_Event.on_gui_selection_state_changed = function(event)
  if not event.element then return end
  if event.element.player_index ~= event.player_index then return end

  if event.element.name == '_gvv-mod_help_copy_mod_string_code_' or event.element.name == '_gvv-mod_help_copy_option_mod_string_' then
    local optionbox
    local modbox
    if event.element.name == '_gvv-mod_help_copy_mod_string_code_' then
      modbox = event.element
      optionbox = event.element.parent.parent['_gvv-mod_help_copy_option_mod_string_']
    elseif event.element.name == '_gvv-mod_help_copy_option_mod_string_' then
      modbox = event.element.parent['mod_list']['_gvv-mod_help_copy_mod_string_code_']
      optionbox = event.element
    end
    local option = optionbox.items[optionbox.selected_index]
    local copybox = modbox.parent['_gvv-mod_copyable_']
    if option == '__<mod_name>__' then
      copybox['_gvv-mod_uneditable_text_buffer_'].caption = '__'..modbox.items[modbox.selected_index]..'__'
    elseif option == 'remote.call..."storage")' then
      copybox['_gvv-mod_uneditable_text_buffer_'].caption = 'remote.call("__'..modbox.items[modbox.selected_index]..'__gvv","storage")'
    elseif option == 'remote.call..."c",)' then
      copybox['_gvv-mod_uneditable_text_buffer_'].caption = 'remote.call("__'..modbox.items[modbox.selected_index]..'__gvv","c",)'
    else
      copybox['_gvv-mod_uneditable_text_buffer_'].caption = modbox.items[modbox.selected_index]
    end
    copybox['_gvv-mod_uneditable_text_'].text = copybox['_gvv-mod_uneditable_text_buffer_'].caption
    copybox['_gvv-mod_uneditable_text_'].focus()
    copybox['_gvv-mod_uneditable_text_'].select_all()
    return
  elseif event.element.name == '_gvv-mod_help_copy_temp_enable_code_' then
    local copybox = event.element.parent['_gvv-mod_copyable_']
    copybox['_gvv-mod_uneditable_text_buffer_'].caption = Copy_Code.in_console_enable(event.element.items[event.element.selected_index])
    copybox['_gvv-mod_uneditable_text_'].text = copybox['_gvv-mod_uneditable_text_buffer_'].caption
    copybox['_gvv-mod_uneditable_text_'].focus()
    copybox['_gvv-mod_uneditable_text_'].select_all()
    return
  elseif event.element.name == '_gvv-mod_help_copy_temp_disable_code_' then
    local copybox = event.element.parent['_gvv-mod_copyable_']
    copybox['_gvv-mod_uneditable_text_buffer_'].caption = Copy_Code.in_console_disable(event.element.items[event.element.selected_index])
    copybox['_gvv-mod_uneditable_text_'].text = copybox['_gvv-mod_uneditable_text_buffer_'].caption
    copybox['_gvv-mod_uneditable_text_'].focus()
    copybox['_gvv-mod_uneditable_text_'].select_all()
    return
  end

  if not storage.players then return end
  local g = storage.players[event.player_index]
  if not g or not g.gui.frame or not g.gui.frame.valid then return end

  if event.element == g.gui.search_glob_result then
    local index = event.element.selected_index
    local data = g.data.search.glob[index]
    g.gui.sub_globtree.scroll_to_element(data.elem, 'top-third')
    event.element.selected_index = 0
  elseif event.element == g.gui.search_prop_result then
    local index = event.element.selected_index
    local data = g.data.search.prop[index]
    g.gui.sub_proptree.scroll_to_element(data.elem, 'top-third')
    event.element.selected_index = 0
  elseif event.element == g.gui.search_gobj_result then
    local index = event.element.selected_index
    local data = g.data.search.gobj[index]
    g.gui.sub_gobjtree.scroll_to_element(data.elem, 'top-third')
    event.element.selected_index = 0
  end

end

Gui_Event['toggle-main-frame_gvv-mod'] = function(event)
  local player = game.players[event.player_index]
  if not player.admin and game.is_multiplayer() then return end
  if player then Gui.open_main(event.player_index) end
end

Gui_Event['refresh_gvv-mod'] = function(event)
  local player = game.players[event.player_index]
  if not player.admin and game.is_multiplayer() then return end
  if not storage.players then return end
  local g = storage.players[event.player_index]
  if g and g.gui and g.gui.tabpane and g.gui.tabpane.valid then
    local pane = g.gui.tabpane
    local tab = pane.selected_tab_index
    if tab == 1 then
      Gui_Event.on_gui_click{
        element = g.gui.track_refresh_btn,
        player_index = event.player_index,
        button = defines.mouse_button_type.left,
        alt = false,
        control = false,
        shift = false
      }
    elseif tab > 1 and tab < 5 then
      Gui_Event.on_gui_click{
        element = g.gui.tree_refresh_btn,
        player_index = event.player_index,
        button = defines.mouse_button_type.left,
        alt = false,
        control = false,
        shift = false
      }
    end
  end
end

return Gui_Event
