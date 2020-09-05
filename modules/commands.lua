-- 커맨드

local Table_to_str = require('modules.table_to_str')
local Gui = require('modules.gui')

local Commands = {}

-- /gvv
Commands.gvv = function(data)
  if data.player_index then
    local player = game.players[data.player_index]
    if not player.admin and game.is_multiplayer() then
      player.print{"",'gvv : ',{"gvv-mod-command-help.only-admin"}}
      return
    end
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

return Commands
