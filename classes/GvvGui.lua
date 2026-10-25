---------------------------------------------------------------------------------------------
-- GVV GUI
---------------------------------------------------------------------------------------------
-- FR : Source : RitnLib (Ritn), classes/LuaClass/RitnGui.lua (RitnLibGui), version 0.10.7.
--      Classe de base des fenêtres de gvv, copiée et adaptée pour que gvv reste autonome.
--      Principe : chaque élément est nommé gui_name-type-name (GvvGuiElement). Lors d'un évènement,
--      le nom de l'élément est découpé ; si gui_name est celui de la fenêtre, l'action type-name
--      (ex. « button-close ») est cherchée dans self.gui_action, qui donne la méthode à appeler.
--      self.gui[1] est le conteneur de la fenêtre, self.content les chemins des éléments (getContent).
--      Différences : l'action appelle directement une méthode de la classe (RitnLib passe par
--      remote.call, utile seulement entre mods) ; les méthodes on_gui_* renvoient true si l'évènement
--      a été traité (pour l'aiguillage de modules/gui.lua) ; tous les évènements GUI sont gérés,
--      pas seulement le clic et la sélection ; plus de condition sur la présence de la fenêtre
--      principale (le préfixe du nom suffit) ; accès protégés via check.lua.
-- EN : Source: RitnLib (Ritn), classes/LuaClass/RitnGui.lua (RitnLibGui), version 0.10.7.
--      Base class of gvv windows, copied and adapted so gvv stays standalone.
--      Principle: each element is named gui_name-type-name (GvvGuiElement). On an event,
--      the element name is split; if gui_name is the window's, the action type-name
--      (e.g. "button-close") is looked up in self.gui_action, which gives the method to call.
--      self.gui[1] is the window container, self.content the element paths (getContent).
--      Differences: the action calls a class method directly (RitnLib goes through
--      remote.call, only useful between mods); on_gui_* methods return true when the event
--      was handled (for the modules/gui.lua dispatcher); every GUI event is handled,
--      not only click and selection; no more condition on the main window being present
--      (the name prefix is enough); protected accesses through check.lua.
---------------------------------------------------------------------------------------------
local check = require(gvv.defines.lualib.common.check)
---------------------------------------------------------------------------------------------

-- FR : gui_name-type-name, aucune partie ne contient de « - »
-- EN : gui_name-type-name, no part contains "-"
local NAME_PATTERN = "^([^-]+)-([^-]+)-([^-]+)$"


---@class GvvGui : GvvPlayer
---@field event table          Évènement reçu / Received event
---@field element LuaGuiElement? Élément de l'évènement / Event element
---@field gui_name string      Préfixe des noms de la fenêtre (ex. gvv_main) / Window names prefix (e.g. gvv_main)
---@field main_gui string      type-name de l'élément racine (ex. frame-main) / type-name of the root element (e.g. frame-main)
---@field gui LuaGuiElement[]  gui[1] : conteneur de la fenêtre / gui[1]: window container
---@field content table        Chemins des éléments depuis gui[1] / Element paths from gui[1]
---@field gui_action table<string, string|function> Action -> méthode / Action -> method
GvvGui = gvv.classFactory.newclass(GvvPlayer, function(self, event, gui_name, main_gui)
    local player = nil
    if check.isTable(event) and event.player_index then
        player = game.get_player(event.player_index)
    end
    GvvPlayer.init(self, player)
    self.object_name = "GvvGui"
    --------------------------------------------------
    self.event = event
    self.element = check.tryGet(event, "element")
    self.gui_name = check.defaultValue(gui_name, "")
    self.main_gui = check.defaultValue(main_gui, "")
    -- FR : Remplis par chaque fenêtre / Filled by each window
    self.gui = {}
    self.content = {}
    self.gui_action = {}
    --------------------------------------------------
end)
----------------------------------------------------------------


---FR : Découpe un nom d'élément en gui_name, type court et name. Renvoie nil si le nom ne suit pas le format.
---EN : Splits an element name into gui_name, short type and name. Returns nil if the name doesn't follow the format.
---@param name any
---@return string? gui_name
---@return string? short_type
---@return string? element_name
function GvvGui.splitName(name)
    if not check.isString(name) then return nil end
    return name:match(NAME_PATTERN)
end


---FR : Élément racine de la fenêtre (gui_name-main_gui dans gui[1]), ou nil s'il n'existe pas.
---EN : Root element of the window (gui_name-main_gui inside gui[1]), or nil if it doesn't exist.
---@return LuaGuiElement?
function GvvGui:getMainElement()
    if not check.isValidLuaObject(self.gui[1]) then return nil end
    return check.tryGet(self.gui[1], self.gui_name .. "-" .. self.main_gui)
end


---FR : Retrouve un élément par son chemin dans self.content (chaque étape est préfixée par gui_name).
---     Renvoie nil dès qu'une étape manque, sans erreur.
---EN : Finds an element through its path in self.content (each step is prefixed by gui_name).
---     Returns nil as soon as a step is missing, without error.
---@param element_type string
---@param element_name? string
---@return LuaGuiElement?
function GvvGui:getElement(element_type, element_name)
    local path
    if element_name ~= nil then
        path = check.getPath(self.content, {element_type, element_name})
    else
        path = check.tryGet(self.content, element_type)
    end
    if not check.isTable(path) then return nil end
    local element = self.gui[1]
    for _, name in ipairs(path) do
        element = check.tryGet(element, self.gui_name .. "-" .. name)
        if element == nil then return nil end
    end
    return element
end


---FR : Appelle la méthode associée à l'action. Renvoie true si une méthode a été appelée.
---EN : Calls the method linked to the action. Returns true if a method was called.
---@param action string
---@return boolean
function GvvGui:actionGui(action, ...)
    local method = self.gui_action[action]
    if method == nil then return false end
    if check.isString(method) then method = self[method] end
    if type(method) ~= "function" then
        log('> ' .. self.object_name .. ':actionGui(' .. action .. ') : no method !')
        return false
    end
    method(self, ...)
    return true
end


---FR : Traite l'évènement si l'élément appartient à cette fenêtre. suffix distingue les évènements autres
---     que le clic (ex. « listbox-mods-selection_state_changed »). Renvoie true si l'évènement a été traité.
---EN : Handles the event if the element belongs to this window. suffix tells apart events other
---     than the click (e.g. "listbox-mods-selection_state_changed"). Returns true if the event was handled.
---@param suffix? string
---@return boolean
function GvvGui:dispatch(suffix, ...)
    if not self.isPresent then return false end
    if not check.isValidLuaObject(self.element) then return false end
    local gui_name, short_type, element_name = GvvGui.splitName(self.element.name)
    if gui_name == nil or gui_name ~= self.gui_name then return false end
    local action = short_type .. "-" .. element_name
    if suffix ~= nil then action = action .. "-" .. suffix end
    return self:actionGui(action, ...)
end


-- FR : Un point d'entrée par évènement GUI / EN : One entry point per GUI event
function GvvGui:on_gui_click(...) return self:dispatch(nil, ...) end
function GvvGui:on_gui_closed(...) return self:dispatch("closed", ...) end
function GvvGui:on_gui_confirmed(...) return self:dispatch("confirmed", ...) end
function GvvGui:on_gui_value_changed(...) return self:dispatch("value_changed", ...) end
function GvvGui:on_gui_text_changed(...) return self:dispatch("text_changed", ...) end
function GvvGui:on_gui_checked_state_changed(...) return self:dispatch("checked_state_changed", ...) end
function GvvGui:on_gui_selection_state_changed(...) return self:dispatch("selection_state_changed", ...) end
function GvvGui:on_gui_selected_tab_changed(...) return self:dispatch("selected_tab_changed", ...) end
