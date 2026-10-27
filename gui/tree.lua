---------------------------------------------------------------------------------------------
-- GUI : TREE
---------------------------------------------------------------------------------------------
-- FR : Éléments communs à tous les arbres de gvv, utilisés par le moteur classes/GvvGuiTree.lua.
--      Les particularités de chaque onglet sont dans un fichier de configuration : gui/tree/<onglet>.lua.
--      Organisation d'un onglet d'arbre (préfixe = gui_name de la configuration, ex. gvv_tree_storage) :
--        flow-wrap > empty-fill, flow-panel
--          flow-panel > pane-list (liste à gauche), empty-divider, pane-tree (l'arbre), panneau de recherche
--      Organisation d'une ligne de l'arbre (conteneur sans nom ; sa clé est dans ses tags : tags.key) :
--        frame-label                      ligne affichée
--        ├ flow-vbar > empty-vbar         trait vertical
--        ├ flow-hbar > empty-hbar         trait horizontal
--        ├ sprite-folder / sprite-load    icône de dossier / de « continuer à charger »
--        ├ button-key                     nom de la clé
--        ├ label-equal                    « = » (valeur seulement)
--        └ label-value / button-value     valeur (button-value : objet Lua, clic droit pour l'ajouter)
--        flow-content                     contenu d'un dossier (caché quand il est fermé)
--        ├ flow-extbar > empty-extbar     prolongement du trait vertical
--        └ flow-folder                    lignes du dossier
--      Une racine (ex. storage d'un mod) est une ligne de dossier avec tags.root = true.
-- EN : Elements shared by all gvv trees, used by the engine classes/GvvGuiTree.lua.
--      Each tab specifics are in a configuration file: gui/tree/<tab>.lua.
--      Tree tab layout and tree row layout: see the lists above.
--      A root (e.g. a mod storage) is a folder row with tags.root = true.
---------------------------------------------------------------------------------------------


---FR : Description des éléments d'un onglet d'arbre et de ses lignes.
---EN : Description of the elements of a tree tab and its rows.
---@param gui_name string  Préfixe des noms (gui_name de la configuration) / Names prefix (configuration gui_name)
---@return table
local function getElement(gui_name)
    local element = {
        -- FR : Onglet
        -- EN : Tab
        flow = {
            wrap = GvvGuiElement(gui_name, "flow", "wrap"):vertical():style("vflow_gvv-mod"):get(),
            panel = GvvGuiElement(gui_name, "flow", "panel"):horizontal():style("hflow_gvv-mod"):get(),
            -- FR : Ligne : sans nom (plusieurs lignes côte à côte), clé dans ses tags
            -- EN : Row: unnamed (several rows side by side), key in its tags
            row = { type = "flow", direction = "vertical", style = "vflow_gvv-mod" },
            vbar = GvvGuiElement(gui_name, "flow", "vbar"):vertical():style("vflow_gvv-mod"):get(),
            hbar = GvvGuiElement(gui_name, "flow", "hbar"):horizontal():style("hflow_gvv-mod"):get(),
            content = GvvGuiElement(gui_name, "flow", "content"):horizontal():style("hflow_gvv-mod"):get(),
            extbar = GvvGuiElement(gui_name, "flow", "extbar"):horizontal():style("hflow_gvv-mod"):get(),
            folder = GvvGuiElement(gui_name, "flow", "folder"):vertical():style("vflow_gvv-mod"):get(),
        },
        empty = {
            fill = GvvGuiElement(gui_name, "empty-widget", "fill"):style("empty-tabbed_pane_frame-bg_gvv-mod"):get(),
            divider = GvvGuiElement(gui_name, "empty-widget", "divider"):style("vertical-divider_gvv-mod"):get(),
            vbar = GvvGuiElement(gui_name, "empty-widget", "vbar"):style("branch_gvv-mod"):get(),
            hbar = GvvGuiElement(gui_name, "empty-widget", "hbar"):style("branch_gvv-mod"):get(),
            extbar = GvvGuiElement(gui_name, "empty-widget", "extbar"):style("branch_gvv-mod"):get(),
        },
        pane = {
            list = GvvGuiElement(gui_name, "scroll-pane", "list"):verticalScrollPolicy("auto")
                :horizontalScrollPolicy("auto"):style("scroll_pane_gvv-mod"):get(),
            tree = GvvGuiElement(gui_name, "scroll-pane", "tree"):verticalScrollPolicy("auto")
                :horizontalScrollPolicy("auto"):style("scroll_pane_gvv-mod"):get(),
        },
        -- FR : Ligne affichée (cadre transparent, surligné par la recherche)
        -- EN : Displayed row (transparent frame, highlighted by the search)
        frame = {
            label = GvvGuiElement(gui_name, "frame", "label"):horizontal():style("transparent-frame_gvv-mod"):get(),
        },
        sprite = {
            folder = GvvGuiElement(gui_name, "sprite", "folder"):spritePath("gvv-mod_folder-opened"):resizeSprite(false):get(),
            load = GvvGuiElement(gui_name, "sprite", "load"):spritePath("gvv-mod_load-cont"):resizeSprite(false):get(),
        },
        button = {
            -- FR : Clé ; légende, style et boutons de souris donnés par le moteur
            -- EN : Key; caption, style and mouse buttons given by the engine
            key = GvvGuiElement(gui_name, "button", "key"):get(),
            -- FR : Valeur objet Lua (clic droit : ajouter l'objet à l'onglet property)
            -- EN : Lua object value (right click: add the object to the property tab)
            value = GvvGuiElement(gui_name, "button", "value"):style("tree-item-luaobj_gvv-mod"):mouseButtonFilter({"right"}):get(),
            -- FR : Élément de la liste de gauche (nom item_<n>, valeur dans ses tags)
            -- EN : Element of the left list (name item_<n>, value in its tags)
            item = GvvGuiElement(gui_name, "button", "item"):style("c_sub_mod_gvv-mod"):mouseButtonFilter({"left"}):get(),
        },
        label = {
            equal = GvvGuiElement(gui_name, "label", "equal"):caption(" = "):get(),
            value = GvvGuiElement(gui_name, "label", "value"):get(),
        },
    }
    return element
end


---FR : Description des outils des arbres, dans la barre d'outils de la fenêtre principale :
---     bouton de rafraîchissement (onglets 2 à 4), cases n/a, nil et méthodes (onglets property et LuaObject).
---     Cachés au départ : GvvGuiTree.changeTab les affiche selon l'onglet.
---EN : Description of the trees tools, inside the main window toolbar:
---     refresh button (tabs 2 to 4), n/a, nil and methods boxes (property and LuaObject tabs).
---     Hidden at first: GvvGuiTree.changeTab shows them according to the tab.
---@param tools_name string  Préfixe des noms des outils (« gvv_trees ») / Tools names prefix ("gvv_trees")
---@return table
local function getTools(tools_name)
    local element = {
        button = {
            -- FR : Rafraîchir l'arbre de l'onglet affiché
            -- EN : Refresh the tree of the displayed tab
            refresh = GvvGuiElement(tools_name, "sprite-button", "refresh"):spritePath("utility/reset_white")
                :style("frame_action_button"):mouseButtonFilter({"left"})
                :tooltip({"gvv-mod.tree-refresh"}):visible(false):get(),
        },
        -- FR : Lignes à afficher : n/a, nil, méthodes (l'état de départ est donné à la construction)
        -- EN : Rows to show: n/a, nil, methods (the starting state is given on building)
        checkbox = {
            na = GvvGuiElement(tools_name, "checkbox", "na"):caption("n/a"):tooltip({"gvv-mod.show_na"}):visible(false):get(),
            ["nil"] = GvvGuiElement(tools_name, "checkbox", "nil"):caption("nil"):tooltip({"gvv-mod.show_nil"}):visible(false):get(),
            func = GvvGuiElement(tools_name, "checkbox", "func"):caption("method"):tooltip({"gvv-mod.show_func"}):visible(false):get(),
        },
    }
    return element
end


---------------------------------------------------------------------------------------------
-- FR : Fonctions exportées
-- EN : Exported functions
return {
    getElement = getElement,
    getTools = getTools,
}
