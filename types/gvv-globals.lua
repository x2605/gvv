---@meta
---@diagnostic disable
-- ============================================================================
-- Type-only meta file for gvv runtime globals.
-- ============================================================================
-- NOT loaded at runtime by Factorio. Sole purpose: help LuaLS resolve global
-- class references across source files (shipped in the mod zip on purpose,
-- so that mod developers get the types too).
--
-- Discipline: when you add a @field to a class in its source file, mirror it
-- here too. Keep the @operator call signatures identical.
-- ============================================================================

-- ----------------------------------------------------------------------------
-- Registry / Registre (core/defines.lua, core/setup-classes.lua)
-- ----------------------------------------------------------------------------

---@class GvvGlobal
---@field defines table
---@field classFactory GvvClassFactory
gvv = {}

-- ----------------------------------------------------------------------------
-- Session variables (outside storage) / Variables de session (hors storage)
-- control.lua, modules/events.lua
-- ----------------------------------------------------------------------------

---@type boolean
_initiated_session_ = false
---@type fun()
_on_tick_function_ = nil
---@type boolean
_one_of_three_volatiles_executed_ = false
---@type boolean
_initiated_on_tick_ = false

-- ----------------------------------------------------------------------------
-- Classes (classes/)
-- ----------------------------------------------------------------------------

---@class GvvPlayer
---@field object_name string
---@field isPresent boolean
---@field player LuaPlayer
---@field index uint
---@field name string
---@field admin boolean
---@field connected boolean
---@operator call(LuaPlayer?): GvvPlayer
GvvPlayer = {}

---@class GvvGui : GvvPlayer
---@field object_name string
---@field event table
---@field element LuaGuiElement?
---@field gui_name string
---@field main_gui string
---@field gui LuaGuiElement[]
---@field content table
---@field gui_action table<string, string|function>
---@operator call(table, string?, string?): GvvGui
GvvGui = {}

---@class GvvGuiElement
---@field object_name string
---@field gui_name string
---@field name string
---@field type string
---@field ui string
---@field action string
---@field gui_element table
---@operator call(string, string, string): GvvGuiElement
GvvGuiElement = {}

---@class GvvGuiMain : GvvGui
---@field object_name string
---@operator call(table): GvvGuiMain
GvvGuiMain = {}

---@class GvvGuiDialog : GvvGui
---@field object_name string
---@field kind string?
---@operator call(table): GvvGuiDialog
GvvGuiDialog = {}

---@class GvvGuiHelp : GvvGui
---@field object_name string
---@field specs table
---@field top LuaGuiElement?
---@field pointer LuaGuiElement? Container where elements are added
---@operator call(table): GvvGuiHelp
GvvGuiHelp = {}

---@class GvvGuiTracking : GvvGui
---@field object_name string
---@field specs table
---@field tools LuaGuiElement?
---@operator call(table): GvvGuiTracking
GvvGuiTracking = {}

---@class GvvGuiSearch : GvvGui
---@field object_name string
---@field specs table
---@field tools LuaGuiElement?
---@operator call(table): GvvGuiSearch
GvvGuiSearch = {}

---@class GvvGuiTree : GvvGui
---@field object_name string
---@field config GvvTreeConfig
---@field specs table
---@operator call(table, "storage"|"property"|"luaobject"): GvvGuiTree
GvvGuiTree = {}
