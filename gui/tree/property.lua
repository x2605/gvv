---------------------------------------------------------------------------------------------
-- GUI : TREE : PROPERTY
---------------------------------------------------------------------------------------------
-- FR : Configuration de l'arbre de l'onglet property, lue par le moteur classes/GvvGuiTree.lua.
--      Liste de gauche : les objets Lua ajoutés (clic droit sur une valeur objet Lua d'un autre arbre),
--      gardés dans data.data.docked_luaobj ; clic gauche : afficher, clic droit : retirer.
--      Objet choisi : une racine, ses propriétés. L'objet est relu à chaque affichage : il a pu
--      disparaître depuis son ajout (entité détruite...), il est alors retiré de la liste.
--      Repris de l'ancien code (legacy/tree.lua : draw_init 'prop', register_object, draw_proptree,
--      remove_prop_tree).
-- EN : Configuration of the property tab tree, read by the engine classes/GvvGuiTree.lua.
--      Left list: the added Lua objects (right click on a Lua object value of another tree),
--      kept in data.data.docked_luaobj; left click: show, right click: remove.
--      Chosen object: one root, its properties. The object is read again on each display: it may
--      have disappeared since it was added (destroyed entity...), it is then removed from the list.
--      Taken from the old code (legacy/tree.lua: draw_init 'prop', register_object, draw_proptree,
--      remove_prop_tree).
---------------------------------------------------------------------------------------------
local Util = require(gvv.defines.lualib.common.util)
local Table_to_str = require(gvv.defines.lualib.common.table_to_str)
---------------------------------------------------------------------------------------------


local config = {
    -- FR : Préfixe des noms des éléments de cet arbre
    -- EN : Names prefix of this tree elements
    gui_name = "gvv_tree_property",

    -- FR : Onglet de la fenêtre principale (gvv_main-flow-property) et son numéro
    -- EN : Main window tab (gvv_main-flow-property) and its number
    tab = "property",
    tab_index = 3,

    -- FR : Nom de cet arbre pour la recherche (GvvGuiSearch)
    -- EN : Name of this tree for the search (GvvGuiSearch)
    search = "prop",

    -- FR : Clé des dossiers ouverts gardés : data.data.opened_data.proptree, opened_root.proptree
    -- EN : Key of the kept opened folders: data.data.opened_data.proptree, opened_root.proptree
    opened = "proptree",

    -- FR : Dernier objet choisi dans la liste (son numéro) : data.tabs.last_sub_obj
    -- EN : Last object chosen in the list (its number): data.tabs.last_sub_obj
    last_selection = "last_sub_obj",

    -- FR : Propriétés d'objets Lua : oui (chaque objet Lua s'ouvre comme un dossier de propriétés)
    -- EN : Lua object properties: yes (each Lua object opens as a properties folder)
    prop_allowed = true,

    -- FR : Boutons de la liste : clic gauche (afficher) et clic droit (retirer)
    -- EN : List buttons: left click (show) and right click (remove)
    item_buttons = {"left", "right"},

    -- FR : Liste remplie à la construction, puis à chaque ajout d'objet
    -- EN : List filled on building, then on each object added
    refill_on_tab = false,
}


---------------------------------------------------------------------------------------------
-- FR : OBJETS AJOUTÉS
-- EN : ADDED OBJECTS
---------------------------------------------------------------------------------------------

-- FR : Objets ajoutés du joueur (data.data.docked_luaobj), créés si besoin
-- EN : Player's added objects (data.data.docked_luaobj), created if needed
local function getDocked(tree)
    local data = tree:getData().data

    -- FR : Liste absente (ancienne sauvegarde) : créée vide
    -- EN : Missing list (old save): created empty
    if not data.docked_luaobj then
        data.docked_luaobj = {}
    end
    return data.docked_luaobj
end


-- FR : Un objet Lua est-il encore utilisable ? (objet sans champ valid : considéré valide)
-- EN : Is a Lua object still usable? (object without a valid field: considered valid)
local function isUsableObject(value)
    -- FR : Pas un objet Lua : non
    -- EN : Not a Lua object: no
    if type(value) ~= "userdata" then
        return false
    end

    -- FR : Un objet Lua a un object_name ; lecture protégée
    -- EN : A Lua object has an object_name; protected read
    local has_name, object_name = pcall(function() return value.object_name end)
    if not has_name or not object_name then
        return false
    end

    -- FR : valid vaut false quand l'objet a été détruit ; un objet sans valid est considéré valide
    -- EN : valid is false when the object was destroyed; an object without valid is considered valid
    local has_valid, valid = pcall(function() return value.valid end)
    if not has_valid then
        return true
    end
    return valid
end


-- FR : Message quand un objet n'existe plus ; where : texte qui dit de quel objet il s'agit
-- EN : Message when an object no longer exists; where: text that tells which object it is
local function objectGoneMessage(value, where)
    -- FR : Nom de classe de l'objet s'il se lit encore, sinon « LuaObject »
    -- EN : Class name of the object if it can still be read, otherwise "LuaObject"
    local name = 'LuaObject'
    if type(value) == 'userdata' then
        local has_name, object_name = pcall(function() return value.object_name end)
        if has_name and object_name then
            name = object_name
        end
    end
    return 'That ' .. name .. ' is not there anymore.\n' .. where
end


-- FR : Numéro de l'objet dans le nom d'une racine : « (3) ... » donne 3
-- EN : Object number inside a root name: "(3) ..." gives 3
local function indexOf(root_key)
    return tonumber(root_key:match('^[(](%d+)[)] '))
end


---------------------------------------------------------------------------------------------
-- FR : FONCTIONS LUES PAR LE MOTEUR
-- EN : FUNCTIONS READ BY THE ENGINE
---------------------------------------------------------------------------------------------

---FR : Éléments de la liste de gauche : les objets ajoutés, « (numéro) clé », avec leur chemin en infobulle.
---EN : Left list elements: the added objects, "(number) key", with their path as tooltip.
---@param tree GvvGuiTree
---@return table[]
function config.getItems(tree)
    local items = {}

    -- FR : Un bouton par objet ajouté ; la valeur est le numéro de l'objet
    -- EN : One button per added object; the value is the object number
    for _, docked in pairs(getDocked(tree)) do
        items[#items + 1] = {
            value = docked.index,
            caption = '(' .. tostring(docked.index) .. ') ' .. Table_to_str.to_luaon(docked.key, true),
            tooltip = {"", {"gvv-mod.obj-list-tooltip"}, '\n', Table_to_str.path_to_lua_prop_path(docked.tree_path)},
        }
    end
    return items
end


---FR : Racine à afficher pour l'objet choisi. L'objet est relu par son chemin : s'il n'existe plus,
---     il est retiré de la liste et une erreur est levée (message affiché dans le chat).
---EN : Root to show for the chosen object. The object is read again through its path: if it no longer
---     exists, it is removed from the list and an error is raised (message shown in the chat).
---@param tree GvvGuiTree
---@param index integer  Numéro de l'objet / Object number
---@return table[]  { key, caption, bottom_padding }
function config.getRoots(tree, index)
    local docked = getDocked(tree)[index]

    -- FR : Objet retiré entre-temps : rien à afficher
    -- EN : Object removed in the meantime: nothing to show
    if docked == nil then
        return {}
    end

    -- FR : Objet relu par son chemin complet
    -- EN : Object read again through its full path
    local value = GvvGuiTree.readFullPath(docked.tree_path)

    -- FR : L'objet n'existe plus : retiré de la liste avant d'afficher le message
    -- EN : The object no longer exists: removed from the list before showing the message
    if not isUsableObject(value) then
        local message = objectGoneMessage(value, '(' .. tostring(index) .. ') ' .. Table_to_str.path_to_lua_prop_path(docked.tree_path, true))
        tree:removeItem(index)
        error(message)
    end
    docked.luaobj = value

    -- FR : Racine « (numéro) chemin », suivie de l'icône et de la classe de l'objet
    -- EN : Root "(number) path", followed by the object icon and class
    local root_name = '(' .. tostring(index) .. ') ' .. Table_to_str.path_to_lua_prop_path(docked.tree_path)
    return {
        {
            key = root_name,
            caption = GvvGuiTree.objectCaption(root_name, value),
            bottom_padding = true,
        },
    }
end


---FR : Données d'une racine : l'objet ajouté (relu par getRoots juste avant le dessin).
---EN : Data of a root: the added object (read again by getRoots just before drawing).
---@param tree GvvGuiTree
---@param root_key string  « (numéro) chemin » / "(number) path"
---@return any
function config.read(tree, root_key)
    local docked = getDocked(tree)[indexOf(root_key)]

    -- FR : Objet retiré entre-temps : plus de données
    -- EN : Object removed in the meantime: no more data
    if docked == nil then
        return nil
    end
    return docked.luaobj
end


---FR : Aucun dossier bloqué dans cet arbre.
---EN : No blocked folder in this tree.
---@param tree GvvGuiTree
---@param path table
---@return boolean
function config.isBlocked(tree, path)
    return false
end


---FR : Chemin complet pour le suivi : le chemin de l'objet ajouté, prolongé par les clés sous la racine.
---EN : Full path for the tracking: the added object path, extended with the keys under the root.
---@param tree GvvGuiTree
---@param path table
---@return table
function config.fullPath(tree, path)
    local docked = getDocked(tree)[indexOf(path[1])]

    -- FR : Copie du chemin de l'objet (il ne doit pas être modifié)
    -- EN : Copy of the object path (it must not be modified)
    local full_path = {}
    for index, key in ipairs(docked.tree_path) do
        full_path[index] = key
    end

    -- FR : Puis les clés sous la racine (sans la racine elle-même)
    -- EN : Then the keys under the root (without the root itself)
    for index = 2, #path do
        full_path[#full_path + 1] = path[index]
    end
    return full_path
end


---FR : Oublie un objet ajouté (clic droit sur son bouton). Le moteur retire ensuite son bouton et son arbre.
---EN : Forgets an added object (right click on its button). The engine then removes its button and its tree.
---@param tree GvvGuiTree
---@param index integer
function config.forget(tree, index)
    getDocked(tree)[index] = nil
end


---FR : Ajoute un objet Lua à la liste (clic droit sur une valeur objet Lua dans un arbre), puis l'affiche
---     dans l'onglet property. Un objet déjà ajouté (même chemin) n'est pas ajouté deux fois.
---     Renvoie le numéro de l'objet. Repris de l'ancien Tree.register_object.
---EN : Adds a Lua object to the list (right click on a Lua object value in a tree), then shows it
---     in the property tab. An object already added (same path) is not added twice.
---     Returns the object number. Taken from the old Tree.register_object.
---@param tree GvvGuiTree   Arbre property / property tree
---@param key any           Clé de la valeur / Value key
---@param full_path table   Chemin complet de la valeur / Value full path
---@param caption string    Texte de la valeur (message si l'objet a disparu) / Value text (message if the object is gone)
---@return integer
function config.addObject(tree, key, full_path, caption)
    local docked = getDocked(tree)

    -- FR : Objet relu par son chemin : il doit encore exister
    -- EN : Object read again through its path: it must still exist
    local value = GvvGuiTree.readFullPath(full_path)
    if not isUsableObject(value) then
        error(objectGoneMessage(value, caption))
    end

    -- FR : Déjà ajouté (même chemin) : on reprend son numéro
    -- EN : Already added (same path): its number is reused
    local index = nil
    for docked_index, entry in pairs(docked) do
        if Util.table_shallow_compare(full_path, entry.tree_path) then
            index = docked_index
            break
        end
    end

    -- FR : Nouvel objet : ajouté à la fin, puis la liste est remplie à nouveau
    -- EN : New object: added at the end, then the list is filled again
    if index == nil then
        index = #docked + 1
        docked[index] = {
            index = index,
            luaobj = value,
            key = key,
            tree_path = full_path,
        }
        tree:fillList()
    end

    -- FR : Onglet property affiché, avec l'arbre de l'objet
    -- EN : property tab shown, with the object tree
    GvvGuiMain(tree.event):changeTab(config.tab_index)
    tree:draw(index)
    return index
end


---------------------------------------------------------------------------------------------
return config
