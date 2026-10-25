---------------------------------------------------------------------------------------------
-- GVV GUI MAIN
---------------------------------------------------------------------------------------------
-- FR : Fenêtre principale de gvv (étape 3.1 de la restructuration 0.6).
--      Gère : l'ouverture, la fermeture et la bascule (Ctrl+Shift+V, /gvv), le bouton fermer,
--      le redimensionnement, le changement d'onglet.
--      Le contenu de chaque onglet et les boutons propres à chaque onglet sont encore construits
--      par l'ancien code (legacy/gui.lua, fonctions build_*), dans les conteneurs créés ici.
--      Description des éléments : gui/main.lua.
-- EN : gvv main window (step 3.1 of the 0.6 restructuring).
--      Handles: opening, closing and toggling (Ctrl+Shift+V, /gvv), the close button,
--      resizing, tab change.
--      The content of each tab and the buttons specific to each tab are still built
--      by the old code (legacy/gui.lua, build_* functions), inside the containers created here.
--      Elements description: gui/main.lua.
---------------------------------------------------------------------------------------------
local check = require(gvv.defines.lualib.common.check)
local fGui = require(gvv.defines.gui.main)
---------------------------------------------------------------------------------------------
-- FR : Ancien code, appelé le temps de la migration des onglets
-- EN : Old code, called while the tabs are being migrated
local Legacy_Gui = require(gvv.defines.legacy.gui)
local Legacy_Tree = require(gvv.defines.legacy.tree)
---------------------------------------------------------------------------------------------

-- FR : Nom de l'ancienne fenêtre principale (avant 0.6), détruite si elle traîne encore
-- EN : Name of the old main window (before 0.6), destroyed if it is still there
local LEGACY_FRAME_NAME = "_gvv-mod_frame_"


---@class GvvGuiMain : GvvGui
GvvGuiMain = gvv.classFactory.newclass(GvvGui, function(self, event)
    -- FR : Fenêtre « gvv_main », dont l'élément racine est « frame-main » (gvv_main-frame-main)
    -- EN : Window "gvv_main", whose root element is "frame-main" (gvv_main-frame-main)
    GvvGui.init(self, event, "gvv_main", "frame-main")
    self.object_name = "GvvGuiMain"

    --------------------------------------------------
    -- FR : La fenêtre vit dans player.gui.screen (fenêtre libre, déplaçable)
    -- EN : The window lives in player.gui.screen (free, movable window)
    if self.isPresent then
        self.gui = { self.player.gui.screen }
    end

    -- FR : Chemins des éléments (gui/main.lua)
    -- EN : Element paths (gui/main.lua)
    self.content = fGui.getContent()

    -- FR : Actions de la fenêtre : élément (type-name[-évènement]) -> méthode
    -- EN : Window actions: element (type-name[-event]) -> method
    self.gui_action = {
        ["button-close"] = "action_close",                                  -- FR : bouton fermer / EN : close button
        ["slider-width-value_changed"] = "action_resize",                   -- FR : curseur largeur / EN : width slider
        ["slider-height-value_changed"] = "action_resize",                  -- FR : curseur hauteur / EN : height slider
        ["tabbed-tabs-selected_tab_changed"] = "action_change_tab",         -- FR : changement d'onglet / EN : tab change
    }
    --------------------------------------------------
end)
----------------------------------------------------------------


---FR : Vrai si la fenêtre principale est ouverte.
---EN : True if the main window is open.
---@return boolean
function GvvGuiMain:isOpen()
    return self:getMainElement() ~= nil
end


---FR : Ouvre la fenêtre si elle est fermée, la ferme si elle est ouverte (Ctrl+Shift+V, /gvv).
---EN : Opens the window if it is closed, closes it if it is open (Ctrl+Shift+V, /gvv).
---@return GvvGuiMain
function GvvGuiMain:toggle()
    -- FR : Joueur absent ou invalide : rien à faire
    -- EN : Missing or invalid player: nothing to do
    if not self.isPresent then
        return self
    end

    if self:isOpen() then
        self:close()
    else
        self:open()
    end
    return self
end


---FR : Construit et ouvre la fenêtre principale.
---EN : Builds and opens the main window.
---@return GvvGuiMain
function GvvGuiMain:open()
    -- FR : Joueur absent, ou fenêtre déjà ouverte : rien à faire
    -- EN : Missing player, or window already open: nothing to do
    if not self.isPresent or self:isOpen() then
        return self
    end

    -- FR : Données gvv du joueur, créées et complétées si besoin
    -- EN : The player's gvv data, created and completed if needed
    local data, first_time = self:initData()

    -- FR : Ancienne fenêtre (noms d'avant 0.6) encore ouverte, par exemple dans une sauvegarde
    --      de développement sans changement de version : on la détruit
    -- EN : Old window (pre-0.6 names) still open, for example in a development save
    --      without version change: destroy it
    local legacy_frame = check.tryGet(self.gui[1], LEGACY_FRAME_NAME)
    if check.isValidLuaObject(legacy_frame) then
        legacy_frame.destroy()
    end
    -- FR : Même chose pour les anciennes petites fenêtres
    -- EN : Same for the old small windows
    GvvGuiDialog(self.event):destroyLegacy()

    -- FR : Les références d'éléments de l'ancien code repartent de zéro
    --      (elles pointaient vers une fenêtre qui n'existe plus)
    -- EN : The old code's element references start again from scratch
    --      (they pointed to a window that no longer exists)
    data.gui = {}
    -- FR : Dernier élément ouvert dans chaque onglet (tab2 : last_sub_mod, tab3 : last_sub_obj, tab4 : last_sub_gobj)
    -- EN : Last element opened in each tab (tab2: last_sub_mod, tab3: last_sub_obj, tab4: last_sub_gobj)
    data.tabs = {}

    -- FR : Description de tous les éléments de la fenêtre
    -- EN : Description of all the window elements
    local element = fGui.getElement(self.gui_name)

    --------------------------------------------------
    -- FR : Cadre principal, à la dernière taille choisie, centré à l'écran
    --      (avant 0.6, il s'ouvrait en haut à gauche : location = {0, 0}).
    --      Le centrage est activé une fois la taille donnée, pour être calculé sur la bonne taille.
    -- EN : Main frame, at the last chosen size, centred on screen
    --      (before 0.6, it opened top left: location = {0, 0}).
    --      Centring is enabled once the size is given, so it is computed on the right size.
    local frame = self.gui[1].add(element.frame.main)
    frame.style.width = data.last_width
    frame.style.height = data.last_height
    frame.auto_center = true

    --------------------------------------------------
    -- FR : Barre de titre : fond, titre, zone de déplacement, bouton fermer
    -- EN : Title bar: background, title, drag area, close button
    local top = frame.add(element.frame.top)
    top.style.top_padding = 4
    top.style.right_padding = 8
    top.style.left_padding = 8

    local header = top.add(element.flow.header)
    header.drag_target = frame                              -- FR : déplacer la fenêtre / EN : drag the window
    header.style.vertically_stretchable = false

    local title = header.add(element.label.title)
    title.caption = {"", {"gvv-mod.title"}, ' - gvv ', storage.meta_data.version}
    title.drag_target = frame

    local drag = header.add(element.empty.drag)
    drag.drag_target = frame
    drag.style.right_margin = 8
    drag.style.height = 24
    drag.style.horizontally_stretchable = true
    drag.style.vertically_stretchable = true

    header.add(element.button.close)

    --------------------------------------------------
    -- FR : Partie centrale : bordure gauche, cadre intérieur, bordure droite
    -- EN : Middle part: left border, inner frame, right border
    local middle = frame.add(element.flow.middle)

    local left = middle.add(element.empty.left)
    left.style.width = 5
    left.style.vertically_stretchable = true

    local wrap = middle.add(element.frame.wrap)
    local inner = wrap.add(element.frame.inner)

    local right = middle.add(element.empty.right)
    right.style.width = 5
    right.style.vertically_stretchable = true

    -- FR : Bordure basse
    -- EN : Bottom border
    local bottom = frame.add(element.empty.bottom)
    bottom.style.height = 5
    bottom.style.horizontally_stretchable = true

    --------------------------------------------------
    -- FR : Barre d'outils : redimensionnement, puis les boutons propres aux onglets (flow-tools)
    -- EN : Toolbar: resizing, then the buttons specific to the tabs (flow-tools)
    local toolbar = inner.add(element.flow.toolbar)
    toolbar.style.padding = 6
    toolbar.style.horizontal_spacing = 6
    toolbar.style.vertical_align = 'center'

    -- FR : Curseurs de largeur et de hauteur, à la taille actuelle de la fenêtre
    -- EN : Width and height sliders, at the current window size
    element.slider.width.value = data.last_width
    element.slider.height.value = data.last_height
    toolbar.add(element.label.width)
    local slider_width = toolbar.add(element.slider.width)
    slider_width.style.width = 80
    toolbar.add(element.label.height)
    local slider_height = toolbar.add(element.slider.height)
    slider_height.style.width = 80

    -- FR : Conteneur des boutons propres aux onglets, aligné comme la barre d'outils
    -- EN : Container of the tab-specific buttons, aligned like the toolbar
    local tools = toolbar.add(element.flow.tools)
    tools.style.horizontal_spacing = 6
    tools.style.vertical_align = 'center'

    --------------------------------------------------
    -- FR : Onglets : un onglet et son contenu par entrée de fGui.TABS
    -- EN : Tabs: one tab and its content per fGui.TABS entry
    local tabbed = inner.add(element.tabbed.tabs)
    tabbed.style.horizontally_stretchable = true

    local contents = {}
    for _, tab_info in ipairs(fGui.TABS) do
        local tab = tabbed.add(element.tab[tab_info.name])
        local content = tabbed.add(element.content[tab_info.name])
        content.style.horizontally_stretchable = true
        content.style.vertically_stretchable = true
        tabbed.add_tab(tab, content)
        contents[tab_info.name] = content
    end
    -- FR : Premier onglet (suivi de variables) sélectionné à l'ouverture
    -- EN : First tab (variable tracking) selected on opening
    tabbed.selected_tab_index = 1

    --------------------------------------------------
    -- FR : Références gardées temporairement pour l'ancien code, qui s'en sert partout
    --      (g.gui.frame : gvv est-il ouvert ? g.gui.tabpane : quel onglet ?). Supprimées en 3.7.
    -- EN : References kept temporarily for the old code, which uses them everywhere
    --      (g.gui.frame: is gvv open? g.gui.tabpane: which tab?). Removed in 3.7.
    data.gui.frame = frame
    data.gui.tabpane = tabbed

    -- FR : Contenu construit par l'ancien code : boutons des onglets, puis contenu de chaque onglet
    -- EN : Content built by the old code: tab buttons, then each tab content
    Legacy_Gui.build_tools(data, tools)
    Legacy_Gui.build_tracking(data, contents.tracking)
    Legacy_Gui.build_storage(data, contents.storage)
    Legacy_Gui.build_property(data, contents.property)
    Legacy_Gui.build_luaobject(data, contents.luaobject)
    Legacy_Gui.build_help(data, contents.help)

    -- FR : Listes (mods, objets ajoutés, objets globaux, pages d'aide) et entrées du suivi
    -- EN : Lists (mods, added objects, global objects, help pages) and tracking entries
    Legacy_Gui.fill_lists(data)
    Legacy_Gui.fill_tracking(data, first_time)

    return self
end


---FR : Ferme la fenêtre principale et les petites fenêtres de gvv.
---     L'état des dossiers ouverts dans les arbres est sauvegardé, sauf si ignore_save est vrai.
---EN : Closes the main window and gvv's small windows.
---     The state of the folders opened in the trees is saved, unless ignore_save is true.
---@param ignore_save? boolean
---@return GvvGuiMain
function GvvGuiMain:close(ignore_save)
    -- FR : Joueur absent ou invalide : rien à faire
    -- EN : Missing or invalid player: nothing to do
    if not self.isPresent then
        return self
    end

    -- FR : Sauvegarde des dossiers ouverts (avant de détruire les arbres), protégée :
    --      une erreur ne doit pas empêcher la fermeture
    -- EN : Save the opened folders (before destroying the trees), protected:
    --      an error must not prevent closing
    local data = self:getData()
    local saved, message = true, nil
    if not ignore_save and data ~= nil then
        saved, message = pcall(Legacy_Tree.save_on_quit, data)
    end

    -- FR : Destruction de la fenêtre principale
    -- EN : Destroy the main window
    local frame = self:getMainElement()
    if frame ~= nil then
        frame.destroy()
    end

    -- FR : Destruction des petites fenêtres de gvv (code, copie, édition, export, import)
    -- EN : Destroy gvv's small windows (code, copy, edit, export, import)
    GvvGuiDialog(self.event):closeWithMain()

    -- FR : La sauvegarde a échoué : l'erreur est remontée (affichée dans le chat), comme avant
    -- EN : The save failed: the error is raised (shown in the chat), as before
    if not saved then
        error(message)
    end
    return self
end


---FR : Bouton fermer.
---EN : Close button.
function GvvGuiMain:action_close()
    self:close()
end


---FR : Curseur de largeur ou de hauteur déplacé : la fenêtre prend la nouvelle taille, gardée pour la prochaine ouverture.
---EN : Width or height slider moved: the window takes the new size, kept for the next opening.
function GvvGuiMain:action_resize()
    -- FR : Données du joueur et éléments concernés
    -- EN : Player data and elements concerned
    local data = self:getData()
    local frame = self:getMainElement()
    local slider_width = self:getElement("slider", "width")
    local slider_height = self:getElement("slider", "height")

    -- FR : Un élément manque : rien à faire
    -- EN : An element is missing: nothing to do
    if data == nil or frame == nil or slider_width == nil or slider_height == nil then
        return
    end

    -- FR : Nouvelle taille, gardée dans les données du joueur
    -- EN : New size, kept in the player data
    data.last_width = slider_width.slider_value
    data.last_height = slider_height.slider_value
    frame.style.width = data.last_width
    frame.style.height = data.last_height
end


---FR : Onglet changé : l'ancien code affiche les bons boutons et met à jour l'onglet choisi.
---EN : Tab changed: the old code shows the right buttons and updates the chosen tab.
function GvvGuiMain:action_change_tab()
    -- FR : Données du joueur et panneau d'onglets
    -- EN : Player data and tabbed pane
    local data = self:getData()
    local tabbed = self:getElement("tabbed", "tabs")

    -- FR : Un élément manque : rien à faire
    -- EN : An element is missing: nothing to do
    if data == nil or tabbed == nil then
        return
    end

    -- FR : Ancien code (legacy/gui.lua), migré avec les onglets
    -- EN : Old code (legacy/gui.lua), migrated with the tabs
    Legacy_Gui.change_tab(data, tabbed.selected_tab_index)
end
