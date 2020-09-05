--도움말

local Util = require('modules.util')
local Copy_Code = require('modules.copy_code')

local Help_Menu = {}

Help_Menu.page_list = {
  {
    name = 'control_lua',
    caption = {"gvv-mod-help.control_lua"},
  },
  {
    name = 'console1',
    caption = {"gvv-mod-help.console1"},
  },
  {
    name = 'console2',
    caption = {"gvv-mod-help.console2"},
  },
  {
    name = 'how_to_use_gui',
    caption = {"gvv-mod-help.how_to_use_gui"},
  },
  {
    name = 'troubleshoot',
    caption = {"gvv-mod-help.troubleshoot"},
  },
}

Help_Menu.get_page = function(name)
  for _, v in pairs(Help_Menu.page_list) do
    if v.name == name then return v end
  end
end

local x
local p = {}
local this
local content_writer = {}

Help_Menu.draw_page = function(g, name)
  local panel = g.gui.sub_helppanel
  panel.clear()

  p = {top = panel, pointer = panel}
  content_writer[name]()
end

local function text(locstr)
  local u = p.pointer.add{type = 'label', caption = locstr}
  u.style.horizontally_stretchable = true
  u.style.single_line = false
  this = u
  return u
end

local function head(locstr)
  local u = p.pointer.add{type = 'label', caption = locstr}
  u.style.horizontally_stretchable = true
  u.style.single_line = false
  u.style.font = 'heading-1'
  this = u
  return u
end

local function copyable(str, wrapper_name)
  local flow = p.pointer.add{type = 'flow', direction = 'vertical', name = wrapper_name, style = 'vflow_gvv-mod'}
  local u = flow.add{type = 'textfield', name = '_gvv-mod_uneditable_text_', text = str, clear_and_focus_on_right_click = true, tooltip = {"gvv-mod.right-to-select-all"}}
  flow.style.horizontally_stretchable = true
  flow['_gvv-mod_uneditable_text_'].style.horizontally_stretchable = true
  flow['_gvv-mod_uneditable_text_'].style.horizontally_squashable = true
  flow['_gvv-mod_uneditable_text_'].style.minimal_width = 10
  flow['_gvv-mod_uneditable_text_'].style.maximal_width = 9999
  flow.add{type = 'label', name = '_gvv-mod_uneditable_text_buffer_', caption = str}
  flow['_gvv-mod_uneditable_text_buffer_'].visible = false
  this = u
  return u
end

local function hpo()
  local u = p.pointer.add{type = 'flow', direction = 'horizontal', style = 'hflow_gvv-mod'}
  u.style.horizontally_stretchable = true
  this = u
  p.pointer = u
  return u
end

local function vpo()
  local u = p.pointer.add{type = 'flow', direction = 'vertical', style = 'vflow_gvv-mod'}
  u.style.horizontally_stretchable = true
  this = u
  p.pointer = u
  return u
end

local function px()
  if p.pointer == p.top then return end
  local u = p.pointer.parent
  this = u
  p.pointer = u
  return u
end

-------------------------------------
content_writer['control_lua'] = function()
  x = 'gvv-mod-help-control_lua.'
-------------------------------------
head{x..'1'}
text{x..'2'}
text{x..'3'}
copyable(Copy_Code.in_control_lua())
text{x..'4'}
text(' ')
text{x..'5', {"",'[font=default-bold]',Help_Menu.get_page('console1').caption,'[/font]'}}
text{x..'6'}
end ---------------------------------


-------------------------------------
content_writer['console1'] = function()
  x = 'gvv-mod-help-console1.'
-------------------------------------
head{x..'1'}
text{x..'2'}
text{x..'3', ' [font=default-bold]/gvv[/font]'}
text{x..'4', ' [font=default-bold]/gmods[/font]'}
text{x..'5', ' [font=default-bold]/gdump[/font]', '[font=default-bold]/gdump-luaon & /gdump-json[/font]', '[font=default-bold]/gdump-luaon[/font]'}
text(' ')
text{x..'6'}
copyable(Copy_Code.in_console_enable())
text{x..'7'}
text(' ')
text{x..'8'}
copyable(Copy_Code.in_console_disable())
text{x..'9'}
text{x..'10'}
end ---------------------------------


-------------------------------------
content_writer['console2'] = function()
  x = 'gvv-mod-help-console2.'
-------------------------------------
head{x..'1'}
text{x..'2'}
vpo() do
  local modlist = Util.get_accessible_mod_list()
  local copy = copyable('', '_gvv-mod_copyable_')
  local sel = p.pointer.add{type = 'list-box', name = '_gvv-mod_help_copy_mod_global_code_',
    items = modlist, selected_index = 1, style = 'list_box-transparent_gvv-mod',
  }
  sel.style.vertically_stretchable = true
  copy.parent['_gvv-mod_uneditable_text_buffer_'].caption = 'remote.call("__'..sel.items[sel.selected_index]..'__gvv","global")'
  copy.text = copy.parent['_gvv-mod_uneditable_text_buffer_'].caption
px() end
end ---------------------------------


-------------------------------------
content_writer['how_to_use_gui'] = function()
  x = 'gvv-mod-help-how_to_use_gui.'
-------------------------------------
head{x..'1'}
text{x..'2'}
text{x..'3', {"",' [font=default-bold]',{"gvv-mod.tab-filtered-view"},'[/font]'}}
text{x..'4', ' [font=default-bold]global[/font]'}
text{x..'5', ' [font=default-bold]property[/font]'}
text{x..'6', ' [font=default-bold]LuaObject[/font]'}
text{x..'7', {"",' [font=default-bold]',{"gvv-mod.help-tab"},'[/font]'}}
text(' ')
text{x..'8'}
hpo() do
  local sprite = p.pointer.add{type = 'sprite', name = 'folder_sprite', sprite = 'gvv-mod_folder-opened'}
  sprite.style.width = 20
  sprite.style.height = 20
  sprite.style.stretch_image_to_widget_size = true
  sprite.resize_to_sprite = false
  p.pointer.add{type = 'button', name = '_gvv-mod_key_label', caption = '[font=default-bold]table_key_name[/font]',
    style = 'tree-item-folder_gvv-mod', mouse_button_filter = {'left', 'right'},
  }
  text{x..'9', {"",' [font=default-bold]',{"gvv-mod.tab-filtered-view"},'[/font]'}}
px() end
hpo() do
  p.pointer.add{type = 'button', name = '_gvv-mod_key_label', caption = ' [font=default-bold]value_key_name[/font]',
    style = 'tree-item_gvv-mod', mouse_button_filter = {'right'},
  }
  text{x..'10', {"",' [font=default-bold]',{"gvv-mod.tab-filtered-view"},'[/font]'}}
px() end
hpo() do
  p.pointer.add{type = 'button', name = '_gvv-mod_key_value', caption = ' [color=blue][font=default-bold]LuaObj_value[/font][/color]',
    style = 'tree-item-luaobj_gvv-mod', mouse_button_filter = {'right'},
  }
  text{x..'11', ' [font=default-bold]property[/font]'}
px() end
hpo() do
  p.pointer.add{type = 'button', name = '_gvv-mod_key_label', caption = ' [color=0.5,0.5,0.5,0.5][font=default-bold]n/a_property_name[/font][/color]',
    style = 'tree-item-na_gvv-mod', mouse_button_filter = {'right'},
  }
  text{x..'12'}
px() end
hpo() do
  p.pointer.add{type = 'button', name = '_gvv-mod_key_label', caption = ' [color=0.5,0.5,0.5,0.5][font=default-bold]method_name(...)[/font][/color]',
    style = 'tree-item-func_gvv-mod', mouse_button_filter = {'right'},
  }
  text{x..'13'}
px() end
text(' ')
text{x..'14', {"",'[font=default-bold]',{"gvv-mod.tab-filtered-view"},'[/font]'}}
text{x..'15', {"",'[font=default-bold]',{"gvv-mod.tab-filtered-view"},'[/font]'}}
end ---------------------------------


-------------------------------------
content_writer['troubleshoot'] = function()
  x = 'gvv-mod-help-troubleshoot.'
-------------------------------------
head{x..'1'}
text{x..'2'}
text{x..'3'}
text(' ')
text{x..'4'}
vpo() do
  text(" · Can't copy object of type function") this.style.font='var' this.style.font_color={1,0.85,0.7,1}
  text(" · Can't copy object of type userdata") this.style.font='var' this.style.font_color={1,0.85,0.7,1}
  text(" · table index is nil") this.style.font='var' this.style.font_color={1,0.85,0.7,1}
px() end
text{x..'5', {"",'[font=default-bold]',
  {"gvv-mod-helpui.diagnose"},'[/font]'},
  {"",'[font=default-bold]',{"gvv-mod-helpui.fix"},'[/font]'},
  'global.report',
}
text{x..'6', {"",'[font=default-bold]',{"gvv-mod-helpui.fix"},'[/font]'}}
vpo() do
  p.pointer.style.padding = 10
  local textinput = p.pointer.add{type = 'textfield', name = '_gvv-mod_fix_mod_name_input_', text = '', clear_and_focus_on_right_click = false}
  textinput.style.horizontally_stretchable = true
  textinput.style.horizontally_squashable = true
  textinput.style.minimal_width = 10
  textinput.style.maximal_width = 9999
  textinput.style.bottom_margin = 10
  local flow = p.pointer.add{type = 'flow', direction = 'horizontal', name = '_gvv-mod_fix_btn_wrap_', style = 'hflow_gvv-mod'}
  flow.style.horizontally_stretchable = true
  flow.style.horizontal_align = 'right'
  local btn1 = flow.add{type = 'button', name = '_gvv-mod_fix_diagnose_btn_', caption = {"gvv-mod-helpui.diagnose"}, style = 'c_sub_mod_gvv-mod', mouse_button_filter = {'left'}}
  btn1.style.right_margin = 10
  btn1.style.horizontally_stretchable = false
  local btn2 = flow.add{type = 'button', name = '_gvv-mod_fix_fix_btn_', caption = {"gvv-mod-helpui.fix"}, style = 'c_sub_mod_gvv-mod', mouse_button_filter = {'left'}}
  btn2.style.horizontally_stretchable = false
px() end
text{x..'7', {"",'[font=default-bold]',{"gvv-mod-helpui.fix"},'[/font]'},'.error'}
hpo() do
  p.pointer.style.vertical_align = 'center'
  text{x..'8','global.report'} this.style.right_margin = 5 this.style.left_margin = 5
  local btn = p.pointer.add{type = 'button', name = '_gvv-mod_fix_clear_report_btn_', caption = {"gvv-mod-helpui.clear-report"}, style = 'c_sub_mod_gvv-mod', mouse_button_filter = {'left'}}
  btn.style.horizontally_stretchable = false
px() end
end ---------------------------------


return Help_Menu
