-- 그래픽 유저 인터페이스

local Util = require(gvv.defines.lualib.common.util)
local Tree = require(gvv.defines.legacy.tree)
local Table_to_str = require(gvv.defines.lualib.common.table_to_str)

local Gui = {}

local gobjlist = {'game', 'script', 'remote', 'commands', 'settings', 'prototypes', 'rcon', 'rendering', 'helpers', 'defines'}

-- 메인 윈도우
-- FR : Fenêtre principale : maintenant construite par classes/GvvGuiMain.lua (étape 3.1).
--      Gui.open_main et Gui.close_main restent comme points d'entrée pour l'ancien code (/gvv, migrations).
-- EN : Main window: now built by classes/GvvGuiMain.lua (step 3.1).
--      Gui.open_main and Gui.close_main stay as entry points for the old code (/gvv, migrations).
Gui.open_main = function(player_index)
  GvvGuiMain({player_index = player_index}):toggle()
end

-- 메인 윈도우 닫기
Gui.close_main = function(g, ignore_save)
  GvvGuiMain({player_index = g.index}):close(ignore_save)
end

-- FR : Boutons propres aux onglets, dans flow-tools de la barre d'outils (repris de l'ancien open_main).
-- EN : Tab-specific buttons, inside the toolbar flow-tools (taken from the old open_main).
Gui.build_tools = function(g, topspace)
  -- FR : Outils du suivi : construits par GvvGuiTracking (étape 3.4) / EN : Tracking tools: built by GvvGuiTracking (step 3.4)
  topspace.add{type = 'sprite-button', name = 'tree_refresh_btn', sprite = 'utility/reset_white',
    style = 'frame_action_button', mouse_button_filter = {'left'}, tooltip = {"gvv-mod.tree-refresh"},
  }
  topspace.tree_refresh_btn.style.width = 20
  topspace.tree_refresh_btn.style.height = 20
  topspace.tree_refresh_btn.visible = false
  -- FR : Bouton loupe : construit par GvvGuiSearch:buildButton (étape 3.5) / EN : Magnifier button: built by GvvGuiSearch:buildButton (step 3.5)
  topspace.add{type = 'checkbox', name = 'chk_show_na', state = g.show_na, caption = 'n/a', tooltip = {"gvv-mod.show_na"}}
  topspace.chk_show_na.visible = false
  topspace.add{type = 'checkbox', name = 'chk_show_nil', state = g.show_nil, caption = 'nil', tooltip = {"gvv-mod.show_nil"}}
  topspace.chk_show_nil.visible = false
  topspace.add{type = 'checkbox', name = 'chk_show_func', state = g.show_func, caption = 'method', tooltip = {"gvv-mod.show_func"}}
  topspace.chk_show_func.visible = false

  g.gui.tree_refresh_btn = topspace.tree_refresh_btn -- 사용자 개체 등록
  g.gui.chk_show_na = topspace.chk_show_na -- 사용자 개체 등록
  g.gui.chk_show_nil = topspace.chk_show_nil -- 사용자 개체 등록
  g.gui.chk_show_func = topspace.chk_show_func -- 사용자 개체 등록
end

-- FR : Panneau de recherche d'un arbre : construit par GvvGuiSearch:buildPanel (étape 3.5)
-- EN : Search panel of a tree: built by GvvGuiSearch:buildPanel (step 3.5)

-- FR : Contenu commun aux onglets : bande de fond en haut (« w » > « fill »). Renvoie le conteneur « w ».
-- EN : Content shared by the tabs: background strip at the top ("w" > "fill"). Returns the "w" container.
local build_tab_wrap = function(cwrap)
  cwrap.add{type = 'flow', name = 'w', direction = 'vertical', style = 'vflow_gvv-mod'}
  cwrap.w.add{type = 'empty-widget', name = 'fill', style = 'empty-tabbed_pane_frame-bg_gvv-mod'}
  cwrap.w.fill.style.height = 8
  return cwrap.w
end

-- FR : Liste à gauche + séparateur + arbre à droite (onglets storage, property, LuaObject, aide). Renvoie le panneau, la liste et l'arbre.
-- EN : List on the left + divider + tree on the right (storage, property, LuaObject, help tabs). Returns the panel, the list and the tree.
local build_list_and_tree = function(cwrap, list_name, tree_name)
  local panel = build_tab_wrap(cwrap).add{type = 'flow', direction = 'horizontal', style = 'hflow_gvv-mod'}
  local sub_list = panel.add{type = 'scroll-pane', name = list_name, direction = 'vertical', vertical_scroll_policy='auto',
    horizontal_scroll_policy = 'auto', style='scroll_pane_gvv-mod',
  }
  sub_list.style.horizontally_stretchable = false
  sub_list.style.horizontally_squashable = true
  sub_list.style.maximal_width = 230
  local vdiv = panel.add{type = 'empty-widget', style = 'vertical-divider_gvv-mod'}
  vdiv.style.width = 6
  local sub_tree = panel.add{type = 'scroll-pane', name = tree_name, direction = 'vertical', vertical_scroll_policy='auto',
    horizontal_scroll_policy = 'auto', style='scroll_pane_gvv-mod',
  }
  return panel, sub_list, sub_tree
end

-- FR : Onglet 1, suivi de variables : construit par classes/GvvGuiTracking.lua (étape 3.4)
-- EN : Tab 1, variable tracking: built by classes/GvvGuiTracking.lua (step 3.4)

-- FR : Onglet 2, storage et _G des mods : construit par classes/GvvGuiTree.lua (étape 3.6a)
-- EN : Tab 2, mods storage and _G: built by classes/GvvGuiTree.lua (step 3.6a)

-- FR : Onglet 3, objets Lua ajoutés (repris de l'ancien open_main).
-- EN : Tab 3, added Lua objects (taken from the old open_main).
Gui.build_property = function(g, cwrap3)
  local panel3, sub_objlist, sub_proptree = build_list_and_tree(cwrap3, '_gvv-mod_sub_objlist_', '_gvv-mod_sub_proptree_')
  g.gui.sub_objlist = sub_objlist -- 사용자 개체 등록
  g.gui.sub_proptree = sub_proptree -- 사용자 개체 등록
  GvvGuiSearch({player_index = g.index}):buildPanel('prop', panel3)
end

-- FR : Onglet 4, objets globaux (repris de l'ancien open_main).
-- EN : Tab 4, global objects (taken from the old open_main).
Gui.build_luaobject = function(g, cwrap4)
  local panel4, sub_gobjlist, sub_gobjtree = build_list_and_tree(cwrap4, '_gvv-mod_sub_gobjlist_', '_gvv-mod_sub_gobjtree_')
  g.gui.sub_gobjlist = sub_gobjlist -- 사용자 개체 등록
  g.gui.sub_gobjtree = sub_gobjtree -- 사용자 개체 등록
  GvvGuiSearch({player_index = g.index}):buildPanel('gobj', panel4)
end

-- FR : Onglet 5, aide : construit par classes/GvvGuiHelp.lua (étape 3.3)
-- EN : Tab 5, help: built by classes/GvvGuiHelp.lua (step 3.3)

-- FR : Remplit les listes de gauche : objets ajoutés, objets globaux (repris de l'ancien open_main).
--      Les mods sont listés par GvvGuiTree, les pages d'aide par GvvGuiHelp.
-- EN : Fills the left lists: added objects, global objects (taken from the old open_main).
--      Mods are listed by GvvGuiTree, help pages by GvvGuiHelp.
Gui.fill_lists = function(g)
  for k, v in pairs(g.data.docked_luaobj) do
    local caption = '('..tostring(v.index)..') '..Table_to_str.to_luaon(v.key, true)
    local btn = g.gui.sub_objlist.add{type = 'button', caption = caption, name = '_gvv-mod_c_sub_obj_'..tostring(v.index), mouse_button_filter = {'left', 'right'}, style = 'c_sub_mod_gvv-mod', tooltip = {"",{"gvv-mod.obj-list-tooltip"},'\n',Table_to_str.path_to_lua_prop_path(v.tree_path)}}
  end

  for i, v in ipairs(gobjlist) do
    local btn = g.gui.sub_gobjlist.add{type = 'button', caption = v, name = '_gvv-mod_c_sub_obj_'..string.format('%d',i), mouse_button_filter = {'left'}, style = 'c_sub_mod_gvv-mod'}
  end
end

-- FR : Entrées du suivi : affichées par GvvGuiTracking:fillEntries (étape 3.4)
-- EN : Tracking entries: shown by GvvGuiTracking:fillEntries (step 3.4)

-- 내용을 복사할 수 있는 미니 윈도우1
-- FR : Petites fenêtres : maintenant construites par classes/GvvGuiDialog.lua (étape 3.2).
--      Ces fonctions restent comme points d'entrée pour l'ancien code (/gdump, onglet suivi).
-- EN : Small windows: now built by classes/GvvGuiDialog.lua (step 3.2).
--      These functions stay as entry points for the old code (/gdump, tracking tab).
Gui.copyable_dump = function(player_index, str, title)
  GvvGuiDialog({player_index = player_index}):openDump(str, title)
end

-- 코드를 입력하는 미니 윈도우
Gui.put_anycode_in_tracking = function(g)
  return GvvGuiDialog({player_index = g.index}):openAnycode()
end

-- 탭 변경
Gui.change_tab = function(g, index)
  -- FR : Onglet sélectionné et outils du suivi : gérés par GvvGuiMain:changeTab et GvvGuiTracking (étape 3.4)
  -- EN : Selected tab and tracking tools: handled by GvvGuiMain:changeTab and GvvGuiTracking (step 3.4)
  -- FR : Onglet 2 : liste des mods remplie à nouveau par GvvGuiTree:fillList (étape 3.6a)
  -- EN : Tab 2: mods list filled again by GvvGuiTree:fillList (step 3.6a)
  local tab = index
  if tab == 3 or tab == 4 then
    g.gui.chk_show_na.visible = true
    g.gui.chk_show_nil.visible = true
    g.gui.chk_show_func.visible = true
  else
    g.gui.chk_show_na.visible = false
    g.gui.chk_show_nil.visible = false
    g.gui.chk_show_func.visible = false
  end
  if tab > 1 and tab < 5 then
    g.gui.tree_refresh_btn.visible = true
  else
    g.gui.tree_refresh_btn.visible = false
  end
end

-- 내용을 복사할 수 있는 미니 윈도우2
Gui.copyable_tracking_code = function(g, str, entry_name)
  GvvGuiDialog({player_index = g.index}):openCopy(str, entry_name)
end

-- 코드를 편집하는 미니 윈도우
Gui.edit_code_in_tracking = function(g, str, entry_name)
  return GvvGuiDialog({player_index = g.index}):openEdit(str, entry_name)
end

--내보내기 윈도우
Gui.export_window = function(g)
  GvvGuiDialog({player_index = g.index}):openExport()
end

--가져오기 윈도우
Gui.import_window = function(g)
  GvvGuiDialog({player_index = g.index}):openImport()
end

return Gui
