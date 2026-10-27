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
---**EN**
---
---Description: Shape of a gvv module (`modules/*.lua`), sent to `__core__/lualib/event_handler`.
---
---──────────────────────────────
---
---**FR**
---
---Description: Forme d'un module de gvv (`modules/*.lua`), envoyé à `__core__/lualib/event_handler`.
---@class GvvModule
---@field events? table<defines.events|string, fun(event: table)>   Handlers indexed by event id or custom input name
---@field on_init? fun()
---@field on_load? fun()
---@field on_configuration_changed? fun(data: ConfigurationChangedData)
---@field add_commands? fun()

---@type table<string, GvvModule>
local modules = {}
log('modules gvv')
---------------------------------------------------------------------------------------------
modules.events =    require(gvv.defines.modules.events)     -- FR : cycle de vie du mod / EN : mod life cycle
modules.player =    require(gvv.defines.modules.player)     -- FR : évènements joueurs / EN : player events
modules.gui =       require(gvv.defines.modules.gui)        -- FR : évènements GUI et raccourcis / EN : GUI events and shortcuts
modules.commands =  require(gvv.defines.modules.commands)   -- FR : commandes, paramètres du mod / EN : commands, mod settings
---------------------------------------------------------------------------------------------
return modules
