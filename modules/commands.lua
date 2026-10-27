-- 커맨드

local Table_to_str = require(gvv.defines.lualib.common.table_to_str)

local Commands = {}

local setting_prefix = 'gvv-mod_'
local changeable_setting_list = {
  [setting_prefix..'enable-on-tick'] = true,
}

-- /gvv
Commands.gvv = function(data)
  local player
  if data.player_index then
    player = game.get_player(data.player_index)
    if not player.admin and game.is_multiplayer() then
      player.print{"",'gvv : ',{"gvv-mod-command-help.only-admin"}}
      return
    end
  end
  if player then
    GvvGuiMain({player_index = data.player_index}):toggle()
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
    player = game.get_player(data.player_index)
    if not player.admin and game.is_multiplayer() then
      player.print{"",data.name,' : ',{"gvv-mod-command-help.only-admin"}}
      return
    end
  end
  if not data.parameter or data.parameter == '' or data.parameter:gsub('^%s*(.-)%s*$', '%1')..'' == 'level' then
    local pc = nil
    mod_name = 'level'
    pc, rmt_glob = pcall(function() return remote.call('__level__gvv','storage') end)
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
        pc, rmt_glob = pcall(function() return remote.call('__'..name..'__gvv','storage') end)
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
      GvvGuiDialog({player_index = data.player_index}):openDump(Table_to_str.to_lang(rmt_glob, lang), '/gdump-'..lang..' '..mod_name)
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
  if pcall(function() return remote.interfaces['__level__gvv']['storage'] end) then
    rmt_glob_str[#rmt_glob_str + 1] = 'level'
    rmt_glob_cnt = rmt_glob_cnt + 1
  end
  for name, ver in pairs(script.active_mods) do
    if #s > 0 then s[#s + 1] = ', ' end
    s[#s + 1] = name..'_'..ver
    if pcall(function() return remote.interfaces['__'..name..'__gvv']['storage'] end) then
      if #rmt_glob_str > 0 then rmt_glob_str[#rmt_glob_str + 1] = ', ' end
      rmt_glob_str[#rmt_glob_str + 1] = name
      rmt_glob_cnt = rmt_glob_cnt + 1
    end
  end
  if data.player_index then
    local player = game.get_player(data.player_index)
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

-- 모드 설정 변경시
Commands.when_change_mod_settings = function(event)
  if not changeable_setting_list[event.setting] then return end
  local setting_name = event.setting:match('^gvv%-mod_(.*)')
  if not storage.meta_data then storage.meta_data = {} end
  if event.setting_type == 'runtime-global' then
    local value = settings.global[event.setting].value
    local message
    if event.player_index then
      message = {"",'(gvv) Player ',game.get_player(event.player_index).name,' changed "',setting_name,'" mod-setting to "',value,'"'}
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
        storage.meta_data['enable-on-tick'] = true
        -- FR : Nombre de l'intervalle en blanc pour chaque joueur / EN : Interval number in white for each player
        for _, player in pairs(game.players) do
          GvvGuiTracking({player_index = player.index}):updateTickWarning()
        end
      else
        script.on_event(defines.events.on_tick, nil)
        storage.meta_data['enable-on-tick'] = false
        -- FR : Nombre de l'intervalle en rouge pour chaque joueur / EN : Interval number in red for each player
        for _, player in pairs(game.players) do
          GvvGuiTracking({player_index = player.index}):updateTickWarning()
        end
      end
    end

  elseif event.setting_type == 'runtime-per-user' then
  end
end

---------------------------------------------------------------------------------------------
-- FR : Enregistrement des commandes de la console, appelé une fois par session par l'event handler
--      (dans on_init ou on_load).
-- EN : Console commands registration, called once per session by the event handler
--      (in on_init or on_load).
local function add_commands()
  -- FR : Liste des commandes : nom, aide affichée par /help, fonction appelée
  -- EN : Commands list: name, help shown by /help, called function
  local command_list = {
    {'gvv', {"gvv-mod-command-help.gvv"}, Commands.gvv},
    {'gdump-json', {"gvv-mod-command-help.gdump-json"}, Commands.gdump_json},
    {'gdump-luaon', {"gvv-mod-command-help.gdump-luaon"}, Commands.gdump_luaon},
    {'gdump', {"gvv-mod-command-help.gdump"}, Commands.gdump_luaon},
    {'gmods', {"gvv-mod-command-help.gmods"}, Commands.gmods},
  }

  for _, command in ipairs(command_list) do
    -- FR : Enregistrement protégé : une commande déjà enregistrée (erreur) ne bloque pas les suivantes
    -- EN : Protected registration: an already registered command (error) doesn't block the next ones
    local success, message = pcall(commands.add_command, command[1], command[2], command[3])

    -- FR : En cas d'erreur, on la note dans le log
    -- EN : On error, write it to the log
    if not success then
      log(message)
    end
  end
end

---------------------------------------------------------------------------------------------
-- FR : Module envoyé à l'event handler (core/modules.lua)
-- EN : Module sent to the event handler (core/modules.lua)
local module = {events = {}}
---------------------------------------------------------------------------------------------
-- FR : Commandes de la console
-- EN : Console commands
module.add_commands = add_commands
-- FR : Changement d'un paramètre du mod en cours de partie
-- EN : Mod setting changed during the game
module.events[defines.events.on_runtime_mod_setting_changed] = Commands.when_change_mod_settings
---------------------------------------------------------------------------------------------
return module
