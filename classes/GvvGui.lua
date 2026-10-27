---------------------------------------------------------------------------------------------
-- GVV GUI
---------------------------------------------------------------------------------------------
-- FR : Source : RitnLib (Ritn), classes/LuaClass/RitnGui.lua (RitnLibGui), version 0.10.7.
--      Classe de base des fenêtres de gvv, copiée et adaptée pour que gvv reste autonome.
--      Différences : l'action appelle directement une méthode de la classe (RitnLib passe par
--      remote.call, utile seulement entre mods) ; les méthodes on_gui_* renvoient true si l'évènement
--      a été traité (pour l'aiguillage de modules/gui.lua) ; tous les évènements GUI sont gérés,
--      pas seulement le clic et la sélection ; plus de condition sur la présence de la fenêtre
--      principale (le préfixe du nom suffit) ; accès protégés via check.lua.
-- EN : Source: RitnLib (Ritn), classes/LuaClass/RitnGui.lua (RitnLibGui), version 0.10.7.
--      Base class of gvv windows, copied and adapted so gvv stays standalone.
--      Differences: the action calls a class method directly (RitnLib goes through
--      remote.call, only useful between mods); on_gui_* methods return true when the event
--      was handled (for the modules/gui.lua dispatcher); every GUI event is handled,
--      not only click and selection; no more condition on the main window being present
--      (the name prefix is enough); protected accesses through check.lua.
---------------------------------------------------------------------------------------------
-- FR : Principe :
--      1. Chaque élément d'une fenêtre est nommé gui_name-type-name (voir GvvGuiElement),
--         ex. « gvv_main-button-close ».
--      2. Lors d'un évènement, le nom de l'élément est découpé en trois parties.
--      3. Si gui_name est celui de la fenêtre, l'action « type-name » (ex. « button-close »)
--         est cherchée dans self.gui_action, qui donne la méthode à appeler (ex. « action_close »).
--      Une fenêtre hérite de GvvGui, remplit self.gui, self.content et self.gui_action,
--      et écrit ses méthodes action_*.
-- EN : Principle:
--      1. Each element of a window is named gui_name-type-name (see GvvGuiElement),
--         e.g. "gvv_main-button-close".
--      2. On an event, the element name is split into three parts.
--      3. If gui_name is the window's, the action "type-name" (e.g. "button-close")
--         is looked up in self.gui_action, which gives the method to call (e.g. "action_close").
--      A window inherits from GvvGui, fills self.gui, self.content and self.gui_action,
--      and writes its action_* methods.
---------------------------------------------------------------------------------------------
local check = require(gvv.defines.lualib.common.check)
---------------------------------------------------------------------------------------------

-- FR : Format d'un nom d'élément : gui_name-type-name, aucune des trois parties ne contient de « - »
-- EN : Element name format: gui_name-type-name, none of the three parts contains "-"
local NAME_PATTERN = "^([^-]+)-([^-]+)-([^-]+)$"


---**EN**
---
---Description: Base class of gvv windows (copied from RitnLib `RitnLibGui`). Splits element names `gui_name-type-name`
---and calls the method linked to the action in `gui_action`.
---
---Extension contract: each window (sub-class) fills `gui[1]` (its container), `content` (element paths)
---and `gui_action` (action -> method), and writes its `action_*` methods.
---
---⚠ Temporary wrapper, created on each event. Do not store the instance in `storage`.
---
---──────────────────────────────
---
---**FR**
---
---Description: Classe de base des fenêtres de gvv (copiée de `RitnLibGui` de RitnLib). Découpe les noms d'éléments
---`gui_name-type-name` et appelle la méthode liée à l'action dans `gui_action`.
---
---Contrat d'extension : chaque fenêtre (sous-classe) remplit `gui[1]` (son conteneur), `content` (chemins
---des éléments) et `gui_action` (action -> méthode), et écrit ses méthodes `action_*`.
---
---⚠ Wrapper temporaire, créé à chaque évènement. Ne pas stocker l'instance dans `storage`.
---@class GvvGui : GvvPlayer
---@field object_name string                          "GvvGui" (overridden by sub-classes)
---@field event table                                 Received event (or `{player_index = ...}`)
---@field element LuaGuiElement?                      Event element
---@field gui_name string                             Window names prefix (e.g. gvv_main)
---@field main_gui string                             type-name of the root element (e.g. frame-main)
---@field gui LuaGuiElement[]                         gui[1]: window container (filled by the sub-class)
---@field content table                               Element paths from gui[1] (filled by the sub-class)
---@field gui_action table<string, string|function>   Action -> method (filled by the sub-class)
---@operator call(table, string?, string?): GvvGui
---@type GvvGui
GvvGui = gvv.classFactory.newclass(GvvPlayer, function(self, event, gui_name, main_gui)
    -- FR : Le joueur vient de l'évènement (event.player_index) ; sans évènement, pas de joueur
    -- EN : The player comes from the event (event.player_index); without event, no player
    local player = nil
    if check.isTable(event) and event.player_index then
        player = game.get_player(event.player_index)
    end

    -- FR : Initialisation de la partie joueur (classe parente GvvPlayer)
    -- EN : Initialise the player part (parent class GvvPlayer)
    GvvPlayer.init(self, player)
    self.object_name = "GvvGui"

    --------------------------------------------------
    -- FR : L'évènement reçu et l'élément concerné (nil pour un raccourci clavier, par exemple)
    -- EN : The received event and the element concerned (nil for a keyboard shortcut, for example)
    self.event = event
    self.element = check.tryGet(event, "element")

    -- FR : Identité de la fenêtre : préfixe de ses noms (ex. « gvv_main ») et élément racine (ex. « frame-main »)
    -- EN : Window identity: prefix of its names (e.g. "gvv_main") and root element (e.g. "frame-main")
    self.gui_name = check.defaultValue(gui_name, "")
    self.main_gui = check.defaultValue(main_gui, "")

    -- FR : Remplis par chaque fenêtre (classe enfant) :
    --        gui[1]     : conteneur où vit la fenêtre (ex. player.gui.screen)
    --        content    : chemins des éléments (getContent du fichier gui/)
    --        gui_action : action -> méthode à appeler
    -- EN : Filled by each window (child class):
    --        gui[1]     : container where the window lives (e.g. player.gui.screen)
    --        content    : element paths (getContent of the gui/ file)
    --        gui_action : action -> method to call
    self.gui = {}
    self.content = {}
    self.gui_action = {}
    --------------------------------------------------
end) --[[@as GvvGui]]
----------------------------------------------------------------


---**EN**
---
---Description: Splits an element name into gui_name, short type and name.
---Returns nil if the name doesn't follow the format (e.g. the old "_gvv-mod_..." names).
---
---──────────────────────────────
---
---**FR**
---
---Description: Découpe un nom d'élément en gui_name, type court et name.
---Renvoie nil si le nom ne suit pas le format (ex. les anciens noms « _gvv-mod_... »).
---@param name any
---@return string? gui_name
---@return string? short_type
---@return string? element_name
function GvvGui.splitName(name)
    -- FR : Pas un texte : rien à découper
    -- EN : Not a text: nothing to split
    if not check.isString(name) then
        return nil
    end

    -- FR : « gvv_main-button-close » donne « gvv_main », « button », « close »
    -- EN : "gvv_main-button-close" gives "gvv_main", "button", "close"
    return name:match(NAME_PATTERN)
end


---**EN**
---
---Description: Root element of the window (gui_name-main_gui inside gui[1]), or nil if it doesn't exist
---(window closed).
---
---──────────────────────────────
---
---**FR**
---
---Description: Élément racine de la fenêtre (gui_name-main_gui dans gui[1]), ou nil s'il n'existe pas
---(fenêtre fermée).
---@return LuaGuiElement?
function GvvGui:getMainElement()
    -- FR : Conteneur absent ou invalide : la fenêtre ne peut pas exister
    -- EN : Missing or invalid container: the window cannot exist
    if not check.isValidLuaObject(self.gui[1]) then
        return nil
    end

    -- FR : ex. player.gui.screen["gvv_main-frame-main"]
    -- EN : e.g. player.gui.screen["gvv_main-frame-main"]
    return check.tryGet(self.gui[1], self.gui_name .. "-" .. self.main_gui)
end


---**EN**
---
---Description: Finds an element through its path in self.content (each step is prefixed by gui_name).
---Returns nil as soon as a step is missing, without error.
---
---──────────────────────────────
---
---**FR**
---
---Description: Retrouve un élément par son chemin dans self.content (chaque étape est préfixée par gui_name).
---Renvoie nil dès qu'une étape manque, sans erreur.
---@param element_type string
---@param element_name? string
---@return LuaGuiElement?
function GvvGui:getElement(element_type, element_name)
    -- FR : Chemin de l'élément dans self.content (rempli par getContent de la fenêtre)
    --      ex. content.button.close = { "frame-main", "flow-header", "button-close" }
    -- EN : Element path in self.content (filled by the window's getContent)
    --      e.g. content.button.close = { "frame-main", "flow-header", "button-close" }
    local path
    if element_name ~= nil then
        -- FR : Élément rangé par type puis par nom : content[type][name]
        -- EN : Element sorted by type then name: content[type][name]
        path = check.getPath(self.content, {element_type, element_name})
    else
        -- FR : Élément rangé par type seulement : content[type]
        -- EN : Element sorted by type only: content[type]
        path = check.tryGet(self.content, element_type)
    end

    -- FR : Chemin inconnu : rien à chercher
    -- EN : Unknown path: nothing to look for
    if not check.isTable(path) then
        return nil
    end

    -- FR : On part du conteneur de la fenêtre (ex. player.gui.screen)
    -- EN : Start from the window container (e.g. player.gui.screen)
    local element = self.gui[1]

    -- FR : On descend étape par étape ; chaque nom en jeu est préfixé par gui_name
    --      (« frame-main » devient « gvv_main-frame-main »)
    -- EN : Go down step by step; each in-game name is prefixed by gui_name
    --      ("frame-main" becomes "gvv_main-frame-main")
    for _, name in ipairs(path) do
        element = check.tryGet(element, self.gui_name .. "-" .. name)

        -- FR : Une étape manque (fenêtre fermée, élément pas encore créé) : on s'arrête sans erreur
        -- EN : A step is missing (window closed, element not created yet): stop without error
        if element == nil then
            return nil
        end
    end

    -- FR : Élément trouvé
    -- EN : Element found
    return element
end


---**EN**
---
---Description: Calls the method linked to the action. Returns true if a method was called.
---
---──────────────────────────────
---
---**FR**
---
---Description: Appelle la méthode associée à l'action. Renvoie true si une méthode a été appelée.
---@param action string
---@return boolean
function GvvGui:actionGui(action, ...)
    -- FR : Méthode associée à l'action, ex. gui_action["button-close"] = "action_close"
    -- EN : Method linked to the action, e.g. gui_action["button-close"] = "action_close"
    local method = self.gui_action[action]

    -- FR : Action inconnue de cette fenêtre : pas traitée ici
    -- EN : Action unknown to this window: not handled here
    if method == nil then
        return false
    end

    -- FR : La méthode peut être donnée par son nom (cas habituel) ou directement par une fonction
    -- EN : The method can be given by its name (usual case) or directly as a function
    if check.isString(method) then
        method = self[method]
    end

    -- FR : Nom de méthode qui n'existe pas dans la classe : erreur de programmation, on la note dans le log
    -- EN : Method name that doesn't exist in the class: programming error, written to the log
    if type(method) ~= "function" then
        log('> ' .. self.object_name .. ':actionGui(' .. action .. ') : no method !')
        return false
    end

    -- FR : Appel de la méthode sur cette fenêtre
    -- EN : Call the method on this window
    method(self, ...)
    return true
end


---**EN**
---
---Description: Handles the event if the element belongs to this window. suffix tells apart events other
---than the click (e.g. "listbox-mods-selection_state_changed"). Returns true if the event was handled.
---
---──────────────────────────────
---
---**FR**
---
---Description: Traite l'évènement si l'élément appartient à cette fenêtre. suffix distingue les évènements autres
---que le clic (ex. « listbox-mods-selection_state_changed »). Renvoie true si l'évènement a été traité.
---@param suffix? string
---@return boolean
function GvvGui:dispatch(suffix, ...)
    -- FR : Joueur absent ou invalide : rien à faire
    -- EN : Missing or invalid player: nothing to do
    if not self.isPresent then
        return false
    end

    -- FR : Pas d'élément (raccourci clavier...) ou élément détruit : rien à faire
    -- EN : No element (keyboard shortcut...) or destroyed element: nothing to do
    if not check.isValidLuaObject(self.element) then
        return false
    end

    -- FR : Découpage du nom : « gvv_main-button-close » donne « gvv_main », « button », « close »
    -- EN : Name split: "gvv_main-button-close" gives "gvv_main", "button", "close"
    local gui_name, short_type, element_name = GvvGui.splitName(self.element.name)

    -- FR : Élément d'une autre fenêtre, ou ancien nom : pas pour nous
    -- EN : Element of another window, or old name: not for us
    if gui_name == nil or gui_name ~= self.gui_name then
        return false
    end

    -- FR : Action = type-name, suivie du suffixe de l'évènement s'il y en a un
    --      (clic : « button-close » ; sélection : « listbox-mods-selection_state_changed »)
    -- EN : Action = type-name, followed by the event suffix if any
    --      (click: "button-close"; selection: "listbox-mods-selection_state_changed")
    local action = short_type .. "-" .. element_name
    if suffix ~= nil then
        action = action .. "-" .. suffix
    end

    -- FR : Appel de la méthode associée (true si elle existe)
    -- EN : Call the linked method (true if it exists)
    return self:actionGui(action, ...)
end


---------------------------------------------------------------------------------------------
-- FR : Un point d'entrée par évènement GUI. Chacun renvoie true si l'évènement a été traité.
-- EN : One entry point per GUI event. Each returns true if the event was handled.
---------------------------------------------------------------------------------------------

---**EN**
---
---Description: Click on an element. Action without suffix (e.g. "button-close").
---
---──────────────────────────────
---
---**FR**
---
---Description: Clic sur un élément. Action sans suffixe (ex. « button-close »).
---@return boolean
function GvvGui:on_gui_click(...)
    return self:dispatch(nil, ...)
end

---**EN**
---
---Description: Element closed (Escape, or player.opened replaced). Action "type-name-closed".
---
---──────────────────────────────
---
---**FR**
---
---Description: Fermeture d'un élément (Échap, ou player.opened remplacé). Action « type-name-closed ».
---@return boolean
function GvvGui:on_gui_closed(...)
    return self:dispatch("closed", ...)
end

---**EN**
---
---Description: Text field confirmed (Enter). Action "type-name-confirmed".
---
---──────────────────────────────
---
---**FR**
---
---Description: Validation d'un champ texte (Entrée). Action « type-name-confirmed ».
---@return boolean
function GvvGui:on_gui_confirmed(...)
    return self:dispatch("confirmed", ...)
end

---**EN**
---
---Description: Slider value changed. Action "type-name-value_changed".
---
---──────────────────────────────
---
---**FR**
---
---Description: Valeur d'un curseur modifiée. Action « type-name-value_changed ».
---@return boolean
function GvvGui:on_gui_value_changed(...)
    return self:dispatch("value_changed", ...)
end

---**EN**
---
---Description: Field text changed. Action "type-name-text_changed".
---
---──────────────────────────────
---
---**FR**
---
---Description: Texte d'un champ modifié. Action « type-name-text_changed ».
---@return boolean
function GvvGui:on_gui_text_changed(...)
    return self:dispatch("text_changed", ...)
end

---**EN**
---
---Description: Checkbox or radio button changed. Action "type-name-checked_state_changed".
---
---──────────────────────────────
---
---**FR**
---
---Description: Case à cocher ou bouton radio modifié. Action « type-name-checked_state_changed ».
---@return boolean
function GvvGui:on_gui_checked_state_changed(...)
    return self:dispatch("checked_state_changed", ...)
end

---**EN**
---
---Description: Selection changed in a list or drop-down. Action "type-name-selection_state_changed".
---
---──────────────────────────────
---
---**FR**
---
---Description: Sélection modifiée dans une liste ou un menu déroulant. Action « type-name-selection_state_changed ».
---@return boolean
function GvvGui:on_gui_selection_state_changed(...)
    return self:dispatch("selection_state_changed", ...)
end

---**EN**
---
---Description: Selected tab changed. Action "type-name-selected_tab_changed".
---
---──────────────────────────────
---
---**FR**
---
---Description: Onglet sélectionné modifié. Action « type-name-selected_tab_changed ».
---@return boolean
function GvvGui:on_gui_selected_tab_changed(...)
    return self:dispatch("selected_tab_changed", ...)
end
