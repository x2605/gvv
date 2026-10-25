---------------------------------------------------------------------------------------------
-- MODULES
---------------------------------------------------------------------------------------------
-- FR : Liste des modules envoyés à l'event handler (__core__/lualib/event_handler) par control.lua.
--      Chaque module peut fournir on_init, on_load, on_configuration_changed, add_commands
--      et une table events ; l'event handler les enregistre auprès de Factorio.
-- EN : List of modules sent to the event handler (__core__/lualib/event_handler) by control.lua.
--      Each module may provide on_init, on_load, on_configuration_changed, add_commands
--      and an events table; the event handler registers them with Factorio.
---------------------------------------------------------------------------------------------
local modules = {}
log('modules gvv')
---------------------------------------------------------------------------------------------
modules.events =    require(gvv.defines.modules.events)     -- FR : cycle de vie du mod / EN : mod life cycle
modules.player =    require(gvv.defines.modules.player)     -- FR : évènements joueurs / EN : player events
modules.gui =       require(gvv.defines.modules.gui)        -- FR : évènements GUI et raccourcis / EN : GUI events and shortcuts
modules.commands =  require(gvv.defines.modules.commands)   -- FR : commandes, paramètres du mod / EN : commands, mod settings
---------------------------------------------------------------------------------------------
return modules
