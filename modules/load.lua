--로드

local Commands = require('modules.commands')
local Util = require('modules.util')

local Load = {}

Load.example_load = function()
  global.example = {
    forces = {
      player_force = game.forces.player,
      biter_force = game.forces['enemy'],
      tree_force = game.forces[3],
    },
    initial_surface = game.surfaces[1],
  }
end

one_of_three_volatiles_executed_ = false

Load.on_configuration_changed = function(data)
  Load.register_meta_data()
  Load.register_volatiles()
  Load.example_load()
end

Load.on_init = function()
  Load.register_meta_data()
  Load.register_volatiles()
  Load.example_load()
end

Load.on_load = function()
  Load.register_volatiles()
end

Load.register_meta_data = function()
  if not global.meta_data then global.meta_data = {} end
  local version = script.active_mods['gvv']
  global.meta_data.version = version
  if not global.meta_data._nil_ then global.meta_data._nil_ = {Used_for_categorizing=''} end
  if not global.meta_data._function_ then global.meta_data._function_ = {Used_for_categorizing=''} end
  if not global.meta_data._na_ then global.meta_data._na_ = {Used_for_categorizing=''} end
  if not global.meta_data.initiated then
    global.meta_data.initiated = true

    if settings.global['gvv-mod_on_start'].value then
      local raw = settings.global['gvv-mod_preinput_code'].value
      local r, codes = true, {}
      local final_codes = {}
      local c = 0
      while r do
        codes[#codes + 1] = raw:match('^(.-)([-][-][[][[][]][]][-][-])')
        raw, c = raw:gsub('^(.-)([-][-][[][[][]][]][-][-])','')
        if c == 0 then
          codes[#codes + 1] = raw
          r = false
        end
      end
      for i, v in ipairs(codes) do
        codes[i] = v:gsub('^%s*(.-)%s*$', '%1')
        if codes[i] ~= '' then final_codes[#final_codes + 1] = codes[i] end
      end
      global.meta_data.default_tracking_list = {}
      for _, v in pairs(final_codes) do
        global.meta_data.default_tracking_list[v] = v
      end
    end

  end
end

Load.register_volatiles = function()
  if not one_of_three_volatiles_executed_ then
    local pc, ret
    pc, ret = pcall(function()
      commands.add_command('gvv', {"gvv-mod-command-help.gvv"}, Commands.gvv)
    end) if not pc then log(ret) end
    pc, ret = pcall(function()
      commands.add_command('gdump-json', {"gvv-mod-command-help.gdump-json"}, Commands.gdump_json)
    end) if not pc then log(ret) end
    pc, ret = pcall(function()
      commands.add_command('gdump-luaon', {"gvv-mod-command-help.gdump-luaon"}, Commands.gdump_luaon)
    end) if not pc then log(ret) end
    pc, ret = pcall(function()
      commands.add_command('gdump', {"gvv-mod-command-help.gdump"}, Commands.gdump_luaon)
    end) if not pc then log(ret) end
    pc, ret = pcall(function()
      commands.add_command('gmods', {"gvv-mod-command-help.gmods"}, Commands.gmods)
    end) if not pc then log(ret) end
    pc, ret = pcall(function()
      commands.add_command('g-c', {"gvv-mod-command-help.g-c"}, Commands.g_command)
    end) if not pc then log(ret) end
    pc, ret = pcall(function()
      commands.add_command('g-command', {"gvv-mod-command-help.g-command"}, Commands.g_command)
    end) if not pc then log(ret) end
    pc, ret = pcall(function()
      commands.add_command('g-sc', {"gvv-mod-command-help.g-sc"}, Commands.g_silent_command)
    end) if not pc then log(ret) end
    pc, ret = pcall(function()
      commands.add_command('g-silent-command', {"gvv-mod-command-help.g-silent-command"}, Commands.g_silent_command)
    end) if not pc then log(ret) end
    one_of_three_volatiles_executed_ = true
  end
end

return Load
