---------------------------------------------------------------------------------------------
-- GVV GUI SEARCH
---------------------------------------------------------------------------------------------
-- FR : Recherche dans les arbres de gvv (étape 3.5 de la restructuration 0.6).
--      Construit le bouton loupe (barre d'outils) et un panneau de recherche par arbre
--      (storage, property, LuaObject), cherche le texte dans les lignes affichées de l'arbre,
--      surligne les résultats et fait défiler l'arbre jusqu'au résultat choisi.
--      Comportement repris de l'ancien code (legacy/search_tree.lua, legacy/gui_event.lua), sans changement :
--      la recherche ne porte que sur les lignes affichées (dossiers ouverts).
--      Les lignes des arbres sont parcourues par le moteur des arbres (GvvGuiTree, 3.6).
--      Description des éléments : gui/search.lua.
-- EN : Search in gvv trees (step 3.5 of the 0.6 restructuring).
--      Builds the magnifier button (toolbar) and one search panel per tree
--      (storage, property, LuaObject), looks for the text in the displayed tree rows,
--      highlights the results and scrolls the tree to the chosen result.
--      Behaviour taken from the old code (legacy/search_tree.lua, legacy/gui_event.lua), unchanged:
--      the search only covers the displayed rows (opened folders).
--      The tree rows are walked by the trees engine (GvvGuiTree, 3.6).
--      Elements description: gui/search.lua.
---------------------------------------------------------------------------------------------
local check = require(gvv.defines.lualib.common.check)
local fGui = require(gvv.defines.gui.search)
---------------------------------------------------------------------------------------------

-- FR : Arbres qui ont une recherche, et numéro de leur onglet
-- EN : Trees that have a search, and their tab number
local TREE_TABS = { glob = 2, prop = 3, gobj = 4 }

-- FR : Nom de recherche d'un arbre -> nom de sa configuration (GvvGuiTree)
-- EN : Search name of a tree -> name of its configuration (GvvGuiTree)
local TREE_ENGINES = { glob = "storage", prop = "property", gobj = "luaobject" }


---**EN**
---
---Description: Search in the trees ("gvv_search"): magnifier button, one panel per tree, results highlighted;
---the rows are walked by the trees engine (GvvGuiTree).
---
---⚠ Temporary wrapper, created on each event. Do not store the instance in `storage`.
---
---──────────────────────────────
---
---**FR**
---
---Description: Recherche dans les arbres (« gvv_search ») : bouton loupe, un panneau par arbre, résultats surlignés ;
---les lignes sont parcourues par le moteur des arbres (GvvGuiTree).
---
---⚠ Wrapper temporaire, créé à chaque évènement. Ne pas stocker l'instance dans `storage`.
---@class GvvGuiSearch : GvvGui
---@field object_name string     "GvvGuiSearch"
---@field specs table            Elements description (gui/search.lua)
---@field tools LuaGuiElement?   Main window toolbar
---@operator call(table): GvvGuiSearch
---@type GvvGuiSearch
GvvGuiSearch = gvv.classFactory.newclass(GvvGui, function(self, event)
    -- FR : Recherche « gvv_search » ; ses panneaux sont dans les onglets des arbres
    -- EN : "gvv_search" search; its panels are inside the trees tabs
    GvvGui.init(self, event, fGui.GUI_NAME, "flow-panel")
    self.object_name = "GvvGuiSearch"

    --------------------------------------------------
    -- FR : Barre d'outils de la fenêtre principale (nil si elle est fermée)
    -- EN : Main window toolbar (nil if it is closed)
    if self.isPresent then
        self.tools = GvvGuiMain(event):getElement("flow", "tools")
    end

    -- FR : Description des éléments (gui/search.lua)
    -- EN : Elements description (gui/search.lua)
    self.specs = fGui.getElement(self.gui_name)

    -- FR : Actions de la recherche
    -- EN : Search actions
    self.gui_action = {
        ["button-toggle"] = "action_toggle",                                -- FR : loupe / EN : magnifier
        ["textfield-text-text_changed"] = "action_text",                    -- FR : texte cherché / EN : searched text
        ["listbox-result-selection_state_changed"] = "action_result",       -- FR : résultat choisi / EN : chosen result
    }
    -- FR : Une case par filtre : « checkbox-<filtre>-checked_state_changed »
    -- EN : One box per filter: "checkbox-<filter>-checked_state_changed"
    for _, filter in ipairs(fGui.FILTERS) do
        self.gui_action["checkbox-" .. filter.name .. "-checked_state_changed"] = "action_filter"
    end
    --------------------------------------------------
end) --[[@as GvvGuiSearch]]
----------------------------------------------------------------


---------------------------------------------------------------------------------------------
-- FR : ACCÈS AUX ÉLÉMENTS
-- EN : ELEMENTS ACCESS
---------------------------------------------------------------------------------------------

---**EN**
---
---Description: Tree engine (GvvGuiTree) that has this search name.
---
---──────────────────────────────
---
---**FR**
---
---Description: Moteur de l'arbre (GvvGuiTree) qui porte ce nom de recherche.
---@param tree_name string  'glob', 'prop' ou 'gobj'
---@return GvvGuiTree
function GvvGuiSearch:getEngine(tree_name)
    return GvvGuiTree(self.event, TREE_ENGINES[tree_name])
end


---**EN**
---
---Description: Tree container (engine scrolling area), or nil.
---
---──────────────────────────────
---
---**FR**
---
---Description: Conteneur de l'arbre (zone défilante du moteur), ou nil.
---@param tree_name string  'glob', 'prop' ou 'gobj'
---@return LuaGuiElement?
function GvvGuiSearch:getTree(tree_name)
    return self:getEngine(tree_name):getPane()
end


---**EN**
---
---Description: Search panel of a tree (next to the tree), or nil.
---
---──────────────────────────────
---
---**FR**
---
---Description: Panneau de recherche d'un arbre (à côté de l'arbre), ou nil.
---@param tree_name string
---@return LuaGuiElement?
function GvvGuiSearch:getPanel(tree_name)
    local tree = self:getTree(tree_name)
    if tree == nil then
        return nil
    end
    return check.tryGet(tree.parent, self.gui_name .. "-flow-panel")
end


---**EN**
---
---Description: Element of a search panel, by its "type-name" part (e.g. "textfield-text"), or nil.
---
---──────────────────────────────
---
---**FR**
---
---Description: Élément d'un panneau de recherche, par sa partie « type-name » (ex. « textfield-text »), ou nil.
---@param tree_name string
---@param type_name string
---@return LuaGuiElement?
function GvvGuiSearch:getPart(tree_name, type_name)
    local panel = self:getPanel(tree_name)
    local column = check.tryGet(panel, self.gui_name .. "-flow-column")
    if type_name == "listbox-result" then
        return check.tryGet(column, self.gui_name .. "-" .. type_name)
    end
    local row = check.tryGet(column, self.gui_name .. "-flow-row")
    if type_name == "textfield-text" then
        return check.tryGet(row, self.gui_name .. "-" .. type_name)
    end
    local filters = check.tryGet(row, self.gui_name .. "-table-filters")
    return check.tryGet(filters, self.gui_name .. "-" .. type_name)
end


---**EN**
---
---Description: Tree of the panel that contains the element ('glob', 'prop' or 'gobj'), read in the panel tags, or nil.
---
---──────────────────────────────
---
---**FR**
---
---Description: Arbre du panneau qui contient l'élément ('glob', 'prop' ou 'gobj'), lu dans les tags du panneau, ou nil.
---@param element LuaGuiElement
---@return string?
function GvvGuiSearch:findTreeName(element)
    local current = element
    while check.isValidLuaObject(current) do
        if current.name == self.gui_name .. "-flow-panel" then
            return current.tags.tree
        end
        current = current.parent
    end
    return nil
end


---------------------------------------------------------------------------------------------
-- FR : CONSTRUCTION
-- EN : BUILDING
---------------------------------------------------------------------------------------------

---**EN**
---
---Description: Magnifier button inside the toolbar, right after the trees refresh button (as before).
---Called by GvvGuiMain:open, after the trees tools.
---
---──────────────────────────────
---
---**FR**
---
---Description: Bouton loupe dans la barre d'outils, juste après le bouton de rafraîchissement des arbres (comme avant).
---Appelé par GvvGuiMain:open, après les outils des arbres.
---@return GvvGuiSearch
function GvvGuiSearch:buildButton()
    if not check.isValidLuaObject(self.tools) then
        return self
    end

    -- FR : Position : juste après le bouton de rafraîchissement des arbres (ancien code)
    -- EN : Position: right after the trees refresh button (old code)
    local spec = self.specs.button.toggle
    for index, tool in ipairs(self.tools.children) do
        if tool.name == 'gvv_trees-button-refresh' then
            spec.index = index + 1
        end
    end

    local button = self.tools.add(spec)
    button.style.right_margin = 8
    button.style.width = 20
    button.style.height = 20
    return self
end


---**EN**
---
---Description: Search panel of a tree, on the right of the tree (taken from the old build_search_panel).
---Called by the old code that builds the trees tabs.
---
---──────────────────────────────
---
---**FR**
---
---Description: Panneau de recherche d'un arbre, à droite de l'arbre (repris de l'ancien build_search_panel).
---Appelé par l'ancien code qui construit les onglets des arbres.
---@param tree_name string    'glob', 'prop' ou 'gobj'
---@param parent LuaGuiElement Container of the list and the tree
---@return GvvGuiSearch
function GvvGuiSearch:buildPanel(tree_name, parent)
    local data = self:getData()
    local settings = data.search_settings[tree_name]
    local specs = self.specs

    -- FR : Panneau, caché si la recherche est fermée ; l'arbre concerné est dans ses tags
    -- EN : Panel, hidden if the search is closed; the tree concerned is in its tags
    specs.flow.panel.tags = { tree = tree_name }
    local panel = parent.add(specs.flow.panel)
    panel.style.width = 180
    panel.style.horizontally_stretchable = false
    panel.visible = data.show_search

    local divider = panel.add(specs.empty.divider)
    divider.style.width = 6

    local column = panel.add(specs.flow.column)
    local row = column.add(specs.flow.row)

    -- FR : Texte cherché, repris des réglages du joueur
    -- EN : Searched text, taken from the player settings
    specs.textfield.text.text = settings.text
    local input = row.add(specs.textfield.text)
    input.style.minimal_width = 50
    input.style.maximal_width = 9999
    input.style.horizontally_stretchable = true

    -- FR : Filtres (2 par ligne), cochés selon les réglages du joueur
    -- EN : Filters (2 per row), checked according to the player settings
    local filters = row.add(specs.table.filters)
    filters.style.horizontal_spacing = 0
    filters.style.vertical_spacing = 0
    for _, filter in ipairs(fGui.FILTERS) do
        specs.checkbox[filter.name].state = settings[filter.setting]
        filters.add(specs.checkbox[filter.name])
    end

    -- FR : Liste des résultats
    -- EN : Results list
    local result = column.add(specs.listbox.result)
    result.style.horizontally_stretchable = true
    return self
end


---**EN**
---
---Description: Magnifier button visible only on the trees tabs (2 to 4). Called on each tab change.
---
---──────────────────────────────
---
---**FR**
---
---Description: Bouton loupe visible seulement sur les onglets des arbres (2 à 4). Appelé à chaque changement d'onglet.
---@param tab_index integer
---@return GvvGuiSearch
function GvvGuiSearch:updateTools(tab_index)
    local button = check.tryGet(self.tools, self.gui_name .. "-button-toggle")
    if button ~= nil then
        button.visible = tab_index > 1 and tab_index < 5
    end
    return self
end


---------------------------------------------------------------------------------------------
-- FR : RECHERCHE DANS L'ARBRE (reprise de l'ancien legacy/search_tree.lua)
-- EN : SEARCH IN THE TREE (taken from the old legacy/search_tree.lua)
---------------------------------------------------------------------------------------------

---**EN**
---
---Description: Removes the rich text of a displayed key ([color=...], [img=...], brackets, quotes)
---
---──────────────────────────────
---
---**FR**
---
---Description: Retire le texte enrichi d'une clé affichée ([color=...], [img=...], crochets, guillemets)
---@param text string
---@return string
local function removeRichKey(text)
    text = text:gsub('^(.-) %(%[color=[^%[]+][^%[]+%[/color]%)$', '%1')
    text = text:gsub('^%[img=[^%[]+](.-)$', '%1')
    text = text:gsub('^%[color=[^%[]+](.-)%[/color]$', '%1')
    text = text:gsub('^%[(.-)]$', '%1')
    text = text:gsub('^%[color=[^%[]+](.-)%[/color]$', '%1')
    text = text:gsub('^"(.-)"$', '%1')
    return text
end

---**EN**
---
---Description: Removes the rich text of a displayed value (quotes, [color=...])
---
---──────────────────────────────
---
---**FR**
---
---Description: Retire le texte enrichi d'une valeur affichée (guillemets, [color=...])
---@param text string
---@return string
local function removeRichValue(text)
    text = text:gsub('^"(.-)"$', '%1')
    text = text:gsub('^%[color=[^%[]+](.-)%[/color]$', '%1')
    return text
end

---**EN**
---
---Description: Runs the search again in a tree.
---
---──────────────────────────────
---
---**FR**
---
---Description: Relance la recherche dans un arbre.
---@param tree_name string  'glob', 'prop' ou 'gobj'
---@return GvvGuiSearch
function GvvGuiSearch:refresh(tree_name)
    self:run(tree_name)
    return self
end


---**EN**
---
---Description: Searches inside a tree, highlights and lists the results, then returns them (taken from the old
---Search_Tree.refresh). Search closed: styles reset. Invalid Lua pattern: text in red,
---no search. The results are no longer kept in storage (they hold GUI elements):
---a chosen result is found by running the search again, which gives the same results.
---
---──────────────────────────────
---
---**FR**
---
---Description: Cherche dans un arbre, surligne et liste les résultats, puis les renvoie (repris de l'ancien
---Search_Tree.refresh). Recherche fermée : styles remis à zéro. Motif Lua invalide : texte en rouge,
---pas de recherche. Les résultats ne sont plus gardés dans storage (ils contiennent des éléments GUI) :
---un résultat choisi est retrouvé en relançant la recherche, qui donne les mêmes résultats.
---@param tree_name string  'glob', 'prop' ou 'gobj'
---@return table[]  { elem, name }
function GvvGuiSearch:run(tree_name)
    local data = self:getData()
    local panel = self:getPanel(tree_name)
    local input = self:getPart(tree_name, "textfield-text")
    local result = self:getPart(tree_name, "listbox-result")
    if data == nil or panel == nil or input == nil or result == nil then
        return {}
    end

    local engine = self:getEngine(tree_name)
    local settings = data.search_settings[tree_name]
    local text = settings.text

    -- FR : Résultats précédents effacés
    -- EN : Previous results cleared
    result.clear_items()

    -- FR : Recherche fermée : styles remis à zéro dans l'arbre
    -- EN : Search closed: styles reset in the tree
    if not panel.visible then
        engine:searchReset()
        return {}
    end

    -- FR : Motif Lua : vérifié (rouge s'il est invalide) ; sinon les caractères spéciaux sont échappés
    -- EN : Lua pattern: checked (red if invalid); otherwise special characters are escaped
    if settings.regexp then
        local valid = pcall(string.match, '', text)
        if not valid then
            input.style.font_color = {1, 0, 0}
            return {}
        end
        input.style.font_color = {0, 0, 0}
    else
        input.style.font_color = {0, 0, 0}
        text = text:gsub('[%(%)%.%%%+%-%*%?%[%^%$]', '%%%1')
    end
    if not settings.case then
        text = text:lower()
    end

    local state = { text = text, found = {}, key = settings.key, value = settings.value, case = settings.case,
        removeRichKey = removeRichKey, removeRichValue = removeRichValue }
    -- FR : Lignes parcourues par le moteur de l'arbre ; arbre vide : rien à chercher
    -- EN : Rows walked by the tree engine; empty tree: nothing to search
    if not engine:searchScan(state) then
        return {}
    end

    -- FR : Résultats affichés dans la liste
    -- EN : Results shown in the list
    local items = {}
    for index, found in ipairs(state.found) do
        items[index] = found.name
    end
    result.items = items
    return state.found
end


---**EN**
---
---Description: Runs the search again in the three trees.
---
---──────────────────────────────
---
---**FR**
---
---Description: Relance la recherche dans les trois arbres.
---@return GvvGuiSearch
function GvvGuiSearch:refreshAll()
    for _, tree_name in ipairs({'glob', 'prop', 'gobj'}) do
        self:refresh(tree_name)
    end
    return self
end


---------------------------------------------------------------------------------------------
-- FR : ACTIONS
-- EN : ACTIONS
---------------------------------------------------------------------------------------------

---**EN**
---
---Description: Magnifier: shows or hides the search panels of the three trees; on opening,
---the field of the displayed tab gets the focus.
---
---──────────────────────────────
---
---**FR**
---
---Description: Loupe : affiche ou cache les panneaux de recherche des trois arbres ; à l'ouverture,
---le champ de l'onglet affiché prend le focus.
function GvvGuiSearch:action_toggle()
    local data = self:getData()
    data.show_search = not data.show_search

    for tree_name in pairs(TREE_TABS) do
        local panel = self:getPanel(tree_name)
        if panel ~= nil then
            panel.visible = data.show_search
        end
    end

    -- FR : Focus sur le champ de l'onglet affiché
    -- EN : Focus on the field of the displayed tab
    if data.show_search then
        local tabbed = GvvGuiMain(self.event):getElement("tabbed", "tabs")
        for tree_name, tab_index in pairs(TREE_TABS) do
            local input = self:getPart(tree_name, "textfield-text")
            if tabbed ~= nil and tabbed.selected_tab_index == tab_index and input ~= nil then
                input.focus()
            end
        end
    end

    self:refreshAll()
end


---**EN**
---
---Description: Searched text modified: kept in the settings, then search run again.
---
---──────────────────────────────
---
---**FR**
---
---Description: Texte cherché modifié : gardé dans les réglages, puis recherche relancée.
function GvvGuiSearch:action_text()
    local tree_name = self:findTreeName(self.element)
    if tree_name == nil then
        return
    end
    self:getData().search_settings[tree_name].text = self.element.text
    self:refresh(tree_name)
end


---**EN**
---
---Description: Filter checked / unchecked: kept in the settings, then search run again.
---
---──────────────────────────────
---
---**FR**
---
---Description: Filtre coché / décoché : gardé dans les réglages, puis recherche relancée.
function GvvGuiSearch:action_filter()
    local tree_name = self:findTreeName(self.element)
    if tree_name == nil then
        return
    end
    local _, _, filter_name = GvvGui.splitName(self.element.name)
    self:getData().search_settings[tree_name][filter_name] = self.element.state
    self:refresh(tree_name)
end


---**EN**
---
---Description: Result chosen: the tree scrolls to it, then the selection is cleared.
---
---──────────────────────────────
---
---**FR**
---
---Description: Résultat choisi : l'arbre défile jusqu'à lui, puis la sélection est effacée.
function GvvGuiSearch:action_result()
    local tree_name = self:findTreeName(self.element)
    if tree_name == nil then
        return
    end

    -- FR : Ligne choisie, puis résultats retrouvés en relançant la recherche (mêmes résultats, même ordre)
    -- EN : Chosen line, then results found again by running the search again (same results, same order)
    local index = self.element.selected_index
    local found = self:run(tree_name)[index]

    -- FR : L'arbre défile jusqu'au résultat
    -- EN : The tree scrolls to the result
    local tree = self:getTree(tree_name)
    if tree ~= nil and found ~= nil and check.isValidLuaObject(found.elem) then
        tree.scroll_to_element(found.elem, 'top-third')
    end
    self.element.selected_index = 0
end
