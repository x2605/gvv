---------------------------------------------------------------------------------------------
-- DEFINES
---------------------------------------------------------------------------------------------
-- FR : Registre des chemins de gvv. Aucun fichier ne doit écrire un chemin de require en dur :
--      on passe toujours par gvv.defines. Si un fichier est déplacé, seul ce registre change.
-- EN : gvv path registry. No file should hard-code a require path:
--      always go through gvv.defines. If a file moves, only this registry changes.
---------------------------------------------------------------------------------------------
local name = "gvv"
local directory = "__" .. name .. "__"
---------------------------------------------------------------------------------------------
local defines = {
    name = name,
    directory = directory,

    -- FR : Démarrage du mod (control stage)
    -- EN : Mod bootstrap (control stage)
    setup = directory .. ".core.setup-classes",
    event = "__core__.lualib.event_handler",
    -- FR : util de Factorio (copie profonde, formattime...)
    -- EN : Factorio's util (deep copy, formattime...)
    util = "__core__.lualib.util",

    -- FR : Interface remote publique, chargée aussi par les autres mods (chemin à ne jamais changer)
    -- EN : Public remote interface, also loaded by other mods (path must never change)
    interface = directory .. ".gvv",

    -- FR : Factory de classes
    -- EN : Class factory
    class = {
        core = directory .. ".core.class",
    },

    -- FR : Modules envoyés à l'event handler
    -- EN : Modules sent to the event handler
    modules = {
        core = directory .. ".core.modules",
        ----
        events = directory .. ".modules.events",
        player = directory .. ".modules.player",
        gui_event = directory .. ".modules.gui_event",
        ----
        commands = directory .. ".modules.commands",
    },

    -- FR : Construction et gestion des fenêtres
    -- EN : Windows building and handling
    gui = {
        main = directory .. ".modules.gui",
        tree = directory .. ".modules.tree",
        tracking = directory .. ".core.utils.tracking",
        help_menu = directory .. ".modules.help_menu",
        search_tree = directory .. ".modules.search_tree",
    },

    -- FR : Bibliothèque de gvv, rangée par partie
    -- EN : gvv library, sorted by part
    lualib = {
        -- FR : Fonctions génériques, sans interface graphique
        -- EN : Generic functions, without GUI
        common = {
            util = directory .. ".lualib.common.util",
            table_to_str = directory .. ".lualib.common.table_to_str",
            sprite = directory .. ".lualib.common.sprite",
            luaobj_prop = directory .. ".lualib.common.luaobj_prop",
            copy_code = directory .. ".lualib.common.copy_code",
            doctor = directory .. ".lualib.common.doctor",
        },
        -- FR : Description de l'API Factorio, écrite à la main (complète generated/)
        -- EN : Factorio API description, hand-written (completes generated/)
        api = {
            attribute_type_map = directory .. ".lualib.api.attribute_type_map",
            concept_fields = directory .. ".lualib.api.concept_fields",
        },
        -- FR : Modèles de code Lua à copier dans la console ou dans un autre mod
        -- EN : Lua code templates to copy into the console or into another mod
        remote_code = {
            diag_n_fix = directory .. ".lualib.remote_code.diag_n_fix",
            lua_command = directory .. ".lualib.remote_code.lua_command",
            get_g = directory .. ".lualib.remote_code.get_g",
            get_global = directory .. ".lualib.remote_code.get_global",
        },
    },

    -- FR : Description de l'API Factorio, produite par le convertisseur
    -- EN : Factorio API description, produced by the converter
    generated = {
        runtime_api_stable = directory .. ".generated.runtime-api-stable",
        runtime_api_latest = directory .. ".generated.runtime-api-latest",
    },
}
---------------------------------------------------------------------------------------------
if not gvv then gvv = {} end
gvv.defines = defines
log('declare : gvv.defines | ' .. gvv.defines.name .. ' -> finish !')
---------------------------------------------------------------------------------------------
