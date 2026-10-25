---------------------------------------------------------------------------------------------
-- MODULES
---------------------------------------------------------------------------------------------
-- FR : Liste des modules envoyés à l'event handler (__core__/lualib/event_handler).
--      Chaque module peut fournir on_init, on_load, on_configuration_changed et une table events.
-- EN : List of modules sent to the event handler (__core__/lualib/event_handler).
--      Each module may provide on_init, on_load, on_configuration_changed and an events table.
---------------------------------------------------------------------------------------------
local modules = {}
log('modules gvv')
---------------------------------------------------------------------------------------------
modules.events =    require(gvv.defines.modules.events)
modules.player =    require(gvv.defines.modules.player)
modules.gui =       require(gvv.defines.modules.gui)
modules.commands =  require(gvv.defines.modules.commands)
---------------------------------------------------------------------------------------------
return modules
