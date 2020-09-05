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

one_of_three_executed_gvv_mod_run_check_ = false

Load.on_configuration_changed = function(data)
  Load.register_meta_data()
  Load.register_volatiles()
  one_of_three_executed_gvv_mod_run_check_ = true
  Load.example_load()
end

Load.on_init = function()
  Load.register_meta_data()
  Load.register_volatiles()
  one_of_three_executed_gvv_mod_run_check_ = true
  Load.example_load()
end

Load.on_load = function()
  Load.register_meta_data()
  Load.register_volatiles()
  one_of_three_executed_gvv_mod_run_check_ = true
end

Load.register_meta_data = function()
  if not one_of_three_executed_gvv_mod_run_check_ then
    local version = script.active_mods['gvv']
    if not global.meta_data then global.meta_data = {} end
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
end

Load.register_volatiles = function()
  if not one_of_three_executed_gvv_mod_run_check_ then
    local pc, ret
    pc, ret = pcall(function()
      commands.add_command('gvv', {"gvv-mod-command-help.gvv"}, Commands.gvv)
    end)
    if not pc then log(ret) end
    pc, ret = pcall(function()
      commands.add_command('gdump-json', {"gvv-mod-command-help.gdump-json"}, Commands.gdump_json)
    end)
    if not pc then log(ret) end
    pc, ret = pcall(function()
      commands.add_command('gdump-luaon', {"gvv-mod-command-help.gdump-luaon"}, Commands.gdump_luaon)
    end)
    if not pc then log(ret) end
    pc, ret = pcall(function()
      commands.add_command('gdump', {"gvv-mod-command-help.gdump"}, Commands.gdump_luaon)
    end)
    if not pc then log(ret) end
    pc, ret = pcall(function()
      commands.add_command('gmods', {"gvv-mod-command-help.gmods"}, Commands.gmods)
    end)
    if not pc then log(ret) end
  end
end

return Load
