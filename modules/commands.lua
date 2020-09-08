-- 커맨드

local Table_to_str = require('modules.table_to_str')
local Gui = require('modules.gui')

local Commands = {}

local setting_prefix = 'gvv-mod_'
local changeable_setting_list = {
  [setting_prefix..'enable-on-tick'] = true,
}

-- /gvv
Commands.gvv = function(data)
  local player
  if data.player_index then
    player = game.players[data.player_index]
    if not player.admin and game.is_multiplayer() then
      player.print{"",'gvv : ',{"gvv-mod-command-help.only-admin"}}
      return
    end
  end
  if player then
    Gui.open_main(data.player_index)
  else
    localised_print{"",'[COMMAND-ERROR] gvv : ',{"gvv-mod-command-help.need-graphic"}}
  end
end

-- /gdump-json
Commands.gdump_json = function(data)
  Commands.gdump(data, 'json')
end

-- /gdump-luaon
Commands.gdump_luaon = function(data)
  Commands.gdump(data, 'luaon')
end

-- /gdump
Commands.gdump = function(data, lang)
  local rmt_glob, player, mod_name
  if data.player_index then
    player = game.players[data.player_index]
    if not player.admin and game.is_multiplayer() then
      player.print{"",data.name,' : ',{"gvv-mod-command-help.only-admin"}}
      return
    end
  end
  if not data.parameter or data.parameter == '' or data.parameter:gsub('^%s*(.-)%s*$', '%1')..'' == 'level' then
    local pc = nil
    mod_name = 'level'
    pc, rmt_glob = pcall(function() return remote.call('__level__gvv','global') end)
    if not pc then
      rmt_glob = nil
      if player then
        player.print{"",{"gvv-mod-command-help.no-level-support"}}
      else
        localised_print{"",'[COMMAND-ERROR] gdump-',lang,'(gvv) : ',{"gvv-mod-command-help.no-level-support"}}
      end
    end
  else
    mod_name = data.parameter:gsub('^%s*(.-)%s*$', '%1')..''
    local found = false
    for name, ver in pairs(script.active_mods) do
      if mod_name == name then
        found = true
        local pc
        pc, rmt_glob = pcall(function() return remote.call('__'..name..'__gvv','global') end)
        if not pc then
          rmt_glob = nil
          if player then
            player.print{"",{"gvv-mod-command-help.no-level-support",mod_name}}
          else
            localised_print{"",'[COMMAND-ERROR] gdump-',lang,'(gvv) : ',{"gvv-mod-command-help.no-mod-support",mod_name}}
          end
        end
        break
      end
    end
    if not found then
      if player then
        player.print{"",{"gvv-mod-command-help.no-mod-found",mod_name}}
      else
        localised_print{"",'[COMMAND-ERROR] gdump-',lang,'(gvv) : ',{"gvv-mod-command-help.no-mod-found",mod_name}}
      end
    end
  end
  if rmt_glob then
    if player then
      Gui.copyable_dump(data.player_index, Table_to_str.to_lang(rmt_glob, lang), '/gdump-'..lang..' '..mod_name)
    else
      localised_print{"",'[COMMAND] gdump-',lang,'(gvv) : "',mod_name,'" ',Table_to_str.to_lang(rmt_glob, lang)}
    end
  end
end

-- /gmods
Commands.gmods = function(data)
  local s = {}
  local rmt_glob_str = {}
  local rmt_glob_cnt = 0
  if pcall(function() return remote.interfaces['__level__gvv']['global'] end) then
    rmt_glob_str[#rmt_glob_str + 1] = 'level'
    rmt_glob_cnt = rmt_glob_cnt + 1
  end
  for name, ver in pairs(script.active_mods) do
    if #s > 0 then s[#s + 1] = ', ' end
    s[#s + 1] = name..'_'..ver
    if pcall(function() return remote.interfaces['__'..name..'__gvv']['global'] end) then
      if #rmt_glob_str > 0 then rmt_glob_str[#rmt_glob_str + 1] = ', ' end
      rmt_glob_str[#rmt_glob_str + 1] = name
      rmt_glob_cnt = rmt_glob_cnt + 1
    end
  end
  if data.player_index then
    local player = game.players[data.player_index]
    if not player.admin and game.is_multiplayer() then
      player.print{"",'Loaded mod list (',table_size(script.active_mods),'):\n',table.concat(s)}
    else
      player.print{"",'(gvv) Loaded mod list (',table_size(script.active_mods),'):\n',table.concat(s)}
      player.print{"",'(gvv) global accessible mod list (',rmt_glob_cnt,'):\n',table.concat(rmt_glob_str)}
    end
  else
    localised_print{"",'[COMMAND] gmods(gvv) Loaded mod list (',table_size(script.active_mods),'): ',table.concat(s)}
    localised_print{"",'[COMMAND] gmods(gvv) global accessible mod list (',rmt_glob_cnt,'): ',table.concat(rmt_glob_str)}
  end
end

-- /gvv-c & /gvv-silent-command
local command_execute = function(data, broadcast)
  local player
  if data.player_index then player = game.players[data.player_index] end
  if player then
    if not player.admin and game.is_multiplayer() then
      player.print{"",data.name,' : ',{"gvv-mod-command-help.only-admin"}}
      return
    end
  end
  if data.parameter then
    data.parameter = data.parameter:gsub('^%s*(.-)%s*$', '%1')..''
  else
    data.parameter = ''
  end

  if broadcast then
    local name, chat_color
    if player then
      local tag = player.tag
      if tag ~= '' then
        name = player.name..tag
      else
        name = player.name
      end
      chat_color = player.chat_color
    else
      name = '<server>'
      chat_color = { r = 0.7  , g = 0.7  , b = 0.7   }
    end
    local player_message

    player_message = '[font=var-outline-gvv-mod]'..name..' (gvv-command): '..data.parameter..'[/font]'
    for _, p in pairs(game.connected_players) do
      p.print(player_message, chat_color)
    end
    print('[COMMAND] '..name..' (gvv-command): '..data.parameter)
  end

  local pc, ret
  local m1, m2, m3, m4 = data.parameter:match('^(%s*%-%-%[%[)(.-)(%]%]%s*)(.*)',1)
  if m2 and m4 then
    m2 = m2:match('^%s*(.-)%s*$')
    pc, ret = pcall(function()
      local a,b = remote.call('__'..m2..'__gvv','c',m4)
      if a then return b else error(b) end
    end)
  else
    pc, ret = pcall(function() assert(loadstring(data.parameter))() end)
  end
  if not pc then
    local message
    if broadcast then
      message = 'Cannot execute command /g-c. Error: '
    else
      message = 'Cannot execute command /g-sc. Error: '
    end
    player_message = {"",'[font=var-outline-gvv-mod]',message,ret,'[/font]'}
    if broadcast then
      for _, p in pairs(game.connected_players) do
        p.print(player_message, {1,0.85,0.7,1})
      end
      log(message..ret)
    else
      if player then
        player.print(player_message, {1,0.85,0.7,1})
      else
        log(message..ret)
      end
    end
  end
end

-- /gvv-c
Commands.g_command = function(data)
  command_execute(data, true)
end

-- /gvv-silent-command
Commands.g_silent_command = function(data)
  command_execute(data, false)
end

-- 모드 설정 변경시
Commands.when_change_mod_settings = function(event)
  if not changeable_setting_list[event.setting] then return end
  local setting_name = event.setting:match('^gvv%-mod_(.*)')
  if not global.meta_data then global.meta_data = {} end
  if event.setting_type == 'runtime-global' then
    local value = settings.global[event.setting].value
    local message
    if event.player_index then
      message = {"",'(gvv) Player ',game.players[event.player_index].name,' changed "',setting_name,'" mod-setting to "',value,'"'}
    else
      message = {"",'(gvv) "',setting_name,'" mod-setting is changed to "',value,'"'}
    end
    if game.is_multiplayer() then
      for _, player in pairs(game.connected_players) do
        if player.admin then
          player.print(message)
        end
      end
    else
      for _, player in pairs(game.connected_players) do
        player.print(message)
      end
    end
    localised_print({"",'[MOD-SETTING] ',message})

    if setting_name == 'enable-on-tick' then
      local g
      if value then
        script.on_event(defines.events.on_tick, _on_tick_function_)
        global.meta_data['enable-on-tick'] = true
        if global.players then
          for _, player in pairs(game.players) do
            g = global.players[player.index]
            if g and g.gui and g.gui.track_inter_show and g.gui.track_inter_show.valid then
              g.gui.track_inter_show.style.font_color = {1,1,1}
              g.gui.track_inter_show.tooltip = {"gvv-mod.track-interval-control"}
            end
          end
        end
      else
        script.on_event(defines.events.on_tick, nil)
        global.meta_data['enable-on-tick'] = false
        if global.players then
          for _, player in pairs(game.players) do
            g = global.players[player.index]
            if g and g.gui and g.gui.track_inter_show and g.gui.track_inter_show.valid then
              g.gui.track_inter_show.style.font_color = {1,0.25,0.25}
              g.gui.track_inter_show.tooltip = {"gvv-mod.track-interval-control-off"}
            end
          end
        end
      end
    end

  elseif event.setting_type == 'runtime-per-user' then
  end
end

return Commands
