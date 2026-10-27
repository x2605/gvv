---------------------------------------------------------------------------------------------
-- GVV GUI HELP
---------------------------------------------------------------------------------------------
-- FR : Onglet aide de gvv (étape 3.3 de la restructuration 0.6).
--      Construit l'onglet dans le contenu de l'onglet aide de la fenêtre principale
--      (gvv_main-flow-help), affiche les pages (contenu : gui/help_pages.lua) et gère leurs actions :
--      choix d'une page, textes à copier, menus de choix d'un mod, diagnostic / nettoyage, démonstrations.
--      Comportement repris de l'ancien code (legacy/help_menu.lua, legacy/gui_event.lua), sans changement.
--      Les textes à copier sont en lecture seule grâce à leurs tags (plus de label caché).
--      Description des éléments : gui/help.lua.
-- EN : gvv help tab (step 3.3 of the 0.6 restructuring).
--      Builds the tab inside the content of the main window's help tab
--      (gvv_main-flow-help), shows the pages (content: gui/help_pages.lua) and handles their actions:
--      page choice, texts to copy, mod choice menus, diagnosis / fixing, demonstrations.
--      Behaviour taken from the old code (legacy/help_menu.lua, legacy/gui_event.lua), unchanged.
--      Texts to copy are read-only thanks to their tags (no more hidden label).
--      Elements description: gui/help.lua.
---------------------------------------------------------------------------------------------
local check = require(gvv.defines.lualib.common.check)
local Copy_Code = require(gvv.defines.lualib.common.copy_code)
local Doctor = require(gvv.defines.lualib.common.doctor)
local fGui = require(gvv.defines.gui.help)
local fPages = require(gvv.defines.gui.help_pages)
---------------------------------------------------------------------------------------------

-- FR : Styles des boutons de démonstration, et leur version « suivie » (clic droit pour passer de l'un à l'autre)
-- EN : Demonstration buttons styles, and their "tracked" version (right click to switch from one to the other)
local DEMO_STYLE_SWITCH = {
    ['tree-item_gvv-mod'] = 'tracked-tree-item_gvv-mod',
    ['tracked-tree-item_gvv-mod'] = 'tree-item_gvv-mod',
    ['tree-item-folder_gvv-mod'] = 'tracked-tree-item-folder_gvv-mod',
    ['tracked-tree-item-folder_gvv-mod'] = 'tree-item-folder_gvv-mod',
    ['tree-item-luaobj_gvv-mod'] = 'tracked-tree-item-luaobj_gvv-mod',
    ['tracked-tree-item-luaobj_gvv-mod'] = 'tree-item-luaobj_gvv-mod',
}

-- FR : Formes du nom de mod (liste « option » de la page console 2) et texte correspondant
-- EN : Mod name forms ("option" list of the console 2 page) and matching text
local MOD_STRING_FORMS = {
    ['__<mod_name>__'] = function(mod_name)
        return '__' .. mod_name .. '__'
    end,
    ['remote.call..."storage")'] = function(mod_name)
        return 'remote.call("__' .. mod_name .. '__gvv","storage")'
    end,
    ['remote.call..."c",)'] = function(mod_name)
        return 'remote.call("__' .. mod_name .. '__gvv","c",)'
    end,
}


---**EN**
---
---Description: Help tab ("gvv_help"): pages list, page drawing (gui/help_pages.lua), diagnose / fix of a mod.
---
---⚠ Temporary wrapper, created on each event. Do not store the instance in `storage`.
---
---──────────────────────────────
---
---**FR**
---
---Description: Onglet aide (« gvv_help ») : liste des pages, dessin d'une page (gui/help_pages.lua), diagnostic / réparation d'un mod.
---
---⚠ Wrapper temporaire, créé à chaque évènement. Ne pas stocker l'instance dans `storage`.
---@class GvvGuiHelp : GvvGui
---@field object_name string     "GvvGuiHelp"
---@field specs table            Elements description (gui/help.lua)
---@field top LuaGuiElement?     Page being written
---@field pointer LuaGuiElement? Container where elements are added
---@operator call(table): GvvGuiHelp
---@type GvvGuiHelp
GvvGuiHelp = gvv.classFactory.newclass(GvvGui, function(self, event)
    -- FR : Onglet « gvv_help », dont l'élément racine est « flow-wrap » (gvv_help-flow-wrap)
    -- EN : "gvv_help" tab, whose root element is "flow-wrap" (gvv_help-flow-wrap)
    GvvGui.init(self, event, fGui.GUI_NAME, "flow-wrap")
    self.object_name = "GvvGuiHelp"

    --------------------------------------------------
    -- FR : Le conteneur est le contenu de l'onglet aide de la fenêtre principale (nil si elle est fermée)
    -- EN : The container is the content of the main window's help tab (nil if it is closed)
    if self.isPresent then
        self.gui = { GvvGuiMain(event):getElement("content", "help") }
    end

    -- FR : Chemins des éléments (gui/help.lua) et description des éléments
    -- EN : Element paths (gui/help.lua) and elements description
    self.content = fGui.getContent()
    self.specs = fGui.getElement(self.gui_name)

    -- FR : Actions de l'onglet
    -- EN : Tab actions
    self.gui_action = {
        ["textfield-text-text_changed"] = "action_restore_text",                -- FR : texte à copier modifié / EN : text to copy modified
        ["textbox-text-text_changed"] = "action_restore_text",
        ["dropdown-enable-selection_state_changed"] = "action_enable_mod",      -- FR : mod du code d'activation / EN : enabling code mod
        ["dropdown-disable-selection_state_changed"] = "action_disable_mod",    -- FR : mod du code de désactivation / EN : disabling code mod
        ["listbox-option-selection_state_changed"] = "action_mod_string",       -- FR : forme du nom de mod / EN : mod name form
        ["listbox-mod-selection_state_changed"] = "action_mod_string",          -- FR : mod choisi / EN : chosen mod
        ["button-diagnose"] = "action_diagnose",                                -- FR : diagnostic / EN : diagnosis
        ["button-fix"] = "action_fix",                                          -- FR : nettoyage / EN : fixing
        ["button-clear_report"] = "action_clear_report",                        -- FR : effacer storage.report / EN : clear storage.report
        ["button-demo"] = "action_demo",                                        -- FR : démonstration / EN : demonstration
    }
    -- FR : Un bouton par page dans la liste : « button-page_<nom> »
    -- EN : One button per page in the list: "button-page_<name>"
    for _, page in ipairs(fPages.pages) do
        self.gui_action["button-page_" .. page.name] = "action_open_page"
    end
    --------------------------------------------------
end) --[[@as GvvGuiHelp]]
----------------------------------------------------------------


---**EN**
---
---Description: Builds the help tab (pages list and empty page panel). Called by GvvGuiMain:open.
---
---──────────────────────────────
---
---**FR**
---
---Description: Construit l'onglet aide (liste des pages et panneau de page vide). Appelé par GvvGuiMain:open.
---@return GvvGuiHelp
function GvvGuiHelp:build()
    -- FR : Conteneur absent (fenêtre principale fermée) : rien à construire
    -- EN : Missing container (main window closed): nothing to build
    if not check.isValidLuaObject(self.gui[1]) then
        return self
    end

    -- FR : Conteneur de l'onglet, avec une bande de fond en haut
    -- EN : Tab container, with a background strip at the top
    local wrap = self.gui[1].add(self.specs.flow.wrap)
    local fill = wrap.add(self.specs.empty.fill)
    fill.style.height = 8

    -- FR : Liste des pages à gauche, séparateur, page à droite
    -- EN : Pages list on the left, divider, page on the right
    local panel = wrap.add(self.specs.flow.panel)

    local list = panel.add(self.specs.pane.list)
    list.style.horizontally_stretchable = false
    list.style.horizontally_squashable = true
    list.style.maximal_width = 230

    local divider = panel.add(self.specs.empty.divider)
    divider.style.width = 6

    panel.add(self.specs.pane.page)

    -- FR : Un bouton par page
    -- EN : One button per page
    for _, page in ipairs(fPages.pages) do
        list.add(fGui.getPageButton(self.gui_name, page))
    end
    return self
end


---**EN**
---
---Description: Shows a page: empties the panel, then the page writes itself with the add* methods below.
---
---──────────────────────────────
---
---**FR**
---
---Description: Affiche une page : vide le panneau, puis la page s'écrit avec les méthodes add* ci-dessous.
---@param page_name string
---@return GvvGuiHelp
function GvvGuiHelp:drawPage(page_name)
    -- FR : Page et panneau
    -- EN : Page and panel
    local page = fPages.getPage(page_name)
    local panel = self:getElement("pane", "page")
    if page == nil or panel == nil then
        return self
    end

    -- FR : Panneau vidé ; l'écriture commence à sa racine
    -- EN : Panel emptied; writing starts at its root
    panel.clear()
    self.top = panel
    self.pointer = panel
    page.write(self)
    return self
end


---------------------------------------------------------------------------------------------
-- FR : ÉCRITURE DES PAGES (appelée par gui/help_pages.lua). Chaque méthode renvoie l'élément créé.
-- EN : PAGES WRITING (called by gui/help_pages.lua). Each method returns the created element.
---------------------------------------------------------------------------------------------

---**EN**
---
---Description: Adds any element (description) into the current container.
---
---──────────────────────────────
---
---**FR**
---
---Description: Ajoute un élément quelconque (description) dans le conteneur actuel.
---@param spec table
---@return LuaGuiElement
function GvvGuiHelp:add(spec)
    return self.pointer.add(spec)
end


---**EN**
---
---Description: Multi-line label, taking the whole width (shared by addText, addTitle, addSubtitle)
---
---──────────────────────────────
---
---**FR**
---
---Description: Label sur plusieurs lignes, qui prend toute la largeur (commun à addText, addTitle, addSubtitle)
---@param self GvvGuiHelp
---@param caption LocalisedString
---@param tooltip? LocalisedString
---@param style? string
---@return LuaGuiElement label
local function addLabel(self, caption, tooltip, style)
    local label = self.pointer.add{ type = 'label', caption = caption, tooltip = tooltip, style = style }
    label.style.horizontally_stretchable = true
    label.style.single_line = false
    return label
end

---**EN**
---
---Description: Paragraph (localised or plain text), with an optional tooltip.
---
---──────────────────────────────
---
---**FR**
---
---Description: Paragraphe (texte localisé ou texte simple), avec une infobulle facultative.
---@param caption LocalisedString
---@param tooltip? LocalisedString
---@return LuaGuiElement
function GvvGuiHelp:addText(caption, tooltip)
    return addLabel(self, caption, tooltip, nil)
end

---**EN**
---
---Description: Page title.
---
---──────────────────────────────
---
---**FR**
---
---Description: Titre de page.
---@param caption LocalisedString
---@return LuaGuiElement
function GvvGuiHelp:addTitle(caption)
    return addLabel(self, caption, nil, 'frame_title')
end

---**EN**
---
---Description: Subtitle, slightly shifted to the right.
---
---──────────────────────────────
---
---**FR**
---
---Description: Sous-titre, légèrement décalé à droite.
---@param caption LocalisedString
---@return LuaGuiElement
function GvvGuiHelp:addSubtitle(caption)
    local label = addLabel(self, caption, nil, 'heading_2_label')
    label.style.left_padding = 7
    return label
end

---**EN**
---
---Description: Horizontal separator line.
---
---──────────────────────────────
---
---**FR**
---
---Description: Ligne de séparation horizontale.
---@return LuaGuiElement
function GvvGuiHelp:addLine()
    local line = self.pointer.add{ type = 'line', direction = 'horizontal' }
    line.style.horizontally_stretchable = true
    return line
end

---**EN**
---
---Description: Opens a horizontal container: the next elements are added into it, until closeContainer.
---
---──────────────────────────────
---
---**FR**
---
---Description: Ouvre un conteneur horizontal : les éléments suivants s'y ajoutent, jusqu'à closeContainer.
---@return LuaGuiElement
function GvvGuiHelp:openRow()
    local row = self.pointer.add{ type = 'flow', direction = 'horizontal', style = 'hflow_gvv-mod' }
    row.style.horizontally_stretchable = true
    self.pointer = row
    return row
end

---**EN**
---
---Description: Opens a vertical container (spec: description of a named flow, optional).
---
---──────────────────────────────
---
---**FR**
---
---Description: Ouvre un conteneur vertical (spec : description d'un flow nommé, facultative).
---@param spec? table
---@return LuaGuiElement
function GvvGuiHelp:openColumn(spec)
    local column = self.pointer.add(spec or { type = 'flow', direction = 'vertical', style = 'vflow_gvv-mod' })
    column.style.horizontally_stretchable = true
    self.pointer = column
    return column
end

---**EN**
---
---Description: Goes back to the parent container (without going above the page).
---
---──────────────────────────────
---
---**FR**
---
---Description: Revient au conteneur parent (sans remonter au-delà de la page).
---@return LuaGuiElement
function GvvGuiHelp:closeContainer()
    if self.pointer ~= self.top then
        self.pointer = self.pointer.parent
    end
    return self.pointer
end

---**EN**
---
---Description: Code to copy, read-only (original text stored in the tags): on one line,
---or on several (adapted height, 400 at most). linked: container named "flow-copy",
---found by the menus and lists that change this code.
---
---──────────────────────────────
---
---**FR**
---
---Description: Code à copier, en lecture seule (texte d'origine rangé dans les tags) : sur une ligne,
---ou sur plusieurs (hauteur adaptée, 400 au plus). linked : conteneur nommé « flow-copy »,
---retrouvé par les menus et listes qui changent ce code.
---@param text string
---@param linked? boolean
---@return LuaGuiElement
function GvvGuiHelp:addCopyable(text, linked)
    -- FR : Conteneur du code
    -- EN : Code container
    local flow_spec = { type = 'flow', direction = 'vertical', style = 'vflow_gvv-mod' }
    if linked then
        flow_spec = self.specs.flow.copy
    end
    local flow = self.pointer.add(flow_spec)
    flow.style.horizontally_stretchable = true

    -- FR : Une ligne (textfield) ou plusieurs (text-box)
    -- EN : One line (textfield) or several (text-box)
    local newline_count = select(2, text:gsub('\n', ''))
    local spec = self.specs.text.field
    if newline_count > 0 then
        spec = self.specs.text.box
    end
    spec.text = text
    spec.tags = { text = text }
    spec.clear_and_focus_on_right_click = true
    local text_element = flow.add(spec)

    -- FR : Hauteur d'un texte sur plusieurs lignes
    -- EN : Height of a multi-line text
    if newline_count > 0 then
        local height = 22 + 22 * newline_count
        if height > 400 then
            height = 400
        end
        text_element.style.height = height
    end

    -- FR : Largeur : remplit la place disponible
    -- EN : Width: fills the available space
    text_element.style.horizontally_stretchable = true
    text_element.style.horizontally_squashable = true
    text_element.style.minimal_width = 10
    text_element.style.maximal_width = 9999
    return text_element
end

---**EN**
---
---Description: Replaces the text of a code to copy (and its copy in the tags).
---
---──────────────────────────────
---
---**FR**
---
---Description: Remplace le texte d'un code à copier (et sa copie dans les tags).
---@param text_element LuaGuiElement
---@param text string
function GvvGuiHelp:setCopyableText(text_element, text)
    text_element.text = text
    text_element.tags = { text = text }
end

---**EN**
---
---Description: Demonstration button of a tree row (right click: "tracked" style or not).
---
---──────────────────────────────
---
---**FR**
---
---Description: Bouton de démonstration d'une ligne d'arbre (clic droit : style « suivi » ou non).
---@param caption string
---@param style string
---@param mouse_filter string[]
---@return LuaGuiElement
function GvvGuiHelp:addDemo(caption, style, mouse_filter)
    local spec = self.specs.button.demo
    spec.caption = caption
    spec.style = style
    spec.mouse_button_filter = mouse_filter
    return self.pointer.add(spec)
end


---------------------------------------------------------------------------------------------
-- FR : ACTIONS
-- EN : ACTIONS
---------------------------------------------------------------------------------------------

---**EN**
---
---Description: Page button in the list: shows the page (its name is in the button tags).
---
---──────────────────────────────
---
---**FR**
---
---Description: Bouton d'une page dans la liste : affiche la page (son nom est dans les tags du bouton).
function GvvGuiHelp:action_open_page()
    local page_name = check.tryGet(self.element.tags, "page")
    if page_name ~= nil then
        self:drawPage(page_name)
    end
end


---**EN**
---
---Description: Text to copy modified by the player: put the original text back (tags) and select it.
---
---──────────────────────────────
---
---**FR**
---
---Description: Texte à copier modifié par le joueur : on remet le texte d'origine (tags) et on le sélectionne.
function GvvGuiHelp:action_restore_text()
    local original = check.tryGet(self.element.tags, "text")
    if original ~= nil then
        self.element.text = original
        self.element.select_all()
    end
end


---**EN**
---
---Description: Code to copy linked to the menu or list: inside the "flow-copy" container of the same parent
---
---──────────────────────────────
---
---**FR**
---
---Description: Code à copier lié au menu ou à la liste : dans le conteneur « flow-copy » du même parent
---@param self GvvGuiHelp
---@param parent LuaGuiElement
---@return LuaGuiElement?
local function linkedCopyable(self, parent)
    local flow = check.tryGet(parent, self.gui_name .. "-flow-copy")
    return check.tryGet(flow, self.gui_name .. "-textfield-text") or check.tryGet(flow, self.gui_name .. "-textbox-text")
end

---**EN**
---
---Description: Changes the code to copy, then selects it (ready to copy)
---
---──────────────────────────────
---
---**FR**
---
---Description: Change le code à copier, puis le sélectionne (prêt à copier)
---@param self GvvGuiHelp
---@param text_element LuaGuiElement
---@param text string
local function showLinkedCode(self, text_element, text)
    if text_element == nil then
        return
    end
    self:setCopyableText(text_element, text)
    text_element.focus()
    text_element.select_all()
end

---**EN**
---
---Description: Enabling code menu (console 1 page): enabling code for the chosen mod.
---
---──────────────────────────────
---
---**FR**
---
---Description: Menu du code d'activation (page console 1) : code d'activation pour le mod choisi.
function GvvGuiHelp:action_enable_mod()
    local mod_name = self.element.items[self.element.selected_index]
    showLinkedCode(self, linkedCopyable(self, self.element.parent), Copy_Code.in_console_enable(mod_name))
end

---**EN**
---
---Description: Disabling code menu (console 1 page): disabling code for the chosen mod.
---
---──────────────────────────────
---
---**FR**
---
---Description: Menu du code de désactivation (page console 1) : code de désactivation pour le mod choisi.
function GvvGuiHelp:action_disable_mod()
    local mod_name = self.element.items[self.element.selected_index]
    showLinkedCode(self, linkedCopyable(self, self.element.parent), Copy_Code.in_console_disable(mod_name))
end

---**EN**
---
---Description: Console 2 page lists: writes the chosen mod name in the chosen form.
---
---──────────────────────────────
---
---**FR**
---
---Description: Listes de la page console 2 : écrit le nom du mod choisi sous la forme choisie.
function GvvGuiHelp:action_mod_string()
    -- FR : Les deux listes : « option » est dans la ligne, « mod » dans la colonne flow-mod_list de cette ligne
    -- EN : Both lists: "option" is in the row, "mod" in the flow-mod_list column of this row
    local option_list, mod_list
    if self.element.name == self.gui_name .. "-listbox-mod" then
        mod_list = self.element
        option_list = check.tryGet(mod_list.parent.parent, self.gui_name .. "-listbox-option")
    else
        option_list = self.element
        mod_list = check.getPath(option_list.parent, {self.gui_name .. "-flow-mod_list", self.gui_name .. "-listbox-mod"})
    end
    if option_list == nil or mod_list == nil then
        return
    end

    -- FR : Texte selon la forme ; « <mod_name> » : le nom seul
    -- EN : Text according to the form; "<mod_name>": the name alone
    local mod_name = mod_list.items[mod_list.selected_index]
    local form = MOD_STRING_FORMS[option_list.items[option_list.selected_index]]
    local text = mod_name
    if form ~= nil then
        text = form(mod_name)
    end
    showLinkedCode(self, linkedCopyable(self, mod_list.parent), text)
end


---**EN**
---
---Description: Mod name typed in the troubleshooting page (field above the buttons)
---
---──────────────────────────────
---
---**FR**
---
---Description: Nom du mod saisi dans la page dépannage (champ au-dessus des boutons)
---@param self GvvGuiHelp
---@return string
local function typedModName(self)
    local field = check.tryGet(self.element.parent.parent, self.gui_name .. "-textfield-mod")
    return check.tryGet(field, "text") or ''
end

---**EN**
---
---Description: Diagnose button: diagnosis of the typed mod storage (lualib/common/doctor.lua).
---
---──────────────────────────────
---
---**FR**
---
---Description: Bouton diagnostic : diagnostic du storage du mod saisi (lualib/common/doctor.lua).
function GvvGuiHelp:action_diagnose()
    self:runDoctor('diag')
end

---**EN**
---
---Description: Fix button: cleaning of the typed mod storage (lualib/common/doctor.lua).
---
---──────────────────────────────
---
---**FR**
---
---Description: Bouton nettoyage : nettoyage du storage du mod saisi (lualib/common/doctor.lua).
function GvvGuiHelp:action_fix()
    self:runDoctor('fix')
end

---**EN**
---
---Description: Runs the diagnosis ('diag') or the fixing ('fix') on the typed mod.
---Empty field: a message asks for the mod name (before: error ""____gvv" interface is not found").
---
---──────────────────────────────
---
---**FR**
---
---Description: Lance le diagnostic ('diag') ou le nettoyage ('fix') sur le mod saisi.
---Champ vide : un message demande le nom du mod (avant : erreur « "____gvv" interface is not found »).
---@param action string
function GvvGuiHelp:runDoctor(action)
    -- FR : Nom du mod sans espaces autour ; vide : on le demande
    -- EN : Mod name without surrounding spaces; empty: ask for it
    local mod_name = typedModName(self):gsub('^%s*(.-)%s*$', '%1')
    if mod_name == '' then
        self.player.print('(gvv) Type a mod name first.')
        return
    end
    Doctor.take_a_look(self:getData(), mod_name, action)
end

---**EN**
---
---Description: storage.report clearing button.
---
---──────────────────────────────
---
---**FR**
---
---Description: Bouton d'effacement de storage.report.
function GvvGuiHelp:action_clear_report()
    storage.report = {}
    self.player.print('(gvv) storage.report is cleared.')
end

---**EN**
---
---Description: Demonstration button: right click switches from the normal style to the "tracked" style, and back.
---
---──────────────────────────────
---
---**FR**
---
---Description: Bouton de démonstration : le clic droit passe du style normal au style « suivi », et inversement.
function GvvGuiHelp:action_demo()
    if self.event.button ~= defines.mouse_button_type.right then
        return
    end
    local next_style = DEMO_STYLE_SWITCH[self.element.style.name]
    if next_style ~= nil then
        self.element.style = next_style
    end
end
