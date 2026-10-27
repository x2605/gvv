---------------------------------------------------------------------------------------------
-- GUI : TREE : STORAGE
---------------------------------------------------------------------------------------------
-- FR : Configuration de l'arbre de l'onglet storage, lue par le moteur classes/GvvGuiTree.lua.
--      Liste de gauche : les mods qui chargent l'interface gvv. Mod choisi : deux racines,
--      son _G puis son storage, lus par remote.call("__<mod>__gvv", "_G" / "storage").
--      Repris de l'ancien code (legacy/tree.lua : draw_init 'glob' / '_G_glob', get_storage).
-- EN : Configuration of the storage tab tree, read by the engine classes/GvvGuiTree.lua.
--      Left list: the mods that load the gvv interface. Chosen mod: two roots,
--      its _G then its storage, read through remote.call("__<mod>__gvv", "_G" / "storage").
--      Taken from the old code (legacy/tree.lua: draw_init 'glob' / '_G_glob', get_storage).
---------------------------------------------------------------------------------------------
local Util = require(gvv.defines.lualib.common.util)
---------------------------------------------------------------------------------------------

-- FR : Préfixe des racines _G : « _G:<mod> » (même format que l'ancien code et les chemins du suivi)
-- EN : _G roots prefix: "_G:<mod>" (same format as the old code and the tracking paths)
local G_PREFIX = "_G:"


local config = {
    -- FR : Préfixe des noms des éléments de cet arbre
    -- EN : Names prefix of this tree elements
    gui_name = "gvv_tree_storage",

    -- FR : Onglet de la fenêtre principale (gvv_main-flow-storage) et son numéro
    -- EN : Main window tab (gvv_main-flow-storage) and its number
    tab = "storage",
    tab_index = 2,

    -- FR : Nom de cet arbre pour la recherche (GvvGuiSearch)
    -- EN : Name of this tree for the search (GvvGuiSearch)
    search = "glob",

    -- FR : Clé des dossiers ouverts gardés : data.data.opened_data.globtree, opened_root.globtree
    -- EN : Key of the kept opened folders: data.data.opened_data.globtree, opened_root.globtree
    opened = "globtree",

    -- FR : Dernier élément choisi dans la liste : data.tabs.last_sub_mod
    -- EN : Last element chosen in the list: data.tabs.last_sub_mod
    last_selection = "last_sub_mod",

    -- FR : Propriétés d'objets Lua : non (les valeurs viennent de remote.call)
    -- EN : Lua object properties: no (values come from remote.call)
    prop_allowed = false,

    -- FR : Boutons de la liste : clic gauche seulement (choisir un mod)
    -- EN : List buttons: left click only (choose a mod)
    item_buttons = {"left"},

    -- FR : Liste remplie à nouveau à chaque retour sur l'onglet (les mods qui chargent gvv peuvent changer)
    -- EN : List filled again each time the tab is displayed (the mods loading gvv can change)
    refill_on_tab = true,
}


---FR : Éléments de la liste de gauche : les mods qui chargent l'interface gvv (level compris).
---     Chaque élément : value (gardée dans les tags du bouton), caption.
---EN : Left list elements: the mods that load the gvv interface (level included).
---     Each element: value (kept in the button tags), caption.
---@param tree GvvGuiTree
---@return table[]
function config.getItems(tree)
    local items = {}

    -- FR : Un bouton par mod, son nom pour valeur et pour texte
    -- EN : One button per mod, its name as value and as text
    for _, mod_name in ipairs(Util.get_accessible_mod_list()) do
        items[#items + 1] = { value = mod_name, caption = mod_name }
    end
    return items
end


---FR : Racines à afficher pour le mod choisi : son _G, puis son storage (avec une marge en bas).
---EN : Roots to show for the chosen mod: its _G, then its storage (with a bottom margin).
---@param tree GvvGuiTree
---@param mod_name string
---@return table[]  { key, caption, bottom_padding }
function config.getRoots(tree, mod_name)
    return {
        {
            key = G_PREFIX .. mod_name,
            caption = 'remote.call("__[font=default-bold][color=green]' .. mod_name .. '[/color][/font]__gvv","[font=default-bold][color=yellow]_G[/color][/font]")',
            bottom_padding = false,
        },
        {
            key = mod_name,
            caption = 'remote.call("__[font=default-bold][color=green]' .. mod_name .. '[/color][/font]__gvv","[font=default-bold][color=yellow]storage[/color][/font]")',
            bottom_padding = true,
        },
    }
end


---FR : Données d'une racine : le _G ou le storage du mod, par remote.call. Peut lever une erreur.
---EN : Data of a root: the mod _G or storage, through remote.call. May raise an error.
---@param tree GvvGuiTree
---@param root_key string  « _G:<mod> » ou « <mod> » / "_G:<mod>" or "<mod>"
---@return any
function config.read(tree, root_key)
    local mod_name = root_key:match('^' .. G_PREFIX .. '(.*)$')
    if mod_name ~= nil then
        return remote.call('__' .. mod_name .. '__gvv', '_G')
    end
    return remote.call('__' .. root_key .. '__gvv', 'storage')
end


---FR : Chemin dont le dossier ne doit pas s'ouvrir : les données des joueurs de gvv lui-même
---     (elles contiennent les éléments de l'interface).
---EN : Path whose folder must not open: gvv's own players data
---     (it holds the interface elements).
---@param tree GvvGuiTree
---@param path table
---@return boolean
function config.isBlocked(tree, path)
    return path[1] == 'gvv' and path[2] == 'players' and path[4] == 'data'
end


---FR : Chemin complet pour le suivi : le même chemin (il commence déjà par le mod ou « _G:<mod> »).
---EN : Full path for the tracking: the same path (it already starts with the mod or "_G:<mod>").
---@param tree GvvGuiTree
---@param path table
---@return table
function config.fullPath(tree, path)
    return path
end


---------------------------------------------------------------------------------------------
return config
