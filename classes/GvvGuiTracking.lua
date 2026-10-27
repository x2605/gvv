---------------------------------------------------------------------------------------------
-- GVV GUI TRACKING
---------------------------------------------------------------------------------------------
-- FR : Onglet suivi de variables de gvv (étape 3.4 de la restructuration 0.6).
--      Construit l'onglet (dans gvv_main-flow-tracking) et ses outils (dans gvv_main-flow-tools),
--      gère les entrées du suivi (ajout, affichage, suppression, déplacement, cases à cocher, export,
--      import, modification) et le rafraîchissement des valeurs (bouton, Shift+X, on_tick).
--      Comportement repris de l'ancien code (legacy/tracking.lua, legacy/gui_event.lua), sans changement.
--      Le code d'une entrée est rangé dans ses tags (tags.path), et non plus dans son nom.
--      La liste des entrées reste dans les données du joueur : data.data.tracking_list[code] = chemin.
--      Description des éléments : gui/tracking.lua.
-- EN : gvv variable tracking tab (step 3.4 of the 0.6 restructuring).
--      Builds the tab (inside gvv_main-flow-tracking) and its tools (inside gvv_main-flow-tools),
--      handles the tracking entries (add, display, removal, moving, checkboxes, export,
--      import, edit) and the values refresh (button, Shift+X, on_tick).
--      Behaviour taken from the old code (legacy/tracking.lua, legacy/gui_event.lua), unchanged.
--      An entry code is stored in its tags (tags.path), no longer in its name.
--      The entries list stays in the player data: data.data.tracking_list[code] = path.
--      Elements description: gui/tracking.lua.
---------------------------------------------------------------------------------------------
local check = require(gvv.defines.lualib.common.check)
local Util = require(gvv.defines.lualib.common.util)
local Table_to_str = require(gvv.defines.lualib.common.table_to_str)
local fGui = require(gvv.defines.gui.tracking)
---------------------------------------------------------------------------------------------

-- FR : Codes d'exemple ajoutés à la première ouverture de gvv (sans liste par défaut dans les paramètres)
-- EN : Example codes added the first time gvv is opened (without default list in the settings)
local EXAMPLE_CODES = {
    '-- evolution factor --\nassert(function()\n  return game.forces.enemy.get_evolution_factor()\nend)()',
    '1+1 .. "   " .. tostring(game.tick) .. "   " .. util.formattime(game.ticks_played) --see __core__/lualib/util.lua for informations',
    '-- arithmetic sequence --\nassert(function()\n  local a = 0\n  for i = 0, 10 do\n    a = a + i\n  end\n  return a\nend)()',
}

-- FR : Couleurs de la valeur affichée : normale, ou erreur (orange)
-- EN : Displayed value colours: normal, or error (orange)
local COLOR_VALUE = {1, 1, 1}
local COLOR_ERROR = { r = 1.000, g = 0.630, b = 0.259 }

-- FR : Couleur de l'intervalle quand on_tick est désactivé dans les paramètres du mod (rouge)
-- EN : Interval colour when on_tick is disabled in the mod settings (red)
local COLOR_TICK_OFF = {1, 0.25, 0.25}


---**EN**
---
---Description: Variable tracking tab ("gvv_tracking") and its tools: entries (Lua codes evaluated again at each
---refresh), moving, removing, export / import, automatic refresh (on_tick).
---
---⚠ Temporary wrapper, created on each event. Do not store the instance in `storage`.
---
---──────────────────────────────
---
---**FR**
---
---Description: Onglet suivi de variables (« gvv_tracking ») et ses outils : entrées (codes Lua réévalués à chaque
---rafraîchissement), déplacement, suppression, export / import, rafraîchissement automatique (on_tick).
---
---⚠ Wrapper temporaire, créé à chaque évènement. Ne pas stocker l'instance dans `storage`.
---@class GvvGuiTracking : GvvGui
---@field object_name string     "GvvGuiTracking"
---@field specs table            Elements description (gui/tracking.lua)
---@field tools LuaGuiElement?   Main window toolbar (gvv_main-flow-tools)
---@operator call(table): GvvGuiTracking
---@type GvvGuiTracking
GvvGuiTracking = gvv.classFactory.newclass(GvvGui, function(self, event)
    -- FR : Onglet « gvv_tracking », dont l'élément racine est « flow-wrap » (gvv_tracking-flow-wrap)
    -- EN : "gvv_tracking" tab, whose root element is "flow-wrap" (gvv_tracking-flow-wrap)
    GvvGui.init(self, event, fGui.GUI_NAME, "flow-wrap")
    self.object_name = "GvvGuiTracking"

    --------------------------------------------------
    -- FR : Deux conteneurs dans la fenêtre principale (nil si elle est fermée) :
    --      le contenu de l'onglet suivi, et la barre d'outils
    -- EN : Two containers in the main window (nil if it is closed):
    --      the tracking tab content, and the toolbar
    if self.isPresent then
        local main = GvvGuiMain(event)
        self.gui = { main:getElement("content", "tracking") }
        self.tools = main:getElement("flow", "tools")
    end

    -- FR : Chemins et description des éléments (gui/tracking.lua)
    -- EN : Element paths and description (gui/tracking.lua)
    self.content = fGui.getContent()
    self.specs = fGui.getElement(self.gui_name)

    -- FR : Actions de l'onglet et de ses outils
    -- EN : Tab and tools actions
    self.gui_action = {
        ["button-refresh"] = "action_refresh",                          -- FR : rafraîchir / EN : refresh
        ["slider-interval-value_changed"] = "action_interval_slider",   -- FR : curseur de l'intervalle / EN : interval slider
        ["label-interval"] = "action_interval_edit",                    -- FR : clic sur l'intervalle / EN : click on the interval
        ["textfield-interval-confirmed"] = "action_interval_confirm",   -- FR : intervalle saisi / EN : interval typed
        ["button-remove"] = "action_remove",                            -- FR : supprimer (demande confirmation) / EN : remove (asks confirmation)
        ["button-confirm_remove"] = "action_confirm_remove",            -- FR : confirmer la suppression / EN : confirm removal
        ["button-cancel_remove"] = "action_cancel_remove",              -- FR : annuler la suppression / EN : cancel removal
        ["button-up"] = "action_move",                                  -- FR : monter / EN : move up
        ["button-down"] = "action_move",                                -- FR : descendre / EN : move down
        ["button-check"] = "action_check",                              -- FR : cases à cocher / EN : checkboxes
        ["button-export_import"] = "action_export_import",              -- FR : exporter / importer / EN : export / import
        ["label-path"] = "action_copy_path",                            -- FR : code d'une entrée / EN : entry code
        ["label-output"] = "action_copy_output",                        -- FR : valeur d'une entrée / EN : entry value
    }
    --------------------------------------------------
end) --[[@as GvvGuiTracking]]
----------------------------------------------------------------


---------------------------------------------------------------------------------------------
-- FR : ACCÈS AUX ÉLÉMENTS
-- EN : ELEMENTS ACCESS
---------------------------------------------------------------------------------------------

---**EN**
---
---Description: Toolbar tool, by its "type-name" part (e.g. "button-refresh"), or nil.
---The confirmation buttons are inside the frame-confirm frame.
---
---──────────────────────────────
---
---**FR**
---
---Description: Outil de la barre d'outils, par sa partie « type-name » (ex. « button-refresh »), ou nil.
---Les boutons de confirmation sont dans le cadre frame-confirm.
---@param type_name string
---@return LuaGuiElement?
function GvvGuiTracking:getTool(type_name)
    -- FR : Boutons de confirmation : un niveau plus bas, dans frame-confirm
    -- EN : Confirmation buttons: one level lower, inside frame-confirm
    if type_name == "button-confirm_remove" or type_name == "button-cancel_remove" then
        local frame = check.tryGet(self.tools, self.gui_name .. "-frame-confirm")
        return check.tryGet(frame, self.gui_name .. "-" .. type_name)
    end
    return check.tryGet(self.tools, self.gui_name .. "-" .. type_name)
end


---**EN**
---
---Description: Panel that holds the tracking entries, or nil (window closed).
---
---──────────────────────────────
---
---**FR**
---
---Description: Panneau qui contient les entrées du suivi, ou nil (fenêtre fermée).
---@return LuaGuiElement?
function GvvGuiTracking:getPanel()
    return self:getElement("flow", "panel")
end


---**EN**
---
---Description: Tracking entries, in display order: { element, path (code), checked (checked box), value (displayed value) }.
---
---──────────────────────────────
---
---**FR**
---
---Description: Entrées du suivi, dans l'ordre affiché : { element, path (code), checked (case cochée), value (valeur affichée) }.
---@return table[]
function GvvGuiTracking:getEntries()
    local entries = {}
    local panel = self:getPanel()
    if panel == nil then
        return entries
    end
    for _, element in ipairs(panel.children) do
        entries[#entries + 1] = {
            element = element,
            path = element.tags.path,
            checked = self:getEntryCheckbox(element).state,
            value = self:getEntryOutput(element).caption,
        }
    end
    return entries
end


---**EN**
---
---Description: Checkbox of an entry.
---
---──────────────────────────────
---
---**FR**
---
---Description: Case à cocher d'une entrée.
---@param entry LuaGuiElement
---@return LuaGuiElement
function GvvGuiTracking:getEntryCheckbox(entry)
    return entry[self.gui_name .. "-flow-header"][self.gui_name .. "-checkbox-remove"]
end


---**EN**
---
---Description: Value label of an entry.
---
---──────────────────────────────
---
---**FR**
---
---Description: Label de la valeur d'une entrée.
---@param entry LuaGuiElement
---@return LuaGuiElement
function GvvGuiTracking:getEntryOutput(entry)
    return entry[self.gui_name .. "-flow-body"][self.gui_name .. "-label-output"]
end


---**EN**
---
---Description: Entry that contains the element (walking up to the panel), or nil.
---
---──────────────────────────────
---
---**FR**
---
---Description: Entrée qui contient l'élément (en remontant jusqu'au panneau), ou nil.
---@param element LuaGuiElement
---@return LuaGuiElement?
function GvvGuiTracking:findEntry(element)
    local panel = self:getPanel()
    local current = element
    while check.isValidLuaObject(current) and check.isValidLuaObject(current.parent) do
        if current.parent == panel then
            return current
        end
        current = current.parent
    end
    return nil
end


---**EN**
---
---Description: True if the element is inside the scrolling area of the tracking tab.
---
---──────────────────────────────
---
---**FR**
---
---Description: Vrai si l'élément est dans la zone défilante de l'onglet suivi.
---@param element LuaGuiElement
---@return boolean
function GvvGuiTracking:isInTab(element)
    local scroll = self:getElement("pane", "scroll")
    local current = element
    while check.isValidLuaObject(current) do
        if current == scroll then
            return true
        end
        current = current.parent
    end
    return false
end


---**EN**
---
---Description: True if the tracking tab is the displayed tab.
---
---──────────────────────────────
---
---**FR**
---
---Description: Vrai si l'onglet suivi est l'onglet affiché.
---@return boolean
function GvvGuiTracking:isTabSelected()
    local tabbed = GvvGuiMain(self.event):getElement("tabbed", "tabs")
    return tabbed ~= nil and tabbed.selected_tab_index == 1
end


---------------------------------------------------------------------------------------------
-- FR : CONSTRUCTION
-- EN : BUILDING
---------------------------------------------------------------------------------------------

---**EN**
---
---Description: Builds the tools (toolbar) and the tab, then shows the entries. Called by GvvGuiMain:open.
---first_time: first time this player opens gvv (default list or examples).
---
---──────────────────────────────
---
---**FR**
---
---Description: Construit les outils (barre d'outils) et l'onglet, puis affiche les entrées. Appelé par GvvGuiMain:open.
---first_time : première ouverture de gvv par ce joueur (liste par défaut ou exemples).
---@param first_time boolean
---@return GvvGuiTracking
function GvvGuiTracking:build(first_time)
    -- FR : Conteneurs absents (fenêtre principale fermée) : rien à construire
    -- EN : Missing containers (main window closed): nothing to build
    if not check.isValidLuaObject(self.gui[1]) or not check.isValidLuaObject(self.tools) then
        return self
    end
    self:buildTools()
    self:buildTab()
    self:fillEntries(first_time)
    return self
end


---**EN**
---
---Description: Tracking tools inside the toolbar (taken from the old Gui.build_tools).
---
---──────────────────────────────
---
---**FR**
---
---Description: Outils du suivi dans la barre d'outils (repris de l'ancien Gui.build_tools).
function GvvGuiTracking:buildTools()
    local data = self:getData()
    local specs = self.specs
    local tools = self.tools

    -- FR : Bouton rafraîchir
    -- EN : Refresh button
    local refresh = tools.add(specs.button.refresh)
    refresh.style.width = 20
    refresh.style.height = 20

    -- FR : Intervalle : curseur, nombre affiché (clic pour le saisir), saisie cachée
    -- EN : Interval: slider, displayed number (click to type it), hidden input
    specs.slider.interval.value = data.track_interval_tick
    local slider = tools.add(specs.slider.interval)
    slider.style.width = 70

    specs.label.interval.caption = data.track_interval_tick
    tools.add(specs.label.interval)
    self:updateTickWarning()

    specs.textfield.interval.text = tostring(data.track_interval_tick)
    local edit = tools.add(specs.textfield.interval)
    edit.style.width = 30
    edit.style.height = 20
    edit.style.right_margin = 5

    -- FR : Bouton supprimer, et son cadre de confirmation (posé par-dessus, caché)
    -- EN : Remove button, and its confirmation frame (laid over it, hidden)
    local remove = tools.add(specs.button.remove)
    remove.style.left_margin = 8
    remove.style.width = 20
    remove.style.height = 20

    local confirm = tools.add(specs.frame.confirm)
    confirm.style.padding = 0
    confirm.style.width = 48
    confirm.style.left_margin = -50
    confirm.style.right_margin = -4
    confirm.style.top_margin = -1
    confirm.style.bottom_margin = -15
    local confirm_remove = confirm.add(specs.button.confirm_remove)
    confirm_remove.style.width = 18
    confirm_remove.style.height = 18
    local cancel_remove = confirm.add(specs.button.cancel_remove)
    cancel_remove.style.width = 18
    cancel_remove.style.height = 18

    -- FR : Monter, descendre, cases à cocher, exporter / importer
    -- EN : Move up, move down, checkboxes, export / import
    local up = tools.add(specs.button.up)
    up.style.left_margin = 8
    up.style.width = 20
    up.style.height = 20
    local down = tools.add(specs.button.down)
    down.style.left_margin = -3
    down.style.width = 20
    down.style.height = 20
    local check_button = tools.add(specs.button.check)
    check_button.style.left_margin = 2
    check_button.style.width = 20
    check_button.style.height = 20
    local export_import = tools.add(specs.button.export_import)
    export_import.style.left_margin = 2
    export_import.style.width = 20
    export_import.style.height = 20
end


---**EN**
---
---Description: Tab content: background strip, scrolling area, entries panel (taken from the old Gui.build_tracking).
---
---──────────────────────────────
---
---**FR**
---
---Description: Contenu de l'onglet : bande de fond, zone défilante, panneau des entrées (repris de l'ancien Gui.build_tracking).
function GvvGuiTracking:buildTab()
    local wrap = self.gui[1].add(self.specs.flow.wrap)
    local fill = wrap.add(self.specs.empty.fill)
    fill.style.height = 8

    local scroll = wrap.add(self.specs.pane.scroll)
    local panel = scroll.add(self.specs.flow.panel)
    panel.style.vertical_spacing = 0
    panel.style.horizontally_stretchable = true
    panel.style.vertically_stretchable = true
end


---**EN**
---
---Description: Shows the entries: on first opening, the default list from the settings or the examples;
---otherwise the player's list (taken from the old Gui.fill_tracking).
---
---──────────────────────────────
---
---**FR**
---
---Description: Affiche les entrées : à la première ouverture, la liste par défaut des paramètres ou les exemples ;
---sinon la liste du joueur (repris de l'ancien Gui.fill_tracking).
---@param first_time boolean
function GvvGuiTracking:fillEntries(first_time)
    local data = self:getData()

    if first_time and storage.meta_data.default_tracking_list then
        -- FR : Liste par défaut des paramètres du mod ; une entrée en erreur est signalée sans bloquer les autres
        -- EN : Default list from the mod settings; an entry in error is reported without blocking the others
        data.data.tracking_list = Util.deepcopytbl(storage.meta_data.default_tracking_list)
        for path_str, full_path in pairs(data.data.tracking_list) do
            local drawn, message = pcall(self.drawEntry, self, path_str, full_path)
            if not drawn then
                -- FR : Erreur écrite dans le log, puis affichée au joueur
                -- EN : Error written to the log, then shown to the player
                log('[ERROR] gvv tracking : ' .. path_str .. ' : ' .. tostring(message))
                self.player.print('[font=var-outline-gvv-mod]error caused when adding codes first time : ' .. path_str .. '\n' .. message .. '[/font]', {1, 0.85, 0.7, 1})
            end
        end
    elseif first_time then
        -- FR : Exemples (protégés, comme avant)
        -- EN : Examples (protected, as before)
        pcall(function()
            for _, code in ipairs(EXAMPLE_CODES) do
                self:add(code)
            end
        end)
    else
        -- FR : Liste du joueur
        -- EN : Player's list
        for path_str, full_path in pairs(data.data.tracking_list) do
            self:drawEntry(path_str, full_path)
        end
    end
end


---**EN**
---
---Description: Draws an entry at the end of the panel (taken from the old Tracking.draw).
---full_path: path in the tree (table) or Lua code (text). preinput: state to take back
---{ remchk = checked box, value = displayed value } (moving, edit).
---
---──────────────────────────────
---
---**FR**
---
---Description: Dessine une entrée à la fin du panneau (repris de l'ancien Tracking.draw).
---full_path : chemin dans l'arbre (table) ou code Lua (texte). preinput : état à reprendre
---{ remchk = case cochée, value = valeur affichée } (déplacement, modification).
---@param path_str string
---@param full_path table|string
---@param preinput? table
function GvvGuiTracking:drawEntry(path_str, full_path, preinput)
    local specs = self.specs

    -- FR : Entrée sans nom, son code dans ses tags
    -- EN : Unnamed entry, its code in its tags
    specs.flow.entry.tags = { path = path_str }
    local entry = self:getPanel().add(specs.flow.entry)

    -- FR : En-tête : case à cocher, nom de la clé (entrée venant de l'arbre), code
    -- EN : Header: checkbox, key name (entry coming from the tree), code
    local header = entry.add(specs.flow.header)
    header.style.vertical_align = 'center'
    header.style.left_padding = 6
    header.style.horizontal_spacing = 6
    local checkbox = header.add(specs.checkbox.remove)

    if type(full_path) == 'table' then
        -- FR : Nom de la clé : objet global (« *game ») ou dernière clé du chemin
        -- EN : Key name: global object ("*game") or last key of the path
        local caption
        if #full_path == 1 and full_path[1]:match('^[*]') then
            caption = full_path[1]:gsub('^[*]', '') .. ' :'
        else
            caption = Table_to_str.key_to_str(full_path[#full_path]) .. ' :'
        end
        specs.label.key.caption = caption
        local key = header.add(specs.label.key)
        key.style.font_color = {0.6, 0.8, 1, 1}
    elseif type(full_path) ~= 'string' then
        error('full_path is not table nor string')
    end

    specs.label.path.caption = path_str
    local path = header.add(specs.label.path)
    path.style.font_color = {0.75, 0.75, 0.75, 1}

    -- FR : Corps : « = » et la valeur
    -- EN : Body: "=" and the value
    local body = entry.add(specs.flow.body)
    body.style.vertical_align = 'center'
    body.style.left_padding = 6
    body.style.horizontal_spacing = 6
    body.add(specs.label.equal)
    local output = body.add(specs.label.output)
    output.style.font = 'default-bold'

    -- FR : État repris (déplacement, modification)
    -- EN : Taken back state (moving, edit)
    if check.isTable(preinput) and check.isString(preinput.value) and type(preinput.remchk) == 'boolean' then
        checkbox.state = preinput.remchk
        output.caption = preinput.value
    end

    -- FR : Séparateur
    -- EN : Separator
    entry.add{ type = 'line', direction = 'horizontal' }
end


---------------------------------------------------------------------------------------------
-- FR : GESTION DES ENTRÉES (aussi utilisée par l'arbre et les petites fenêtres)
-- EN : ENTRIES HANDLING (also used by the tree and the small windows)
---------------------------------------------------------------------------------------------

---**EN**
---
---Description: Adds an entry to the tracking, if it isn't already there (taken from the old Tracking.add).
---full_path: path in the tree (table) or Lua code (text).
---
---──────────────────────────────
---
---**FR**
---
---Description: Ajoute une entrée au suivi, si elle n'y est pas déjà (repris de l'ancien Tracking.add).
---full_path : chemin dans l'arbre (table) ou code Lua (texte).
---@param full_path table|string
---@param preinput? table
---@return GvvGuiTracking
function GvvGuiTracking:add(full_path, preinput)
    local data = self:getData()
    if data == nil or self:getPanel() == nil then
        return self
    end

    -- FR : Code de l'entrée : chemin écrit en Lua, ou le code tel quel
    -- EN : Entry code: path written in Lua, or the code as is
    local path_str
    if type(full_path) == 'table' then
        path_str = Table_to_str.path_to_lua_prop_path(full_path, true)
    elseif type(full_path) == 'string' then
        path_str = full_path
    else
        error('full_path is not table nor string')
    end

    -- FR : Déjà suivie : rien à faire
    -- EN : Already tracked: nothing to do
    if data.data.tracking_list[path_str] ~= nil then
        return self
    end

    self:drawEntry(path_str, full_path, preinput)
    data.data.tracking_list[path_str] = full_path
    return self
end


---**EN**
---
---Description: Removes all entries then draws them again in the given order (list from getEntries).
---
---──────────────────────────────
---
---**FR**
---
---Description: Supprime toutes les entrées puis les redessine dans l'ordre donné (liste de getEntries).
---@param entries table[]
function GvvGuiTracking:redraw(entries)
    local list = self:getData().data.tracking_list
    for _, entry in ipairs(self:getEntries()) do
        entry.element.destroy()
    end
    for _, entry in ipairs(entries) do
        self:drawEntry(entry.path, list[entry.path], { remchk = entry.checked, value = entry.value })
    end
end


---**EN**
---
---Description: Replaces the code of an entry, keeping its place in the list (edit window).
---
---──────────────────────────────
---
---**FR**
---
---Description: Remplace le code d'une entrée, en gardant sa place dans la liste (fenêtre de modification).
---@param old_path string
---@param new_code string
function GvvGuiTracking:replaceEntry(old_path, new_code)
    local list = self:getData().data.tracking_list

    -- FR : Les entrées après l'entrée modifiée sont mises de côté, puis retirées ; l'entrée modifiée est retirée
    -- EN : The entries after the edited entry are set aside, then removed; the edited entry is removed
    local after = {}
    local found = false
    for _, entry in ipairs(self:getEntries()) do
        if found then
            after[#after + 1] = entry
            entry.element.destroy()
        elseif entry.path == old_path then
            list[entry.path] = nil
            entry.element.destroy()
            found = true
        end
    end

    -- FR : Nouveau code ajouté, puis les entrées mises de côté redessinées après lui
    -- EN : New code added, then the entries set aside drawn again after it
    self:add(new_code)
    for _, entry in ipairs(after) do
        self:drawEntry(entry.path, list[entry.path], { remchk = entry.checked, value = entry.value })
    end
end


---**EN**
---
---Description: Imports a list of codes: already tracked codes are checked, new ones added and checked,
---the others unchecked. Returns the number of new codes and of codes already present.
---
---──────────────────────────────
---
---**FR**
---
---Description: Importe une liste de codes : les codes déjà suivis sont cochés, les nouveaux ajoutés et cochés,
---les autres décochés. Renvoie le nombre de nouveaux codes et de codes déjà présents.
---@param codes string[]
---@return integer new_count
---@return integer duplicate_count
function GvvGuiTracking:importCodes(codes)
    local existing = self:getEntries()
    local new_count, duplicate_count = 0, 0

    -- FR : Toutes les entrées existantes sont décochées
    -- EN : All existing entries are unchecked
    for _, entry in ipairs(existing) do
        self:getEntryCheckbox(entry.element).state = false
    end

    -- FR : Chaque code : déjà présent -> l'entrée est cochée ; nouveau -> ajouté
    -- EN : Each code: already present -> the entry is checked; new -> added
    for _, code in ipairs(codes) do
        local duplicate = false
        for _, entry in ipairs(existing) do
            if entry.path == code then
                duplicate = true
                self:getEntryCheckbox(entry.element).state = true
                duplicate_count = duplicate_count + 1
                break
            end
        end
        if not duplicate then
            self:add(code)
            new_count = new_count + 1
        end
    end

    -- FR : Les nouvelles entrées (après les existantes) sont cochées
    -- EN : The new entries (after the existing ones) are checked
    local entries = self:getEntries()
    for index = #existing + 1, #entries do
        self:getEntryCheckbox(entries[index].element).state = true
    end
    return new_count, duplicate_count
end


---**EN**
---
---Description: Entries codes in display order, separated by "--[[]]--" (export window).
---
---──────────────────────────────
---
---**FR**
---
---Description: Codes des entrées dans l'ordre affiché, séparés par « --[[]]-- » (fenêtre d'export).
---@return string
function GvvGuiTracking:exportText()
    local text = ''
    for _, entry in ipairs(self:getEntries()) do
        text = text .. entry.path .. '\n--[[]]--\n'
    end
    return text
end


---------------------------------------------------------------------------------------------
-- FR : VALEURS
-- EN : VALUES
---------------------------------------------------------------------------------------------

---**EN**
---
---Description: Computes again the value of each entry (taken from the old Tracking.refresh_value).
---An entry in error shows the message in orange.
---
---──────────────────────────────
---
---**FR**
---
---Description: Recalcule la valeur de chaque entrée (repris de l'ancien Tracking.refresh_value).
---Une entrée en erreur affiche le message en orange.
---@return GvvGuiTracking
function GvvGuiTracking:refreshValues()
    local data = self:getData()
    if data == nil then
        return self
    end
    local list = data.data.tracking_list
    for _, entry in ipairs(self:getEntries()) do
        local output = self:getEntryOutput(entry.element)
        local full_path = list[entry.path]

        -- FR : Valeur : par son chemin dans l'arbre (table) ou en exécutant le code (texte)
        -- EN : Value: through its path in the tree (table) or by running the code (text)
        local computed, value = pcall(function()
            if type(full_path) == 'table' then
                return GvvGuiTree.readFullPath(full_path)
            elseif type(full_path) == 'string' then
                return assert(loadstring('return ' .. full_path))()
            end
            error('full_path is not table nor string')
        end)

        if computed then
            output.caption = Table_to_str.value_to_str(value)
            output.style.font_color = COLOR_VALUE
            output.tooltip = {"gvv-mod.right-to-copy-code"}
        else
            output.caption = value
            output.tooltip = value
            output.style.font_color = COLOR_ERROR
        end
    end
    return self
end


---**EN**
---
---Description: Automatic refresh (on_tick): for each connected player whose gvv is open on the tracking tab,
---at their interval. Registered or removed according to the mod "on_tick" setting.
---
---──────────────────────────────
---
---**FR**
---
---Description: Rafraîchissement automatique (on_tick) : pour chaque joueur connecté dont gvv est ouvert sur
---l'onglet suivi, à son intervalle. Enregistré ou retiré selon le paramètre « on_tick » du mod.
function GvvGuiTracking.onTick()
    if not storage.players then
        return
    end
    for _, player in pairs(game.connected_players) do
        local data = storage.players[player.index]
        if data and game.tick % data.track_interval_tick == 0 then
            local tracking = GvvGuiTracking({ player_index = player.index })
            if tracking:getPanel() ~= nil and tracking:isTabSelected() then
                tracking:refreshValues()
            end
        end
    end
end


---**EN**
---
---Description: Interval number colour: red if on_tick is disabled (mod setting), otherwise white.
---
---──────────────────────────────
---
---**FR**
---
---Description: Couleur du nombre de l'intervalle : rouge si on_tick est désactivé (paramètre du mod), sinon blanc.
---@return GvvGuiTracking
function GvvGuiTracking:updateTickWarning()
    local label = self:getTool("label-interval")
    if label == nil then
        return self
    end
    if script.get_event_handler(defines.events.on_tick) then
        label.style.font_color = {1, 1, 1}
        label.tooltip = {"gvv-mod.track-interval-control"}
    else
        label.style.font_color = COLOR_TICK_OFF
        label.tooltip = {"gvv-mod.track-interval-control-off"}
    end
    return self
end


---**EN**
---
---Description: Tracking tools visible only on the tracking tab (index 1). Called on each tab change.
---
---──────────────────────────────
---
---**FR**
---
---Description: Outils du suivi visibles seulement sur l'onglet suivi (index 1). Appelé à chaque changement d'onglet.
---@param tab_index integer
---@return GvvGuiTracking
function GvvGuiTracking:updateTools(tab_index)
    local visible = tab_index == 1
    for _, type_name in ipairs({"button-refresh", "slider-interval", "label-interval", "button-remove",
                                "button-up", "button-down", "button-check", "button-export_import"}) do
        local tool = self:getTool(type_name)
        if tool ~= nil then
            tool.visible = visible
        end
    end
    -- FR : Saisie de l'intervalle et confirmation de suppression : toujours cachées au changement d'onglet
    -- EN : Interval input and removal confirmation: always hidden on tab change
    local edit = self:getTool("textfield-interval")
    if edit ~= nil then
        edit.visible = false
    end
    local confirm = self:getTool("frame-confirm")
    if confirm ~= nil then
        confirm.visible = false
    end
    return self
end


---------------------------------------------------------------------------------------------
-- FR : CLIC (avant et après les actions)
-- EN : CLICK (before and after the actions)
---------------------------------------------------------------------------------------------

---**EN**
---
---Description: Click: first what the old code did on each click (confirm the interval being typed,
---hide the removal confirmation), then the actions; finally, inside the tracking tab,
---right click on empty space: code input; middle click on an entry: check / uncheck.
---
---──────────────────────────────
---
---**FR**
---
---Description: Clic : d'abord ce que l'ancien code faisait à chaque clic (valider l'intervalle en cours de saisie,
---cacher la confirmation de suppression), puis les actions ; enfin, dans l'onglet suivi,
---clic droit dans le vide : saisie d'un code ; clic molette sur une entrée : cocher / décocher.
---@return boolean
function GvvGuiTracking:on_gui_click(...)
    -- FR : Onglet suivi absent (fenêtre fermée) : rien à faire
    -- EN : Missing tracking tab (window closed): nothing to do
    if not self.isPresent or self:getPanel() == nil then
        return false
    end

    -- FR : Intervalle en cours de saisie : un clic ailleurs le valide
    -- EN : Interval being typed: a click elsewhere confirms it
    local edit = self:getTool("textfield-interval")
    if edit ~= nil and edit.visible and self.element ~= edit then
        self:applyIntervalInput()
    end

    -- FR : Confirmation de suppression affichée : un clic ailleurs la cache
    -- EN : Removal confirmation shown: a click elsewhere hides it
    local confirm = self:getTool("frame-confirm")
    if confirm ~= nil and confirm.visible and self.element ~= self:getTool("button-remove") and self.element ~= confirm then
        confirm.visible = false
    end

    -- FR : Actions des éléments nommés
    -- EN : Named elements actions
    if self:dispatch(nil, ...) then
        return true
    end

    -- FR : Clic dans l'onglet suivi, sur l'onglet affiché
    -- EN : Click inside the tracking tab, on the displayed tab
    if not self:isInTab(self.element) or not self:isTabSelected() then
        return false
    end
    if self.event.button == defines.mouse_button_type.right then
        -- FR : Clic droit dans le vide : fenêtre de saisie d'un code
        -- EN : Right click on empty space: code input window
        GvvGuiDialog(self.event):openAnycode()
        return true
    elseif self.event.button == defines.mouse_button_type.middle then
        -- FR : Clic molette sur une entrée : sa case est cochée / décochée
        -- EN : Middle click on an entry: its box is checked / unchecked
        local entry = self:findEntry(self.element)
        if entry ~= nil then
            local checkbox = self:getEntryCheckbox(entry)
            checkbox.state = not checkbox.state
        end
        return true
    end
    return false
end


---------------------------------------------------------------------------------------------
-- FR : ACTIONS
-- EN : ACTIONS
---------------------------------------------------------------------------------------------

---**EN**
---
---Description: Refresh button.
---
---──────────────────────────────
---
---**FR**
---
---Description: Bouton rafraîchir.
function GvvGuiTracking:action_refresh()
    self:refreshValues()
end


---**EN**
---
---Description: Interval slider: new interval, shown next to it.
---
---──────────────────────────────
---
---**FR**
---
---Description: Curseur de l'intervalle : nouvel intervalle, affiché à côté.
function GvvGuiTracking:action_interval_slider()
    local data = self:getData()
    data.track_interval_tick = self.element.slider_value
    self:getTool("label-interval").caption = data.track_interval_tick
end


---**EN**
---
---Description: Left click on the interval number: it is replaced by the input.
---
---──────────────────────────────
---
---**FR**
---
---Description: Clic gauche sur le nombre de l'intervalle : il est remplacé par la saisie.
function GvvGuiTracking:action_interval_edit()
    if self.event.button ~= defines.mouse_button_type.left then
        return
    end
    local data = self:getData()
    local edit = self:getTool("textfield-interval")
    self.element.visible = false
    edit.visible = true
    edit.text = data.track_interval_tick .. ''
    edit.focus()
    edit.select_all()
end


---**EN**
---
---Description: Interval typed then Enter.
---
---──────────────────────────────
---
---**FR**
---
---Description: Intervalle saisi puis Entrée.
function GvvGuiTracking:action_interval_confirm()
    self:applyIntervalInput()
end


---**EN**
---
---Description: Applies the typed interval (1 at least), hides the input and updates the number and the slider.
---
---──────────────────────────────
---
---**FR**
---
---Description: Applique l'intervalle saisi (1 au minimum), cache la saisie et met à jour le nombre et le curseur.
function GvvGuiTracking:applyIntervalInput()
    local data = self:getData()
    local edit = self:getTool("textfield-interval")
    local label = self:getTool("label-interval")
    local slider = self:getTool("slider-interval")

    -- FR : Valeur saisie (champ vide : intervalle inchangé), 1 au minimum
    -- EN : Typed value (empty field: interval unchanged), 1 at least
    if edit.text ~= '' then
        data.track_interval_tick = tonumber(edit.text) or data.track_interval_tick
    end
    if data.track_interval_tick < 1 then
        data.track_interval_tick = 1
    end

    -- FR : Retour à l'affichage du nombre (seulement sur l'onglet suivi)
    -- EN : Back to showing the number (only on the tracking tab)
    edit.visible = false
    if self:isTabSelected() then
        label.visible = true
    end
    label.caption = data.track_interval_tick
    slider.slider_value = data.track_interval_tick
end


---**EN**
---
---Description: Remove button: shows or hides the confirmation.
---
---──────────────────────────────
---
---**FR**
---
---Description: Bouton supprimer : affiche ou cache la confirmation.
function GvvGuiTracking:action_remove()
    local confirm = self:getTool("frame-confirm")
    confirm.visible = not confirm.visible
end


---**EN**
---
---Description: Confirmation: removes the checked entries.
---
---──────────────────────────────
---
---**FR**
---
---Description: Confirmation : supprime les entrées cochées.
function GvvGuiTracking:action_confirm_remove()
    local list = self:getData().data.tracking_list
    for _, entry in ipairs(self:getEntries()) do
        if entry.checked then
            list[entry.path] = nil
            entry.element.destroy()
        end
    end
end


---**EN**
---
---Description: Cancel: hides the confirmation.
---
---──────────────────────────────
---
---**FR**
---
---Description: Annulation : cache la confirmation.
function GvvGuiTracking:action_cancel_remove()
    self:getTool("frame-confirm").visible = false
end


---**EN**
---
---Description: Move the checked entries up / down: left click by one step, right click to the top / bottom.
---
---──────────────────────────────
---
---**FR**
---
---Description: Monter / descendre les entrées cochées : clic gauche d'un cran, clic droit tout en haut / en bas.
function GvvGuiTracking:action_move()
    -- FR : Sens : -1 vers le haut, 1 vers le bas
    -- EN : Direction: -1 up, 1 down
    local direction = 1
    if self.element.name == self.gui_name .. "-button-up" then
        direction = -1
    end

    local entries = self:getEntries()
    if self.event.button == defines.mouse_button_type.left then
        entries = Util.shift_checked(entries, direction)
    elseif self.event.button == defines.mouse_button_type.right then
        entries = Util.push_checked(entries, direction)
    end
    self:redraw(entries)
end


---**EN**
---
---Description: Checkboxes: left click inverts all boxes; right click unchecks all if a box is checked,
---otherwise checks all.
---
---──────────────────────────────
---
---**FR**
---
---Description: Cases à cocher : clic gauche inverse toutes les cases ; clic droit décoche tout si une case
---est cochée, sinon coche tout.
function GvvGuiTracking:action_check()
    local entries = self:getEntries()

    if self.event.button == defines.mouse_button_type.left then
        for _, entry in ipairs(entries) do
            self:getEntryCheckbox(entry.element).state = not entry.checked
        end
    elseif self.event.button == defines.mouse_button_type.right then
        local something_checked = false
        for _, entry in ipairs(entries) do
            if entry.checked then
                something_checked = true
                break
            end
        end
        for _, entry in ipairs(entries) do
            self:getEntryCheckbox(entry.element).state = not something_checked
        end
    end
end


---**EN**
---
---Description: Export (left click) / import (right click): opens the matching small window.
---
---──────────────────────────────
---
---**FR**
---
---Description: Exporter (clic gauche) / importer (clic droit) : ouvre la petite fenêtre correspondante.
function GvvGuiTracking:action_export_import()
    if self.event.button == defines.mouse_button_type.left then
        GvvGuiDialog(self.event):openExport()
    elseif self.event.button == defines.mouse_button_type.right then
        GvvGuiDialog(self.event):openImport()
    end
end


---**EN**
---
---Description: Right click on an entry code: copy window, with the "edit" button.
---
---──────────────────────────────
---
---**FR**
---
---Description: Clic droit sur le code d'une entrée : fenêtre de copie, avec le bouton « modifier ».
function GvvGuiTracking:action_copy_path()
    if self.event.button ~= defines.mouse_button_type.right then
        return
    end
    local entry = self:findEntry(self.element)
    GvvGuiDialog(self.event):openCopy(self.element.caption, entry and entry.tags.path)
end


---**EN**
---
---Description: Right click on an entry value: copy window.
---
---──────────────────────────────
---
---**FR**
---
---Description: Clic droit sur la valeur d'une entrée : fenêtre de copie.
function GvvGuiTracking:action_copy_output()
    if self.event.button ~= defines.mouse_button_type.right then
        return
    end
    GvvGuiDialog(self.event):openCopy(self.element.caption)
end
