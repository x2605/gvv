---------------------------------------------------------------------------------------------
-- GUI : SEARCH
---------------------------------------------------------------------------------------------
-- FR : Description de la recherche dans les arbres, utilisée par classes/GvvGuiSearch.lua.
--      Deux endroits :
--        - le bouton loupe, dans la barre d'outils de la fenêtre principale (gvv_main-flow-tools) :
--            button-toggle (affiche / cache les panneaux de recherche)
--        - un panneau de recherche à droite de chaque arbre (storage, property, LuaObject) :
--            flow-panel (tags.tree = 'glob', 'prop' ou 'gobj')
--            ├ empty-divider              séparateur
--            └ flow-column
--              ├ flow-row
--              │ ├ textfield-text         texte cherché
--              │ └ table-filters          checkbox-key, checkbox-value, checkbox-regexp, checkbox-case
--              └ listbox-result           résultats (clic : l'arbre défile jusqu'au résultat)
-- EN : Description of the search in the trees, used by classes/GvvGuiSearch.lua.
--      Two places: the magnifier button inside the main window toolbar (gvv_main-flow-tools),
--      and a search panel on the right of each tree (storage, property, LuaObject). See the tree above.
---------------------------------------------------------------------------------------------

-- FR : Préfixe des noms de la recherche
-- EN : Search names prefix
local GUI_NAME = "gvv_search"

-- FR : Filtres de la recherche : nom de l'élément, réglage dans data.search_settings[arbre], infobulle
-- EN : Search filters: element name, setting in data.search_settings[tree], tooltip
local FILTERS = {
    { name = "key", setting = "key", tooltip = {"gvv-mod.search-key"} },            -- FR : chercher dans les clés / EN : search in keys
    { name = "value", setting = "value", tooltip = {"gvv-mod.search-value"} },      -- FR : chercher dans les valeurs / EN : search in values
    { name = "regexp", setting = "regexp", tooltip = {"gvv-mod.search-regexp"} },   -- FR : motif Lua / EN : Lua pattern
    { name = "case", setting = "case", tooltip = {"gvv-mod.search-case"} },         -- FR : respecter la casse / EN : case sensitive
}


---**EN**
---
---Description: Description of the search elements.
---
---──────────────────────────────
---
---**FR**
---
---Description: Description des éléments de la recherche.
---@param gui_name string  Names prefix ("gvv_search")
---@return table
local function getElement(gui_name)
    local element = {
        button = {
            toggle = GvvGuiElement(gui_name, "sprite-button", "toggle"):spritePath("utility/search")
                :style("frame_action_button"):mouseButtonFilter({"left"}):tooltip({"gvv-mod.search-btn"}):visible(false):get(),
        },
        flow = {
            panel = GvvGuiElement(gui_name, "flow", "panel"):horizontal():style("hflow_gvv-mod"):get(),
            column = GvvGuiElement(gui_name, "flow", "column"):vertical():style("vflow_gvv-mod"):get(),
            row = GvvGuiElement(gui_name, "flow", "row"):horizontal():style("hflow_gvv-mod"):get(),
        },
        empty = {
            divider = GvvGuiElement(gui_name, "empty-widget", "divider"):style("vertical-divider_gvv-mod"):get(),
        },
        textfield = {
            text = GvvGuiElement(gui_name, "textfield", "text"):get(),
        },
        table = {
            filters = GvvGuiElement(gui_name, "table", "filters"):get(),
        },
        checkbox = {},
        listbox = {
            result = GvvGuiElement(gui_name, "list-box", "result"):style("list_box-transparent_gvv-mod"):get(),
        },
    }

    -- FR : Réglage donné à la création (pas modifiable ensuite) : 2 cases par ligne
    -- EN : Setting given at creation (not modifiable afterwards): 2 boxes per row
    element.table.filters.column_count = 2

    -- FR : Une case par filtre
    -- EN : One box per filter
    for _, filter in ipairs(FILTERS) do
        element.checkbox[filter.name] = GvvGuiElement(gui_name, "checkbox", filter.name):checked(false):tooltip(filter.tooltip):get()
    end

    return element
end


---------------------------------------------------------------------------------------------
-- FR : Fonctions exportées, préfixe et filtres
-- EN : Exported functions, prefix and filters
return {
    getElement = getElement,
    GUI_NAME = GUI_NAME,
    FILTERS = FILTERS,
}
