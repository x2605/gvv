---------------------------------------------------------------------------------------------
-- GVV GUI TREE
---------------------------------------------------------------------------------------------
-- FR : Moteur générique des arbres de gvv (étape 3.6 de la restructuration 0.6).
--      Une seule classe pour tous les onglets d'arbre : GvvGuiTree(event, "storage" | "property" | "luaobject").
--      Les particularités
--      de chaque onglet (liste de gauche, racines, lecture des données, options) viennent de son fichier
--      de configuration gui/tree/<onglet>.lua, au lieu des « if tab == ... » de l'ancien code.
--      Le moteur construit l'onglet, la liste de gauche et l'arbre, ouvre / ferme les dossiers (chargés
--      à la demande), gère « continuer à charger », les clics droits (suivi, objets Lua), garde les
--      dossiers ouverts et fournit le parcours des lignes à la recherche (GvvGuiSearch).
--      Il gère aussi les outils communs aux arbres, dans la barre d'outils de la fenêtre principale
--      (préfixe gvv_trees : rafraîchir, cases n/a, nil, méthodes).
--      Les données d'une ligne sont dans ses tags (tags.key, tags.folder, tags.root, tags.cont_from),
--      au lieu des listes de références d'éléments rangées dans storage par l'ancien code.
--      Comportement repris de l'ancien code (legacy/tree.lua, legacy/gui_event.lua), sans changement.
--      Description des éléments : gui/tree.lua.
-- EN : Generic engine of gvv trees (step 3.6 of the 0.6 restructuring).
--      One class for all the tree tabs: GvvGuiTree(event, "storage" | "property" | "luaobject"). Each tab specifics (left list,
--      roots, data reading, options) come from its configuration file gui/tree/<tab>.lua, instead of the
--      old code's "if tab == ...".
--      The engine builds the tab, the left list and the tree, opens / closes the folders (loaded on
--      demand), handles "continue to load", right clicks (tracking, Lua objects), keeps the opened
--      folders and provides the rows walk to the search (GvvGuiSearch).
--      It also handles the tools shared by the trees, inside the main window toolbar
--      (gvv_trees prefix: refresh, n/a, nil, methods boxes).
--      A row data is in its tags (tags.key, tags.folder, tags.root, tags.cont_from), instead of the
--      element references lists the old code stored in storage.
--      Behaviour taken from the old code (legacy/tree.lua, legacy/gui_event.lua), unchanged.
--      Elements description: gui/tree.lua.
---------------------------------------------------------------------------------------------
local check = require(gvv.defines.lualib.common.check)
local Util = require(gvv.defines.lualib.common.util)
local Table_to_str = require(gvv.defines.lualib.common.table_to_str)
local Sprite = require(gvv.defines.lualib.common.sprite)
local fGui = require(gvv.defines.gui.tree)
---------------------------------------------------------------------------------------------

-- FR : Arbres, dans l'ordre des onglets ; chacun a sa configuration gui/tree/<nom>.lua
-- EN : Trees, in the tabs order; each one has its configuration gui/tree/<name>.lua
local TREE_NAMES = { "storage", "property", "luaobject" }

-- FR : Préfixe des noms des outils des arbres (gvv_trees-button-refresh...)
-- EN : Names prefix of the trees tools (gvv_trees-button-refresh...)
local TOOLS_NAME = "gvv_trees"

-- FR : Cases des outils : partie « name » de la case -> réglage du joueur
-- EN : Tools boxes: "name" part of the box -> player setting
local SHOW_SETTINGS = {
    na = "show_na",
    ["nil"] = "show_nil",
    func = "show_func",
}

-- FR : Styles de la clé : normal et « suivi » (clic droit pour passer de l'un à l'autre)
-- EN : Key styles: normal and "tracked" (right click to switch from one to the other)
local TRACKED_STYLE = {
    ['tree-item_gvv-mod'] = 'tracked-tree-item_gvv-mod',
    ['tree-item-folder_gvv-mod'] = 'tracked-tree-item-folder_gvv-mod',
}
local UNTRACKED_STYLE = {
    ['tracked-tree-item_gvv-mod'] = 'tree-item_gvv-mod',
    ['tracked-tree-item-folder_gvv-mod'] = 'tree-item-folder_gvv-mod',
}

-- FR : Nombre de lignes dessinées au plus par dossier avant « continuer à charger » (réglage par défaut)
-- EN : Maximum number of rows drawn per folder before "continue to load" (default setting)
local DEFAULT_TREE_LIMIT = 500


---@class GvvGuiTree : GvvGui
---@field config table     Configuration de l'onglet (gui/tree/<onglet>.lua) / Tab configuration (gui/tree/<tab>.lua)
---@field specs table      Description des éléments (gui/tree.lua) / Elements description (gui/tree.lua)
GvvGuiTree = gvv.classFactory.newclass(GvvGui, function(self, event, tree_name)
    -- FR : Configuration de l'onglet demandé
    -- EN : Configuration of the requested tab
    local config = require(gvv.defines.gui.trees[tree_name])

    -- FR : Onglet dont l'élément racine est « flow-wrap » (ex. gvv_tree_storage-flow-wrap)
    -- EN : Tab whose root element is "flow-wrap" (e.g. gvv_tree_storage-flow-wrap)
    GvvGui.init(self, event, config.gui_name, "flow-wrap")
    self.object_name = "GvvGuiTree"
    self.config = config

    --------------------------------------------------
    -- FR : Conteneur : le contenu de l'onglet dans la fenêtre principale (nil si elle est fermée)
    -- EN : Container: the tab content in the main window (nil if it is closed)
    if self.isPresent then
        self.gui = { GvvGuiMain(event):getElement("content", config.tab) }
    end

    -- FR : Chemins et description des éléments
    -- EN : Element paths and description
    self.content = {
        pane = {
            list = { "flow-wrap", "flow-panel", "pane-list" },
            tree = { "flow-wrap", "flow-panel", "pane-tree" },
        },
        flow = {
            panel = { "flow-wrap", "flow-panel" },
        },
    }
    self.specs = fGui.getElement(self.gui_name)

    -- FR : Actions des lignes de l'arbre (les boutons de la liste sont traités dans on_gui_click)
    -- EN : Tree rows actions (the list buttons are handled in on_gui_click)
    self.gui_action = {
        ["button-key"] = "action_key",          -- FR : clé : dossier, « continuer à charger », suivi / EN : key: folder, "continue to load", tracking
        ["button-value"] = "action_value",      -- FR : valeur objet Lua / EN : Lua object value
    }
    --------------------------------------------------
end)
----------------------------------------------------------------


---------------------------------------------------------------------------------------------
-- FR : FONCTIONS DE LA CLASSE (sans arbre précis : appelées GvvGuiTree.nom(...))
-- EN : CLASS FUNCTIONS (no specific tree: called GvvGuiTree.name(...))
---------------------------------------------------------------------------------------------

---FR : Arbre qui reçoit un évènement GUI, pour l'aiguillage de modules/gui.lua : celui dont le préfixe
---     est celui de l'élément ; sinon l'arbre storage (il traite aussi les outils communs).
---EN : Tree that receives a GUI event, for the modules/gui.lua dispatcher: the one whose prefix
---     is the element's; otherwise the storage tree (it also handles the shared tools).
---@param event table
---@return GvvGuiTree
function GvvGuiTree.fromEvent(event)
    -- FR : Préfixe du nom de l'élément (nil sans élément, ou pour un ancien nom)
    -- EN : Element name prefix (nil without element, or for an old name)
    local gui_name = GvvGui.splitName(check.tryGet(check.tryGet(event, "element"), "name"))

    -- FR : Arbre dont la configuration a ce préfixe
    -- EN : Tree whose configuration has this prefix
    for _, tree_name in ipairs(TREE_NAMES) do
        if require(gvv.defines.gui.trees[tree_name]).gui_name == gui_name then
            return GvvGuiTree(event, tree_name)
        end
    end

    -- FR : Sinon l'arbre storage
    -- EN : Otherwise the storage tree
    return GvvGuiTree(event, TREE_NAMES[1])
end


---FR : Arbre affiché dans l'onglet donné (2 à 4), ou nil pour un autre onglet.
---EN : Tree shown in the given tab (2 to 4), or nil for another tab.
---@param event table
---@param tab_index integer
---@return GvvGuiTree?
function GvvGuiTree.fromTab(event, tab_index)
    for _, tree_name in ipairs(TREE_NAMES) do
        if require(gvv.defines.gui.trees[tree_name]).tab_index == tab_index then
            return GvvGuiTree(event, tree_name)
        end
    end
    return nil
end


---FR : Tous les arbres (un par onglet), dans l'ordre des onglets.
---EN : All the trees (one per tab), in the tabs order.
---@param event table
---@return GvvGuiTree[]
function GvvGuiTree.all(event)
    local trees = {}
    for index, tree_name in ipairs(TREE_NAMES) do
        trees[index] = GvvGuiTree(event, tree_name)
    end
    return trees
end


---FR : Valeur au bout d'un chemin complet (chemins du suivi et des objets ajoutés) :
---     « *nom » : objet global de l'API ; « _G:<mod> » : _G du mod ; « <mod> » : storage du mod ; puis chaque clé.
---     Une étape manquante lève une erreur (comme avant). Repris de l'ancien Tree.get_tree_value.
---EN : Value at the end of a full path (tracking and added objects paths):
---     "*name": API global object; "_G:<mod>": mod _G; "<mod>": mod storage; then each key.
---     A missing step raises an error (as before). Taken from the old Tree.get_tree_value.
---@param full_path table
---@return any
function GvvGuiTree.readFullPath(full_path)
    local value
    local first = full_path[1]

    -- FR : Départ du chemin : objet global, _G ou storage d'un mod
    -- EN : Path start: global object, _G or storage of a mod
    if type(first) == 'string' then
        if first:match('^[*]') then
            value = assert(loadstring('return ' .. first:match('^[*](.*)')))()
        elseif first:match('^_G:') then
            value = remote.call('__' .. first:match('^_G:(.*)') .. '__gvv', '_G')
        else
            value = remote.call('__' .. first .. '__gvv', 'storage')
        end
    end

    -- FR : Puis chaque clé du chemin
    -- EN : Then each key of the path
    for index = 2, #full_path do
        value = value[full_path[index]]
    end
    return value
end


---FR : Texte d'une racine d'objet : son nom, puis l'icône et la classe de l'objet Lua (en bleu),
---     ou son type (en rouge) si ce n'est pas un objet Lua. Repris de l'ancien draw_init.
---EN : Text of an object root: its name, then the Lua object icon and class (in blue),
---     or its type (in red) if it is not a Lua object. Taken from the old draw_init.
---@param name string
---@param value any
---@return string
function GvvGuiTree.objectCaption(name, value)
    -- FR : Objet Lua : icône et classe
    -- EN : Lua object: icon and class
    if check.isLuaObject(value) then
        return name .. ' ' .. Sprite.img(value) .. '([color=blue]' .. value.object_name .. '[/color])'
    end

    -- FR : Autre valeur (ex. defines, une table) : son type
    -- EN : Other value (e.g. defines, a table): its type
    return name .. ' ([color=1,0.3,0.3,1]' .. type(value) .. '[/color])'
end


---FR : Construit les outils des arbres dans la barre d'outils de la fenêtre principale (cachés au départ).
---     Repris de l'ancien Gui.build_tools. Appelé par GvvGuiMain:open, après les outils du suivi.
---EN : Builds the trees tools inside the main window toolbar (hidden at first).
---     Taken from the old Gui.build_tools. Called by GvvGuiMain:open, after the tracking tools.
---@param event table
function GvvGuiTree.buildTools(event)
    local main = GvvGuiMain(event)
    local tools = main:getElement("flow", "tools")
    local data = main:getData()
    if tools == nil or data == nil then
        return
    end
    local specs = fGui.getTools(TOOLS_NAME)

    -- FR : Bouton de rafraîchissement
    -- EN : Refresh button
    local refresh = tools.add(specs.button.refresh)
    refresh.style.width = 20
    refresh.style.height = 20

    -- FR : Cases n/a, nil, méthodes, cochées selon les réglages du joueur
    -- EN : n/a, nil, methods boxes, checked according to the player settings
    for _, box_name in ipairs({ "na", "nil", "func" }) do
        local spec = specs.checkbox[box_name]
        spec.state = data[SHOW_SETTINGS[box_name]]
        tools.add(spec)
    end
end


---FR : Changement d'onglet : outils des arbres affichés selon l'onglet (rafraîchir : onglets des arbres ;
---     cases : onglets d'objets), et liste de l'arbre de l'onglet remplie à nouveau si sa configuration le demande.
---     Repris de l'ancien Gui.change_tab. Appelé par GvvGuiMain:changeTab.
---EN : Tab change: trees tools shown according to the tab (refresh: trees tabs;
---     boxes: objects tabs), and list of the tab tree filled again if its configuration asks for it.
---     Taken from the old Gui.change_tab. Called by GvvGuiMain:changeTab.
---@param event table
---@param tab_index integer
function GvvGuiTree.changeTab(event, tab_index)
    local tools = GvvGuiMain(event):getElement("flow", "tools")
    local tree = GvvGuiTree.fromTab(event, tab_index)

    -- FR : Bouton de rafraîchissement : sur les onglets des arbres
    -- EN : Refresh button: on the trees tabs
    local refresh = check.tryGet(tools, TOOLS_NAME .. "-button-refresh")
    if refresh ~= nil then
        refresh.visible = tree ~= nil
    end

    -- FR : Cases : sur les onglets d'objets (propriétés d'objets Lua)
    -- EN : Boxes: on the objects tabs (Lua object properties)
    for box_name in pairs(SHOW_SETTINGS) do
        local box = check.tryGet(tools, TOOLS_NAME .. "-checkbox-" .. box_name)
        if box ~= nil then
            box.visible = tree ~= nil and tree.config.prop_allowed
        end
    end

    -- FR : Liste remplie à nouveau (ex. les mods qui chargent gvv)
    -- EN : List filled again (e.g. the mods loading gvv)
    if tree ~= nil and tree.config.refill_on_tab then
        tree:fillList()
    end
end


---FR : Rafraîchit l'arbre de l'onglet affiché (bouton de rafraîchissement, Shift+X).
---EN : Refreshes the tree of the displayed tab (refresh button, Shift+X).
---@param event table
function GvvGuiTree.refreshTab(event)
    local tabbed = GvvGuiMain(event):getElement("tabbed", "tabs")
    if tabbed == nil then
        return
    end
    local tree = GvvGuiTree.fromTab(event, tabbed.selected_tab_index)
    if tree ~= nil then
        tree:refresh()
    end
end


---------------------------------------------------------------------------------------------
-- FR : ACCÈS
-- EN : ACCESS
---------------------------------------------------------------------------------------------

---FR : Conteneur de l'arbre (zone défilante), ou nil.
---EN : Tree container (scrolling area), or nil.
---@return LuaGuiElement?
function GvvGuiTree:getPane()
    return self:getElement("pane", "tree")
end


---FR : Enfant d'un élément par sa partie « type-name » (ex. child(row, "frame-label")), ou nil.
---EN : Child of an element by its "type-name" part (e.g. child(row, "frame-label")), or nil.
---@param element LuaGuiElement?
---@param type_name string
---@return LuaGuiElement?
function GvvGuiTree:child(element, type_name)
    return check.tryGet(element, self.gui_name .. "-" .. type_name)
end


---FR : Dossiers ouverts gardés pour une racine, et état ouvert / fermé de la racine (créés si besoin).
---EN : Kept opened folders for a root, and the root opened / closed state (created if needed).
---@param root_key string
---@return table opened_folders
---@return table opened_root   { vis = boolean }
function GvvGuiTree:getOpened(root_key)
    local data = self:getData().data
    local opened = self.config.opened
    if not data.opened_data then
        data.opened_data = {}
    end
    if not data.opened_root then
        data.opened_root = {}
    end
    if not data.opened_data[opened] then
        data.opened_data[opened] = {}
    end
    if not data.opened_root[opened] then
        data.opened_root[opened] = {}
    end
    if not data.opened_data[opened][root_key] then
        data.opened_data[opened][root_key] = {}
    end
    if not data.opened_root[opened][root_key] then
        data.opened_root[opened][root_key] = { vis = true }
    end
    return data.opened_data[opened][root_key], data.opened_root[opened][root_key]
end


---FR : Ligne qui contient l'élément (conteneur qui a des tags de ligne), ou nil.
---EN : Row that contains the element (container that has row tags), or nil.
---@param element LuaGuiElement
---@return LuaGuiElement?
function GvvGuiTree:rowOf(element)
    local current = element
    while check.isValidLuaObject(current) do
        if check.tryGet(current.tags, "row") then
            return current
        end
        current = current.parent
    end
    return nil
end


---FR : Ligne parente d'une ligne (le dossier qui la contient), ou nil pour une racine.
---EN : Parent row of a row (the folder that holds it), or nil for a root.
---@param row LuaGuiElement
---@return LuaGuiElement?
function GvvGuiTree:parentRow(row)
    if row.tags.root then
        return nil
    end
    -- FR : ligne > flow-folder > flow-content > ligne parente
    -- EN : row > flow-folder > flow-content > parent row
    return check.getPath(row, {"parent", "parent", "parent"})
end


---FR : Chemin d'une ligne : les clés depuis la racine, ex. { "RitnLib", "players", 1 }.
---EN : Path of a row: the keys from the root, e.g. { "RitnLib", "players", 1 }.
---@param row LuaGuiElement
---@return table
function GvvGuiTree:pathOf(row)
    local path = {}
    local current = row
    while current ~= nil do
        table.insert(path, 1, current.tags.key)
        current = self:parentRow(current)
    end
    return path
end


---FR : Valeur au bout d'un chemin : données de la racine (configuration), puis chaque clé.
---     Renvoie nil si une étape manque (donnée supprimée depuis l'affichage).
---EN : Value at the end of a path: root data (configuration), then each key.
---     Returns nil if a step is missing (data removed since it was displayed).
---@param path table
---@return any
function GvvGuiTree:readPath(path)
    return check.getPath(self.config.read(self, path[1]), path, 2)
end


---FR : Données à dessiner pour une valeur : dans les onglets d'objets, la liste des propriétés
---     d'un objet Lua, ou d'une racine (comme avant) ; sinon la valeur elle-même.
---EN : Data to draw for a value: in the objects tabs, the properties list
---     of a Lua object, or of a root (as before); otherwise the value itself.
---@param value any
---@param is_root boolean
---@return any
function GvvGuiTree:expand(value, is_root)
    if self.config.prop_allowed and (is_root or check.isLuaObject(value)) then
        return Util.get_property_list(value, true)
    end
    return value
end


---FR : Lignes racines affichées dans l'arbre.
---EN : Root rows displayed in the tree.
---@return LuaGuiElement[]
function GvvGuiTree:getRoots()
    local roots = {}
    local pane = self:getPane()
    if pane == nil then
        return roots
    end
    for _, row in ipairs(pane.children) do
        if check.tryGet(row.tags, "root") then
            roots[#roots + 1] = row
        end
    end
    return roots
end


---------------------------------------------------------------------------------------------
-- FR : CONSTRUCTION DE L'ONGLET
-- EN : TAB BUILDING
---------------------------------------------------------------------------------------------

---FR : Construit l'onglet : liste à gauche, arbre à droite, panneau de recherche, puis remplit la liste.
---     Repris de l'ancien Gui.build_storage. Appelé par GvvGuiMain:open.
---EN : Builds the tab: list on the left, tree on the right, search panel, then fills the list.
---     Taken from the old Gui.build_storage. Called by GvvGuiMain:open.
---@return GvvGuiTree
function GvvGuiTree:build()
    if not check.isValidLuaObject(self.gui[1]) then
        return self
    end
    local specs = self.specs

    -- FR : Conteneur de l'onglet, avec une bande de fond en haut
    -- EN : Tab container, with a background strip at the top
    local wrap = self.gui[1].add(specs.flow.wrap)
    local fill = wrap.add(specs.empty.fill)
    fill.style.height = 8

    -- FR : Liste à gauche, séparateur, arbre à droite
    -- EN : List on the left, divider, tree on the right
    local panel = wrap.add(specs.flow.panel)
    local list = panel.add(specs.pane.list)
    list.style.horizontally_stretchable = false
    list.style.horizontally_squashable = true
    list.style.maximal_width = 230
    local divider = panel.add(specs.empty.divider)
    divider.style.width = 6
    panel.add(specs.pane.tree)

    -- FR : Panneau de recherche, à droite de l'arbre
    -- EN : Search panel, on the right of the tree
    GvvGuiSearch(self.event):buildPanel(self.config.search, panel)

    self:fillList()
    return self
end


---FR : Remplit la liste de gauche (ex. les mods accessibles). Appelé à la construction et à chaque
---     retour sur l'onglet (la liste des mods peut changer).
---EN : Fills the left list (e.g. the accessible mods). Called on building and each time the tab
---     is displayed again (the mods list can change).
---@return GvvGuiTree
function GvvGuiTree:fillList()
    local list = self:getElement("pane", "list")
    if list == nil then
        return self
    end
    list.clear()
    local spec = self.specs.button.item

    -- FR : Boutons de souris acceptés (ex. clic droit pour retirer un objet ajouté)
    -- EN : Accepted mouse buttons (e.g. right click to remove an added object)
    spec.mouse_button_filter = self.config.item_buttons

    for index, item in ipairs(self.config.getItems(self)) do
        -- FR : Bouton item_<n>, valeur dans ses tags
        -- EN : item_<n> button, value in its tags
        spec.name = self.gui_name .. "-button-item_" .. index
        spec.caption = item.caption
        spec.tooltip = item.tooltip
        spec.tags = { item = item.value }
        list.add(spec)
    end
    return self
end


---FR : Bouton de la liste dont la valeur est item, ou nil.
---EN : List button whose value is item, or nil.
---@param item any
---@return LuaGuiElement?
function GvvGuiTree:getItemButton(item)
    local list = self:getElement("pane", "list")
    if list == nil then
        return nil
    end
    for _, button in ipairs(list.children) do
        if check.tryGet(button.tags, "item") == item then
            return button
        end
    end
    return nil
end


---FR : Retire un élément de la liste (ex. objet ajouté, clic droit) : oublié par la configuration,
---     son bouton est détruit, et son arbre effacé s'il est affiché. Repris de l'ancien remove_prop_tree.
---EN : Removes an element from the list (e.g. added object, right click): forgotten by the configuration,
---     its button is destroyed, and its tree cleared if it is displayed. Taken from the old remove_prop_tree.
---@param item any
---@return GvvGuiTree
function GvvGuiTree:removeItem(item)
    -- FR : Oublié par la configuration (ex. retiré de data.data.docked_luaobj)
    -- EN : Forgotten by the configuration (e.g. removed from data.data.docked_luaobj)
    if self.config.forget then
        self.config.forget(self, item)
    end

    -- FR : Son bouton
    -- EN : Its button
    local button = self:getItemButton(item)
    if button ~= nil then
        button.destroy()
    end

    -- FR : Son arbre, s'il est affiché
    -- EN : Its tree, if it is displayed
    for _, root in ipairs(self:getRoots()) do
        if root.tags.item == item then
            self:getPane().clear()
            break
        end
    end
    return self
end


---------------------------------------------------------------------------------------------
-- FR : DESSIN DE L'ARBRE
-- EN : TREE DRAWING
---------------------------------------------------------------------------------------------

---FR : Dessine la partie fixe d'une ligne : traits de l'arbre (repris de l'ancien draw_branch).
---     no_icon : ligne sans icône (valeur), le trait horizontal est plus long.
---EN : Draws the fixed part of a row: tree lines (taken from the old draw_branch).
---     no_icon: row without icon (value), the horizontal line is longer.
---@param row LuaGuiElement
---@param no_icon boolean
---@return LuaGuiElement label  frame-label de la ligne / row frame-label
function GvvGuiTree:drawBranch(row, no_icon)
    local specs = self.specs
    row.style.vertically_stretchable = false

    local label = row.add(specs.frame.label)
    label.style.height = 20

    -- FR : Trait vertical
    -- EN : Vertical line
    local vbar = label.add(specs.flow.vbar)
    vbar.style.left_margin = 9
    vbar.style.width = 2
    vbar.style.vertically_stretchable = true
    local vbar_part = vbar.add(specs.empty.vbar)
    vbar_part.style.width = 2
    vbar_part.style.height = 20

    -- FR : Trait horizontal
    -- EN : Horizontal line
    local hbar = label.add(specs.flow.hbar)
    if no_icon then
        hbar.style.width = 30
    else
        hbar.style.width = 10
    end
    hbar.style.vertically_stretchable = true
    hbar.style.vertical_align = 'center'
    local hbar_part = hbar.add(specs.empty.hbar)
    hbar_part.style.height = 2
    hbar_part.style.horizontally_stretchable = true

    return label
end


---FR : Ajoute une ligne de dossier (repris de l'ancien draw_folder). Renvoie la ligne, son flow-folder
---     (où s'ajoutent ses lignes) et sa clé (bouton).
---EN : Adds a folder row (taken from the old draw_folder). Returns the row, its flow-folder
---     (where its rows are added) and its key (button).
---@param parent LuaGuiElement   flow-folder parent, ou le conteneur de l'arbre pour une racine / parent flow-folder, or the tree container for a root
---@param key any
---@param caption LocalisedString
---@param root_item? any   Racine : l'élément de la liste qu'elle affiche ; nil pour un dossier / Root: the list element it shows; nil for a folder
---@return LuaGuiElement row
---@return LuaGuiElement folder
---@return LuaGuiElement key_button
function GvvGuiTree:addFolderRow(parent, key, caption, root_item)
    local specs = self.specs

    -- FR : Ligne de dossier ; clé et nature dans ses tags (une racine garde aussi l'élément de la liste)
    -- EN : Folder row; key and kind in its tags (a root also keeps the list element)
    specs.flow.row.tags = { row = true, key = key, folder = true, root = root_item ~= nil, item = root_item }
    local row = parent.add(specs.flow.row)
    local label = self:drawBranch(row, false)

    -- FR : Icône de dossier ouvert, et clé (clic gauche : ouvrir / fermer ; clic droit : suivre)
    -- EN : Opened folder icon, and key (left click: open / close; right click: track)
    local sprite = label.add(specs.sprite.folder)
    sprite.style.width = 20
    sprite.style.height = 20
    sprite.style.stretch_image_to_widget_size = true
    specs.button.key.caption = caption
    specs.button.key.style = 'tree-item-folder_gvv-mod'
    specs.button.key.mouse_button_filter = {'left', 'right'}
    local key_button = label.add(specs.button.key)

    -- FR : Contenu : prolongement du trait, puis les lignes du dossier
    -- EN : Content: line extension, then the folder rows
    local content = row.add(specs.flow.content)
    local extbar = content.add(specs.flow.extbar)
    extbar.style.width = 11
    extbar.style.horizontal_align = 'right'
    local extbar_part = extbar.add(specs.empty.extbar)
    extbar_part.style.left_margin = 9
    extbar_part.style.width = 2
    extbar_part.style.vertically_stretchable = true

    local folder = content.add(specs.flow.folder)
    folder.style.left_padding = 11
    return row, folder, key_button
end


---FR : Ajoute une ligne de valeur : clé (clic droit : suivre), puis « = » et la valeur si value_caption est donné.
---EN : Adds a value row: key (right click: track), then "=" and the value if value_caption is given.
---@param parent LuaGuiElement
---@param key any
---@param key_caption LocalisedString
---@param key_style string
---@param value_caption? LocalisedString
---@param value_is_object? boolean  Valeur objet Lua (bouton, clic droit pour l'ajouter) / Lua object value (button, right click to add it)
---@param kind? string  « na », « nil » ou « func » : ligne cachée par la case du même nom / "na", "nil" or "func": row hidden by the box of the same name
---@return LuaGuiElement row
function GvvGuiTree:addValueRow(parent, key, key_caption, key_style, value_caption, value_is_object, kind)
    local specs = self.specs

    -- FR : Ligne de valeur ; clé et sorte (n/a, nil, méthode) dans ses tags
    -- EN : Value row; key and kind (n/a, nil, method) in its tags
    specs.flow.row.tags = { row = true, key = key, kind = kind }
    local row = parent.add(specs.flow.row)
    local label = self:drawBranch(row, true)

    specs.button.key.caption = key_caption
    specs.button.key.style = key_style
    specs.button.key.mouse_button_filter = {'right'}
    label.add(specs.button.key)

    if value_caption ~= nil then
        label.add(specs.label.equal)
        if value_is_object then
            specs.button.value.caption = value_caption
            label.add(specs.button.value)
        else
            specs.label.value.caption = value_caption
            label.add(specs.label.value)
        end
    end
    return row
end


---FR : Ferme un dossier dessiné : contenu caché, icône de dossier fermé.
---EN : Closes a drawn folder: content hidden, closed folder icon.
---@param row LuaGuiElement
function GvvGuiTree:setFolderClosed(row)
    self:child(row, "flow-content").visible = false
    self:child(self:child(row, "frame-label"), "sprite-folder").sprite = 'gvv-mod_folder-closed'
end


---FR : Dessine les lignes d'une table dans un dossier (repris de l'ancien Tree.draw).
---     opened_tree : dossiers ouverts gardés pour ce niveau ; draw_from : lignes déjà dessinées
---     (« continuer à charger »). Au-delà de la limite, une ligne « continuer à charger » termine le dossier.
---EN : Draws the rows of a table inside a folder (taken from the old Tree.draw).
---     opened_tree: kept opened folders for this level; draw_from: rows already drawn
---     ("continue to load"). Past the limit, a "continue to load" row ends the folder.
---@param tbl table
---@param folder LuaGuiElement
---@param opened_tree table?
---@param draw_from? integer
function GvvGuiTree:drawItems(tbl, folder, opened_tree, draw_from)
    if not opened_tree or type(tbl) ~= 'table' then
        return
    end
    local data = self:getData()
    local prop_allowed = self.config.prop_allowed
    draw_from = draw_from or 0
    if not storage.meta_data.treelimit then
        storage.meta_data.treelimit = DEFAULT_TREE_LIMIT
    end

    local index = 0
    local drawn = 0
    local folder_keys = {}
    for key, value in pairs(tbl) do
        local value_type = type(value)
        index = index + 1
        if index > draw_from then
            drawn = drawn + 1

            if drawn > storage.meta_data.treelimit then
                -- FR : Limite atteinte : ligne « continuer à charger » (reste à dessiner à partir de index)
                -- EN : Limit reached: "continue to load" row (remaining to draw from index)
                self.specs.flow.row.tags = { row = true, key = key, cont_from = index - 1 }
                local row = folder.add(self.specs.flow.row)
                local label = self:drawBranch(row, false)
                local sprite = label.add(self.specs.sprite.load)
                sprite.style.width = 20
                sprite.style.height = 20
                sprite.style.stretch_image_to_widget_size = true
                self.specs.button.key.caption = {"gvv-mod.load_cont", table_size(tbl) - index + 1}
                self.specs.button.key.style = 'load-cont_gvv-mod'
                self.specs.button.key.mouse_button_filter = {'left'}
                label.add(self.specs.button.key)
                break
            end

            if prop_allowed and check.isLuaObject(value) then
                -- FR : Objet Lua (onglets d'objets) : dossier de ses propriétés
                -- EN : Lua object (objects tabs): folder of its properties
                local caption = Sprite.img(value) .. Table_to_str.to_richtext(key, true) .. ' ([color=blue]' .. value.object_name .. '[/color])'
                local row, sub_folder = self:addFolderRow(folder, key, caption)
                if not opened_tree[key] then
                    self:setFolderClosed(row)
                else
                    self:drawItems(Util.get_property_list(value, true), sub_folder, opened_tree[key])
                end
                folder_keys[key] = true

            elseif value_type == 'table' and getmetatable(value) == storage.meta_data._nil_ then
                -- FR : Propriété nil (onglets d'objets), cachée selon la case nil
                -- EN : nil property (objects tabs), hidden according to the nil box
                local row = self:addValueRow(folder, key, Table_to_str.to_richtext(key, true), 'tree-item_gvv-mod',
                    Table_to_str.to_richtext(nil), false, 'nil')
                if not data.show_nil then
                    row.visible = false
                end

            elseif value_type == 'table' and getmetatable(value) == storage.meta_data._na_ then
                -- FR : Propriété non disponible (onglets d'objets), cachée selon la case n/a
                -- EN : Unavailable property (objects tabs), hidden according to the n/a box
                local row = self:addValueRow(folder, key, '[color=0.5,0.5,0.5,0.5]' .. Table_to_str.to_richtext(key, true) .. '[/color]',
                    'tree-item-na_gvv-mod', '[color=0.5,0,0,0.5]n/a[/color]', false, 'na')
                if not data.show_na then
                    row.visible = false
                end

            elseif value_type == 'function' or value_type == 'table' and getmetatable(value) == storage.meta_data._function_ then
                if prop_allowed then
                    -- FR : Méthode (onglets d'objets), cachée selon la case méthodes
                    -- EN : Method (objects tabs), hidden according to the methods box
                    local row = self:addValueRow(folder, key, '[color=0.5,0.5,0.5,0.5]' .. Table_to_str.to_richtext(key, true) .. '(...)[/color]',
                        'tree-item-func_gvv-mod', nil, false, 'func')
                    if not data.show_func then
                        row.visible = false
                    end
                else
                    -- FR : Fonction dans des données : valeur affichée en texte
                    -- EN : Function inside data: value shown as text
                    self:addValueRow(folder, key, Table_to_str.to_richtext(key, true), 'tree-item_gvv-mod', Table_to_str.to_richtext(value))
                end

            elseif value_type == 'table' then
                -- FR : Table : dossier, ouvert si gardé ouvert, sinon fermé (chargé au premier clic)
                -- EN : Table: folder, opened if kept opened, otherwise closed (loaded on first click)
                local row, sub_folder = self:addFolderRow(folder, key, Table_to_str.to_richtext(key, true))
                if not opened_tree[key] then
                    self:setFolderClosed(row)
                else
                    self:drawItems(value, sub_folder, opened_tree[key])
                end
                folder_keys[key] = true

            else
                -- FR : Valeur simple, ou objet Lua (bouton : clic droit pour l'ajouter à l'onglet property)
                -- EN : Simple value, or Lua object (button: right click to add it to the property tab)
                if check.isLuaObject(value) then
                    self:addValueRow(folder, key, Table_to_str.to_richtext(key, true), 'tree-item_gvv-mod',
                        Sprite.img(value) .. Table_to_str.to_richtext(value), true)
                else
                    self:addValueRow(folder, key, Table_to_str.to_richtext(key, true), 'tree-item_gvv-mod', Table_to_str.to_richtext(value))
                end
            end
        end
    end

    -- FR : Les dossiers gardés ouverts qui n'existent plus sont oubliés
    -- EN : Kept opened folders that no longer exist are forgotten
    for key in pairs(opened_tree) do
        if not folder_keys[key] then
            opened_tree[key] = nil
        end
    end
    self:reviseLines(folder)
end


---FR : Ajuste les traits de l'arbre : la dernière ligne visible d'un dossier a un trait vertical
---     raccourci (repris de l'ancien Tree.revision_line).
---EN : Adjusts the tree lines: the last visible row of a folder has a shortened
---     vertical line (taken from the old Tree.revision_line).
---@param folder LuaGuiElement
function GvvGuiTree:reviseLines(folder)
    local last_visible = nil
    for _, row in ipairs(folder.children) do
        local label = self:child(row, "frame-label")
        if label ~= nil and row.visible then
            last_visible = row
            self:child(self:child(label, "flow-vbar"), "empty-vbar").style.height = 20
            local content = self:child(row, "flow-content")
            if content ~= nil then
                self:setExtbarStyle(content, 'branch_gvv-mod')
                self:reviseLines(self:child(content, "flow-folder"))
            end
        end
    end
    if last_visible ~= nil then
        local label = self:child(last_visible, "frame-label")
        self:child(self:child(label, "flow-vbar"), "empty-vbar").style.height = 11
        local content = self:child(last_visible, "flow-content")
        if content ~= nil then
            self:setExtbarStyle(content, 'branch-hide_gvv-mod')
        end
    end
end


-- FR : Style du prolongement de trait d'un dossier (visible ou caché), avec ses réglages
-- EN : Style of a folder line extension (visible or hidden), with its settings
function GvvGuiTree:setExtbarStyle(content, style)
    local part = self:child(self:child(content, "flow-extbar"), "empty-extbar")
    part.style = style
    part.style.left_margin = 9
    part.style.width = 2
    part.style.vertically_stretchable = true
end


---FR : Dessine l'arbre de l'élément choisi dans la liste (ex. un mod) : garde d'abord les dossiers
---     ouverts de l'arbre affiché, puis dessine chaque racine (repris de l'ancien Tree.draw_init).
---EN : Draws the tree of the element chosen in the list (e.g. a mod): first keeps the opened
---     folders of the displayed tree, then draws each root (taken from the old Tree.draw_init).
---@param selection any
---@return GvvGuiTree
function GvvGuiTree:draw(selection)
    local pane = self:getPane()
    if pane == nil then
        return self
    end

    -- FR : Racines à dessiner ; la configuration peut lever une erreur (ex. objet ajouté qui n'existe plus)
    -- EN : Roots to draw; the configuration may raise an error (e.g. added object that no longer exists)
    local roots = self.config.getRoots(self, selection)

    -- FR : Dossiers ouverts de l'arbre affiché gardés, puis arbre vidé
    -- EN : Opened folders of the displayed tree kept, then tree emptied
    self:saveOpened()
    pane.clear()

    for _, root in ipairs(roots) do
        local opened_tree, opened_root = self:getOpened(root.key)

        -- FR : Données de la racine ; une erreur s'affiche comme une entrée « <ERROR> » (comme avant)
        -- EN : Root data; an error is shown as an "<ERROR>" entry (as before)
        local read, value = pcall(function()
            return self:expand(self.config.read(self, root.key), true)
        end)
        if not read then
            value = {['<ERROR>'] = '<' .. tostring(value) .. '>'}
        end

        local row, folder = self:addFolderRow(pane, root.key, root.caption, selection)
        self:drawItems(value, folder, opened_tree)

        -- FR : Racine fermée si elle l'était ; pas de traits devant une racine
        -- EN : Root closed if it was; no lines in front of a root
        if not opened_root.vis then
            self:setFolderClosed(row)
        end
        local content = self:child(row, "flow-content")
        local label = self:child(row, "frame-label")
        self:child(content, "flow-extbar").visible = false
        self:child(label, "flow-vbar").visible = false
        self:child(self:child(label, "flow-hbar"), "empty-hbar").style = 'branch-hide_gvv-mod'
        if root.bottom_padding then
            row.style.bottom_padding = 75
        end
    end
    return self
end


---FR : Redessine l'arbre de l'élément choisi en dernier (bouton de rafraîchissement, Shift+X).
---EN : Draws again the tree of the last chosen element (refresh button, Shift+X).
---@return GvvGuiTree
function GvvGuiTree:refresh()
    local selection = check.getPath(self:getData(), {"tabs", self.config.last_selection})

    -- FR : Comme avant : seulement si l'élément est encore dans la liste (un objet retiré ne revient pas)
    -- EN : As before: only if the element is still in the list (a removed object doesn't come back)
    if selection ~= nil and self:getItemButton(selection) ~= nil then
        self:draw(selection)
        GvvGuiSearch(self.event):refresh(self.config.search)
    end
    return self
end


---FR : Garde les dossiers ouverts de l'arbre affiché (et l'état ouvert / fermé de chaque racine),
---     pour les rouvrir au prochain dessin. Repris de l'ancien save_opened_tree / save_on_quit.
---EN : Keeps the opened folders of the displayed tree (and each root opened / closed state),
---     to open them again on the next drawing. Taken from the old save_opened_tree / save_on_quit.
---@return GvvGuiTree
function GvvGuiTree:saveOpened()
    for _, root in ipairs(self:getRoots()) do
        local opened_tree, opened_root = self:getOpened(root.tags.key)

        -- FR : Ancien état effacé (même table : elle reste partagée), puis recalculé
        -- EN : Old state cleared (same table: it stays shared), then computed again
        for key in pairs(opened_tree) do
            opened_tree[key] = nil
        end
        local content = self:child(root, "flow-content")
        opened_root.vis = content.visible
        if opened_root.vis then
            self:collectOpened(self:child(content, "flow-folder"), opened_tree)
        end
    end
    return self
end


-- FR : Ajoute à opened_tree les dossiers ouverts d'un dossier, récursivement
-- EN : Adds to opened_tree the opened folders of a folder, recursively
function GvvGuiTree:collectOpened(folder, opened_tree)
    for _, row in ipairs(folder.children) do
        local content = self:child(row, "flow-content")
        if check.tryGet(row.tags, "folder") and content ~= nil and content.visible then
            opened_tree[row.tags.key] = {}
            self:collectOpened(self:child(content, "flow-folder"), opened_tree[row.tags.key])
        end
    end
end


---FR : Affiche ou cache les lignes d'une sorte (« na », « nil » ou « func ») dans tout l'arbre,
---     puis ajuste les traits. Repris de l'ancien Tree.set_visible_item.
---EN : Shows or hides the rows of a kind ("na", "nil" or "func") in the whole tree,
---     then adjusts the lines. Taken from the old Tree.set_visible_item.
---@param kind string
---@param state boolean
---@return GvvGuiTree
function GvvGuiTree:setVisible(kind, state)
    local pane = self:getPane()
    if pane == nil then
        return self
    end
    self:setRowsVisible(pane, kind, state)
    self:reviseLines(pane)
    return self
end


-- FR : Affiche ou cache les lignes d'une sorte dans un dossier, récursivement
-- EN : Shows or hides the rows of a kind inside a folder, recursively
function GvvGuiTree:setRowsVisible(folder, kind, state)
    for _, row in ipairs(folder.children) do
        -- FR : Ligne de cette sorte : affichée ou cachée
        -- EN : Row of this kind: shown or hidden
        if check.tryGet(row.tags, "kind") == kind then
            row.visible = state
        end

        -- FR : Dossier : ses lignes aussi
        -- EN : Folder: its rows too
        local content = self:child(row, "flow-content")
        if content ~= nil then
            self:setRowsVisible(self:child(content, "flow-folder"), kind, state)
        end
    end
end


---------------------------------------------------------------------------------------------
-- FR : RECHERCHE (appelée par GvvGuiSearch) — même logique que l'ancien legacy/search_tree.lua
-- EN : SEARCH (called by GvvGuiSearch) — same logic as the old legacy/search_tree.lua
---------------------------------------------------------------------------------------------

---FR : Remet le style normal sur toutes les lignes (recherche fermée).
---EN : Puts the normal style back on all rows (search closed).
function GvvGuiTree:searchReset()
    for _, root in ipairs(self:getRoots()) do
        self:resetRows(self:child(self:child(root, "flow-content"), "flow-folder"))
    end
end

-- FR : Style normal sur les lignes d'un dossier, dossiers compris
-- EN : Normal style on a folder rows, folders included
function GvvGuiTree:resetRows(folder)
    for _, row in ipairs(folder.children) do
        local label = self:child(row, "frame-label")
        if label ~= nil then
            label.style = 'transparent-frame_gvv-mod'
            local content = self:child(row, "flow-content")
            if content ~= nil then
                self:resetRows(self:child(content, "flow-folder"))
            end
        end
    end
end

-- FR : Style normal sur les lignes d'un dossier fermé (sans y chercher)
-- EN : Normal style on a closed folder rows (without searching in it)
function GvvGuiTree:notScan(folder)
    for _, row in ipairs(folder.children) do
        local label = self:child(row, "frame-label")
        if label ~= nil then
            label.style = 'transparent-frame_gvv-mod'
        end
    end
end


---FR : Cherche dans les lignes affichées de chaque racine ouverte. state : voir GvvGuiSearch:refresh,
---     avec removeRichKey / removeRichValue pour retirer le texte enrichi.
---EN : Searches the displayed rows of each opened root. state: see GvvGuiSearch:refresh,
---     with removeRichKey / removeRichValue to remove the rich text.
---@param state table
---@return boolean  true si l'arbre a des racines (sinon rien à chercher) / true if the tree has roots (otherwise nothing to search)
function GvvGuiTree:searchScan(state)
    local roots = self:getRoots()
    for _, root in ipairs(roots) do
        local content = self:child(root, "flow-content")
        local folder = self:child(content, "flow-folder")
        if content.visible then
            self:scanRows(folder, state)
        else
            self:notScan(folder)
        end
    end
    return #roots > 0
end

-- FR : Cherche dans les lignes visibles d'un dossier, et dans ses sous-dossiers ouverts
-- EN : Searches the visible rows of a folder, and its opened sub-folders
function GvvGuiTree:scanRows(folder, state)
    for _, row in ipairs(folder.children) do
        local label = self:child(row, "frame-label")
        local key_button = self:child(label, "button-key")
        if label ~= nil and row.visible and key_button ~= nil and type(key_button.caption) == 'string' then
            local value_element = self:child(label, "label-value") or self:child(label, "button-value")

            -- FR : Clé et valeur sans texte enrichi, en minuscules si la casse est ignorée
            -- EN : Key and value without rich text, in lower case if case is ignored
            local key = state.removeRichKey(key_button.caption)
            if not state.case then
                key = key:lower()
            end
            local value = nil
            if value_element ~= nil then
                value = state.removeRichValue(value_element.caption)
                if not state.case then
                    value = value:lower()
                end
            end

            if state.text ~= '' and state.key and key:match(state.text) then
                local name = key_button.caption
                if value then
                    name = key_button.caption .. ' = ' .. value_element.caption
                end
                state.found[#state.found + 1] = { elem = key_button, name = name }
                label.style = 'highlighted-frame_gvv-mod'
            elseif state.text ~= '' and state.value and value and value:match(state.text) then
                state.found[#state.found + 1] = { elem = key_button, name = key_button.caption .. ' = ' .. value_element.caption }
                label.style = 'highlighted-frame_gvv-mod'
            else
                label.style = 'transparent-frame_gvv-mod'
            end

            -- FR : Sous-dossier : ouvert -> on cherche dedans ; fermé -> style normal
            -- EN : Sub-folder: opened -> search inside; closed -> normal style
            local content = self:child(row, "flow-content")
            if content ~= nil and content.visible then
                self:scanRows(self:child(content, "flow-folder"), state)
            elseif content ~= nil then
                self:notScan(self:child(content, "flow-folder"))
            end
        end
    end
end


---------------------------------------------------------------------------------------------
-- FR : ÉVÈNEMENTS
-- EN : EVENTS
---------------------------------------------------------------------------------------------

---FR : Clic : bouton de rafraîchissement des outils, boutons de la liste de gauche (item_<n>),
---     puis les actions des lignes.
---EN : Click: tools refresh button, left list buttons (item_<n>), then the rows actions.
---@return boolean
function GvvGuiTree:on_gui_click(...)
    if not self.isPresent or not check.isValidLuaObject(self.element) then
        return false
    end
    local gui_name, short_type, element_name = GvvGui.splitName(self.element.name)

    -- FR : Outils : rafraîchir l'arbre de l'onglet affiché
    -- EN : Tools: refresh the tree of the displayed tab
    if gui_name == TOOLS_NAME and short_type == "button" and element_name == "refresh" then
        GvvGuiTree.refreshTab(self.event)
        return true
    end

    -- FR : Liste : clic gauche choisit, clic droit retire (si la configuration le permet)
    -- EN : List: left click chooses, right click removes (if the configuration allows it)
    if gui_name == self.gui_name and short_type == "button" and element_name:match("^item_%d+$") then
        if self.event.button == defines.mouse_button_type.right then
            self:action_remove()
        else
            self:action_select()
        end
        return true
    end
    return self:dispatch(nil, ...)
end


---FR : Case des outils cochée / décochée (n/a, nil, méthodes) : réglage gardé, lignes affichées ou cachées
---     dans les arbres d'objets, puis recherche relancée. Repris de l'ancien code (chk_show_*).
---EN : Tools box checked / unchecked (n/a, nil, methods): setting kept, rows shown or hidden
---     in the objects trees, then search run again. Taken from the old code (chk_show_*).
---@return boolean
function GvvGuiTree:on_gui_checked_state_changed(...)
    if not self.isPresent or not check.isValidLuaObject(self.element) then
        return false
    end
    local gui_name, short_type, element_name = GvvGui.splitName(self.element.name)
    if gui_name ~= TOOLS_NAME or short_type ~= "checkbox" or SHOW_SETTINGS[element_name] == nil then
        return self:dispatch("checked_state_changed", ...)
    end

    -- FR : Réglage du joueur
    -- EN : Player setting
    local state = self.element.state
    self:getData()[SHOW_SETTINGS[element_name]] = state

    -- FR : Arbres d'objets : lignes de cette sorte affichées ou cachées, puis recherche relancée
    -- EN : Objects trees: rows of this kind shown or hidden, then search run again
    for _, tree in ipairs(GvvGuiTree.all(self.event)) do
        if tree.config.prop_allowed then
            tree:setVisible(element_name, state)
            GvvGuiSearch(self.event):refresh(tree.config.search)
        end
    end
    return true
end


---FR : Élément de la liste choisi : son arbre est dessiné, puis la recherche relancée.
---EN : List element chosen: its tree is drawn, then the search run again.
function GvvGuiTree:action_select()
    local item = self.element.tags.item
    self:draw(item)
    GvvGuiSearch(self.event):refresh(self.config.search)
    self:getData().tabs[self.config.last_selection] = item
end


---FR : Clic droit sur un élément de la liste : retiré (ex. objet ajouté), puis la recherche relancée.
---EN : Right click on a list element: removed (e.g. added object), then the search run again.
function GvvGuiTree:action_remove()
    -- FR : Configuration qui ne permet pas de retirer : rien à faire
    -- EN : Configuration that doesn't allow removing: nothing to do
    if not self.config.forget then
        return
    end
    local item = self.element.tags.item
    self:removeItem(item)
    GvvGuiSearch(self.event):refresh(self.config.search)

    -- FR : Élément choisi en dernier retiré : plus rien à rafraîchir
    -- EN : Last chosen element removed: nothing left to refresh
    local tabs = self:getData().tabs
    if tabs[self.config.last_selection] == item then
        tabs[self.config.last_selection] = nil
    end
end


---FR : Clic sur une clé : clic gauche ouvre / ferme un dossier ou continue le chargement ;
---     clic droit ajoute la ligne au suivi (ou retire le style « suivi »).
---EN : Click on a key: left click opens / closes a folder or continues the loading;
---     right click adds the row to the tracking (or removes the "tracked" style).
function GvvGuiTree:action_key()
    local row = self:rowOf(self.element)
    if row == nil then
        return
    end
    if self.event.button == defines.mouse_button_type.left then
        if row.tags.cont_from ~= nil then
            self:continueLoading(row)
        elseif row.tags.folder then
            self:toggleFolder(row)
        end
    elseif self.event.button == defines.mouse_button_type.right then
        self:toggleTracked(row)
    end
end


---FR : Données disparues depuis l'affichage : message, puis arbre redessiné (repris de on_tree_data_gone).
---EN : Data gone since it was displayed: message, then tree drawn again (taken from on_tree_data_gone).
function GvvGuiTree:onDataGone()
    self.player.print({"gvv-mod.tree-data-gone"})
    self:refresh()
end


---FR : Ouvre / ferme un dossier ; à la première ouverture, ses lignes sont lues et dessinées.
---EN : Opens / closes a folder; on first opening, its rows are read and drawn.
---@param row LuaGuiElement
function GvvGuiTree:toggleFolder(row)
    local path = self:pathOf(row)
    if self.config.isBlocked(self, path) then
        return
    end

    local content = self:child(row, "flow-content")
    local folder = self:child(content, "flow-folder")
    content.visible = not content.visible

    -- FR : Dossier jamais chargé : lecture des données au bout du chemin
    -- EN : Folder never loaded: reading the data at the end of the path
    if #folder.children == 0 then
        local value = self:expand(self:readPath(path), #path == 1)
        if type(value) ~= 'table' then
            return self:onDataGone()
        end
        self:drawItems(value, folder, {})
    end

    -- FR : Icône de dossier ouvert / fermé
    -- EN : Opened / closed folder icon
    local sprite = self:child(self:child(row, "frame-label"), "sprite-folder")
    if content.visible then
        sprite.sprite = 'gvv-mod_folder-opened'
    else
        sprite.sprite = 'gvv-mod_folder-closed'
    end
    GvvGuiSearch(self.event):refresh(self.config.search)
end


---FR : « Continuer à charger » : la ligne est retirée, puis la suite du dossier est dessinée.
---EN : "Continue to load": the row is removed, then the rest of the folder is drawn.
---@param row LuaGuiElement
function GvvGuiTree:continueLoading(row)
    local parent = self:parentRow(row)
    local folder = row.parent
    local cont_from = row.tags.cont_from
    row.destroy()

    local path = self:pathOf(parent)
    local value = self:expand(self:readPath(path), #path == 1)
    if type(value) ~= 'table' then
        return self:onDataGone()
    end
    self:drawItems(value, folder, {}, cont_from)
    GvvGuiSearch(self.event):refresh(self.config.search)
end


---FR : Clic droit sur une clé : style « suivi » et ajout au suivi ; un second clic droit remet le style normal.
---EN : Right click on a key: "tracked" style and added to the tracking; a second right click puts the normal style back.
---@param row LuaGuiElement
function GvvGuiTree:toggleTracked(row)
    local key_button = self.element
    local tracked = TRACKED_STYLE[key_button.style.name]
    if tracked ~= nil then
        key_button.style = tracked
        GvvGuiTracking(self.event):add(self.config.fullPath(self, self:pathOf(row)))
        return
    end
    local untracked = UNTRACKED_STYLE[key_button.style.name]
    if untracked ~= nil then
        key_button.style = untracked
    end
end


---FR : Clic droit sur une valeur objet Lua : ajoutée à l'onglet property (style « suivi ») ;
---     un second clic droit remet le style normal.
---EN : Right click on a Lua object value: added to the property tab ("tracked" style);
---     a second right click puts the normal style back.
function GvvGuiTree:action_value()
    if self.event.button ~= defines.mouse_button_type.right then
        return
    end
    if self.element.style.name == 'tree-item-luaobj_gvv-mod' then
        self.element.style = 'tracked-tree-item-luaobj_gvv-mod'
        local row = self:rowOf(self.element)

        -- FR : Ajout à l'onglet property (sa configuration), qui s'affiche avec l'arbre de l'objet
        -- EN : Added to the property tab (its configuration), which is shown with the object tree
        local property = GvvGuiTree(self.event, "property")
        local index = property.config.addObject(property, row.tags.key, self.config.fullPath(self, self:pathOf(row)), self.element.caption)
        GvvGuiSearch(self.event):refresh(property.config.search)
        self:getData().tabs[property.config.last_selection] = index
    elseif self.element.style.name == 'tracked-tree-item-luaobj_gvv-mod' then
        self.element.style = 'tree-item-luaobj_gvv-mod'
    end
end
