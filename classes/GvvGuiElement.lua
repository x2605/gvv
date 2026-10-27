---------------------------------------------------------------------------------------------
-- GVV GUI ELEMENT
---------------------------------------------------------------------------------------------
-- FR : Source : RitnLib (Ritn), classes/RitnClass/gui/RitnGuiElement.lua (RitnLibGuiElement), version 0.10.7.
--      Constructeur de la description d'un élément GUI (la table passée à LuaGuiElement.add),
--      copié et adapté pour que gvv reste autonome.
--      Différences : plus de log à chaque appel, text() corrigé (il testait une variable inexistante
--      et ne fonctionnait jamais), ajout de tags() pour les données des éléments dynamiques,
--      textfield accepté par text().
-- EN : Source: RitnLib (Ritn), classes/RitnClass/gui/RitnGuiElement.lua (RitnLibGuiElement), version 0.10.7.
--      Builder of a GUI element description (the table given to LuaGuiElement.add),
--      copied and adapted so gvv stays standalone.
--      Differences: no more log on each call, text() fixed (it tested a non-existent variable
--      and never worked), added tags() for dynamic elements data, textfield accepted by text().
---------------------------------------------------------------------------------------------
-- FR : Utilisation : chaque méthode renvoie l'objet, on enchaîne donc les appels, puis get() :
--        parent.add( GvvGuiElement("gvv_main", "sprite-button", "close"):style("frame_action_button"):get() )
--      Nom généré : gui_name-type-name (ici « gvv_main-button-close »), découpé par GvvGui pour
--      retrouver l'action. Ni gui_name ni name ne doivent contenir de « - ».
--      Une méthode qui reçoit une valeur invalide, ou qui ne concerne pas ce type d'élément,
--      ne fait rien (pas d'erreur).
-- EN : Usage: each method returns the object, so calls are chained, then get():
--        parent.add( GvvGuiElement("gvv_main", "sprite-button", "close"):style("frame_action_button"):get() )
--      Generated name: gui_name-type-name (here "gvv_main-button-close"), split by GvvGui to
--      find the action. Neither gui_name nor name may contain "-".
--      A method that receives an invalid value, or that doesn't apply to this element type,
--      does nothing (no error).
---------------------------------------------------------------------------------------------

-- FR : Types Factorio raccourcis dans le nom de l'élément (le « - » est réservé au découpage du nom)
-- EN : Factorio types shortened in the element name (the "-" is reserved for splitting the name)
local short_types = {
    ["sprite-button"] = "button",
    ["choose-elem-button"] = "button",
    ["text-box"] = "textbox",
    ["list-box"] = "listbox",
    ["drop-down"] = "dropdown",
    ["entity-preview"] = "preview",
    ["empty-widget"] = "empty",
    ["scroll-pane"] = "pane",
    ["tabbed-pane"] = "tabbed",
}

-- FR : Valeurs acceptées pour les barres de défilement d'un scroll-pane
-- EN : Accepted values for the scroll bars of a scroll-pane
local scroll_policy_valid = {
    auto = true,
    never = true,
    always = true,
    ["auto-and-reserve-space"] = true,
    ["dont-show-but-allow-scrolling"] = true,
}

-- FR : Types de valeur acceptés pour un texte affiché : texte simple ou texte localisé (table)
-- EN : Value types accepted for a displayed text: plain text or localised string (table)
local string_valid = { string = true, table = true }

-- FR : Types d'éléments concernés par chaque méthode
-- EN : Element types concerned by each method
local orientation_valid = { frame = true, flow = true, line = true }   -- horizontal(), vertical()
local text_valid = { textfield = true, ["text-box"] = true }           -- text()
local button_valid = { button = true, ["sprite-button"] = true }       -- mouseButtonFilter()
local sprite_valid = { sprite = true, ["sprite-button"] = true }       -- spritePath()
local check_valid = { checkbox = true, radiobutton = true }            -- checked()


---**EN**
---
---Description: Chainable builder of a GUI element description (spec given to `LuaGuiElement.add`), named
---`gui_name-type-name` (copied from RitnLib `RitnLibGuiElement`). `get()` returns the description.
---
---──────────────────────────────
---
---**FR**
---
---Description: Constructeur chaînable de la description d'un élément GUI (spec passée à `LuaGuiElement.add`), nommé
---`gui_name-type-name` (copié de `RitnLibGuiElement` de RitnLib). `get()` renvoie la description.
---@class GvvGuiElement
---@field object_name string     "GvvGuiElement"
---@field gui_name string        Full in-game element name
---@field name string            "name" part
---@field type string            Factorio type
---@field ui string              Window name (GvvGui gui_name)
---@field action string          short_type-name, the triggered action
---@field gui_element table      Description given to LuaGuiElement.add
---@operator call(string, string, string): GvvGuiElement
---@type GvvGuiElement
GvvGuiElement = gvv.classFactory.newclass(function(self, ui_name, element_type, element_name)
    -- FR : Nom de la classe, utile dans les logs
    -- EN : Class name, useful in logs
    self.object_name = "GvvGuiElement"

    -- FR : Type raccourci pour le nom (« sprite-button » devient « button »), sinon le type tel quel
    -- EN : Shortened type for the name ("sprite-button" becomes "button"), otherwise the type as is
    local short_type = short_types[element_type] or element_type

    --------------------------------------------------
    -- FR : Nom en jeu : gui_name-type-name, ex. « gvv_main-button-close »
    -- EN : In-game name: gui_name-type-name, e.g. "gvv_main-button-close"
    self.gui_name = ui_name .. "-" .. short_type .. "-" .. element_name
    self.name = element_name        -- FR : partie « name » (ex. « close ») / EN : "name" part (e.g. "close")
    self.type = element_type        -- FR : type Factorio complet (ex. « sprite-button ») / EN : full Factorio type (e.g. "sprite-button")
    self.ui = ui_name               -- FR : fenêtre (ex. « gvv_main ») / EN : window (e.g. "gvv_main")
    -- FR : Action déclenchée par cet élément, cherchée dans gui_action de la fenêtre (ex. « button-close »)
    -- EN : Action triggered by this element, looked up in the window's gui_action (e.g. "button-close")
    self.action = short_type .. "-" .. element_name
    --------------------------------------------------

    -- FR : Description de départ, complétée par les méthodes ci-dessous
    -- EN : Starting description, completed by the methods below
    self.gui_element = {
        type = self.type,
        name = self.gui_name,
        visible = true,
    }

    -- FR : Un scroll-pane n'a pas de barre horizontale par défaut
    -- EN : A scroll-pane has no horizontal bar by default
    if element_type == "scroll-pane" then
        self.gui_element.horizontal_scroll_policy = "never"
    end
end) --[[@as GvvGuiElement]]
----------------------------------------------------------------


---**EN**
---
---Description: Adds the element to parent and returns the created LuaGuiElement.
---
---──────────────────────────────
---
---**FR**
---
---Description: Ajoute l'élément à parent et renvoie le LuaGuiElement créé.
---@param parent LuaGuiElement
---@return LuaGuiElement?
function GvvGuiElement:add(parent)
    -- FR : Pas de parent : rien à créer
    -- EN : No parent: nothing to create
    if parent == nil then
        return nil
    end

    -- FR : Création de l'élément dans le parent
    -- EN : Create the element inside the parent
    return parent.add(self.gui_element)
end


---**EN**
---
---Description: Returns the element description, to give to parent.add(...).
---
---──────────────────────────────
---
---**FR**
---
---Description: Renvoie la description de l'élément, à passer à parent.add(...).
---@return table
function GvvGuiElement:get()
    return self.gui_element
end


---**EN**
---
---Description: Horizontal layout of children (frame, flow) or horizontal line (line).
---
---──────────────────────────────
---
---**FR**
---
---Description: Disposition horizontale des enfants (frame, flow) ou ligne horizontale (line).
---@return GvvGuiElement
function GvvGuiElement:horizontal()
    -- FR : Seulement pour les éléments qui ont une direction
    -- EN : Only for elements that have a direction
    if orientation_valid[self.type] then
        self.gui_element.direction = "horizontal"
    end
    return self
end


---**EN**
---
---Description: Vertical layout of children (frame, flow) or vertical line (line).
---
---──────────────────────────────
---
---**FR**
---
---Description: Disposition verticale des enfants (frame, flow) ou ligne verticale (line).
---@return GvvGuiElement
function GvvGuiElement:vertical()
    -- FR : Seulement pour les éléments qui ont une direction
    -- EN : Only for elements that have a direction
    if orientation_valid[self.type] then
        self.gui_element.direction = "vertical"
    end
    return self
end


---**EN**
---
---Description: Automatically centres the window on screen (frame only).
---
---──────────────────────────────
---
---**FR**
---
---Description: Centre automatiquement la fenêtre à l'écran (frame seulement).
---@return GvvGuiElement
function GvvGuiElement:autoCenter()
    if self.type == "frame" then
        self.gui_element.auto_center = true
    end
    return self
end


---**EN**
---
---Description: Element visible or hidden when created.
---
---──────────────────────────────
---
---**FR**
---
---Description: Élément visible ou caché à sa création.
---@param visible boolean
---@return GvvGuiElement
function GvvGuiElement:visible(visible)
    -- FR : Valeur non booléenne : ignorée
    -- EN : Non-boolean value: ignored
    if type(visible) ~= "boolean" then
        return self
    end
    self.gui_element.visible = visible
    return self
end


---**EN**
---
---Description: Element enabled or greyed out when created.
---
---──────────────────────────────
---
---**FR**
---
---Description: Élément actif ou grisé à sa création.
---@param enabled boolean
---@return GvvGuiElement
function GvvGuiElement:enabled(enabled)
    -- FR : Valeur non booléenne : ignorée
    -- EN : Non-boolean value: ignored
    if type(enabled) ~= "boolean" then
        return self
    end
    self.gui_element.enabled = enabled
    return self
end


---**EN**
---
---Description: Text displayed on the element (plain text or localised string).
---
---──────────────────────────────
---
---**FR**
---
---Description: Texte affiché sur l'élément (texte simple ou texte localisé).
---@param caption LocalisedString
---@return GvvGuiElement
function GvvGuiElement:caption(caption)
    -- FR : Seulement un texte ou une table (texte localisé)
    -- EN : Only a text or a table (localised string)
    if string_valid[type(caption)] then
        self.gui_element.caption = caption
    end
    return self
end


---**EN**
---
---Description: Tooltip shown on hover (plain text or localised string).
---
---──────────────────────────────
---
---**FR**
---
---Description: Infobulle affichée au survol (texte simple ou texte localisé).
---@param tooltip LocalisedString
---@return GvvGuiElement
function GvvGuiElement:tooltip(tooltip)
    -- FR : Seulement un texte ou une table (texte localisé)
    -- EN : Only a text or a table (localised string)
    if not string_valid[type(tooltip)] then
        return self
    end
    self.gui_element.tooltip = tooltip
    return self
end


---**EN**
---
---Description: Element position among its parent's children (1 = first).
---
---──────────────────────────────
---
---**FR**
---
---Description: Position de l'élément parmi les enfants de son parent (1 = premier).
---@param index integer
---@return GvvGuiElement
function GvvGuiElement:index(index)
    -- FR : Valeur non numérique : ignorée
    -- EN : Non-numeric value: ignored
    if type(index) ~= "number" then
        return self
    end
    self.gui_element.index = index
    return self
end


---**EN**
---
---Description: Starting text of an input field (textfield, text-box).
---Fixed compared to RitnLib, which tested the "tooltip" variable instead of "text".
---
---──────────────────────────────
---
---**FR**
---
---Description: Texte de départ d'un champ de saisie (textfield, text-box).
---Corrigé par rapport à RitnLib, qui testait la variable « tooltip » au lieu de « text ».
---@param text string
---@return GvvGuiElement
function GvvGuiElement:text(text)
    -- FR : Valeur non texte : ignorée
    -- EN : Non-text value: ignored
    if type(text) ~= "string" then
        return self
    end
    -- FR : Seulement pour les champs de saisie
    -- EN : Only for input fields
    if text_valid[self.type] then
        self.gui_element.text = text
    end
    return self
end


---**EN**
---
---Description: Factorio style of the element (e.g. "frame_action_button").
---
---──────────────────────────────
---
---**FR**
---
---Description: Style Factorio de l'élément (ex. « frame_action_button »).
---@param style string
---@return GvvGuiElement
function GvvGuiElement:style(style)
    -- FR : Valeur non texte : ignorée
    -- EN : Non-text value: ignored
    if type(style) ~= "string" then
        return self
    end
    self.gui_element.style = style
    return self
end


---**EN**
---
---Description: Displayed image (sprite, sprite-button), e.g. "utility/close".
---
---──────────────────────────────
---
---**FR**
---
---Description: Image affichée (sprite, sprite-button), ex. « utility/close ».
---@param sprite string
---@return GvvGuiElement
function GvvGuiElement:spritePath(sprite)
    -- FR : Valeur non texte : ignorée
    -- EN : Non-text value: ignored
    if type(sprite) ~= "string" then
        return self
    end
    -- FR : Seulement pour les éléments qui affichent une image
    -- EN : Only for elements that display an image
    if sprite_valid[self.type] then
        self.gui_element.sprite = sprite
    end
    return self
end


---**EN**
---
---Description: Horizontal scroll bar of a scroll-pane ("auto", "never", "always"...).
---
---──────────────────────────────
---
---**FR**
---
---Description: Barre de défilement horizontale d'un scroll-pane (« auto », « never », « always »...).
---@param policy string
---@return GvvGuiElement
function GvvGuiElement:horizontalScrollPolicy(policy)
    -- FR : Valeur inconnue : ignorée
    -- EN : Unknown value: ignored
    if type(policy) ~= "string" or not scroll_policy_valid[policy] then
        return self
    end
    if self.type == "scroll-pane" then
        self.gui_element.horizontal_scroll_policy = policy
    end
    return self
end


---**EN**
---
---Description: Vertical scroll bar of a scroll-pane ("auto", "never", "always"...).
---
---──────────────────────────────
---
---**FR**
---
---Description: Barre de défilement verticale d'un scroll-pane (« auto », « never », « always »...).
---@param policy string
---@return GvvGuiElement
function GvvGuiElement:verticalScrollPolicy(policy)
    -- FR : Valeur inconnue : ignorée
    -- EN : Unknown value: ignored
    if type(policy) ~= "string" or not scroll_policy_valid[policy] then
        return self
    end
    if self.type == "scroll-pane" then
        self.gui_element.vertical_scroll_policy = policy
    end
    return self
end


---**EN**
---
---Description: The sprite element takes its image size (true) or keeps its style size (false).
---
---──────────────────────────────
---
---**FR**
---
---Description: L'élément sprite prend la taille de son image (true) ou garde la taille de son style (false).
---@param resize boolean
---@return GvvGuiElement
function GvvGuiElement:resizeSprite(resize)
    -- FR : Valeur non booléenne : ignorée
    -- EN : Non-boolean value: ignored
    if type(resize) ~= "boolean" then
        return self
    end
    if self.type == "sprite" then
        self.gui_element.resize_to_sprite = resize
    end
    return self
end


---**EN**
---
---Description: Starting state of a checkbox or radio button (checked by default).
---
---──────────────────────────────
---
---**FR**
---
---Description: État de départ d'une case à cocher ou d'un bouton radio (coché par défaut).
---@param state? boolean
---@return GvvGuiElement
function GvvGuiElement:checked(state)
    -- FR : Sans valeur : coché
    -- EN : Without value: checked
    if state == nil then
        state = true
    end
    -- FR : Valeur non booléenne : ignorée
    -- EN : Non-boolean value: ignored
    if type(state) ~= "boolean" then
        return self
    end
    if check_valid[self.type] then
        self.gui_element.state = state
    end
    return self
end


---**EN**
---
---Description: Starting value of a progress bar (0 to 100, 0 by default).
---
---──────────────────────────────
---
---**FR**
---
---Description: Valeur de départ d'une barre de progression (0 à 100, 0 par défaut).
---@param value? number
---@return GvvGuiElement
function GvvGuiElement:progress(value)
    -- FR : Sans valeur : 0
    -- EN : Without value: 0
    if value == nil then
        value = 0
    end
    -- FR : Valeur non numérique ou hors de 0 à 100 : ignorée
    -- EN : Non-numeric value or outside 0 to 100: ignored
    if type(value) ~= "number" or value > 100 or value < 0 then
        return self
    end
    if self.type == "progressbar" then
        self.gui_element.value = value
    end
    return self
end


---**EN**
---
---Description: Mouse buttons accepted by a button ({"left"} by default, e.g. {"left", "right"}).
---
---──────────────────────────────
---
---**FR**
---
---Description: Boutons de la souris acceptés par un bouton ({"left"} par défaut, ex. {"left", "right"}).
---@param filter? string[]
---@return GvvGuiElement
function GvvGuiElement:mouseButtonFilter(filter)
    -- FR : Sans valeur : clic gauche seulement
    -- EN : Without value: left click only
    if filter == nil then
        filter = {'left'}
    end
    -- FR : Valeur qui n'est pas une liste : ignorée
    -- EN : Value that is not a list: ignored
    if type(filter) ~= "table" then
        return self
    end
    if button_valid[self.type] then
        self.gui_element.mouse_button_filter = filter
    end
    return self
end


---**EN**
---
---Description: Data attached to the element (element.tags): key, path, index... for dynamic elements
---(tree rows, tracking entries), instead of encoding them in the name.
---Factorio copies the table: it is read back later with element.tags.
---
---──────────────────────────────
---
---**FR**
---
---Description: Données attachées à l'élément (element.tags) : clé, chemin, index... pour les éléments dynamiques
---(lignes de l'arbre, entrées du suivi), au lieu de les coder dans le nom.
---Factorio copie la table : on la relit plus tard avec element.tags.
---@param tags table
---@return GvvGuiElement
function GvvGuiElement:tags(tags)
    -- FR : Valeur qui n'est pas une table : ignorée
    -- EN : Value that is not a table: ignored
    if type(tags) ~= "table" then
        return self
    end
    self.gui_element.tags = tags
    return self
end
