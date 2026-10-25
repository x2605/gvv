---------------------------------------------------------------------------------------------
-- GVV GUI ELEMENT
---------------------------------------------------------------------------------------------
-- FR : Source : RitnLib (Ritn), classes/RitnClass/gui/RitnGuiElement.lua (RitnLibGuiElement), version 0.10.7.
--      Constructeur de la description d'un élément GUI (la table passée à LuaGuiElement.add),
--      copié et adapté pour que gvv reste autonome.
--      Nom généré : gui_name-type-name (ex. gvv_main-button-close), découpé par GvvGui pour
--      retrouver l'action. Ni gui_name ni name ne doivent contenir de « - ».
--      Différences : plus de log à chaque appel, text() corrigé (il testait une variable inexistante
--      et ne fonctionnait jamais), ajout de tags() pour les données des éléments dynamiques,
--      textfield accepté par text().
-- EN : Source: RitnLib (Ritn), classes/RitnClass/gui/RitnGuiElement.lua (RitnLibGuiElement), version 0.10.7.
--      Builder of a GUI element description (the table given to LuaGuiElement.add),
--      copied and adapted so gvv stays standalone.
--      Generated name: gui_name-type-name (e.g. gvv_main-button-close), split by GvvGui to
--      find the action. Neither gui_name nor name may contain "-".
--      Differences: no more log on each call, text() fixed (it tested a non-existent variable
--      and never worked), added tags() for dynamic elements data, textfield accepted by text().
---------------------------------------------------------------------------------------------

-- FR : Types Factorio raccourcis dans le nom de l'élément (le « - » est réservé au découpage)
-- EN : Factorio types shortened in the element name (the "-" is reserved for splitting)
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

local scroll_policy_valid = {
    auto = true,
    never = true,
    always = true,
    ["auto-and-reserve-space"] = true,
    ["dont-show-but-allow-scrolling"] = true,
}
local string_valid = { string = true, table = true }
local orientation_valid = { frame = true, flow = true, line = true }
local text_valid = { textfield = true, ["text-box"] = true }
local button_valid = { button = true, ["sprite-button"] = true }
local sprite_valid = { sprite = true, ["sprite-button"] = true }
local check_valid = { checkbox = true, radiobutton = true }


---@class GvvGuiElement
---@field object_name string
---@field gui_name string        Nom complet de l'élément en jeu / Full in-game element name
---@field name string            Partie « name » / "name" part
---@field type string            Type Factorio / Factorio type
---@field ui string              Nom de la fenêtre (gui_name de GvvGui) / Window name (GvvGui gui_name)
---@field action string          type_court-name, l'action déclenchée / short_type-name, the triggered action
---@field gui_element table      Description passée à LuaGuiElement.add / Description given to LuaGuiElement.add
GvvGuiElement = gvv.classFactory.newclass(function(self, ui_name, element_type, element_name)
    self.object_name = "GvvGuiElement"
    local short_type = short_types[element_type] or element_type
    --------------------------------------------------
    self.gui_name = ui_name .. "-" .. short_type .. "-" .. element_name
    self.name = element_name
    self.type = element_type
    self.ui = ui_name
    self.action = short_type .. "-" .. element_name
    --------------------------------------------------
    self.gui_element = {
        type = self.type,
        name = self.gui_name,
        visible = true,
    }
    if element_type == "scroll-pane" then
        self.gui_element.horizontal_scroll_policy = "never"
    end
end)
----------------------------------------------------------------


---FR : Ajoute l'élément à parent et renvoie le LuaGuiElement créé.
---EN : Adds the element to parent and returns the created LuaGuiElement.
---@param parent LuaGuiElement
---@return LuaGuiElement?
function GvvGuiElement:add(parent)
    if parent == nil then return nil end
    return parent.add(self.gui_element)
end

---FR : Renvoie la description de l'élément (à passer à parent.add).
---EN : Returns the element description (to give to parent.add).
---@return table
function GvvGuiElement:get()
    return self.gui_element
end

function GvvGuiElement:horizontal()
    if orientation_valid[self.type] then
        self.gui_element.direction = "horizontal"
    end
    return self
end

function GvvGuiElement:vertical()
    if orientation_valid[self.type] then
        self.gui_element.direction = "vertical"
    end
    return self
end

function GvvGuiElement:autoCenter()
    if self.type == "frame" then
        self.gui_element.auto_center = true
    end
    return self
end

function GvvGuiElement:visible(visible)
    if type(visible) ~= "boolean" then return self end
    self.gui_element.visible = visible
    return self
end

function GvvGuiElement:enabled(enabled)
    if type(enabled) ~= "boolean" then return self end
    self.gui_element.enabled = enabled
    return self
end

function GvvGuiElement:caption(caption)
    if string_valid[type(caption)] then
        self.gui_element.caption = caption
    end
    return self
end

function GvvGuiElement:tooltip(tooltip)
    if not string_valid[type(tooltip)] then return self end
    self.gui_element.tooltip = tooltip
    return self
end

function GvvGuiElement:index(index)
    if type(index) ~= "number" then return self end
    self.gui_element.index = index
    return self
end

function GvvGuiElement:text(text)
    if type(text) ~= "string" then return self end
    if text_valid[self.type] then
        self.gui_element.text = text
    end
    return self
end

function GvvGuiElement:style(style)
    if type(style) ~= "string" then return self end
    self.gui_element.style = style
    return self
end

function GvvGuiElement:spritePath(sprite)
    if type(sprite) ~= "string" then return self end
    if sprite_valid[self.type] then
        self.gui_element.sprite = sprite
    end
    return self
end

function GvvGuiElement:horizontalScrollPolicy(policy)
    if type(policy) ~= "string" or not scroll_policy_valid[policy] then return self end
    if self.type == "scroll-pane" then
        self.gui_element.horizontal_scroll_policy = policy
    end
    return self
end

function GvvGuiElement:verticalScrollPolicy(policy)
    if type(policy) ~= "string" or not scroll_policy_valid[policy] then return self end
    if self.type == "scroll-pane" then
        self.gui_element.vertical_scroll_policy = policy
    end
    return self
end

function GvvGuiElement:resizeSprite(resize)
    if type(resize) ~= "boolean" then return self end
    if self.type == "sprite" then
        self.gui_element.resize_to_sprite = resize
    end
    return self
end

function GvvGuiElement:checked(state)
    if state == nil then state = true end
    if type(state) ~= "boolean" then return self end
    if check_valid[self.type] then
        self.gui_element.state = state
    end
    return self
end

function GvvGuiElement:progress(value)
    if value == nil then value = 0 end
    if type(value) ~= "number" or value > 100 or value < 0 then return self end
    if self.type == "progressbar" then
        self.gui_element.value = value
    end
    return self
end

function GvvGuiElement:mouseButtonFilter(filter)
    if filter == nil then filter = {'left'} end
    if type(filter) ~= "table" then return self end
    if button_valid[self.type] then
        self.gui_element.mouse_button_filter = filter
    end
    return self
end

---FR : Données attachées à l'élément (element.tags) : clé, chemin, index... pour les éléments dynamiques
---     (lignes de l'arbre, entrées du suivi), au lieu de les coder dans le nom.
---EN : Data attached to the element (element.tags): key, path, index... for dynamic elements
---     (tree rows, tracking entries), instead of encoding them in the name.
---@param tags table
---@return GvvGuiElement
function GvvGuiElement:tags(tags)
    if type(tags) ~= "table" then return self end
    self.gui_element.tags = tags
    return self
end
