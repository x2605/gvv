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
  {
    name = 'tips',
    caption = {"gvv-mod-help.tips"},
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
local looking_player_index

Help_Menu.draw_page = function(g, name)
  local panel = g.gui.sub_helppanel
  panel.clear()

  p = {top = panel, pointer = panel}
  looking_player_index = g.index
  content_writer[name]()
end

local function text(locstr, tooltip)
  local u = p.pointer.add{type = 'label', caption = locstr, tooltip = tooltip}
  u.style.horizontally_stretchable = true
  u.style.single_line = false
  this = u
  return u
end

local function head(locstr)
  local u = p.pointer.add{type = 'label', caption = locstr, style = 'heading_1_label'}
  u.style.horizontally_stretchable = true
  u.style.single_line = false
  this = u
  return u
end

local function head2(locstr)
  local u = p.pointer.add{type = 'label', caption = locstr, style = 'heading_2_label'}
  u.style.horizontally_stretchable = true
  u.style.single_line = false
  u.style.left_padding = 7
  this = u
  return u
end

local function copyable(str, wrapper_name)
  local newline_count = select(2, str:gsub('\n',''))
  local flow = p.pointer.add{type = 'flow', direction = 'vertical', name = wrapper_name, style = 'vflow_gvv-mod'}
  local u
  if newline_count > 0 then
    local height = 22 + 22 * newline_count
    if height > 400 then height = 400 end
    u = flow.add{type = 'text-box', name = '_gvv-mod_uneditable_text_', text = str, clear_and_focus_on_right_click = true, tooltip = {"gvv-mod.right-to-select-all"}}
    u.style.height = height
  else
    u = flow.add{type = 'textfield', name = '_gvv-mod_uneditable_text_', text = str, clear_and_focus_on_right_click = true, tooltip = {"gvv-mod.right-to-select-all"}}
  end
  flow.style.horizontally_stretchable = true
  u.style.horizontally_stretchable = true
  u.style.horizontally_squashable = true
  u.style.minimal_width = 10
  u.style.maximal_width = 9999
  flow.add{type = 'label', name = '_gvv-mod_uneditable_text_buffer_', caption = str}
  flow['_gvv-mod_uneditable_text_buffer_'].visible = false
  this = u
  return u
end

local function hpo(name)
  local u = p.pointer.add{type = 'flow', name = name, direction = 'horizontal', style = 'hflow_gvv-mod'}
  u.style.horizontally_stretchable = true
  this = u
  p.pointer = u
  return u
end

local function vpo(name)
  local u = p.pointer.add{type = 'flow', name = name, direction = 'vertical', style = 'vflow_gvv-mod'}
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

local function hr(name)
  local u = p.pointer.add{type = 'line', name = name, direction = 'horizontal'}
  u.style.horizontally_stretchable = true
  this = u
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
text(' ')
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
text{x..'5-0'} this.style.top_margin = 5
text{x..'5-1', ' [font=default-bold]/c /command[/font]', '[font=default-bold]/sc /silent-command[/font]'}
  this.style.bottom_margin = 5
hr()
head2{x..'6-0'}
text{x..'6'}
hpo() do
  local modlist = Util.get_all_mod_list({gvv = true, base = true})
  local sel = p.pointer.add{type = 'drop-down', name = '_gvv-mod_help_copy_temp_enable_code_',
    items = modlist, selected_index = 1,
  }
  sel.style.horizontally_squashable = true
  local copy = copyable('', '_gvv-mod_copyable_')
  copy.parent['_gvv-mod_uneditable_text_buffer_'].caption = Copy_Code.in_console_enable()
  copy.text = copy.parent['_gvv-mod_uneditable_text_buffer_'].caption
px() end
text{x..'7'}
text{x..'8'} this.style.top_margin = 5
hpo() do
  local modlist = Util.get_all_mod_list({gvv = true, base = true})
  local sel = p.pointer.add{type = 'drop-down', name = '_gvv-mod_help_copy_temp_disable_code_',
    items = modlist, selected_index = 1,
  }
  sel.style.horizontally_squashable = true
  local copy = copyable('', '_gvv-mod_copyable_')
  copy.parent['_gvv-mod_uneditable_text_buffer_'].caption = Copy_Code.in_console_disable()
  copy.text = copy.parent['_gvv-mod_uneditable_text_buffer_'].caption
px() end
text{x..'9'}
text{x..'10'}
text(' ')
end ---------------------------------


-------------------------------------
content_writer['console2'] = function()
  x = 'gvv-mod-help-console2.'
-------------------------------------
head{x..'1'}
text{x..'2'}
hpo() do
  p.pointer.style.vertical_align = 'top'
  p.pointer.style.horizontally_squashable = true
  local options = {'<mod_name>', '__<mod_name>__', 'remote.call..."global")', 'remote.call..."c",)'}
  local sel1 = p.pointer.add{type = 'list-box', name = '_gvv-mod_help_copy_option_mod_string_',
    items = options, selected_index = 3, style = 'list_box-transparent_gvv-mod',
  }
  sel1.style.horizontally_squashable = true
  sel1.style.horizontally_stretchable = false
  sel1.style.vertically_stretchable = true
  sel1.style.width = 155
  vpo('mod_list') do
    local modlist = Util.get_accessible_mod_list()
    local copy = copyable('', '_gvv-mod_copyable_')
    local sel = p.pointer.add{type = 'list-box', name = '_gvv-mod_help_copy_mod_string_code_',
      items = modlist, selected_index = 1, style = 'list_box-transparent_gvv-mod',
    }
    sel.style.vertically_stretchable = true
    copy.parent['_gvv-mod_uneditable_text_buffer_'].caption = 'remote.call("__'..sel.items[sel.selected_index]..'__gvv","global")'
    copy.text = copy.parent['_gvv-mod_uneditable_text_buffer_'].caption
  px() end
px() end
text(' ')
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
text(' ')
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
  btn1.style.horizontal_align = 'center'
  local btn2 = flow.add{type = 'button', name = '_gvv-mod_fix_fix_btn_', caption = {"gvv-mod-helpui.fix"}, style = 'c_sub_mod_gvv-mod', mouse_button_filter = {'left'}}
  btn2.style.horizontally_stretchable = false
  btn2.style.horizontal_align = 'center'
px() end
text{x..'7', {"",'[font=default-bold]',{"gvv-mod-helpui.fix"},'[/font]'},'.error'}
hpo() do
  p.pointer.style.vertical_align = 'center'
  text{x..'8','global.report'} this.style.right_margin = 5 this.style.left_margin = 5
  local btn = p.pointer.add{type = 'button', name = '_gvv-mod_fix_clear_report_btn_', caption = {"gvv-mod-helpui.clear-report"}, style = 'c_sub_mod_gvv-mod', mouse_button_filter = {'left'}}
  btn.style.horizontally_stretchable = false
  btn.style.horizontal_align = 'center'
px() end
text(' ')
end ---------------------------------


-------------------------------------
content_writer['tips'] = function()
  x = 'gvv-mod-help-tips.'
-------------------------------------
head{x..'1'}
hr()
head2{x..'2'}
text{x..'3'}
text{x..'3-0', {"",'[font=default-bold]',{"gvv-mod.tab-filtered-view"},'[/font]'}}
text{x..'3-1'}
copyable('/c __gvv__ if not global.memo then global.memo={} end global.memo["'..game.players[looking_player_index].name..'"]={}')
  this.style.bottom_margin = 5
text{x..'3-2'}
local memo_prefix = '/sc __gvv__ local MEMO=global.memo["'..game.players[looking_player_index].name..'"] game.player.print("MEMO#"..#MEMO+1) MEMO[#MEMO+1]= '
copyable(memo_prefix..'game.player.selected') this.style.bottom_margin = 5
text{x..'3-3'}
copyable(memo_prefix) this.style.bottom_margin = 5
text({x..'3-4', '[font=default-semibold][color=128, 206, 240]Enter[/color][/font]'}, {x..'3-4'..'-tooltip'})
copyable('/sc __gvv__ local t=setmetatable({},{__newindex=function(a,b,c) global.memo["'..game.players[looking_player_index].name..'"][c]=nil game.player.print("MEMO#"..c.."=nil") end}) t[1]= ')
  this.style.bottom_margin = 5
text{x..'3-5'}
text(' ')
hr()
head2{x..'4'}
text{x..'5',
  {"",'[font=default-bold]',{"gvv-mod.tab-filtered-view"},'[/font]'},
  {"",'[color=0.75,0.75,0.75,1]',{x..'5'..'-word1'},'[/color]'},
}
text{x..'6', {"",'[font=default-bold]','property','[/font]'}}
text{x..'7', '[font=default-semibold][color=128, 206, 240]Ctrl + C[/color][/font]'}
text(' ')
hr()
head2{x..'8'}
text{x..'9', {"",'[font=default-bold]',{"gvv-mod.tab-filtered-view"},'[/font]'}}
text(' ')
hr()
head2{x..'10'}
text{x..'11',
  {"",'[font=default-bold]',{"gui-menu.game-menu"},' - ',{"gui-menu.settings"},' - ',{"gui-menu.mod-settings"},' - ',{"gui-mod-settings.map"},'[/font]'},
  {"",'[font=default-bold]',{"gvv-mod.tab-filtered-view"},'[/font]'}
}
text{x..'11-1'}
text{x..'11-2'}
copyable('/sc __gvv__ settings.global["gvv-mod_enable-on-tick"]={value= false }')
text(' ')
hr()
head2{x..'12'}
text{x..'13'}
text(' ')
hr()
head2{x..'18', {"gvv-mod.tab-filtered-view"}}
text{x..'19'}
copyable('assert(function() <YOUR_CODE> return <RETURN_VALUE> end)()')
text(' ')
hr()
head2{x..'14'}
text{x..'15'}
copyable('/c game.player.print(script.mod_name)')
text('Prints : [color=0.25,1,0.25]level[/color]')
copyable('/c __gvv__ game.player.print(script.mod_name)')
text('Prints : [color=0.25,1,0.25]gvv[/color]')
do
  local example_name = 'my Mod-1'
  for name in pairs(script.active_mods) do
    local pc, ret = pcall(function() return remote.interfaces['__'..name..'__gvv']['c'] end)
    if pc and ret and name ~= 'level' and name ~= 'gvv' then
      example_name = name
      break
    end
  end
  copyable('/c __'..example_name..'__ game.player.print(script.mod_name)')
text({x..'16', 'Prints : [color=0.25,1,0.25]'..example_name..'[/color]'})
end
text(' ')
hr()
head2('remote.call("__<mod_name>__gvv", "c", <script>, ...)')
text{x..'17'}
do
  local example_name = 'gvv'
  for name in pairs(script.active_mods) do
    local pc, ret = pcall(function() return remote.interfaces['__'..name..'__gvv']['c'] end)
    if pc and ret and name ~= 'level' and name ~= 'gvv' then
      example_name = name
      break
    end
  end
  copyable('remote.call("__'..example_name..'__gvv", "c", [[\n'
    ..'local pos = {\n'
    ..'  ( arg[1].right_bottom[1] - arg[1].left_top[1] ) /2 + arg[1].left_top[1],\n'
    ..'  ( arg[1].right_bottom[2] - arg[1].left_top[2] ) /2 + arg[1].left_top[2]\n'
    ..'} -- arg is a predefined table of c function.\n'
    ..'game.player.surface.create_entity{\n'
    ..'  position = pos,\n'
    ..'  name = "flying-text",\n'
    ..'  text = script.mod_name .. arg[2],\n'
    ..'}\n'
    ..']], area, " TEST") -- area is passed to arg[1].\n'
    ..'-- area is a predefined table of Lua snippet.'
  )
end
text(' ')

end ---------------------------------


return Help_Menu
