---------------------------------------------------------------------------------------------
-- GVV GUI SEARCH
---------------------------------------------------------------------------------------------
-- FR : Recherche dans les arbres de gvv (étape 3.5 de la restructuration 0.6).
--      Construit le bouton loupe (barre d'outils) et un panneau de recherche par arbre
--      (storage, property, LuaObject), cherche le texte dans les lignes affichées de l'arbre,
--      surligne les résultats et fait défiler l'arbre jusqu'au résultat choisi.
--      Comportement repris de l'ancien code (legacy/search_tree.lua, legacy/gui_event.lua), sans changement :
--      la recherche ne porte que sur les lignes affichées (dossiers ouverts).
--      Le parcours de l'arbre suit encore la structure de l'ancien arbre (legacy/tree.lua) ; il sera
--      adapté avec les arbres (3.6).
--      Description des éléments : gui/search.lua.
-- EN : Search in gvv trees (step 3.5 of the 0.6 restructuring).
--      Builds the magnifier button (toolbar) and one search panel per tree
--      (storage, property, LuaObject), looks for the text in the displayed tree rows,
--      highlights the results and scrolls the tree to the chosen result.
--      Behaviour taken from the old code (legacy/search_tree.lua, legacy/gui_event.lua), unchanged:
--      the search only covers the displayed rows (opened folders).
--      The tree walk still follows the old tree structure (legacy/tree.lua); it will be
--      adapted with the trees (3.6).
--      Elements description: gui/search.lua.
---------------------------------------------------------------------------------------------
local check = require(gvv.defines.lualib.common.check)
local Util = require(gvv.defines.lualib.common.util)
local fGui = require(gvv.defines.gui.search)
---------------------------------------------------------------------------------------------

-- FR : Arbres qui ont une recherche, et numéro de leur onglet
-- EN : Trees that have a search, and their tab number
local TREE_TABS = { glob = 2, prop = 3, gobj = 4 }


---@class GvvGuiSearch : GvvGui
---@field specs table              Description des éléments (gui/search.lua) / Elements description (gui/search.lua)
---@field tools LuaGuiElement?     Barre d'outils de la fenêtre principale / Main window toolbar
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
end)
----------------------------------------------------------------


---------------------------------------------------------------------------------------------
-- FR : ACCÈS AUX ÉLÉMENTS
-- EN : ELEMENTS ACCESS
---------------------------------------------------------------------------------------------

---FR : Conteneur de l'arbre (ancien code : g.gui.sub_globtree, sub_proptree, sub_gobjtree), ou nil.
---EN : Tree container (old code: g.gui.sub_globtree, sub_proptree, sub_gobjtree), or nil.
---@param tree_name string  'glob', 'prop' ou 'gobj'
---@return LuaGuiElement?
function GvvGuiSearch:getTree(tree_name)
    local tree = check.getPath(self:getData(), {"gui", "sub_" .. tree_name .. "tree"})
    if check.isValidLuaObject(tree) then
        return tree
    end
    return nil
end


---FR : Panneau de recherche d'un arbre (à côté de l'arbre), ou nil.
---EN : Search panel of a tree (next to the tree), or nil.
---@param tree_name string
---@return LuaGuiElement?
function GvvGuiSearch:getPanel(tree_name)
    local tree = self:getTree(tree_name)
    if tree == nil then
        return nil
    end
    return check.tryGet(tree.parent, self.gui_name .. "-flow-panel")
end


---FR : Élément d'un panneau de recherche, par sa partie « type-name » (ex. « textfield-text »), ou nil.
---EN : Element of a search panel, by its "type-name" part (e.g. "textfield-text"), or nil.
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


---FR : Arbre du panneau qui contient l'élément ('glob', 'prop' ou 'gobj'), lu dans les tags du panneau, ou nil.
---EN : Tree of the panel that contains the element ('glob', 'prop' or 'gobj'), read in the panel tags, or nil.
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

---FR : Bouton loupe dans la barre d'outils, juste après le bouton de rafraîchissement des arbres (comme avant).
---     Appelé par GvvGuiMain:open, après les outils des arbres.
---EN : Magnifier button inside the toolbar, right after the trees refresh button (as before).
---     Called by GvvGuiMain:open, after the trees tools.
---@return GvvGuiSearch
function GvvGuiSearch:buildButton()
    if not check.isValidLuaObject(self.tools) then
        return self
    end

    -- FR : Position : juste après le bouton de rafraîchissement des arbres (ancien code)
    -- EN : Position: right after the trees refresh button (old code)
    local spec = self.specs.button.toggle
    for index, tool in ipairs(self.tools.children) do
        if tool.name == 'tree_refresh_btn' then
            spec.index = index + 1
        end
    end

    local button = self.tools.add(spec)
    button.style.right_margin = 8
    button.style.width = 20
    button.style.height = 20
    return self
end


---FR : Panneau de recherche d'un arbre, à droite de l'arbre (repris de l'ancien build_search_panel).
---     Appelé par l'ancien code qui construit les onglets des arbres.
---EN : Search panel of a tree, on the right of the tree (taken from the old build_search_panel).
---     Called by the old code that builds the trees tabs.
---@param tree_name string    'glob', 'prop' ou 'gobj'
---@param parent LuaGuiElement Conteneur de la liste et de l'arbre / Container of the list and the tree
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


---FR : Bouton loupe visible seulement sur les onglets des arbres (2 à 4). Appelé à chaque changement d'onglet.
---EN : Magnifier button visible only on the trees tabs (2 to 4). Called on each tab change.
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

-- FR : Retire le texte enrichi d'une clé affichée ([color=...], [img=...], crochets, guillemets)
-- EN : Removes the rich text of a displayed key ([color=...], [img=...], brackets, quotes)
local function removeRichKey(text)
    text = text:gsub('^(.-) %(%[color=[^%[]+][^%[]+%[/color]%)$', '%1')
    text = text:gsub('^%[img=[^%[]+](.-)$', '%1')
    text = text:gsub('^%[color=[^%[]+](.-)%[/color]$', '%1')
    text = text:gsub('^%[(.-)]$', '%1')
    text = text:gsub('^%[color=[^%[]+](.-)%[/color]$', '%1')
    text = text:gsub('^"(.-)"$', '%1')
    return text
end

-- FR : Retire le texte enrichi d'une valeur affichée (guillemets, [color=...])
-- EN : Removes the rich text of a displayed value (quotes, [color=...])
local function removeRichValue(text)
    text = text:gsub('^"(.-)"$', '%1')
    text = text:gsub('^%[color=[^%[]+](.-)%[/color]$', '%1')
    return text
end

-- FR : Remet le style normal sur toutes les lignes de l'arbre, dossiers compris (recherche fermée)
-- EN : Puts the normal style back on all tree rows, folders included (search closed)
local function resetScan(parent_container)
    for _, container in ipairs(parent_container.children) do
        if container.valid and container.label_container then
            container.label_container.style = 'transparent-frame_gvv-mod'
            if container.content_container then
                resetScan(container.content_container.folder)
            end
        end
    end
end

-- FR : Lignes d'un dossier fermé : style normal, pas de recherche dedans
-- EN : Rows of a closed folder: normal style, no search inside
local function notScan(parent_container)
    for _, container in ipairs(parent_container.children) do
        if container.valid and container.label_container then
            container.label_container.style = 'transparent-frame_gvv-mod'
        end
    end
end

-- FR : Cherche dans les lignes affichées d'un dossier, et dans ses sous-dossiers ouverts.
--      state : { text (texte cherché, déjà préparé), found (résultats), key, value, case (filtres) }
-- EN : Searches the displayed rows of a folder, and its opened sub-folders.
--      state: { text (searched text, already prepared), found (results), key, value, case (filters) }
local function scan(parent_container, state)
    for _, container in ipairs(parent_container.children) do
        if container.valid and container.label_container
            and container.visible and type(container.label_container['_gvv-mod_key_label'].caption) == 'string' then

            local label = container.label_container['_gvv-mod_key_label']
            local value_element = container.label_container['_gvv-mod_key_value']

            -- FR : Clé et valeur sans texte enrichi, en minuscules si la casse est ignorée
            -- EN : Key and value without rich text, in lower case if case is ignored
            local key = removeRichKey(label.caption)
            if not state.case then
                key = key:lower()
            end
            local value = nil
            if value_element then
                value = removeRichValue(value_element.caption)
                if not state.case then
                    value = value:lower()
                end
            end

            if state.text ~= '' and state.key and key:match(state.text) then
                -- FR : Trouvé dans la clé
                -- EN : Found in the key
                local name = label.caption
                if value then
                    name = label.caption .. ' = ' .. value_element.caption
                end
                state.found[#state.found + 1] = { elem = label, name = name }
                container.label_container.style = 'highlighted-frame_gvv-mod'
            elseif state.text ~= '' and state.value and value and value:match(state.text) then
                -- FR : Trouvé dans la valeur
                -- EN : Found in the value
                state.found[#state.found + 1] = { elem = label, name = label.caption .. ' = ' .. value_element.caption }
                container.label_container.style = 'highlighted-frame_gvv-mod'
            else
                container.label_container.style = 'transparent-frame_gvv-mod'
            end

            -- FR : Sous-dossier : ouvert -> on cherche dedans ; fermé -> style normal
            -- EN : Sub-folder: opened -> search inside; closed -> normal style
            if container.content_container and container.content_container.visible then
                scan(container.content_container.folder, state)
            elseif container.content_container then
                notScan(container.content_container.folder)
            end
        end
    end
end

-- FR : Arbre prêt pour la recherche : une racine dessinée (pas un objet global « * ») avec son contenu
-- EN : Tree ready for search: a drawn root (not a "*" global object) with its content
local function treeReady(tree)
    return tree and tree.children[1] and not tree.children[1].name:match('^[*]') and tree.children[2] and tree.children[3]
end


---FR : Relance la recherche dans un arbre (repris de l'ancien Search_Tree.refresh).
---     Recherche fermée : styles remis à zéro. Motif Lua invalide : texte en rouge, pas de recherche.
---EN : Runs the search again in a tree (taken from the old Search_Tree.refresh).
---     Search closed: styles reset. Invalid Lua pattern: text in red, no search.
---@param tree_name string  'glob', 'prop' ou 'gobj'
---@return GvvGuiSearch
function GvvGuiSearch:refresh(tree_name)
    local data = self:getData()
    local panel = self:getPanel(tree_name)
    local input = self:getPart(tree_name, "textfield-text")
    local result = self:getPart(tree_name, "listbox-result")
    if data == nil or panel == nil or input == nil or result == nil then
        return self
    end

    local tree = self:getTree(tree_name)
    local settings = data.search_settings[tree_name]
    local text = settings.text

    -- FR : Résultats précédents effacés
    -- EN : Previous results cleared
    result.clear_items()
    data.data.search[tree_name] = {}

    -- FR : Recherche fermée : styles remis à zéro dans l'arbre
    -- EN : Search closed: styles reset in the tree
    if not panel.visible then
        if treeReady(tree) then
            if tree_name == 'glob' then
                resetScan(tree.children[2].content_container.folder)
            end
            resetScan(tree.children[3].content_container.folder)
        end
        return self
    end

    -- FR : Motif Lua : vérifié (rouge s'il est invalide) ; sinon les caractères spéciaux sont échappés
    -- EN : Lua pattern: checked (red if invalid); otherwise special characters are escaped
    if settings.regexp then
        local valid = pcall(string.match, '', text)
        if not valid then
            input.style.font_color = {1, 0, 0}
            return self
        end
        input.style.font_color = {0, 0, 0}
    else
        input.style.font_color = {0, 0, 0}
        text = text:gsub('[%(%)%.%%%+%-%*%?%[%^%$]', '%%%1')
    end
    if not settings.case then
        text = text:lower()
    end

    if not treeReady(tree) then
        return self
    end

    -- FR : Recherche : dans l'arbre _G (storage seulement), puis dans l'arbre principal
    -- EN : Search: in the _G tree (storage only), then in the main tree
    local state = { text = text, found = {}, key = settings.key, value = settings.value, case = settings.case }
    local roots = { tree.children[3] }
    if tree_name == 'glob' then
        roots = { tree.children[2], tree.children[3] }
    end
    for _, root in ipairs(roots) do
        if root.content_container.visible then
            scan(root.content_container.folder, state)
        else
            notScan(root.content_container.folder)
        end
    end

    -- FR : Résultats gardés (pour défiler jusqu'à eux) et affichés dans la liste
    -- EN : Results kept (to scroll to them) and shown in the list
    data.data.search[tree_name] = Util.deepcopytbl(state.found)
    local items = {}
    for index, found in ipairs(state.found) do
        items[index] = found.name
    end
    result.items = items
    return self
end


---FR : Relance la recherche dans les trois arbres.
---EN : Runs the search again in the three trees.
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

---FR : Loupe : affiche ou cache les panneaux de recherche des trois arbres ; à l'ouverture,
---     le champ de l'onglet affiché prend le focus.
---EN : Magnifier: shows or hides the search panels of the three trees; on opening,
---     the field of the displayed tab gets the focus.
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


---FR : Texte cherché modifié : gardé dans les réglages, puis recherche relancée.
---EN : Searched text modified: kept in the settings, then search run again.
function GvvGuiSearch:action_text()
    local tree_name = self:findTreeName(self.element)
    if tree_name == nil then
        return
    end
    self:getData().search_settings[tree_name].text = self.element.text
    self:refresh(tree_name)
end


---FR : Filtre coché / décoché : gardé dans les réglages, puis recherche relancée.
---EN : Filter checked / unchecked: kept in the settings, then search run again.
function GvvGuiSearch:action_filter()
    local tree_name = self:findTreeName(self.element)
    if tree_name == nil then
        return
    end
    local _, _, filter_name = GvvGui.splitName(self.element.name)
    self:getData().search_settings[tree_name][filter_name] = self.element.state
    self:refresh(tree_name)
end


---FR : Résultat choisi : l'arbre défile jusqu'à lui, puis la sélection est effacée.
---EN : Result chosen: the tree scrolls to it, then the selection is cleared.
function GvvGuiSearch:action_result()
    local tree_name = self:findTreeName(self.element)
    local tree = tree_name and self:getTree(tree_name)
    local found = check.getPath(self:getData(), {"data", "search", tree_name, self.element.selected_index})
    if tree ~= nil and found ~= nil and check.isValidLuaObject(found.elem) then
        tree.scroll_to_element(found.elem, 'top-third')
    end
    self.element.selected_index = 0
end
