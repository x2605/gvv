--[[
  gui_event.lua
]]

-- GUI 이벤트

local Util = require(gvv.defines.lualib.common.util)
local Gui = require(gvv.defines.legacy.gui)
local Tree = require(gvv.defines.legacy.tree)
local Table_to_str = require(gvv.defines.lualib.common.table_to_str)

local Gui_Event = {}

-- FR : Listes des petites fenêtres : maintenant dans gui/dialogs.lua (KINDS)
-- EN : Small windows lists: now in gui/dialogs.lua (KINDS)

--트리 경로를 따라 값 찾기. 중간에 없어지면 nil
--Follow tree path from value. Returns nil if something is gone on the way
local follow_tree_path = function(value, tree_path)
  for i = 2, #tree_path do
    if type(value) ~= 'table' and type(value) ~= 'userdata' then return nil end
    value = value[tree_path[i]]
  end
  return value
end

--그리기 전에 데이터가 사라졌을 때 : 알리고 트리 갱신
--Data is gone since the tree was drawn : notify and refresh tree
local on_tree_data_gone = function(player, player_data, event)
  player.print({"gvv-mod.tree-data-gone"})
  Gui_Event.on_gui_click{
    element = player_data.gui.tree_refresh_btn,
    player_index = event.player_index,
    button = defines.mouse_button_type.left,
    alt = false,
    control = false,
    shift = false
  }
end

Gui_Event.on_gui_click = function(event)
  if not event.element then return end
  if event.element.player_index ~= event.player_index then return end
  local player = game.get_player(event.player_index)
  -- FR : Bouton fermer des petites fenêtres : géré par GvvGuiDialog / EN : Small windows close button: handled by GvvGuiDialog

  if not storage.players then return end
  local player_data = storage.players[event.player_index]
  if not player_data or not player_data.gui.frame or not player_data.gui.frame.valid then return end

  -- FR : Suivi (intervalle, suppression, déplacement, cases, export / import, rafraîchir) : géré par GvvGuiTracking
  -- EN : Tracking (interval, removal, moving, boxes, export / import, refresh): handled by GvvGuiTracking

  --진단, 정리, storage.report 비우기 : FR : gérés par GvvGuiHelp / EN : handled by GvvGuiHelp

  --추적 간격 숫자 누를때 : FR : géré par GvvGuiTracking / EN : handled by GvvGuiTracking

  --트리 항목 라벨을 좌클릭으로 선택할 때
  if event.element.name == '_gvv-mod_key_label' and event.button == defines.mouse_button_type.left then
    if Tree.ignore_in_help_page(player_data, event.element) then return end
    local category = Tree.get_tree_category(event.element)
    local tree_data
    if category == '_G_glob' then
      tree_data = player_data.data._G_tree_item_glob
    elseif category == 'glob' then
      tree_data = player_data.data.tree_item_glob
    elseif category == 'prop' then
      tree_data = player_data.data.tree_item_prop
    elseif category == 'gobj' then
      tree_data = player_data.data.tree_item_gobj
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
          local tbl = follow_tree_path(Tree.get_storage(parentlabel), tree_path)
          if type(tbl) ~= 'table' then return on_tree_data_gone(player, player_data, event) end
          Tree.draw(player_data, tree_data, {}, tbl, folder, parentlabel, false, cont_from)
        elseif category == 'glob' then
          local tbl = follow_tree_path(Tree.get_storage(parentlabel), tree_path)
          if type(tbl) ~= 'table' then return on_tree_data_gone(player, player_data, event) end
          Tree.draw(player_data, tree_data, {}, tbl, folder, parentlabel, false, cont_from)
        elseif category == 'prop' then
          local top = Tree.get_top_parent(parentlabel)
          local obj_index = top.caption:match('^[(](%d+)[)] ') + 0
          local obj = follow_tree_path(player_data.data.docked_luaobj[obj_index].luaobj, tree_path)
          if type(obj) == 'userdata' and obj.object_name then
            Util.logger("get_property_list: userdata with object_name: " .. obj.object_name)
            local props = Util.get_property_list(obj, true)
            Tree.draw(player_data, tree_data, {}, props, folder, parentlabel, true, cont_from)
          elseif type(obj) == 'table' then
            Tree.draw(player_data, tree_data, {}, obj, folder, parentlabel, true, cont_from)
          else
            return on_tree_data_gone(player, player_data, event)
          end
        elseif category == 'gobj' then
          local top = Tree.get_top_parent(parentlabel)
          local gobj_name = top.caption:match('^[%a_][%a%d_]*')
          local obj = follow_tree_path(assert(loadstring('return '..gobj_name))(), tree_path)
          if type(obj) == 'userdata' and obj.object_name then
            Util.logger("get_property_list: userdata with object_name: " .. obj.object_name)
            local props = Util.get_property_list(obj, true)
            Tree.draw(player_data, tree_data, {}, props, folder, parentlabel, true, cont_from)
          elseif type(obj) == 'table' then
            Tree.draw(player_data, tree_data, {}, obj, folder, parentlabel, true, cont_from)
          else
            return on_tree_data_gone(player, player_data, event)
          end
        end
        if category == '_G_glob' then
          GvvGuiSearch(event):refresh('glob')
        else
          GvvGuiSearch(event):refresh(category)
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
              local tbl = follow_tree_path(Tree.get_storage(event.element), tree_path)
              if type(tbl) ~= 'table' then return on_tree_data_gone(player, player_data, event) end
              Tree.draw(player_data, tree_data, {}, tbl, folder, event.element, false)
            elseif category == 'glob' then
              local tbl = follow_tree_path(Tree.get_storage(event.element), tree_path)
              if type(tbl) ~= 'table' then return on_tree_data_gone(player, player_data, event) end
              Tree.draw(player_data, tree_data, {}, tbl, folder, event.element, false)
            elseif category == 'prop' then
              local top = Tree.get_top_parent(event.element)
              local obj_index = top.caption:match('^[(](%d+)[)] ') + 0
              local obj = follow_tree_path(player_data.data.docked_luaobj[obj_index].luaobj, tree_path)
              if type(obj) == 'userdata' and obj.object_name then
                Util.logger("get_property_list: userdata with object_name: " .. obj.object_name)
                local props = Util.get_property_list(obj, true)
                Tree.draw(player_data, tree_data, {}, props, folder, event.element, true)
              elseif type(obj) == 'table' then
                Tree.draw(player_data, tree_data, {}, obj, folder, event.element, true)
              else
                return on_tree_data_gone(player, player_data, event)
              end
            elseif category == 'gobj' then
              local top = Tree.get_top_parent(event.element)
              local gobj_name = top.caption:match('^[%a_][%a%d_]*')
              local obj = follow_tree_path(assert(loadstring('return '..gobj_name))(), tree_path)
              if type(obj) == 'userdata' and obj.object_name then
                Util.logger("get_property_list: userdata with object_name: " .. obj.object_name)
                local props = Util.get_property_list(obj, true)
                Tree.draw(player_data, tree_data, {}, props, folder, event.element, true)
              elseif type(obj) == 'table' then
                Tree.draw(player_data, tree_data, {}, obj, folder, event.element, true)
              else
                return on_tree_data_gone(player, player_data, event)
              end
            end
          end
          if content_container.visible then
            data.object.parent.folder_sprite.sprite = 'gvv-mod_folder-opened'
          else
            data.object.parent.folder_sprite.sprite = 'gvv-mod_folder-closed'
          end
          if category == '_G_glob' then
            GvvGuiSearch(event):refresh('glob')
          else
            GvvGuiSearch(event):refresh(category)
          end
        end
      end
    end

  --트리 항목 라벨을 우클릭으로 등록할 때
  elseif event.element.name == '_gvv-mod_key_label' and event.button == defines.mouse_button_type.right then
    if event.element.style.name == 'tree-item_gvv-mod' then
      event.element.style = 'tracked-tree-item_gvv-mod'
      if Tree.ignore_in_help_page(player_data, event.element) then return end
      local full_path = Tree.track_full_path(player_data, event.element)
      GvvGuiTracking(event):add(full_path)
    elseif event.element.style.name == 'tracked-tree-item_gvv-mod' then
      event.element.style = 'tree-item_gvv-mod'
    elseif event.element.style.name == 'tree-item-folder_gvv-mod' then
      event.element.style = 'tracked-tree-item-folder_gvv-mod'
      if Tree.ignore_in_help_page(player_data, event.element) then return end
      local full_path = Tree.track_full_path(player_data, event.element)
      GvvGuiTracking(event):add(full_path)
    elseif event.element.style.name == 'tracked-tree-item-folder_gvv-mod' then
      event.element.style = 'tree-item-folder_gvv-mod'
    end

  --트리 항목 값을 우클릭으로 등록할 때
  elseif event.element.name == '_gvv-mod_key_value' and event.button == defines.mouse_button_type.right then
    if event.element.style.name == 'tree-item-luaobj_gvv-mod' then
      local btn
      event.element.style = 'tracked-tree-item-luaobj_gvv-mod'
      if Tree.ignore_in_help_page(player_data, event.element) then return end
      btn = Tree.register_object(player_data, event.element.parent['_gvv-mod_key_label'])
      GvvGuiSearch(event):refresh('prop')
      player_data.tabs.last_sub_obj = btn.caption
    elseif event.element.style.name == 'tracked-tree-item-luaobj_gvv-mod' then
      event.element.style = 'tree-item-luaobj_gvv-mod'
    end

  --sub_objlist 의 좌측 항목을 클릭할 때
  elseif event.element.name:match('^_gvv[-]mod_c_sub_obj_%d+$') and event.element.parent and event.element.parent.name == '_gvv-mod_sub_objlist_' then
    local index = event.element.name:match('^_gvv[-]mod_c_sub_obj_(%d+)$') + 0
    if event.button == defines.mouse_button_type.left then
      Tree.draw_proptree(player_data, index)
      GvvGuiSearch(event):refresh('prop')
      player_data.tabs.last_sub_obj = event.element.caption
    elseif event.button == defines.mouse_button_type.right then
      Tree.remove_prop_tree(player_data, index)
      GvvGuiSearch(event):refresh('prop')
      if player_data.tabs.last_sub_obj == event.element then
        player_data.tabs.last_sub_obj = nil
      end
    end

  --sub_modlist 의 좌측 항목을 클릭할 때 : FR : géré par GvvGuiTree (storage) / EN : handled by GvvGuiTree (storage)

  --sub_gobjlist 의 좌측 항목을 클릭할 때
  elseif event.element.name:match('^_gvv[-]mod_c_sub_obj_%d+$') and event.element.parent and event.element.parent.name == '_gvv-mod_sub_gobjlist_' then
    local index = event.element.name:match('^_gvv[-]mod_c_sub_obj_(%d+)$') + 0
    Tree.draw_gobjtree(player_data, event.element.caption)
    GvvGuiSearch(event):refresh('gobj')
    player_data.tabs.last_sub_gobj = event.element.caption

  --sub_helplist 의 좌측 항목을 클릭할 때 : FR : géré par GvvGuiHelp / EN : handled by GvvGuiHelp

  -- _gvv-mod_anycode_frame_, _gvv-mod_copy_tracking_code_frame_, _gvv-mod_edit_tracking_code_frame_ :
  -- FR : boutons gérés par GvvGuiDialog / EN : buttons handled by GvvGuiDialog

  --tracking_panel 의 경로 / 결과값을 우클릭할 때 : FR : géré par GvvGuiTracking / EN : handled by GvvGuiTracking

  --트리 갱신 버튼
  elseif event.element == player_data.gui.tree_refresh_btn then
    local pane = player_data.gui.tabpane
    local tab = pane.selected_tab_index
    local subelem = nil
    if tab == 2 then
      -- FR : Arbre storage : redessiné par GvvGuiTree / EN : storage tree: drawn again by GvvGuiTree
      GvvGuiTree(event, 'storage'):refresh()
    elseif tab == 3 then
      if player_data.tabs.last_sub_obj then
        subelem = Util.get_guichild_by_caption(player_data.gui.sub_objlist, player_data.tabs.last_sub_obj)
      end
    elseif tab == 4 then
      if player_data.tabs.last_sub_gobj then
        subelem = Util.get_guichild_by_caption(player_data.gui.sub_gobjlist, player_data.tabs.last_sub_gobj)
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
  -- FR : Bouton loupe : géré par GvvGuiSearch / EN : Magnifier button: handled by GvvGuiSearch

  --tracking_panel 의 빈 공간을 우클릭 / 휠클릭할 때 : FR : géré par GvvGuiTracking / EN : handled by GvvGuiTracking

  --메인 프레임을 클릭할 때 (이 조건은 가장 마지막에)
  elseif Util.find_parent_gui(event.element, player_data.gui.frame) then
    -- FR : Ferme les petites fenêtres concernées (anycode seulement si vide) / EN : Closes the small windows concerned (anycode only if empty)
    GvvGuiDialog(event):closeOnMainFocus()

  end
end

Gui_Event.on_gui_closed = function(event)
  -- FR : Fermeture des petites fenêtres (Échap) : gérée par GvvGuiDialog / EN : Small windows closing (Escape): handled by GvvGuiDialog
  if event.element then
    if event.element.player_index ~= event.player_index then return end
  end

  if not storage.players then return end
  local player_data = storage.players[event.player_index]
  if not player_data or not player_data.gui.frame or not player_data.gui.frame.valid then return end
end

Gui_Event.on_gui_value_changed = function(event)
  if not event.element then return end
  if event.element.player_index ~= event.player_index then return end
  if not storage.players then return end
  local player_data = storage.players[event.player_index]
  if not player_data or not player_data.gui.frame or not player_data.gui.frame.valid then return end
  -- FR : Redimensionnement : géré par GvvGuiMain ; intervalle du suivi : géré par GvvGuiTracking
  -- EN : Resizing: handled by GvvGuiMain; tracking interval: handled by GvvGuiTracking
end

Gui_Event.on_gui_confirmed = function(event)
  if not event.element then return end
  if event.element.player_index ~= event.player_index then return end
  -- FR : Saisie de l'intervalle du suivi : gérée par GvvGuiTracking ; plus rien à traiter ici
  -- EN : Tracking interval input: handled by GvvGuiTracking; nothing left to handle here
end

Gui_Event.on_gui_selected_tab_changed = function(event)
  if not event.element then return end
  if event.element.player_index ~= event.player_index then return end
  if not storage.players then return end
  local player_data = storage.players[event.player_index]
  if not player_data or not player_data.gui.frame or not player_data.gui.frame.valid then return end

  -- FR : Changement d'onglet : géré par GvvGuiMain / EN : Tab change: handled by GvvGuiMain
end

Gui_Event.on_gui_checked_state_changed = function(event)
  if not event.element then return end
  if event.element.player_index ~= event.player_index then return end
  if not storage.players then return end
  local player_data = storage.players[event.player_index]
  if not player_data or not player_data.gui.frame or not player_data.gui.frame.valid then return end

  if event.element == player_data.gui.chk_show_na then
    player_data.show_na = event.element.state
    Tree.set_visible_item('na', player_data.gui.sub_proptree, player_data.show_na)
    Tree.set_visible_item('na', player_data.gui.sub_gobjtree, player_data.show_na)
    GvvGuiSearch(event):refresh('prop')
    GvvGuiSearch(event):refresh('gobj')
  elseif event.element == player_data.gui.chk_show_nil then
    player_data.show_nil = event.element.state
    Tree.set_visible_item('nil', player_data.gui.sub_proptree, player_data.show_nil)
    Tree.set_visible_item('nil', player_data.gui.sub_gobjtree, player_data.show_nil)
    GvvGuiSearch(event):refresh('prop')
    GvvGuiSearch(event):refresh('gobj')
  elseif event.element == player_data.gui.chk_show_func then
    player_data.show_func = event.element.state
    Tree.set_visible_item('func', player_data.gui.sub_proptree, player_data.show_func)
    Tree.set_visible_item('func', player_data.gui.sub_gobjtree, player_data.show_func)
    GvvGuiSearch(event):refresh('prop')
    GvvGuiSearch(event):refresh('gobj')
  -- FR : Filtres de recherche : gérés par GvvGuiSearch / EN : Search filters: handled by GvvGuiSearch
  end
end

Gui_Event.on_gui_text_changed = function(event)
  if not event.element then return end
  if event.element.player_index ~= event.player_index then return end

  -- FR : Textes à copier en lecture seule : gérés par GvvGuiDialog et GvvGuiHelp (tags)
  -- EN : Read-only texts to copy: handled by GvvGuiDialog and GvvGuiHelp (tags)
  
  if not storage.players then return end
  local player_data = storage.players[event.player_index]
  if not player_data or not player_data.gui.frame or not player_data.gui.frame.valid then return end

  -- FR : Code de la fenêtre anycode : géré par GvvGuiDialog / EN : anycode window code: handled by GvvGuiDialog
  -- FR : Texte cherché : géré par GvvGuiSearch / EN : Searched text: handled by GvvGuiSearch
end

Gui_Event.on_gui_selection_state_changed = function(event)
  if not event.element then return end
  if event.element.player_index ~= event.player_index then return end

  -- FR : Menus et listes de l'onglet aide : gérés par GvvGuiHelp / EN : Help tab menus and lists: handled by GvvGuiHelp

  if not storage.players then return end
  local player_data = storage.players[event.player_index]
  if not player_data or not player_data.gui.frame or not player_data.gui.frame.valid then return end

  -- FR : Résultats de recherche : gérés par GvvGuiSearch / EN : Search results: handled by GvvGuiSearch
end

-- FR : Raccourci Ctrl+Shift+V : géré par modules/gui.lua (GvvGuiMain:toggle)
-- EN : Ctrl+Shift+V shortcut: handled by modules/gui.lua (GvvGuiMain:toggle)

Gui_Event['refresh_gvv-mod'] = function(event)
  local player = game.get_player(event.player_index)
  if not player.admin and game.is_multiplayer() then return end
  if not storage.players then return end
  local player_data = storage.players[event.player_index]
  if player_data and player_data.gui and player_data.gui.tabpane and player_data.gui.tabpane.valid then
    local pane = player_data.gui.tabpane
    local tab = pane.selected_tab_index
    if tab == 1 then
      -- FR : Onglet suivi : rafraîchissement par GvvGuiTracking / EN : Tracking tab: refresh through GvvGuiTracking
      GvvGuiTracking(event):refreshValues()
    elseif tab > 1 and tab < 5 then
      Gui_Event.on_gui_click{
        element = player_data.gui.tree_refresh_btn,
        player_index = event.player_index,
        button = defines.mouse_button_type.left,
        alt = false,
        control = false,
        shift = false
      }
    end
  end
end

-- FR : Handlers bruts, appelés par l'aiguillage modules/gui.lua quand aucune fenêtre migrée ne traite l'évènement
-- EN : Raw handlers, called by the modules/gui.lua dispatcher when no migrated window handles the event
return Gui_Event
