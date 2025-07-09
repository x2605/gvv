-- 트래킹

local Table_to_str = require('core.utils.table_to_str')
local Tree = require('modules.tree')

local Tracking = {}

Tracking.draw = function(panel, path_str, full_path, preinput)
  local container = panel.add{type = 'flow', name = path_str, direction = 'vertical', style = 'vflow_gvv-mod'}
  local header = container.add{type = 'flow', name = 'header', direction = 'horizontal', style = 'hflow_gvv-mod'}
  header.style.vertical_align = 'center'
  header.style.left_padding = 6
  header.style.horizontal_spacing = 6
  header.add{type = 'checkbox', name = 'check_to_remove', state = false, tooltip = {"gvv-mod.check-for-remove", '[img=utility/trash_white]', '[img=gvv-mod_arrow-up][img=gvv-mod_arrow-down]'}}
  local caption
  if type(full_path) == 'table' then
    if #full_path == 1 and full_path[1]:match('^[*]') then
      caption = full_path[1]:gsub('^[*]','')..' :'
    else
      caption = Table_to_str.key_to_str(full_path[#full_path])..' :'
    end
    header.add{type = 'label', name = 'last_key_name', caption = caption}
    header.last_key_name.style.font_color = {0.6,0.8,1,1}
  elseif type(full_path) == 'string' then
    caption = full_path
  else
    error('full_path is not table nor string')
  end
  header.add{type = 'label', name = '_gvv-mod_tracking_path_str_', caption = path_str, tooltip = {"gvv-mod.right-to-copy-edit-code"}}
  header['_gvv-mod_tracking_path_str_'].style.font_color = {0.75,0.75,0.75,1}
  local body = container.add{type = 'flow', name = 'body', direction = 'horizontal', style = 'hflow_gvv-mod'}
  body.style.vertical_align = 'center'
  body.style.left_padding = 6
  body.style.horizontal_spacing = 6
  body.add{type = 'label', name = 'report', caption = '  =  '}
  body.add{type = 'label', name = '_gvv-mod_tracking_output_', tooltip = {"gvv-mod.right-to-copy-code"}}
  body['_gvv-mod_tracking_output_'].style.font = 'default-bold'
  if preinput and type(preinput) == 'table' and type(preinput.value) == 'string' and type(preinput.remchk) == 'boolean' then
    header.check_to_remove.state = preinput.remchk
    body['_gvv-mod_tracking_output_'].caption = preinput.value
  end
  local interline = container.add{type = 'line', direction = 'horizontal'}
end

Tracking.add = function(g, full_path, preinput)
  local panel = g.gui.tracking_panel
  local list = g.data.tracking_list
  local path_str
  if type(full_path) == 'table' then
    path_str = Table_to_str.path_to_lua_prop_path(full_path, true)
  elseif type(full_path) == 'string' then
    path_str = full_path
  else
    error('full_path is not table nor string')
  end
  local already = false

  for k, v in pairs(list) do
    if k == path_str then already = true end
  end
  if already then return end

  Tracking.draw(panel, path_str, full_path, preinput)

  list[path_str] = full_path
end

Tracking.value_output = function(elem, full_path)
  if type(full_path) == 'table' then
    elem.body['_gvv-mod_tracking_output_'].caption = Table_to_str.value_to_str(Tree.get_tree_value(full_path))
    elem.body['_gvv-mod_tracking_output_'].style.font_color = {1,1,1}
    elem.body['_gvv-mod_tracking_output_'].tooltip = {"gvv-mod.right-to-copy-code"}
  elseif type(full_path) == 'string' then
    elem.body['_gvv-mod_tracking_output_'].caption = Table_to_str.value_to_str(assert(loadstring('return '..full_path))())
    elem.body['_gvv-mod_tracking_output_'].style.font_color = {1,1,1}
    elem.body['_gvv-mod_tracking_output_'].tooltip = {"gvv-mod.right-to-copy-code"}
  else
    error('full_path is not table nor string')
  end
end

Tracking.refresh_value = function(g)
  local panel = g.gui.tracking_panel
  local list = g.data.tracking_list
  local pc, ret
  for _, elem in pairs(panel.children) do
    pc, ret = pcall(Tracking.value_output, elem, list[elem.name])
    if not pc then
      elem.body['_gvv-mod_tracking_output_'].tooltip = ret
      elem.body['_gvv-mod_tracking_output_'].caption = ret
      elem.body['_gvv-mod_tracking_output_'].style.font_color = { r = 1.000, g = 0.630, b = 0.259 }
    end
  end
end

Tracking.on_tick = function()
  if not storage.players then return end
  local g
  for _, player in pairs(game.connected_players) do
    g = storage.players[player.index]
    if g and game.tick % g.track_interval_tick == 0
      and g.gui.frame
      and g.gui.frame.valid
      and g.gui.tabpane.selected_tab_index == 1
      then
      Tracking.refresh_value(g)
    end
  end
end

return Tracking
