-- 그래픽 유저 인터페이스

local Util = require('core.utils.util')
local Tree = require('modules.tree')
local Table_to_str = require('core.utils.table_to_str')
local Tracking = require('core.utils.tracking')
local Help_Menu = require('modules.help_menu')

local Gui = {}

local gobjlist = {'game', 'script', 'remote', 'commands', 'settings', 'prototypes', 'rcon', 'rendering', 'helpers', 'defines'}
local other_frames_to_close_when_closing_main = {
  ['_gvv-mod_anycode_frame_'] = true,
  ['_gvv-mod_copy_tracking_code_frame_'] = true,
  ['_gvv-mod_edit_tracking_code_frame_'] = true,
  ['_gvv-mod_export_tracking_code_frame_'] = true,
  ['_gvv-mod_import_tracking_code_frame_'] = true,
}

-- 메인 윈도우
Gui.open_main = function(player_index)
  local player = game.players[player_index]
  local first_time = false
  if not storage.players then storage.players = {} end
  if not storage.players[player_index] then
    storage.players[player_index] = {}
    first_time = true
  end

  local g = storage.players[player_index]
  g.index = player_index

  local frame = player.gui.screen['_gvv-mod_frame_']

  --토글
  if frame and frame.valid then
    Gui.close_main(g)
    return
  end

  frame = player.gui.screen.add{type = 'frame', name = '_gvv-mod_frame_', direction = 'vertical', style = 'frame_gvv-mod'}
  if g.gui then
    for k in pairs(g.gui) do g.gui[k] = nil end
  end
  g.gui = {frame = frame}

  if not g.track_interval_tick then g.track_interval_tick = 60 end
  if not g.last_width then g.last_width = 900 end
  if not g.last_height then g.last_height = 600 end
  if g.show_na == nil then g.show_na = true end
  if g.show_nil == nil then g.show_nil = true end
  if g.show_func == nil then g.show_func = false end
  if not g.search_settings then g.search_settings = {} end
  if not g.search_settings.glob then g.search_settings.glob = {} end
  if not g.search_settings.prop then g.search_settings.prop = {} end
  if not g.search_settings.gobj then g.search_settings.gobj = {} end
  for k, v in pairs(g.search_settings) do
    if not v.text then v.text = '' end
    if v.key == nil then v.key = true end
    if v.value == nil then v.value = false end
    if v.regexp == nil then v.regexp = false end
    if v.case == nil then v.case = false end
  end
  if g.show_search == nil then g.show_search = false end

  if not g.data then g.data = {} end
  if not g.data.docked_luaobj then g.data.docked_luaobj = {} end
  if not g.data.tracking_list then g.data.tracking_list = {} end
  if not g.data.search then g.data.search = {} end
  if not g.data.search.glob then g.data.search.glob = {} end
  if not g.data.search.prop then g.data.search.prop = {} end
  if not g.data.search.gobj then g.data.search.gobj = {} end

  g.tabs = {} --탭에서 열었던 하위 guielement
  -- tab2:last_sub_mod, tab3:last_sub_obj, tab4:last_sub_gobj

  frame.location = {0,0}
  frame.style.width = g.last_width
  frame.style.height = g.last_height
  local top = frame.add{type = 'frame', style = 'frame-bg_gvv-mod'}
  top.style.top_padding = 4
  top.style.right_padding = 8
  top.style.left_padding = 8
  top.add{type = 'flow', name = 'header', direction = 'horizontal'}
  top.header.drag_target = frame
  top.header.style.vertically_stretchable = false
  top.header.add{type = 'label', name = 'title', caption = {"",{"gvv-mod.title"},' - gvv ',storage.meta_data.version}, style = 'frame_title'}
  top.header.title.drag_target = frame
  local drag = top.header.add{type = 'empty-widget', name = 'dragspace', style = 'draggable_space_header'}
  drag.drag_target = frame
  drag.style.right_margin = 8
  drag.style.height = 24
  drag.style.horizontally_stretchable = true
  drag.style.vertically_stretchable = true
  local closebtn = top.header.add{type = 'sprite-button', name = 'closebtn', sprite = 'utility/close', style = 'frame_action_button', mouse_button_filter = {'left'}, tooltip = {"gvv-mod.close-main-tooltip"}}
  g.gui.closebtn = closebtn -- 사용자 개체 등록

  local middle = frame.add{type = 'flow', direction = 'horizontal', style = 'hflow_gvv-mod'}
  middle.add{type = 'empty-widget', name = 'left', style = 'empty-frame-bg_gvv-mod'}
  middle.left.style.width = 5
  middle.left.style.vertically_stretchable = true
  middle.add{type = 'frame', name = 'w', style = 'inside-wrap_gvv-mod'}
  local innerframe = middle.w.add{type = 'frame', direction = 'vertical', style = 'inside_deep_frame_gvv-mod'}
  middle.add{type = 'empty-widget', name = 'right', style = 'empty-frame-bg_gvv-mod'}
  middle.right.style.width = 5
  middle.right.style.vertically_stretchable = true

  local bottom = frame.add{type = 'empty-widget', style = 'empty-frame-bg_gvv-mod'}
  bottom.style.height = 5
  bottom.style.horizontally_stretchable = true

  local topspace = innerframe.add{type = 'flow', name = 'topspace', direction = 'horizontal'}
  topspace.style.padding = 6
  topspace.style.horizontal_spacing = 6
  topspace.style.vertical_align = 'center'
  topspace.add{type = 'label', caption = 'W : ', tooltip = {"gvv-mod.xresize"}}
  topspace.add{type = 'slider', name = 'xresize', minimum_value = 550, maximum_value = 1750, value = g.last_width,
    value_step = 25, discrete_slider = false, discrete_values = true, tooltip = {"gvv-mod.xresize"},
  }
  topspace.xresize.style.width = 80
  topspace.add{type = 'label', caption = 'H : ', tooltip = {"gvv-mod.yresize"}}
  topspace.add{type = 'slider', name = 'yresize', minimum_value = 275, maximum_value = 1475, value = g.last_height,
    value_step = 25, discrete_slider = false, discrete_values = true, tooltip = {"gvv-mod.yresize"},
  }
  topspace.yresize.style.width = 80
  topspace.add{type = 'sprite-button', name = 'track_refresh_btn', sprite = 'utility/reset_white',
    style = 'frame_action_button', mouse_button_filter = {'left'}, tooltip = {"gvv-mod.track-refresh"},
  }
  topspace.track_refresh_btn.style.width = 20
  topspace.track_refresh_btn.style.height = 20
  topspace.add{type = 'slider', name = 'track_inter_slider', minimum_value = 1, maximum_value = 180, value = g.track_interval_tick,
    value_step = 1, discrete_slider = false, discrete_values = true, {"gvv-mod.track-interval-control"},
  }
  topspace.track_inter_slider.style.width = 70
  topspace.add{type = 'label', name = 'track_inter_show', caption = g.track_interval_tick, tooltip = {"gvv-mod.track-interval-control"}}
  if not script.get_event_handler(defines.events.on_tick) then
    topspace.track_inter_show.style.font_color = {1,0.25,0.25}
    topspace.track_inter_show.tooltip = {"gvv-mod.track-interval-control-off"}
  end
  topspace.add{type = 'textfield', name = 'track_inter_edit', text = g.track_interval_tick, tooltip = {"gvv-mod.track-interval-control"},
    numeric = true, allow_decimal = false, allow_negative = false, lose_focus_on_confirm = true, clear_and_focus_on_right_click = true,
  }
  topspace.track_inter_edit.visible = false
  topspace.track_inter_edit.style.width = 30
  topspace.track_inter_edit.style.height = 20
  topspace.track_inter_edit.style.right_margin = 5
  topspace.add{type = 'sprite-button', name = 'remove_checked_btn', sprite = 'utility/trash_white',
    style = 'frame_action_button', mouse_button_filter = {'left'}, tooltip = {"gvv-mod.remove-checked-button"},
  }
  topspace.remove_checked_btn.style.left_margin = 8
  topspace.remove_checked_btn.style.width = 20
  topspace.remove_checked_btn.style.height = 20
  local rcf = topspace.add{type = 'frame', name = 'remove_confirm_frame'}
  rcf.style.padding = 0
  rcf.style.width = 48
  rcf.style.left_margin = -50
  rcf.style.right_margin = -4
  rcf.style.top_margin = -1
  rcf.style.bottom_margin = -15
  rcf.add{type = 'sprite-button', name = 'remove_checked_confirm_btn', sprite = 'gvv-mod_red-check',
    style = 'frame_action_button', mouse_button_filter = {'left'}, tooltip = {"gvv-mod.remove-checked-button"},
  }
  rcf.remove_checked_confirm_btn.style.width = 18
  rcf.remove_checked_confirm_btn.style.height = 18
  rcf.add{type = 'sprite-button', name = 'remove_checked_cancel_btn', sprite = 'gvv-mod_green-close',
    style = 'frame_action_button', mouse_button_filter = {'left'},
  }
  rcf.remove_checked_cancel_btn.style.width = 18
  rcf.remove_checked_cancel_btn.style.height = 18
  rcf.visible = false
  topspace.add{type = 'sprite-button', name = 'move_up_checked_btn', sprite = 'gvv-mod_arrow-up',
    style = 'frame_action_button', mouse_button_filter = {'left', 'right'}, tooltip = {"gvv-mod.move-up-checked"},
  }
  topspace.move_up_checked_btn.style.left_margin = 8
  topspace.move_up_checked_btn.style.width = 20
  topspace.move_up_checked_btn.style.height = 20
  topspace.add{type = 'sprite-button', name = 'move_down_checked_btn', sprite = 'gvv-mod_arrow-down',
    style = 'frame_action_button', mouse_button_filter = {'left', 'right'}, tooltip = {"gvv-mod.move-down-checked"},
  }
  topspace.move_down_checked_btn.style.left_margin = -3
  topspace.move_down_checked_btn.style.width = 20
  topspace.move_down_checked_btn.style.height = 20
  topspace.add{type = 'sprite-button', name = 'check_process_btn', sprite = 'utility/check_mark_white',
    style = 'frame_action_button', mouse_button_filter = {'left', 'right'}, tooltip = {"gvv-mod.check-process-btn"},
  }
  topspace.check_process_btn.style.left_margin = 2
  topspace.check_process_btn.style.width = 20
  topspace.check_process_btn.style.height = 20
  topspace.add{type = 'sprite-button', name = 'export_import_btn', sprite = 'gvv-mod_export-import',
    style = 'frame_action_button', mouse_button_filter = {'left', 'right'}, tooltip = {"gvv-mod.export-import-btn"},
  }
  topspace.export_import_btn.style.left_margin = 2
  topspace.export_import_btn.style.width = 20
  topspace.export_import_btn.style.height = 20


  topspace.add{type = 'sprite-button', name = 'tree_refresh_btn', sprite = 'utility/reset_white',
    style = 'frame_action_button', mouse_button_filter = {'left'}, tooltip = {"gvv-mod.tree-refresh"},
  }
  topspace.tree_refresh_btn.style.width = 20
  topspace.tree_refresh_btn.style.height = 20
  topspace.tree_refresh_btn.visible = false
  topspace.add{type = 'sprite-button', name = 'search_btn', sprite = 'utility/search',
    style = 'frame_action_button', mouse_button_filter = {'left'}, tooltip = {"gvv-mod.search-btn"},
  }
  topspace.search_btn.style.right_margin = 8
  topspace.search_btn.style.width = 20
  topspace.search_btn.style.height = 20
  topspace.search_btn.visible = false
  topspace.add{type = 'checkbox', name = 'chk_show_na', state = g.show_na, caption = 'n/a', tooltip = {"gvv-mod.show_na"}}
  topspace.chk_show_na.visible = false
  topspace.add{type = 'checkbox', name = 'chk_show_nil', state = g.show_nil, caption = 'nil', tooltip = {"gvv-mod.show_nil"}}
  topspace.chk_show_nil.visible = false
  topspace.add{type = 'checkbox', name = 'chk_show_func', state = g.show_func, caption = 'method', tooltip = {"gvv-mod.show_func"}}
  topspace.chk_show_func.visible = false

  g.gui.xresize = topspace.xresize -- 사용자 개체 등록
  g.gui.yresize = topspace.yresize -- 사용자 개체 등록
  g.gui.track_refresh_btn = topspace.track_refresh_btn -- 사용자 개체 등록
  g.gui.track_inter_slider = topspace.track_inter_slider -- 사용자 개체 등록
  g.gui.track_inter_show = topspace.track_inter_show -- 사용자 개체 등록
  g.gui.track_inter_edit = topspace.track_inter_edit -- 사용자 개체 등록
  g.gui.remove_confirm_frame = rcf -- 사용자 개체 등록
  g.gui.remove_checked_confirm_btn = rcf.remove_checked_confirm_btn -- 사용자 개체 등록
  g.gui.remove_checked_cancel_btn = rcf.remove_checked_cancel_btn -- 사용자 개체 등록
  g.gui.remove_checked_btn = topspace.remove_checked_btn -- 사용자 개체 등록
  g.gui.move_up_checked_btn = topspace.move_up_checked_btn -- 사용자 개체 등록
  g.gui.move_down_checked_btn = topspace.move_down_checked_btn -- 사용자 개체 등록
  g.gui.check_process_btn = topspace.check_process_btn -- 사용자 개체 등록
  g.gui.export_import_btn = topspace.export_import_btn -- 사용자 개체 등록
  g.gui.tree_refresh_btn = topspace.tree_refresh_btn -- 사용자 개체 등록
  g.gui.search_btn = topspace.search_btn -- 사용자 개체 등록
  g.gui.chk_show_na = topspace.chk_show_na -- 사용자 개체 등록
  g.gui.chk_show_nil = topspace.chk_show_nil -- 사용자 개체 등록
  g.gui.chk_show_func = topspace.chk_show_func -- 사용자 개체 등록

  local vdiv, hdiv

  local tabpane = innerframe.add{type = 'tabbed-pane', style = 'tabbed_pane_gvv-mod'}
  tabpane.style.horizontally_stretchable = true

  local tab1 = tabpane.add{type = 'tab', name = 'tab1', caption = {"gvv-mod.tab-filtered-view"}}
  local cwrap1 = tabpane.add{type = 'flow', direction = 'vertical'}
  cwrap1.style.horizontally_stretchable = true
  cwrap1.style.vertically_stretchable = true
  tabpane.add_tab(tab1,cwrap1)
  cwrap1.add{type = 'flow', name = 'w', direction = 'vertical', style = 'vflow_gvv-mod'}
  cwrap1.w.add{type = 'empty-widget', name = 'fill', style = 'empty-tabbed_pane_frame-bg_gvv-mod'}
  cwrap1.w.fill.style.height = 8
  local panel1 = cwrap1.w.add{type = 'scroll-pane', direction = 'vertical', vertical_scroll_policy='auto',
    horizontal_scroll_policy = 'auto', style='scroll_pane_gvv-mod',
  }
  local tracking_panel = panel1.add{type = 'flow', name = '_gvv-mod_tracking_panel_', direction = 'vertical', style = 'vflow_gvv-mod'}
  tracking_panel.style.vertical_spacing = 0
  tracking_panel.style.horizontally_stretchable = true
  tracking_panel.style.vertically_stretchable = true

  tabpane.selected_tab_index = 1

  local tab2 = tabpane.add{type = 'tab', name = 'tab2', caption = 'storage'}
  local cwrap2 = tabpane.add{type = 'flow', direction = 'vertical'}
  cwrap2.style.horizontally_stretchable = true
  cwrap2.style.vertically_stretchable = true
  tabpane.add_tab(tab2,cwrap2)
  cwrap2.add{type = 'flow', name = 'w', direction = 'vertical', style = 'vflow_gvv-mod'}
  cwrap2.w.add{type = 'empty-widget', name = 'fill', style = 'empty-tabbed_pane_frame-bg_gvv-mod'}
  cwrap2.w.fill.style.height = 8
  local panel2 = cwrap2.w.add{type = 'flow', direction = 'horizontal', style = 'hflow_gvv-mod'}
  local sub_modlist = panel2.add{type = 'scroll-pane', name = '_gvv-mod_sub_modlist_', direction = 'vertical', vertical_scroll_policy='auto',
    horizontal_scroll_policy = 'auto', style='scroll_pane_gvv-mod',
  }
  sub_modlist.style.horizontally_stretchable = false
  sub_modlist.style.horizontally_squashable = true
  sub_modlist.style.maximal_width = 230
  vdiv = panel2.add{type = 'empty-widget', style = 'vertical-divider_gvv-mod'}
  vdiv.style.width = 6
  local sub_globtree = panel2.add{type = 'scroll-pane', name = '_gvv-mod_sub_globtree_', direction = 'vertical', vertical_scroll_policy='auto',
    horizontal_scroll_policy = 'auto', style='scroll_pane_gvv-mod',
  }

  local tab3 = tabpane.add{type = 'tab', name = 'tab3', caption = 'property'}
  local cwrap3 = tabpane.add{type = 'flow', direction = 'vertical'}
  cwrap3.style.horizontally_stretchable = true
  cwrap3.style.vertically_stretchable = true
  tabpane.add_tab(tab3,cwrap3)
  cwrap3.add{type = 'flow', name = 'w', direction = 'vertical', style = 'vflow_gvv-mod'}
  cwrap3.w.add{type = 'empty-widget', name = 'fill', style = 'empty-tabbed_pane_frame-bg_gvv-mod'}
  cwrap3.w.fill.style.height = 8
  local panel3 = cwrap3.w.add{type = 'flow', direction = 'horizontal', style = 'hflow_gvv-mod'}
  local sub_objlist = panel3.add{type = 'scroll-pane', name = '_gvv-mod_sub_objlist_', direction = 'vertical', vertical_scroll_policy='auto',
    horizontal_scroll_policy = 'auto', style='scroll_pane_gvv-mod',
  }
  sub_objlist.style.horizontally_stretchable = false
  sub_objlist.style.horizontally_squashable = true
  sub_objlist.style.maximal_width = 230
  vdiv = panel3.add{type = 'empty-widget', style = 'vertical-divider_gvv-mod'}
  vdiv.style.width = 6
  local sub_proptree = panel3.add{type = 'scroll-pane', name = '_gvv-mod_sub_proptree_', direction = 'vertical', vertical_scroll_policy='auto',
    horizontal_scroll_policy = 'auto', style='scroll_pane_gvv-mod',
  }

  g.gui.tabpane = tabpane -- 사용자 개체 등록
  g.gui.tracking_panel = tracking_panel -- 사용자 개체 등록
  g.gui.sub_modlist = sub_modlist -- 사용자 개체 등록
  g.gui.sub_globtree = sub_globtree -- 사용자 개체 등록
  g.gui.sub_objlist = sub_objlist -- 사용자 개체 등록
  g.gui.sub_proptree = sub_proptree -- 사용자 개체 등록

  local tab4 = tabpane.add{type = 'tab', name = 'tab4', caption = 'LuaObject'}
  local cwrap4 = tabpane.add{type = 'flow', direction = 'vertical'}
  cwrap4.style.horizontally_stretchable = true
  cwrap4.style.vertically_stretchable = true
  tabpane.add_tab(tab4,cwrap4)
  cwrap4.add{type = 'flow', name = 'w', direction = 'vertical', style = 'vflow_gvv-mod'}
  cwrap4.w.add{type = 'empty-widget', name = 'fill', style = 'empty-tabbed_pane_frame-bg_gvv-mod'}
  cwrap4.w.fill.style.height = 8
  local panel4 = cwrap4.w.add{type = 'flow', direction = 'horizontal', style = 'hflow_gvv-mod'}
  local sub_gobjlist = panel4.add{type = 'scroll-pane', name = '_gvv-mod_sub_gobjlist_', direction = 'vertical', vertical_scroll_policy='auto',
    horizontal_scroll_policy = 'auto', style='scroll_pane_gvv-mod',
  }
  sub_gobjlist.style.horizontally_stretchable = false
  sub_gobjlist.style.horizontally_squashable = true
  sub_gobjlist.style.maximal_width = 230
  vdiv = panel4.add{type = 'empty-widget', style = 'vertical-divider_gvv-mod'}
  vdiv.style.width = 6
  local sub_gobjtree = panel4.add{type = 'scroll-pane', name = '_gvv-mod_sub_gobjtree_', direction = 'vertical', vertical_scroll_policy='auto',
    horizontal_scroll_policy = 'auto', style='scroll_pane_gvv-mod',
  }

  g.gui.sub_gobjlist = sub_gobjlist -- 사용자 개체 등록
  g.gui.sub_gobjtree = sub_gobjtree -- 사용자 개체 등록

  local search_panels = {}
  search_panels[1] = panel2.add{type = 'flow', name = 'search_glob_wrap', direction = 'horizontal', style = 'hflow_gvv-mod'}
  search_panels[2] = panel3.add{type = 'flow', name = 'search_prop_wrap', direction = 'horizontal', style = 'hflow_gvv-mod'}
  search_panels[3] = panel4.add{type = 'flow', name = 'search_gobj_wrap', direction = 'horizontal', style = 'hflow_gvv-mod'}
  local searchinput = {}
  local searchfilter_key = {}
  local searchfilter_value = {}
  local searchfilter_regexp = {}
  local searchfilter_case= {}
  local searchresult = {}
  local tree_names = {'glob', 'prop', 'gobj'}
  for i = 1, 3 do
    local spanel = search_panels[i]
    spanel.style.width = 180
    spanel.style.horizontally_stretchable = false
    if not g.show_search then
      spanel.visible = false
    end
    vdiv = spanel.add{type = 'empty-widget', style = 'vertical-divider_gvv-mod'}
    vdiv.style.width = 6
    local vwrap = spanel.add{type = 'flow', name = 'vwrap', direction = 'vertical', style = 'vflow_gvv-mod'}
    local swrap = vwrap.add{type = 'flow', name = 'swrap', direction = 'horizontal', style = 'hflow_gvv-mod'}
    searchinput[i] = swrap.add{type = 'textfield',
      text = g.search_settings[tree_names[i] ].text, name = 'searchinput',
    }
    searchinput[i].style.minimal_width = 50
    searchinput[i].style.maximal_width = 9999
    searchinput[i].style.horizontally_stretchable = true
    local filter_wrap = swrap.add{type = 'table', column_count = 2}
    filter_wrap.style.horizontal_spacing = 0
    filter_wrap.style.vertical_spacing = 0
    searchfilter_key[i] = filter_wrap.add{type = 'checkbox', tooltip = {"gvv-mod.search-key"},
      state = g.search_settings[tree_names[i] ].key, name = 'searchfilter_key',
    }
    searchfilter_value[i] = filter_wrap.add{type = 'checkbox', tooltip = {"gvv-mod.search-value"},
      state = g.search_settings[tree_names[i] ].value, name = 'searchfilter_value',
    }
    searchfilter_regexp[i] = filter_wrap.add{type = 'checkbox', tooltip = {"gvv-mod.search-regexp"},
      state = g.search_settings[tree_names[i] ].regexp, name = 'searchfilter_regexp',
    }
    searchfilter_case[i] = filter_wrap.add{type = 'checkbox', tooltip = {"gvv-mod.search-case"},
      state = g.search_settings[tree_names[i] ].case, name = 'searchfilter_case',
    }
    searchresult[i] = vwrap.add{type = 'list-box', name = 'sresult', style = 'list_box-transparent_gvv-mod'}
    searchresult[i].style.horizontally_stretchable = true
    g.gui['search_'..tree_names[i]..'_wrap'] = search_panels[i] -- 사용자 개체 등록
    g.gui['search_'..tree_names[i]..'_input'] = searchinput[i] -- 사용자 개체 등록
    g.gui['search_'..tree_names[i]..'_fkey'] = searchfilter_key[i] -- 사용자 개체 등록
    g.gui['search_'..tree_names[i]..'_fvalue'] = searchfilter_value[i] -- 사용자 개체 등록
    g.gui['search_'..tree_names[i]..'_fregexp'] = searchfilter_regexp[i] -- 사용자 개체 등록
    g.gui['search_'..tree_names[i]..'_fcase'] = searchfilter_case[i] -- 사용자 개체 등록
    g.gui['search_'..tree_names[i]..'_result'] = searchresult[i] -- 사용자 개체 등록
  end

  local tab5 = tabpane.add{type = 'tab', name = 'tab5', caption = {"gvv-mod.help-tab"}}
  local cwrap5 = tabpane.add{type = 'flow', direction = 'vertical'}
  cwrap5.style.horizontally_stretchable = true
  cwrap5.style.vertically_stretchable = true
  tabpane.add_tab(tab5,cwrap5)
  cwrap5.add{type = 'flow', name = 'w', direction = 'vertical', style = 'vflow_gvv-mod'}
  cwrap5.w.add{type = 'empty-widget', name = 'fill', style = 'empty-tabbed_pane_frame-bg_gvv-mod'}
  cwrap5.w.fill.style.height = 8
  local panel5 = cwrap5.w.add{type = 'flow', direction = 'horizontal', style = 'hflow_gvv-mod'}
  local sub_helplist = panel5.add{type = 'scroll-pane', name = '_gvv-mod_sub_helplist_', direction = 'vertical', vertical_scroll_policy='auto',
    horizontal_scroll_policy = 'auto', style='scroll_pane_gvv-mod',
  }
  sub_helplist.style.horizontally_stretchable = false
  sub_helplist.style.horizontally_squashable = true
  sub_helplist.style.maximal_width = 230
  vdiv = panel5.add{type = 'empty-widget', style = 'vertical-divider_gvv-mod'}
  vdiv.style.width = 6
  local sub_helppanel = panel5.add{type = 'scroll-pane', name = '_gvv-mod_sub_helppanel_', direction = 'vertical', vertical_scroll_policy='auto',
    horizontal_scroll_policy = 'auto', style='scroll_pane_gvv-mod',
  }

  g.gui.sub_helplist = sub_helplist -- 사용자 개체 등록
  g.gui.sub_helppanel = sub_helppanel -- 사용자 개체 등록

  for i, v in ipairs(Help_Menu.page_list) do
    local btn = sub_helplist.add{type = 'button', caption = v.caption, name = '_gvv-mod_c_sub_help_/'..v.name, mouse_button_filter = {'left'}, style = 'c_sub_mod_gvv-mod'}
  end

  local mod_list = Util.get_accessible_mod_list()
  for i, v in ipairs(mod_list) do
    local btn = sub_modlist.add{type = 'button', caption = v, name = '_gvv-mod_c_sub_mod_'..string.format('%d',i), mouse_button_filter = {'left'}, style = 'c_sub_mod_gvv-mod'}
  end

  for k, v in pairs(g.data.docked_luaobj) do
    local caption = '('..tostring(v.index)..') '..Table_to_str.to_luaon(v.key, true)
    local btn = sub_objlist.add{type = 'button', caption = caption, name = '_gvv-mod_c_sub_obj_'..tostring(v.index), mouse_button_filter = {'left', 'right'}, style = 'c_sub_mod_gvv-mod', tooltip = {"",{"gvv-mod.obj-list-tooltip"},'\n',Table_to_str.path_to_lua_prop_path(v.tree_path)}}
  end

  for i, v in ipairs(gobjlist) do
    local btn = sub_gobjlist.add{type = 'button', caption = v, name = '_gvv-mod_c_sub_obj_'..string.format('%d',i), mouse_button_filter = {'left'}, style = 'c_sub_mod_gvv-mod'}
  end

  if first_time then
    if storage.meta_data.default_tracking_list then
      local pc, ret
      local panel = g.gui.tracking_panel
      g.data.tracking_list = Util.deepcopytbl(storage.meta_data.default_tracking_list)
      for k, v in pairs(g.data.tracking_list) do
        pc, ret = pcall(function() Tracking.draw(panel, k, v) end)
        if not pc then
          player.print('[font=var-outline-gvv-mod]error caused when adding codes first time : '..k..'\n'..ret..'[/font]',{1,0.85,0.7,1})
        end
      end
    else -- Example
      pcall(function()
      Tracking.add(g, '-- evolution factor --\nassert(function()\n  return game.forces.enemy.get_evolution_factor()\nend)()')
      Tracking.add(g, '1+1 .. "   " .. tostring(game.tick) .. "   " .. util.formattime(game.ticks_played) --see __core__/lualib/util.lua for informations')
      Tracking.add(g, '-- arithmetic sequence --\nassert(function()\n  local a = 0\n  for i = 0, 10 do\n    a = a + i\n  end\n  return a\nend)()')
      end)
    end
  else
    local panel = g.gui.tracking_panel
    for k, v in pairs(g.data.tracking_list) do
      Tracking.draw(panel, k, v)
    end
  end
end

-- 메인 윈도우 닫기
Gui.close_main = function(g, ignore_save)
  local player = game.players[g.index]
  local pc, ret
  if not ignore_save then
    pc, ret = pcall(function(g) Tree.save_on_quit(g) end, g)
  end
  g.gui.frame.destroy()
  local frame
  for frame_name in pairs(other_frames_to_close_when_closing_main) do
    frame = player.gui.screen[frame_name]
    if frame and frame.valid then
      frame.destroy()
    end
  end
  if not ignore_save and not pc then error(ret) end
end

-- 내용을 복사할 수 있는 미니 윈도우1
Gui.copyable_dump = function(player_index, str, title)
  local player = game.players[player_index]
  local frame = player.gui.screen['_gvv-mod_dump_frame_']
  local closebtn, innerframe

  if frame and frame.valid then
    frame.destroy()
  end

  frame, closebtn, innerframe = Util.create_frame_w_closebtn(player, '_gvv-mod_dump_frame_', title)
  innerframe.add{type = 'textfield', name = '_gvv-mod_uneditable_text_',
    text = str, clear_and_focus_on_right_click = true, tooltip = {"gvv-mod.right-to-select-all"},
  }
  innerframe['_gvv-mod_uneditable_text_'].focus()
  innerframe['_gvv-mod_uneditable_text_'].select_all()
  innerframe['_gvv-mod_uneditable_text_'].style.width = 400
  innerframe.add{type = 'label', name = '_gvv-mod_uneditable_text_buffer_', caption = str}
  innerframe['_gvv-mod_uneditable_text_buffer_'].visible = false

  player.opened = frame
end

-- 코드를 입력하는 미니 윈도우
Gui.put_anycode_in_tracking = function(g)
  local player = game.players[g.index]
  local frame = player.gui.screen['_gvv-mod_anycode_frame_']
  local closebtn, innerframe

  if frame and frame.valid then
    frame.focus()
    --frame.innerframe['_gvv-mod_anycode_code_'].focus()
    frame.force_auto_center()
    error('Already an input window is opened.')
    return
  end

  frame, closebtn, innerframe = Util.create_frame_w_closebtn(player, '_gvv-mod_anycode_frame_', {"gvv-mod.input-code"})
  innerframe.add{type = 'text-box', name = '_gvv-mod_anycode_code_', text = '', clear_and_focus_on_right_click = false}
  innerframe['_gvv-mod_anycode_code_'].focus()
  innerframe['_gvv-mod_anycode_code_'].style.width = 600
  innerframe['_gvv-mod_anycode_code_'].style.height = 200
  innerframe['_gvv-mod_anycode_code_'].style.font = 'default-semibold'

  local right = innerframe.add{type = 'flow', direction = 'horizontal'}
  right.style.horizontal_align = 'right'
  right.style.horizontally_stretchable = true
  right.style.left_padding = 0
  right.style.top_padding = 6
  local drag = right.add{type = 'empty-widget', name = 'dragspace', style = 'draggable_space_header'}
  drag.drag_target = frame
  drag.style.left_margin = 0
  drag.style.right_margin = 8
  drag.style.height = 32
  drag.style.horizontally_stretchable = true
  g.gui.icconf = right.add{type = 'button', caption = {"gvv-mod.confirm-input-code"}, style = 'confirm_button', mouse_button_filter = {'left'}}

  player.opened = frame
  return true
end

-- 탭 변경
Gui.change_tab = function(g, index)
  local pane = g.gui.tabpane
  local tab = pane.selected_tab_index
  if pane.selected_tab_index ~= index then
    tab = index
    pane.selected_tab_index = index
  end
  if tab == 1 then
    g.gui.track_refresh_btn.visible = true
    g.gui.track_inter_slider.visible = true
    g.gui.track_inter_edit.visible = false
    g.gui.track_inter_show.visible = true
    g.gui.remove_checked_btn.visible = true
    g.gui.move_up_checked_btn.visible = true
    g.gui.move_down_checked_btn.visible = true
    g.gui.check_process_btn.visible = true
    g.gui.export_import_btn.visible = true

    g.gui.remove_confirm_frame.visible = false
  else
    g.gui.track_refresh_btn.visible = false
    g.gui.track_inter_slider.visible = false
    g.gui.track_inter_edit.visible = false
    g.gui.track_inter_show.visible = false
    g.gui.remove_checked_btn.visible = false
    g.gui.move_up_checked_btn.visible = false
    g.gui.move_down_checked_btn.visible = false
    g.gui.check_process_btn.visible = false
    g.gui.export_import_btn.visible = false

    g.gui.remove_confirm_frame.visible = false
  end
  if tab == 2 then
    local mod_list = Util.get_accessible_mod_list()
    g.gui.sub_modlist.clear()
    for i, v in ipairs(mod_list) do
      local btn = g.gui.sub_modlist.add{type = 'button', caption = v, name = '_gvv-mod_c_sub_mod_'..string.format('%d',i), mouse_button_filter = {'left'}, style = 'c_sub_mod_gvv-mod'}
    end
  end
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
    g.gui.search_btn.visible = true
  else
    g.gui.tree_refresh_btn.visible = false
    g.gui.search_btn.visible = false
  end
end

-- 내용을 복사할 수 있는 미니 윈도우2
Gui.copyable_tracking_code = function(g, str, entry_name)
  local player = game.players[g.index]
  local frame = player.gui.screen['_gvv-mod_copy_tracking_code_frame_']
  local closebtn, innerframe

  if frame and frame.valid then
    frame.destroy()
  end

  str = str:gsub('^“',''):gsub('”$','')
  local newline_count = select(2, str:gsub('\n',''))

  frame, closebtn, innerframe = Util.create_frame_w_closebtn(player, '_gvv-mod_copy_tracking_code_frame_', {"gvv-mod.copy-code"})

  if newline_count > 0 then
    local height = 23 + 23 * newline_count
    if height > 400 then height = 400 end
    innerframe.add{type = 'text-box', name = '_gvv-mod_uneditable_text_',
      text = str, clear_and_focus_on_right_click = true, tooltip = {"gvv-mod.right-to-select-all"},
    }
    innerframe['_gvv-mod_uneditable_text_'].style.height = height
  else
    innerframe.add{type = 'textfield', name = '_gvv-mod_uneditable_text_',
      text = str, clear_and_focus_on_right_click = true, tooltip = {"gvv-mod.right-to-select-all"},
    }
  end
  innerframe['_gvv-mod_uneditable_text_'].focus()
  innerframe['_gvv-mod_uneditable_text_'].select_all()
  innerframe['_gvv-mod_uneditable_text_'].style.width = 400
  innerframe.add{type = 'label', name = '_gvv-mod_uneditable_text_buffer_', caption = str}
  innerframe['_gvv-mod_uneditable_text_buffer_'].visible = false

  if entry_name then
    local entry_name_buffer = innerframe.add{type = 'label', name = 'entry_name_buffer', caption = entry_name}
    entry_name_buffer.visible = false
    local center = innerframe.add{type = 'flow', direction = 'horizontal'}
    center.style.horizontal_align = 'center'
    center.style.horizontally_stretchable = true
    center.style.left_padding = 0
    center.style.right_padding = 0
    center.style.top_padding = 6
    local drag1 = center.add{type = 'empty-widget', name = 'dragspace1', style = 'draggable_space_header'}
    drag1.drag_target = frame
    drag1.style.left_margin = 0
    drag1.style.right_margin = 8
    drag1.style.height = 32
    drag1.style.horizontally_stretchable = true
    g.gui.ecedit = center.add{type = 'button', caption = {"gvv-mod.edit-code-btn"}, mouse_button_filter = {'left'}, style = 'dialog_button'}
    local drag2 = center.add{type = 'empty-widget', name = 'dragspace2', style = 'draggable_space_header'}
    drag2.drag_target = frame
    drag2.style.left_margin = 8
    drag2.style.right_margin = 0
    drag2.style.height = 32
    drag2.style.horizontally_stretchable = true
  end

  player.opened = frame
end

-- 코드를 편집하는 미니 윈도우
Gui.edit_code_in_tracking = function(g, str, entry_name)
  local player = game.players[g.index]
  local frame = player.gui.screen['_gvv-mod_edit_tracking_code_frame_']
  local closebtn, innerframe

  if frame and frame.valid then
    frame.focus()
    --frame.innerframe['_gvv-mod_edit_tracking_code_code_'].focus()
    frame.force_auto_center()
    error('Already an edit window is opened.')
    return
  end

  frame, closebtn, innerframe = Util.create_frame_w_closebtn(player, '_gvv-mod_edit_tracking_code_frame_', {"gvv-mod.edit-code-title"})
  innerframe.add{type = 'scroll-pane', name = 'sc', vertical_scroll_policy = 'never', horizontal_scroll_policy = 'auto'}
  innerframe.sc.style.width = 600
  innerframe.sc.style.height = 39
  innerframe.sc.add{type = 'label', name = 'entry_name_buffer', caption = entry_name}

  innerframe.add{type = 'text-box', name = '_gvv-mod_edit_tracking_code_code_', text = '', clear_and_focus_on_right_click = false}
  innerframe['_gvv-mod_edit_tracking_code_code_'].focus()
  innerframe['_gvv-mod_edit_tracking_code_code_'].style.width = 600
  innerframe['_gvv-mod_edit_tracking_code_code_'].style.height = 400
  innerframe['_gvv-mod_edit_tracking_code_code_'].style.font = 'default-semibold'
  innerframe['_gvv-mod_edit_tracking_code_code_'].text = str

  local right = innerframe.add{type = 'flow', direction = 'horizontal'}
  right.style.horizontal_align = 'right'
  right.style.horizontally_stretchable = true
  right.style.left_padding = 0
  right.style.top_padding = 6
  local drag = right.add{type = 'empty-widget', name = 'dragspace', style = 'draggable_space_header'}
  drag.drag_target = frame
  drag.style.left_margin = 0
  drag.style.right_margin = 8
  drag.style.height = 32
  drag.style.horizontally_stretchable = true
  g.gui.ecconf = right.add{type = 'button', caption = {"gvv-mod.confirm-edit-code"}, style = 'confirm_button', mouse_button_filter = {'left'}}

  --player.opened = frame
  return true
end

--내보내기 윈도우
Gui.export_window = function(g)
  local player = game.players[g.index]
  local frame = player.gui.screen['_gvv-mod_export_tracking_code_frame_']
  local closebtn, innerframe

  if frame and frame.valid then
    frame.destroy()
  end

  local panel = g.gui.tracking_panel
  local str = ''
  for i, v in ipairs(panel.children) do
    str = str .. v.name .. '\n--[[]]--\n'
  end

  frame, closebtn, innerframe = Util.create_frame_w_closebtn(player, '_gvv-mod_export_tracking_code_frame_', {"gvv-mod.export-code-title"})
  innerframe.add{type = 'text-box', name = '_gvv-mod_uneditable_text_', text = str, clear_and_focus_on_right_click = true, tooltip = {"gvv-mod.right-to-select-all"}}
  innerframe['_gvv-mod_uneditable_text_'].focus()
  innerframe['_gvv-mod_uneditable_text_'].select_all()
  innerframe['_gvv-mod_uneditable_text_'].style.width = 400
  innerframe['_gvv-mod_uneditable_text_'].style.height = 300
  innerframe.add{type = 'label', name = '_gvv-mod_uneditable_text_buffer_', caption = str}
  innerframe['_gvv-mod_uneditable_text_buffer_'].visible = false

  player.opened = frame
end

--가져오기 윈도우
Gui.import_window = function(g)
  local player = game.players[g.index]
  local frame = player.gui.screen['_gvv-mod_import_tracking_code_frame_']
  local closebtn, innerframe

  if frame and frame.valid then
    frame.destroy()
  end

  local panel = g.gui.tracking_panel
  local str = ''
  for i, v in ipairs(panel.children) do
    str = str .. v.name .. '\n--[[]]--\n'
  end

  frame, closebtn, innerframe = Util.create_frame_w_closebtn(player, '_gvv-mod_import_tracking_code_frame_', {"gvv-mod.import-code-title"})
  innerframe.add{type = 'label', name = 'comment', caption = {"gvv-mod.import-code-comment"}}
  innerframe.comment.style.single_line = false
  innerframe.comment.style.width = 400
  innerframe.add{type = 'text-box', name = '_gvv-mod_import_tracking_code_code_', text = '', clear_and_focus_on_right_click = false}
  innerframe['_gvv-mod_import_tracking_code_code_'].focus()
  innerframe['_gvv-mod_import_tracking_code_code_'].style.width = 400
  innerframe['_gvv-mod_import_tracking_code_code_'].style.height = 300

  local right = innerframe.add{type = 'flow', direction = 'horizontal'}
  right.style.horizontal_align = 'right'
  right.style.horizontally_stretchable = true
  right.style.left_padding = 0
  right.style.top_padding = 6
  local drag = right.add{type = 'empty-widget', name = 'dragspace', style = 'draggable_space_header'}
  drag.drag_target = frame
  drag.style.left_margin = 0
  drag.style.right_margin = 8
  drag.style.height = 32
  drag.style.horizontally_stretchable = true
  g.gui.imconf = right.add{type = 'button', caption = {"gvv-mod.import-code-btn"}, style = 'confirm_button', mouse_button_filter = {'left'}}

  player.opened = frame
end

return Gui
