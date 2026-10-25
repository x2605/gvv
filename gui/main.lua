---------------------------------------------------------------------------------------------
-- GUI : MAIN
---------------------------------------------------------------------------------------------
-- FR : Description de la fenêtre principale de gvv, utilisée par classes/GvvGuiMain.lua.
--        getElement(gui_name) : la description de chaque élément (à passer à parent.add)
--        getContent()         : le chemin de chaque élément depuis player.gui.screen
--      Organisation de la fenêtre :
--        frame-main                       cadre principal
--        ├ frame-top                      barre de titre
--        │ └ flow-header                  titre, zone de déplacement, bouton fermer
--        ├ flow-middle
--        │ ├ empty-left                   bordure gauche
--        │ ├ frame-wrap
--        │ │ └ frame-inner
--        │ │   ├ flow-toolbar             barre d'outils : redimensionnement + flow-tools
--        │ │   │ └ flow-tools             boutons propres à chaque onglet
--        │ │   └ tabbed-tabs              onglets, et leur contenu flow-tracking, flow-storage...
--        │ └ empty-right                  bordure droite
--        └ empty-bottom                   bordure basse
-- EN : Description of gvv's main window, used by classes/GvvGuiMain.lua.
--        getElement(gui_name) : the description of each element (to give to parent.add)
--        getContent()         : the path of each element from player.gui.screen
--      Window layout: see the tree above.
---------------------------------------------------------------------------------------------

-- FR : Onglets, dans l'ordre d'affichage. name : partie « name » des éléments tab-<name> et flow-<name>.
--      L'ordre compte : l'ancien code repère encore les onglets par leur numéro (1 = suivi... 5 = aide).
-- EN : Tabs, in display order. name: "name" part of the tab-<name> and flow-<name> elements.
--      Order matters: the old code still finds tabs by their number (1 = tracking... 5 = help).
local TABS = {
    { name = "tracking", caption = {"gvv-mod.tab-filtered-view"} },    -- 1 : suivi de variables / variable tracking
    { name = "storage", caption = "storage" },                          -- 2 : storage et _G des mods / mods storage and _G
    { name = "property", caption = "property" },                        -- 3 : objets Lua ajoutés / added Lua objects
    { name = "luaobject", caption = "LuaObject" },                      -- 4 : objets globaux / global objects
    { name = "help", caption = {"gvv-mod.help-tab"} },                  -- 5 : aide / help
}


---FR : Description de chaque élément de la fenêtre.
---EN : Description of each element of the window.
---@param gui_name string  Préfixe des noms (« gvv_main ») / Names prefix ("gvv_main")
---@return table
local function getElement(gui_name)
    local element = {
        -- FR : Cadres
        -- EN : Frames
        frame = {
            main = GvvGuiElement(gui_name, "frame", "main"):vertical():style("frame_gvv-mod"):get(),
            top = GvvGuiElement(gui_name, "frame", "top"):style("frame-bg_gvv-mod"):get(),
            wrap = GvvGuiElement(gui_name, "frame", "wrap"):style("inside-wrap_gvv-mod"):get(),
            inner = GvvGuiElement(gui_name, "frame", "inner"):vertical():style("inside_deep_frame_gvv-mod"):get(),
        },
        -- FR : Conteneurs
        -- EN : Containers
        flow = {
            header = GvvGuiElement(gui_name, "flow", "header"):horizontal():get(),
            middle = GvvGuiElement(gui_name, "flow", "middle"):horizontal():style("hflow_gvv-mod"):get(),
            toolbar = GvvGuiElement(gui_name, "flow", "toolbar"):horizontal():get(),
            tools = GvvGuiElement(gui_name, "flow", "tools"):horizontal():get(),
        },
        -- FR : Bordures et zone de déplacement
        -- EN : Borders and drag area
        empty = {
            drag = GvvGuiElement(gui_name, "empty-widget", "drag"):style("draggable_space_header"):get(),
            left = GvvGuiElement(gui_name, "empty-widget", "left"):style("empty-frame-bg_gvv-mod"):get(),
            right = GvvGuiElement(gui_name, "empty-widget", "right"):style("empty-frame-bg_gvv-mod"):get(),
            bottom = GvvGuiElement(gui_name, "empty-widget", "bottom"):style("empty-frame-bg_gvv-mod"):get(),
        },
        -- FR : Textes
        -- EN : Labels
        label = {
            title = GvvGuiElement(gui_name, "label", "title"):style("frame_title"):get(),
            width = GvvGuiElement(gui_name, "label", "width"):caption("W : "):tooltip({"gvv-mod.xresize"}):get(),
            height = GvvGuiElement(gui_name, "label", "height"):caption("H : "):tooltip({"gvv-mod.yresize"}):get(),
        },
        -- FR : Bouton fermer
        -- EN : Close button
        button = {
            close = GvvGuiElement(gui_name, "sprite-button", "close"):spritePath("utility/close")
                :style("frame_action_button"):mouseButtonFilter({"left"})
                :tooltip({"gvv-mod.close-main-tooltip"}):get(),
        },
        -- FR : Curseurs de redimensionnement (la valeur de départ est donnée à la création)
        -- EN : Resize sliders (the starting value is given at creation)
        slider = {
            width = GvvGuiElement(gui_name, "slider", "width"):tooltip({"gvv-mod.xresize"}):get(),
            height = GvvGuiElement(gui_name, "slider", "height"):tooltip({"gvv-mod.yresize"}):get(),
        },
        -- FR : Panneau d'onglets
        -- EN : Tabbed pane
        tabbed = {
            tabs = GvvGuiElement(gui_name, "tabbed-pane", "tabs"):style("tabbed_pane_gvv-mod"):get(),
        },
        -- FR : Onglets et contenus, remplis ci-dessous à partir de TABS
        -- EN : Tabs and contents, filled below from TABS
        tab = {},
        content = {},
    }

    -- FR : Réglages des curseurs, propres au type slider (non gérés par GvvGuiElement)
    -- EN : Slider settings, specific to the slider type (not handled by GvvGuiElement)
    element.slider.width.minimum_value = 550
    element.slider.width.maximum_value = 1750
    element.slider.height.minimum_value = 275
    element.slider.height.maximum_value = 1475
    for _, slider in pairs(element.slider) do
        slider.value_step = 25
        slider.discrete_slider = false
        slider.discrete_values = true
    end

    -- FR : Un onglet (tab-<name>) et son contenu (flow-<name>) par entrée de TABS
    -- EN : One tab (tab-<name>) and its content (flow-<name>) per TABS entry
    for _, tab in ipairs(TABS) do
        element.tab[tab.name] = GvvGuiElement(gui_name, "tab", tab.name):caption(tab.caption):get()
        element.content[tab.name] = GvvGuiElement(gui_name, "flow", tab.name):vertical():get()
    end

    return element
end


---FR : Chemin de chaque élément depuis player.gui.screen (sans le préfixe gui_name, ajouté par GvvGui:getElement).
---EN : Path of each element from player.gui.screen (without the gui_name prefix, added by GvvGui:getElement).
---@return table
local function getContent()
    -- FR : Renvoie une copie du chemin base, prolongée par le nom donné
    --      (ex. extend(toolbar, "slider-width") donne le chemin du curseur de largeur)
    -- EN : Returns a copy of the base path, extended with the given name
    --      (e.g. extend(toolbar, "slider-width") gives the path of the width slider)
    local function extend(base, name)
        local path = {}
        for index, step in ipairs(base) do
            path[index] = step
        end
        path[#path + 1] = name
        return path
    end

    -- FR : Chemins communs, réutilisés plus bas
    -- EN : Common paths, reused below
    local main = { "frame-main" }
    local header = { "frame-main", "frame-top", "flow-header" }
    local inner = { "frame-main", "flow-middle", "frame-wrap", "frame-inner" }
    local toolbar = extend(inner, "flow-toolbar")
    local tabs = extend(inner, "tabbed-tabs")

    local content = {
        frame = {
            main = main,
            inner = inner,
        },
        flow = {
            header = header,
            toolbar = toolbar,
            tools = extend(toolbar, "flow-tools"),
        },
        button = {
            close = extend(header, "button-close"),
        },
        slider = {
            width = extend(toolbar, "slider-width"),
            height = extend(toolbar, "slider-height"),
        },
        tabbed = {
            tabs = tabs,
        },
        -- FR : Contenu de chaque onglet : tabbed-tabs > flow-<name>
        -- EN : Content of each tab: tabbed-tabs > flow-<name>
        content = {},
    }
    for _, tab in ipairs(TABS) do
        content.content[tab.name] = extend(tabs, "flow-" .. tab.name)
    end

    return content
end


---------------------------------------------------------------------------------------------
-- FR : Fonctions exportées, et la liste des onglets
-- EN : Exported functions, and the tabs list
return {
    getElement = getElement,
    getContent = getContent,
    TABS = TABS,
}
