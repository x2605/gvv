--로드

local Commands = require('modules.commands')
local Util = require('modules.util')
local Tracking = require('modules.tracking')
local Gui = require('modules.gui')

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

--중복해서 require('modules.load') 호출해도 한번만 실행되도록
--run single time if called require('modules.load') multiple times
if not _initiated_session_ then
  -- session global variables not inside of global table
  _on_tick_function_ = Tracking.on_tick --constant
  _one_of_three_volatiles_executed_ = false
  _initiated_on_tick_ = false
  _initiated_session_ = true
  ------
end

local vless = function(str, a, b, c)
  local A, B, C = str:match('^(%d+)%.(%d+)%.(%d+)$')
  if A then A = A + 0 end
  if B then B = B + 0 end
  if C then C = C + 0 end
  if not (A and B and C) then
    return true
  end
  if (a == A and b == B and c >= C)
    or (a == A and b > B)
    or a > A
    then
    return true
  end
  return false
end
Load.on_configuration_changed = function(data)
  Load.register_meta_data()
  Load.register_volatiles()
  Load.example_load()
  if data.mod_changes then
    local thismod = data.mod_changes['gvv']
    if thismod then
      if thismod.old_version and vless(thismod.old_version, 0, 4, 0) then
        if global.players then
          for index, g in pairs(global.players) do
            pcall(function()
              if g.gui and g.gui.frame and g.gui.frame.valid then
                Gui.close_main(g, true)
              end
            end)
          end
        end
      end
    end
  end
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
  if global.meta_data['enable-on-tick'] == nil then
    global.meta_data['enable-on-tick'] = settings.global['gvv-mod_enable-on-tick'].value
    if not _initiated_on_tick_ and global.meta_data['enable-on-tick'] then
      script.on_event(defines.events.on_tick, _on_tick_function_)
      _initiated_on_tick_ = true
    elseif not _initiated_on_tick_ and not global.meta_data['enable-on-tick'] then
      script.on_event(defines.events.on_tick, nil)
      _initiated_on_tick_ = true
    end
  end
  if not global.meta_data.initiated then
    global.meta_data.initiated = true

    if settings.global['gvv-mod_on_start'].value then
      local raw = settings.global['gvv-mod_preinput_code'].value
      local r, codes = true, {}
      local final_codes = {}
      local c = 0
      while r do
        codes[#codes + 1] = raw:match('^(.-)(%-%-%[%[%]%]%-%-)')
        raw, c = raw:gsub('^(.-)(%-%-%[%[%]%]%-%-)','')
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
  if not _one_of_three_volatiles_executed_ then
    if not _initiated_on_tick_ and global.meta_data and global.meta_data['enable-on-tick'] then
      script.on_event(defines.events.on_tick, _on_tick_function_)
      _initiated_on_tick_ = true
    elseif not _initiated_on_tick_ and global.meta_data and global.meta_data['enable-on-tick'] == false then
      script.on_event(defines.events.on_tick, nil)
      _initiated_on_tick_ = true
    end
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
    _one_of_three_volatiles_executed_ = true
  end
end

-- 플레이어를 삭제한 후 삭제한 플레이어 인덱스에 새 플레이어가 올 경우
-- for when new player comes at empty index where player removed
Load.on_player_created = function(event)
  if global.players then
    global.players[event.player_index] = nil
  end
end

-- 런타임 모드 설정 변경시
Load.on_runtime_mod_setting_changed = function(event)
  Commands.when_change_mod_settings(event)
end

return Load
