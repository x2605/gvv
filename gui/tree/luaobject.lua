---------------------------------------------------------------------------------------------
-- GUI : TREE : LUAOBJECT
---------------------------------------------------------------------------------------------
-- FR : Configuration de l'arbre de l'onglet LuaObject, lue par le moteur classes/GvvGuiTree.lua.
--      Liste de gauche : les objets globaux de l'API (game, script, remote...).
--      Objet choisi : une racine, ses propriétés. Dans le suivi, son chemin commence par « * »
--      (ex. « *game »), pour le distinguer d'un mod.
--      Repris de l'ancien code (legacy/gui.lua : gobjlist ; legacy/tree.lua : draw_init 'gobj', draw_gobjtree).
-- EN : Configuration of the LuaObject tab tree, read by the engine classes/GvvGuiTree.lua.
--      Left list: the API global objects (game, script, remote...).
--      Chosen object: one root, its properties. In the tracking, its path starts with "*"
--      (e.g. "*game"), to tell it apart from a mod.
--      Taken from the old code (legacy/gui.lua: gobjlist; legacy/tree.lua: draw_init 'gobj', draw_gobjtree).
---------------------------------------------------------------------------------------------

-- FR : Objets globaux de l'API, dans l'ordre de la liste
-- EN : API global objects, in the list order
local GLOBAL_OBJECTS = {'game', 'script', 'remote', 'commands', 'settings', 'prototypes', 'rcon', 'rendering', 'helpers', 'defines'}

-- FR : Préfixe des chemins d'objets globaux dans le suivi (« *game »)
-- EN : Prefix of global objects paths in the tracking ("*game")
local GLOBAL_PREFIX = "*"


local config = {
    -- FR : Préfixe des noms des éléments de cet arbre
    -- EN : Names prefix of this tree elements
    gui_name = "gvv_tree_luaobject",

    -- FR : Onglet de la fenêtre principale (gvv_main-flow-luaobject) et son numéro
    -- EN : Main window tab (gvv_main-flow-luaobject) and its number
    tab = "luaobject",
    tab_index = 4,

    -- FR : Nom de cet arbre pour la recherche (GvvGuiSearch)
    -- EN : Name of this tree for the search (GvvGuiSearch)
    search = "gobj",

    -- FR : Clé des dossiers ouverts gardés : data.data.opened_data.gobjtree, opened_root.gobjtree
    -- EN : Key of the kept opened folders: data.data.opened_data.gobjtree, opened_root.gobjtree
    opened = "gobjtree",

    -- FR : Dernier objet choisi dans la liste (son nom) : data.tabs.last_sub_gobj
    -- EN : Last object chosen in the list (its name): data.tabs.last_sub_gobj
    last_selection = "last_sub_gobj",

    -- FR : Propriétés d'objets Lua : oui (chaque objet Lua s'ouvre comme un dossier de propriétés)
    -- EN : Lua object properties: yes (each Lua object opens as a properties folder)
    prop_allowed = true,

    -- FR : Boutons de la liste : clic gauche seulement (choisir un objet)
    -- EN : List buttons: left click only (choose an object)
    item_buttons = {"left"},

    -- FR : Liste fixe : remplie une seule fois, à la construction
    -- EN : Fixed list: filled only once, on building
    refill_on_tab = false,
}


---FR : Éléments de la liste de gauche : les objets globaux de l'API.
---EN : Left list elements: the API global objects.
---@param tree GvvGuiTree
---@return table[]
function config.getItems(tree)
    local items = {}

    -- FR : Un bouton par objet global, son nom pour valeur et pour texte
    -- EN : One button per global object, its name as value and as text
    for _, name in ipairs(GLOBAL_OBJECTS) do
        items[#items + 1] = { value = name, caption = name }
    end
    return items
end


---FR : Racine à afficher pour l'objet choisi : son nom, suivi de son icône et de sa classe.
---EN : Root to show for the chosen object: its name, followed by its icon and class.
---@param tree GvvGuiTree
---@param name string
---@return table[]  { key, caption, bottom_padding }
function config.getRoots(tree, name)
    return {
        {
            key = name,
            caption = GvvGuiTree.objectCaption(name, config.read(tree, name)),
            bottom_padding = true,
        },
    }
end


---FR : Données d'une racine : l'objet global du même nom (ex. « game » donne game).
---EN : Data of a root: the global object of the same name (e.g. "game" gives game).
---@param tree GvvGuiTree
---@param root_key string
---@return any
function config.read(tree, root_key)
    return assert(loadstring('return ' .. root_key))()
end


---FR : Aucun dossier bloqué dans cet arbre.
---EN : No blocked folder in this tree.
---@param tree GvvGuiTree
---@param path table
---@return boolean
function config.isBlocked(tree, path)
    return false
end


---FR : Chemin complet pour le suivi : le même chemin, la racine préfixée par « * » (ex. « *game »).
---EN : Full path for the tracking: the same path, the root prefixed by "*" (e.g. "*game").
---@param tree GvvGuiTree
---@param path table
---@return table
function config.fullPath(tree, path)
    local full_path = {}

    -- FR : Copie du chemin (il ne doit pas être modifié), racine préfixée
    -- EN : Copy of the path (it must not be modified), root prefixed
    for index, key in ipairs(path) do
        full_path[index] = key
    end
    full_path[1] = GLOBAL_PREFIX .. full_path[1]
    return full_path
end


---------------------------------------------------------------------------------------------
return config
