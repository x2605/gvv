---------------------------------------------------------------------------------------------
-- GUI : DIALOGS
---------------------------------------------------------------------------------------------
-- FR : Description des petites fenêtres de gvv, utilisée par classes/GvvGuiDialog.lua.
--      Chaque petite fenêtre a un type (kind) :
--        dump    : texte à copier (résultat de /gdump)
--        anycode : saisie d'un code à ajouter au suivi
--        copy    : code ou valeur d'une entrée du suivi, à copier (bouton « modifier » pour un code)
--        edit    : modification du code d'une entrée du suivi
--        export  : liste de suivi à copier
--        import  : saisie d'une liste de suivi à importer
--      Organisation d'une petite fenêtre (préfixe gvv_dialog) :
--        frame-<kind>                     cadre, centré à l'écran
--        ├ flow-header                    titre, zone de déplacement, bouton fermer
--        └ flow-inner                     contenu propre au type
--          ├ label-comment                (import) explication du format
--          ├ pane-entry > label-entry     (edit) nom de l'entrée modifiée
--          ├ textfield-text / textbox-text  texte en lecture seule (dump, copy, export)
--          ├ textbox-code                 code saisi (anycode, edit, import)
--          └ flow-footer                  zone de déplacement + bouton (confirm ou edit)
-- EN : Description of gvv's small windows, used by classes/GvvGuiDialog.lua.
--      Each small window has a kind: see the list above.
--      Small window layout (gvv_dialog prefix): see the tree above.
---------------------------------------------------------------------------------------------

-- FR : Préfixe des noms de toutes les petites fenêtres
-- EN : Names prefix of all the small windows
local GUI_NAME = "gvv_dialog"

-- FR : Types de petites fenêtres et leurs réglages :
--        title  : titre de la fenêtre (texte localisé), sauf dump dont le titre est donné à l'ouverture
--        opened : la fenêtre devient player.opened (Échap la ferme)
--        close_with_main : fermée avec la fenêtre principale
--        close_on_main_focus : fermée quand on clique dans la fenêtre principale
-- EN : Small window kinds and their settings:
--        title  : window title (localised string), except dump whose title is given on opening
--        opened : the window becomes player.opened (Escape closes it)
--        close_with_main : closed with the main window
--        close_on_main_focus : closed when clicking in the main window
local KINDS = {
    dump    = { title = nil,                           opened = true,  close_with_main = false, close_on_main_focus = false },
    anycode = { title = {"gvv-mod.input-code"},        opened = true,  close_with_main = true,  close_on_main_focus = true },
    copy    = { title = {"gvv-mod.copy-code"},         opened = true,  close_with_main = true,  close_on_main_focus = true },
    edit    = { title = {"gvv-mod.edit-code-title"},   opened = false, close_with_main = true,  close_on_main_focus = false },
    export  = { title = {"gvv-mod.export-code-title"}, opened = true,  close_with_main = true,  close_on_main_focus = true },
    import  = { title = {"gvv-mod.import-code-title"}, opened = true,  close_with_main = true,  close_on_main_focus = true },
}


---FR : Description des éléments d'une petite fenêtre du type donné.
---EN : Description of the elements of a small window of the given kind.
---@param gui_name string  Préfixe des noms (« gvv_dialog ») / Names prefix ("gvv_dialog")
---@param kind string      Type de la fenêtre / Window kind
---@return table
local function getElement(gui_name, kind)
    local element = {
        -- FR : Cadre de la fenêtre, centré ; le type est rangé dans ses tags
        -- EN : Window frame, centred; the kind is stored in its tags
        frame = GvvGuiElement(gui_name, "frame", kind):vertical():autoCenter():tags({ kind = kind }):get(),
        -- FR : Conteneurs
        -- EN : Containers
        flow = {
            header = GvvGuiElement(gui_name, "flow", "header"):horizontal():get(),
            inner = GvvGuiElement(gui_name, "flow", "inner"):vertical():get(),
            footer = GvvGuiElement(gui_name, "flow", "footer"):horizontal():get(),
        },
        -- FR : Textes
        -- EN : Labels
        label = {
            title = GvvGuiElement(gui_name, "label", "title"):style("frame_title"):get(),
            comment = GvvGuiElement(gui_name, "label", "comment"):caption({"gvv-mod.import-code-comment"}):get(),
            entry = GvvGuiElement(gui_name, "label", "entry"):get(),
        },
        -- FR : Zones de déplacement (barre de titre, pied de fenêtre)
        -- EN : Drag areas (title bar, window footer)
        empty = {
            drag = GvvGuiElement(gui_name, "empty-widget", "drag"):style("draggable_space_header"):get(),
            footer_drag = GvvGuiElement(gui_name, "empty-widget", "footer_drag"):style("draggable_space_header"):get(),
            footer_drag2 = GvvGuiElement(gui_name, "empty-widget", "footer_drag2"):style("draggable_space_header"):get(),
        },
        -- FR : Boutons
        -- EN : Buttons
        button = {
            close = GvvGuiElement(gui_name, "sprite-button", "close"):spritePath("utility/close")
                :style("frame_action_button"):mouseButtonFilter({"left"}):get(),
            confirm = GvvGuiElement(gui_name, "button", "confirm"):style("confirm_button"):mouseButtonFilter({"left"}):get(),
            edit = GvvGuiElement(gui_name, "button", "edit"):caption({"gvv-mod.edit-code-btn"})
                :style("dialog_button"):mouseButtonFilter({"left"}):get(),
        },
        -- FR : Texte en lecture seule, sur une ligne (textfield) ou plusieurs (text-box)
        -- EN : Read-only text, on one line (textfield) or several (text-box)
        text = {
            field = GvvGuiElement(gui_name, "textfield", "text"):tooltip({"gvv-mod.right-to-select-all"}):get(),
            box = GvvGuiElement(gui_name, "text-box", "text"):tooltip({"gvv-mod.right-to-select-all"}):get(),
        },
        -- FR : Code saisi par le joueur
        -- EN : Code typed by the player
        code = GvvGuiElement(gui_name, "text-box", "code"):text(""):get(),
        -- FR : Zone défilante qui affiche le nom de l'entrée modifiée (edit)
        -- EN : Scrolling area that shows the name of the edited entry (edit)
        pane = GvvGuiElement(gui_name, "scroll-pane", "entry"):verticalScrollPolicy("never")
            :horizontalScrollPolicy("auto"):get(),
    }

    -- FR : Clic droit dans un texte en lecture seule : tout sélectionner (pour copier)
    -- EN : Right click in a read-only text: select everything (to copy)
    element.text.field.clear_and_focus_on_right_click = true
    element.text.box.clear_and_focus_on_right_click = true
    -- FR : Clic droit dans un code saisi : ne pas l'effacer
    -- EN : Right click in a typed code: don't clear it
    element.code.clear_and_focus_on_right_click = false

    return element
end


---FR : Chemin de chaque élément d'une petite fenêtre depuis player.gui.screen, rangé par type de fenêtre :
---     content[kind][élément]. Utilisé par GvvGui:getElement(kind, élément).
---EN : Path of each element of a small window from player.gui.screen, sorted by window kind:
---     content[kind][element]. Used by GvvGui:getElement(kind, element).
---@return table
local function getContent()
    local content = {}
    for kind in pairs(KINDS) do
        local frame = "frame-" .. kind
        content[kind] = {
            frame = { frame },
            header = { frame, "flow-header" },
            inner = { frame, "flow-inner" },
            text_field = { frame, "flow-inner", "textfield-text" },
            text_box = { frame, "flow-inner", "textbox-text" },
            code = { frame, "flow-inner", "textbox-code" },
            entry = { frame, "flow-inner", "pane-entry", "label-entry" },
        }
    end
    return content
end


---------------------------------------------------------------------------------------------
-- FR : Fonctions exportées, préfixe et types de fenêtres
-- EN : Exported functions, prefix and window kinds
return {
    getElement = getElement,
    getContent = getContent,
    GUI_NAME = GUI_NAME,
    KINDS = KINDS,
}
