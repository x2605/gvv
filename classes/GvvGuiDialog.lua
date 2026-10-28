---------------------------------------------------------------------------------------------
-- GVV GUI DIALOG
---------------------------------------------------------------------------------------------
-- FR : Petites fenêtres de gvv (étape 3.2 de la restructuration 0.6) : une seule classe pour les
--      six types de fenêtres (dump, anycode, copy, edit, export, import), qui partagent le même cadre.
--      Comportement repris de l'ancien code (legacy/gui.lua et legacy/gui_event.lua), sans changement.
--      Description des éléments : gui/dialogs.lua.
--      Le texte en lecture seule n'utilise plus un label caché comme mémoire : le texte d'origine
--      est rangé dans les tags de l'élément, et remis en place s'il est modifié.
-- EN : gvv small windows (step 3.2 of the 0.6 restructuring): one class for the
--      six window kinds (dump, anycode, copy, edit, export, import), which share the same frame.
--      Behaviour taken from the old code (legacy/gui.lua and legacy/gui_event.lua), unchanged.
--      Elements description: gui/dialogs.lua.
--      Read-only text no longer uses a hidden label as memory: the original text
--      is stored in the element tags, and put back if it is modified.
---------------------------------------------------------------------------------------------
local check = require(gvv.defines.lualib.common.check)
local fGui = require(gvv.defines.gui.dialogs)
---------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------

-- FR : Noms des petites fenêtres d'avant 0.6, détruites si elles traînent encore
-- EN : Names of the pre-0.6 small windows, destroyed if they are still there
local LEGACY_NAMES = {
    '_gvv-mod_dump_frame_',
    '_gvv-mod_anycode_frame_',
    '_gvv-mod_copy_tracking_code_frame_',
    '_gvv-mod_edit_tracking_code_frame_',
    '_gvv-mod_export_tracking_code_frame_',
    '_gvv-mod_import_tracking_code_frame_',
}

-- FR : Séparateur des entrées dans une liste de suivi exportée ou importée
-- EN : Entries separator in an exported or imported tracking list
local SEPARATOR = '\n--[[]]--\n'


---**EN**
---
---Description: gvv small windows ("gvv_dialog"): dump, anycode, copy, edit, export, import. They share the same frame;
---the kind is read from the frame tags.
---
---⚠ Temporary wrapper, created on each event. Do not store the instance in `storage`.
---
---──────────────────────────────
---
---**FR**
---
---Description: Petites fenêtres de gvv (« gvv_dialog ») : dump, anycode, copie, édition, export, import. Elles partagent
---le même cadre ; le type est lu dans les tags du cadre.
---
---⚠ Wrapper temporaire, créé à chaque évènement. Ne pas stocker l'instance dans `storage`.
---@class GvvGuiDialog : GvvGui
---@field object_name string     "GvvGuiDialog"
---@field kind string?           Kind of the small window concerned
---@operator call(table): GvvGuiDialog
---@type GvvGuiDialog
GvvGuiDialog = gvv.classFactory.newclass(GvvGui, function(self, event)
    -- FR : Fenêtres « gvv_dialog » ; l'élément racine dépend du type, connu plus bas
    -- EN : "gvv_dialog" windows; the root element depends on the kind, known below
    GvvGui.init(self, event, fGui.GUI_NAME, "")
    self.object_name = "GvvGuiDialog"

    --------------------------------------------------
    -- FR : Les petites fenêtres vivent dans player.gui.screen
    -- EN : Small windows live in player.gui.screen
    if self.isPresent then
        self.gui = { self.player.gui.screen }
    end

    -- FR : Chemins des éléments, rangés par type de fenêtre (gui/dialogs.lua)
    -- EN : Element paths, sorted by window kind (gui/dialogs.lua)
    self.content = fGui.getContent()

    -- FR : Actions communes à toutes les petites fenêtres
    -- EN : Actions shared by all the small windows
    self.gui_action = {
        -- FR : bouton fermer
        -- EN : close button
        ["button-close"] = "action_close",

        -- FR : valider (anycode, edit, import)
        -- EN : confirm (anycode, edit, import)
        ["button-confirm"] = "action_confirm",

        -- FR : modifier (copy)
        -- EN : edit (copy)
        ["button-edit"] = "action_edit",

        -- FR : texte en lecture seule modifié
        -- EN : read-only text modified
        ["textfield-text-text_changed"] = "action_restore_text",
        ["textbox-text-text_changed"] = "action_restore_text",

        -- FR : code saisi modifié
        -- EN : typed code modified
        ["textbox-code-text_changed"] = "action_code_changed",
    }
    -- FR : Fermeture (Échap, ou autre fenêtre ouverte) : une action par type, ex. « frame-anycode-closed »
    -- EN : Closing (Escape, or another window opened): one action per kind, e.g. "frame-anycode-closed"
    for kind in pairs(fGui.KINDS) do
        self.gui_action["frame-" .. kind .. "-closed"] = "action_closed"
    end

    -- FR : Type de la petite fenêtre qui contient l'élément de l'évènement (nil s'il n'y en a pas)
    -- EN : Kind of the small window that contains the event element (nil if there is none)
    self:setKind(self:findKind(self.element))
    --------------------------------------------------
end) --[[@as GvvGuiDialog]]
----------------------------------------------------------------


---**EN**
---
---Description: Kind of the small window that contains the element (e.g. "anycode"), or nil.
---Walk up to the element placed directly in player.gui.screen, then read its name.
---
---──────────────────────────────
---
---**FR**
---
---Description: Type de la petite fenêtre qui contient l'élément (ex. « anycode »), ou nil.
---On remonte jusqu'à l'élément posé directement dans player.gui.screen, puis on lit son nom.
---@param element LuaGuiElement?
---@return string?
function GvvGuiDialog:findKind(element)
    -- FR : Pas d'élément valide : pas de type
    -- EN : No valid element: no kind
    if not check.isValidLuaObject(element) then
        return nil
    end

    -- FR : Remontée : on s'arrête sur l'élément dont le parent est la racine (player.gui.screen)
    -- EN : Walk up: stop on the element whose parent is the root (player.gui.screen)
    local current = element
    while check.isValidLuaObject(current.parent) and check.isValidLuaObject(current.parent.parent) do
        current = current.parent
    end

    -- FR : « gvv_dialog-frame-anycode » donne « anycode » ; autre nom : pas une petite fenêtre de gvv
    -- EN : "gvv_dialog-frame-anycode" gives "anycode"; other name: not a gvv small window
    local gui_name, short_type, kind = GvvGui.splitName(current.name)
    if gui_name ~= self.gui_name or short_type ~= "frame" or fGui.KINDS[kind] == nil then
        return nil
    end
    return kind
end


---**EN**
---
---Description: Chooses the kind of small window concerned; the root element becomes "frame-<kind>".
---
---──────────────────────────────
---
---**FR**
---
---Description: Choisit le type de petite fenêtre concerné ; l'élément racine devient « frame-<kind> ».
---@param kind string?
---@return GvvGuiDialog
function GvvGuiDialog:setKind(kind)
    self.kind = kind
    if kind ~= nil then
        self.main_gui = "frame-" .. kind
    else
        self.main_gui = ""
    end
    return self
end


---**EN**
---
---Description: Element of the small window of the current kind (e.g. getPart("code")), or nil.
---
---──────────────────────────────
---
---**FR**
---
---Description: Élément de la petite fenêtre du type actuel (ex. getPart("code")), ou nil.
---@param part string
---@return LuaGuiElement?
function GvvGuiDialog:getPart(part)
    -- FR : Pas de type choisi : rien à chercher
    -- EN : No kind chosen: nothing to look for
    if self.kind == nil then
        return nil
    end
    return self:getElement(self.kind, part)
end


---------------------------------------------------------------------------------------------
-- FR : CONSTRUCTION
-- EN : BUILDING
---------------------------------------------------------------------------------------------

---**EN**
---
---Description: Builds the common frame of a small window (title, drag, close button)
---and returns the frame, its content (flow-inner) and the elements description.
---Taken from Util.create_frame_w_closebtn.
---
---──────────────────────────────
---
---**FR**
---
---Description: Construit le cadre commun d'une petite fenêtre (titre, déplacement, bouton fermer)
---et renvoie le cadre, son contenu (flow-inner) et la description des éléments.
---Repris de Util.create_frame_w_closebtn.
---@param kind string
---@param title LocalisedString
---@return LuaGuiElement frame
---@return LuaGuiElement inner
---@return table element
function GvvGuiDialog:buildFrame(kind, title)
    -- FR : Ce type devient le type actuel
    -- EN : This kind becomes the current kind
    self:setKind(kind)
    local element = fGui.getElement(self.gui_name, kind)

    -- FR : Cadre, centré à l'écran
    -- EN : Frame, centred on screen
    local frame = self.gui[1].add(element.frame)

    -- FR : Barre de titre : déplacer la fenêtre en la tirant
    -- EN : Title bar: drag it to move the window
    local header = frame.add(element.flow.header)
    header.drag_target = frame

    local label = header.add(element.label.title)
    label.caption = title
    label.drag_target = frame

    local drag = header.add(element.empty.drag)
    drag.drag_target = frame
    drag.style.right_margin = 8
    drag.style.height = 24
    drag.style.horizontally_stretchable = true

    header.add(element.button.close)

    -- FR : Contenu propre au type, ajouté par la méthode d'ouverture
    -- EN : Kind-specific content, added by the opening method
    local inner = frame.add(element.flow.inner)

    -- FR : Centrage à l'écran, au même moment que l'ancien code (Util.create_frame_w_closebtn)
    -- EN : Centring on screen, at the same moment as the old code (Util.create_frame_w_closebtn)
    frame.auto_center = true

    return frame, inner, element
end


---**EN**
---
---Description: Adds a read-only text: on one line (textfield), or several (text-box) if multiline.
---The original text is stored in the tags, to be put back if it is modified.
---
---──────────────────────────────
---
---**FR**
---
---Description: Ajoute un texte en lecture seule : sur une ligne (textfield), ou plusieurs (text-box) si multiline.
---Le texte d'origine est rangé dans les tags, pour être remis en place s'il est modifié.
---@param inner LuaGuiElement
---@param element table
---@param text string
---@param multiline boolean
---@return LuaGuiElement
function GvvGuiDialog:addReadOnlyText(inner, element, text, multiline)
    -- FR : Description choisie selon le nombre de lignes
    -- EN : Description chosen according to the number of lines
    local spec = element.text.field
    if multiline then
        spec = element.text.box
    end
    spec.text = text
    spec.tags = { text = text }

    -- FR : Création, puis tout le texte sélectionné, prêt à copier
    -- EN : Creation, then the whole text selected, ready to copy
    local text_element = inner.add(spec)
    text_element.focus()
    text_element.select_all()
    text_element.style.width = 400
    return text_element
end


---**EN**
---
---Description: Adds the window footer: drag area + confirm button, aligned to the right.
---
---──────────────────────────────
---
---**FR**
---
---Description: Ajoute le pied de fenêtre : zone de déplacement + bouton de validation, aligné à droite.
---@param frame LuaGuiElement
---@param inner LuaGuiElement
---@param element table
---@param caption LocalisedString  Button text
function GvvGuiDialog:addConfirmFooter(frame, inner, element, caption)
    -- FR : Conteneur aligné à droite
    -- EN : Container aligned to the right
    local footer = inner.add(element.flow.footer)
    footer.style.horizontal_align = 'right'
    footer.style.horizontally_stretchable = true
    footer.style.left_padding = 0
    footer.style.top_padding = 6

    -- FR : Zone de déplacement, qui remplit la place à gauche du bouton
    -- EN : Drag area, which fills the space left of the button
    local drag = footer.add(element.empty.footer_drag)
    drag.drag_target = frame
    drag.style.left_margin = 0
    drag.style.right_margin = 8
    drag.style.height = 32
    drag.style.horizontally_stretchable = true

    -- FR : Bouton de validation
    -- EN : Confirm button
    element.button.confirm.caption = caption
    footer.add(element.button.confirm)
end


---**EN**
---
---Description: Adds the code typed by the player (text-box), empty or with a starting text.
---
---──────────────────────────────
---
---**FR**
---
---Description: Ajoute le code saisi par le joueur (text-box), vide ou avec un texte de départ.
---@param inner LuaGuiElement
---@param element table
---@param width integer
---@param height integer
---@param text? string
---@return LuaGuiElement
function GvvGuiDialog:addCode(inner, element, width, height, text)
    local code = inner.add(element.code)
    code.focus()
    code.style.width = width
    code.style.height = height
    if text ~= nil then
        code.text = text
    end
    return code
end


---**EN**
---
---Description: Destroys the small window of the given kind if it is open. Returns true if it was.
---
---──────────────────────────────
---
---**FR**
---
---Description: Détruit la petite fenêtre du type donné si elle est ouverte. Renvoie true si elle l'était.
---@param kind string
---@return boolean
function GvvGuiDialog:destroyKind(kind)
    local frame = check.tryGet(self.gui[1], self.gui_name .. "-frame-" .. kind)
    if check.isValidLuaObject(frame) then
        frame.destroy()
        return true
    end
    return false
end


---------------------------------------------------------------------------------------------
-- FR : OUVERTURE, un type de fenêtre par méthode
-- EN : OPENING, one window kind per method
---------------------------------------------------------------------------------------------

---**EN**
---
---Description: "dump" window: text to copy, e.g. the result of /gdump. Replaces a dump window already open.
---
---──────────────────────────────
---
---**FR**
---
---Description: Fenêtre « dump » : texte à copier, ex. le résultat de /gdump. Remplace une fenêtre dump déjà ouverte.
---@param text string
---@param title LocalisedString
---@return GvvGuiDialog
function GvvGuiDialog:openDump(text, title)
    if not self.isPresent then
        return self
    end
    self:destroyKind("dump")

    local frame, inner, element = self:buildFrame("dump", title)
    self:addReadOnlyText(inner, element, text, false)

    -- FR : Échap ferme la fenêtre
    -- EN : Escape closes the window
    self.player.opened = frame
    return self
end


---**EN**
---
---Description: "anycode" window: typing a code to add to the tracking.
---If it is already open, it is centred again and an error says so (as before).
---
---──────────────────────────────
---
---**FR**
---
---Description: Fenêtre « anycode » : saisie d'un code à ajouter au suivi.
---Si elle est déjà ouverte, elle est recentrée et une erreur l'indique (comme avant).
---@return boolean
function GvvGuiDialog:openAnycode()
    if not self.isPresent then
        return false
    end

    -- FR : Déjà ouverte : on la met en avant et on le signale
    -- EN : Already open: bring it forward and report it
    self:setKind("anycode")
    local existing = self:getMainElement()
    if existing ~= nil then
        existing.focus()
        existing.force_auto_center()
        error('Already an input window is opened.')
    end

    local frame, inner, element = self:buildFrame("anycode", fGui.KINDS.anycode.title)
    local code = self:addCode(inner, element, 600, 200)
    code.style.font = 'default-semibold'
    self:addConfirmFooter(frame, inner, element, {"gvv-mod.confirm-input-code"})

    -- FR : Échap ferme la fenêtre (seulement si le code est vide, voir action_closed)
    -- EN : Escape closes the window (only if the code is empty, see action_closed)
    self.player.opened = frame
    return true
end


---**EN**
---
---Description: "copy" window: code or value of a tracking entry, to copy.
---entry_name (the entry code): if given, an "edit" button opens the edit window.
---Replaces a copy window already open.
---
---──────────────────────────────
---
---**FR**
---
---Description: Fenêtre « copy » : code ou valeur d'une entrée du suivi, à copier.
---entry_name (code de l'entrée) : si donné, un bouton « modifier » ouvre la fenêtre edit.
---Remplace une fenêtre copy déjà ouverte.
---@param text string
---@param entry_name? string
---@return GvvGuiDialog
function GvvGuiDialog:openCopy(text, entry_name)
    if not self.isPresent then
        return self
    end
    self:destroyKind("copy")

    -- FR : Les guillemets « “ ” » ajoutés à l'affichage d'une valeur texte sont retirés
    -- EN : The "“ ”" quotes added when displaying a text value are removed
    text = text:gsub('^“', ''):gsub('”$', '')
    local newline_count = select(2, text:gsub('\n', ''))

    local frame, inner, element = self:buildFrame("copy", fGui.KINDS.copy.title)

    -- FR : Plusieurs lignes : text-box, haute d'une ligne par ligne de texte (400 au plus)
    -- EN : Several lines: text-box, one line high per text line (400 at most)
    local text_element = self:addReadOnlyText(inner, element, text, newline_count > 0)
    if newline_count > 0 then
        local height = 23 + 23 * newline_count
        if height > 400 then
            height = 400
        end
        text_element.style.height = height
    end

    -- FR : Entrée du suivi connue : bouton « modifier » centré entre deux zones de déplacement
    -- EN : Known tracking entry: "edit" button centred between two drag areas
    if entry_name then
        frame.tags = { kind = "copy", entry_name = entry_name }

        local footer = inner.add(element.flow.footer)
        footer.style.horizontal_align = 'center'
        footer.style.horizontally_stretchable = true
        footer.style.left_padding = 0
        footer.style.right_padding = 0
        footer.style.top_padding = 6

        local drag1 = footer.add(element.empty.footer_drag)
        drag1.drag_target = frame
        drag1.style.left_margin = 0
        drag1.style.right_margin = 8
        drag1.style.height = 32
        drag1.style.horizontally_stretchable = true

        footer.add(element.button.edit)

        local drag2 = footer.add(element.empty.footer_drag2)
        drag2.drag_target = frame
        drag2.style.left_margin = 8
        drag2.style.right_margin = 0
        drag2.style.height = 32
        drag2.style.horizontally_stretchable = true
    end

    -- FR : Échap ferme la fenêtre
    -- EN : Escape closes the window
    self.player.opened = frame
    return self
end


---**EN**
---
---Description: "edit" window: editing the code of a tracking entry.
---If it is already open, it is centred again and an error says so (as before).
---
---──────────────────────────────
---
---**FR**
---
---Description: Fenêtre « edit » : modification du code d'une entrée du suivi.
---Si elle est déjà ouverte, elle est recentrée et une erreur l'indique (comme avant).
---@param text string        Current entry code
---@param entry_name string  Entry name (its original code)
---@return boolean
function GvvGuiDialog:openEdit(text, entry_name)
    if not self.isPresent then
        return false
    end

    -- FR : Déjà ouverte : on la met en avant et on le signale
    -- EN : Already open: bring it forward and report it
    self:setKind("edit")
    local existing = self:getMainElement()
    if existing ~= nil then
        existing.focus()
        existing.force_auto_center()
        error('Already an edit window is opened.')
    end

    local frame, inner, element = self:buildFrame("edit", fGui.KINDS.edit.title)
    frame.tags = { kind = "edit", entry_name = entry_name }

    -- FR : Nom de l'entrée modifiée, dans une zone défilante horizontalement
    -- EN : Name of the edited entry, in a horizontally scrolling area
    local pane = inner.add(element.pane)
    pane.style.width = 600
    pane.style.height = 39
    element.label.entry.caption = entry_name
    pane.add(element.label.entry)

    -- FR : Code à modifier
    -- EN : Code to edit
    local code = self:addCode(inner, element, 600, 400, text)
    code.style.font = 'default-semibold'
    self:addConfirmFooter(frame, inner, element, {"gvv-mod.confirm-edit-code"})

    -- FR : Pas de player.opened : Échap ne ferme pas cette fenêtre (comme avant)
    -- EN : No player.opened: Escape doesn't close this window (as before)
    return true
end


---**EN**
---
---Description: "export" window: the current tracking list, to copy. Replaces an export window already open.
---
---──────────────────────────────
---
---**FR**
---
---Description: Fenêtre « export » : la liste de suivi actuelle, à copier. Remplace une fenêtre export déjà ouverte.
---@return GvvGuiDialog
function GvvGuiDialog:openExport()
    if not self.isPresent then
        return self
    end
    self:destroyKind("export")

    -- FR : Les codes des entrées, dans l'ordre affiché, séparés par « --[[]]-- » (GvvGuiTracking)
    -- EN : The entries codes, in display order, separated by "--[[]]--" (GvvGuiTracking)
    local text = GvvGuiTracking(self.event):exportText()

    local frame, inner, element = self:buildFrame("export", fGui.KINDS.export.title)
    local text_element = self:addReadOnlyText(inner, element, text, true)
    text_element.style.height = 300

    -- FR : Échap ferme la fenêtre
    -- EN : Escape closes the window
    self.player.opened = frame
    return self
end


---**EN**
---
---Description: "import" window: typing a tracking list to import. Replaces an import window already open.
---
---──────────────────────────────
---
---**FR**
---
---Description: Fenêtre « import » : saisie d'une liste de suivi à importer. Remplace une fenêtre import déjà ouverte.
---@return GvvGuiDialog
function GvvGuiDialog:openImport()
    if not self.isPresent then
        return self
    end
    self:destroyKind("import")

    local frame, inner, element = self:buildFrame("import", fGui.KINDS.import.title)

    -- FR : Explication du format, sur plusieurs lignes
    -- EN : Format explanation, on several lines
    local comment = inner.add(element.label.comment)
    comment.style.single_line = false
    comment.style.width = 400

    self:addCode(inner, element, 400, 300)
    self:addConfirmFooter(frame, inner, element, {"gvv-mod.import-code-btn"})

    -- FR : Échap ferme la fenêtre
    -- EN : Escape closes the window
    self.player.opened = frame
    return self
end


---------------------------------------------------------------------------------------------
-- FR : FERMETURES GROUPÉES (appelées par la fenêtre principale et les migrations)
-- EN : GROUPED CLOSINGS (called by the main window and the migrations)
---------------------------------------------------------------------------------------------

---**EN**
---
---Description: Closes the small windows closed with the main window (all except dump).
---
---──────────────────────────────
---
---**FR**
---
---Description: Ferme les petites fenêtres fermées avec la fenêtre principale (toutes sauf dump).
---@return GvvGuiDialog
function GvvGuiDialog:closeWithMain()
    if not self.isPresent then
        return self
    end
    for kind, settings in pairs(fGui.KINDS) do
        if settings.close_with_main then
            self:destroyKind(kind)
        end
    end
    return self
end


---**EN**
---
---Description: Click in the main window: closes the small windows concerned
---(anycode only if its code is empty, so as not to lose a typed code).
---
---──────────────────────────────
---
---**FR**
---
---Description: Clic dans la fenêtre principale : ferme les petites fenêtres concernées
---(anycode seulement si son code est vide, pour ne pas perdre une saisie).
---@return GvvGuiDialog
function GvvGuiDialog:closeOnMainFocus()
    if not self.isPresent then
        return self
    end
    for kind, settings in pairs(fGui.KINDS) do
        if settings.close_on_main_focus then
            -- FR : anycode : on vérifie que le code est vide
            -- EN : anycode: check that the code is empty
            self:setKind(kind)
            local code = self:getPart("code")
            if kind ~= "anycode" or code == nil or code.text == '' then
                self:destroyKind(kind)
            end
        end
    end
    self:setKind(nil)
    return self
end


---**EN**
---
---Description: Destroys the pre-0.6 small windows (old names) still open.
---
---──────────────────────────────
---
---**FR**
---
---Description: Détruit les petites fenêtres d'avant 0.6 (anciens noms) encore ouvertes.
---@return GvvGuiDialog
function GvvGuiDialog:destroyLegacy()
    if not self.isPresent then
        return self
    end
    for _, name in ipairs(LEGACY_NAMES) do
        local frame = check.tryGet(self.gui[1], name)
        if check.isValidLuaObject(frame) then
            frame.destroy()
        end
    end
    return self
end


---------------------------------------------------------------------------------------------
-- FR : ACTIONS (évènements des éléments des petites fenêtres)
-- EN : ACTIONS (events of the small windows elements)
---------------------------------------------------------------------------------------------

---**EN**
---
---Description: Close button: destroys the small window.
---
---──────────────────────────────
---
---**FR**
---
---Description: Bouton fermer : détruit la petite fenêtre.
function GvvGuiDialog:action_close()
    local frame = self:getMainElement()
    if frame ~= nil then
        frame.destroy()
    end
end


---**EN**
---
---Description: Window closed (Escape, or another window opened): destroyed,
---except anycode if a code is being typed.
---
---──────────────────────────────
---
---**FR**
---
---Description: Fenêtre fermée (Échap, ou autre fenêtre ouverte) : détruite,
---sauf anycode si un code est en cours de saisie.
function GvvGuiDialog:action_closed()
    if self.kind == "anycode" then
        local code = self:getPart("code")
        if code ~= nil and code.text ~= '' then
            return
        end
    end
    self:action_close()
end


---**EN**
---
---Description: Read-only text modified by the player: put the original text back (stored in the tags) and select it.
---
---──────────────────────────────
---
---**FR**
---
---Description: Texte en lecture seule modifié par le joueur : on remet le texte d'origine (rangé dans les tags) et on le sélectionne.
function GvvGuiDialog:action_restore_text()
    local original = check.tryGet(self.element.tags, "text")
    if original ~= nil then
        self.element.text = original
        self.element.select_all()
    end
end


---**EN**
---
---Description: Code of the anycode window emptied: it becomes player.opened again, so Escape closes it (as before).
---
---──────────────────────────────
---
---**FR**
---
---Description: Code de la fenêtre anycode vidé : elle redevient player.opened, pour qu'Échap la ferme (comme avant).
function GvvGuiDialog:action_code_changed()
    if self.kind ~= "anycode" or self.element.text ~= '' then
        return
    end
    if self.player.opened_gui_type == defines.gui_type.none then
        self.player.opened = self:getMainElement()
    end
end


---**EN**
---
---Description: "edit" button of the copy window: opens the edit window with this code, then closes the copy window.
---
---──────────────────────────────
---
---**FR**
---
---Description: Bouton « modifier » de la fenêtre copy : ouvre la fenêtre edit avec ce code, puis ferme la fenêtre copy.
function GvvGuiDialog:action_edit()
    local frame = self:getMainElement()
    local text_element = self:getPart("text_field") or self:getPart("text_box")
    if frame == nil or text_element == nil then
        return
    end

    -- FR : Nom de l'entrée (tags du cadre) et code d'origine (tags du texte)
    -- EN : Entry name (frame tags) and original code (text tags)
    local entry_name = frame.tags.entry_name
    local code = text_element.tags.text

    -- FR : Ouverture de la fenêtre edit ; si elle s'ouvre, la fenêtre copy est fermée
    -- EN : Open the edit window; if it opens, the copy window is closed
    local opened = GvvGuiDialog(self.event):openEdit(code, entry_name)
    if opened then
        frame.destroy()
    end
end


---**EN**
---
---Description: Confirm button: its effect depends on the window kind.
---
---──────────────────────────────
---
---**FR**
---
---Description: Bouton de validation : son effet dépend du type de fenêtre.
function GvvGuiDialog:action_confirm()
    if self.kind == "anycode" then
        self:confirmAnycode()
    elseif self.kind == "edit" then
        self:confirmEdit()
    elseif self.kind == "import" then
        self:confirmImport()
    end
end


---**EN**
---
---Description: anycode: adds the code to the tracking, closes the window and shows the tracking tab.
---
---──────────────────────────────
---
---**FR**
---
---Description: anycode : ajoute le code au suivi, ferme la fenêtre et affiche l'onglet suivi.
function GvvGuiDialog:confirmAnycode()
    local data = self:getData()
    local code = self:getPart("code")
    if data == nil or code == nil then
        return
    end
    GvvGuiTracking(self.event):add(code.text)
    self:action_close()
    GvvGuiMain(self.event):changeTab(1)
end


---**EN**
---
---Description: edit: replaces the entry with the new code, at the same place in the list (taken from the old code).
---
---──────────────────────────────
---
---**FR**
---
---Description: edit : remplace l'entrée par le nouveau code, à la même place dans la liste (repris de l'ancien code).
function GvvGuiDialog:confirmEdit()
    local data = self:getData()
    local frame = self:getMainElement()
    local code_element = self:getPart("code")
    if data == nil or frame == nil or code_element == nil then
        return
    end

    -- FR : L'entrée garde sa place dans la liste (GvvGuiTracking:replaceEntry)
    -- EN : The entry keeps its place in the list (GvvGuiTracking:replaceEntry)
    GvvGuiTracking(self.event):replaceEntry(frame.tags.entry_name, code_element.text)

    self:action_close()
    GvvGuiMain(self.event):changeTab(1)
end


---**EN**
---
---Description: import: adds the typed codes to the tracking (separated by "--[[]]--"). Codes already present
---are not added twice; they are checked, like the new ones. Taken from the old code.
---
---──────────────────────────────
---
---**FR**
---
---Description: import : ajoute les codes saisis au suivi (séparés par « --[[]]-- »). Les codes déjà présents
---ne sont pas ajoutés deux fois ; ils sont cochés, comme les nouveaux. Repris de l'ancien code.
function GvvGuiDialog:confirmImport()
    local data = self:getData()
    local code_element = self:getPart("code")
    if data == nil or code_element == nil then
        return
    end

    -- FR : Découpage du texte en codes, sur le séparateur « --[[]]-- »
    -- EN : Split the text into codes, on the "--[[]]--" separator
    local raw = code_element.text
    local codes = {}
    local remaining = true
    local count = 0
    while remaining do
        codes[#codes + 1] = raw:match('^(.-)(%-%-%[%[%]%]%-%-)')
        raw, count = raw:gsub('^(.-)(%-%-%[%[%]%]%-%-)', '')
        if count == 0 then
            codes[#codes + 1] = raw
            remaining = false
        end
    end

    -- FR : Retrait des retours à la ligne au début et à la fin ; les codes vides sont ignorés
    -- EN : Remove line breaks at the start and end; empty codes are ignored
    local import_codes = {}
    for index, code in ipairs(codes) do
        codes[index] = code:gsub('^\n', ''):gsub('\n$', '')
        if codes[index]:gsub('^%s*(.-)%s*$', '%1') ~= '' then
            import_codes[#import_codes + 1] = codes[index]
        end
    end

    -- FR : Ajout au suivi : doublons cochés, nouveaux ajoutés et cochés (GvvGuiTracking:importCodes)
    -- EN : Added to the tracking: duplicates checked, new ones added and checked (GvvGuiTracking:importCodes)
    local new_count, duplicate_count = GvvGuiTracking(self.event):importCodes(import_codes)

    self:action_close()
    GvvGuiMain(self.event):changeTab(1)
    self.player.print('(gvv) ' .. new_count .. ' new entries imported.  /  ' .. duplicate_count .. ' entries already exist.')
end
