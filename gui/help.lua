---------------------------------------------------------------------------------------------
-- GUI : HELP
---------------------------------------------------------------------------------------------
-- FR : Description de l'onglet aide de gvv, utilisée par classes/GvvGuiHelp.lua.
--      L'onglet est construit dans le contenu de l'onglet aide de la fenêtre principale
--      (gvv_main-flow-help), qui sert de conteneur (gui[1]) à GvvGuiHelp.
--      Organisation de l'onglet (préfixe gvv_help) :
--        flow-wrap                        conteneur de l'onglet
--        ├ empty-fill                     bande de fond en haut
--        └ flow-panel
--          ├ pane-list                    liste des pages (boutons button-page_<nom>)
--          ├ empty-divider                séparateur
--          └ pane-page                    page affichée (écrite par gui/help_pages.lua)
--      Les éléments des pages (textes, codes à copier, menus, boutons) sont décrits ici aussi.
-- EN : Description of gvv's help tab, used by classes/GvvGuiHelp.lua.
--      The tab is built inside the content of the main window's help tab
--      (gvv_main-flow-help), which is GvvGuiHelp's container (gui[1]).
--      Tab layout (gvv_help prefix): see the tree above.
--      The page elements (texts, codes to copy, menus, buttons) are described here too.
---------------------------------------------------------------------------------------------

-- FR : Préfixe des noms de l'onglet aide
-- EN : Help tab names prefix
local GUI_NAME = "gvv_help"


---FR : Description des éléments de l'onglet (cadre de l'onglet et éléments réutilisés par les pages).
---EN : Description of the tab elements (tab frame and elements reused by the pages).
---@param gui_name string  Préfixe des noms (« gvv_help ») / Names prefix ("gvv_help")
---@return table
local function getElement(gui_name)
    return {
        -- FR : Cadre de l'onglet
        -- EN : Tab frame
        flow = {
            wrap = GvvGuiElement(gui_name, "flow", "wrap"):vertical():style("vflow_gvv-mod"):get(),
            panel = GvvGuiElement(gui_name, "flow", "panel"):horizontal():style("hflow_gvv-mod"):get(),
            -- FR : Conteneur d'un code à copier lié à un menu (retrouvé par son nom)
            -- EN : Container of a code to copy linked to a menu (found by its name)
            copy = GvvGuiElement(gui_name, "flow", "copy"):vertical():style("vflow_gvv-mod"):get(),
            -- FR : Conteneur de la liste des mods (page console 2)
            -- EN : Mods list container (console 2 page)
            mod_list = GvvGuiElement(gui_name, "flow", "mod_list"):vertical():style("vflow_gvv-mod"):get(),
        },
        empty = {
            fill = GvvGuiElement(gui_name, "empty-widget", "fill"):style("empty-tabbed_pane_frame-bg_gvv-mod"):get(),
            divider = GvvGuiElement(gui_name, "empty-widget", "divider"):style("vertical-divider_gvv-mod"):get(),
        },
        pane = {
            list = GvvGuiElement(gui_name, "scroll-pane", "list"):verticalScrollPolicy("auto")
                :horizontalScrollPolicy("auto"):style("scroll_pane_gvv-mod"):get(),
            page = GvvGuiElement(gui_name, "scroll-pane", "page"):verticalScrollPolicy("auto")
                :horizontalScrollPolicy("auto"):style("scroll_pane_gvv-mod"):get(),
        },
        -- FR : Texte à copier, en lecture seule : sur une ligne ou plusieurs
        -- EN : Text to copy, read-only: on one line or several
        text = {
            field = GvvGuiElement(gui_name, "textfield", "text"):tooltip({"gvv-mod.right-to-select-all"}):get(),
            box = GvvGuiElement(gui_name, "text-box", "text"):tooltip({"gvv-mod.right-to-select-all"}):get(),
        },
        -- FR : Menus de la page console 1 : mod pour le code d'activation / de désactivation
        -- EN : Console 1 page menus: mod for the enabling / disabling code
        dropdown = {
            enable = GvvGuiElement(gui_name, "drop-down", "enable"):get(),
            disable = GvvGuiElement(gui_name, "drop-down", "disable"):get(),
        },
        -- FR : Listes de la page console 2 : forme du nom de mod, puis mod
        -- EN : Console 2 page lists: mod name form, then mod
        listbox = {
            option = GvvGuiElement(gui_name, "list-box", "option"):style("list_box-transparent_gvv-mod"):get(),
            mod = GvvGuiElement(gui_name, "list-box", "mod"):style("list_box-transparent_gvv-mod"):get(),
        },
        -- FR : Page dépannage : nom du mod à diagnostiquer, et boutons
        -- EN : Troubleshooting page: name of the mod to diagnose, and buttons
        textfield = {
            mod = GvvGuiElement(gui_name, "textfield", "mod"):text(""):get(),
        },
        button = {
            diagnose = GvvGuiElement(gui_name, "button", "diagnose"):caption({"gvv-mod-helpui.diagnose"})
                :style("c_sub_mod_gvv-mod"):mouseButtonFilter({"left"}):get(),
            fix = GvvGuiElement(gui_name, "button", "fix"):caption({"gvv-mod-helpui.fix"})
                :style("c_sub_mod_gvv-mod"):mouseButtonFilter({"left"}):get(),
            clear_report = GvvGuiElement(gui_name, "button", "clear_report"):caption({"gvv-mod-helpui.clear-report"})
                :style("c_sub_mod_gvv-mod"):mouseButtonFilter({"left"}):get(),
            -- FR : Bouton de démonstration d'une ligne d'arbre (page utilisation) ; légende et style donnés par la page
            -- EN : Demonstration button of a tree row (usage page); caption and style given by the page
            demo = GvvGuiElement(gui_name, "button", "demo"):get(),
        },
        -- FR : Icône de dossier (démonstration)
        -- EN : Folder icon (demonstration)
        sprite = {
            folder = GvvGuiElement(gui_name, "sprite", "folder"):spritePath("gvv-mod_folder-opened"):resizeSprite(false):get(),
        },
    }
end


---FR : Bouton d'une page dans la liste : nommé button-page_<nom>, le nom de la page est aussi dans ses tags.
---EN : Button of a page in the list: named button-page_<name>, the page name is also in its tags.
---@param gui_name string
---@param page table  { name, caption }
---@return table
local function getPageButton(gui_name, page)
    return GvvGuiElement(gui_name, "button", "page_" .. page.name):caption(page.caption)
        :style("c_sub_mod_gvv-mod"):mouseButtonFilter({"left"}):tags({ page = page.name }):get()
end


---FR : Chemin de chaque élément de l'onglet depuis gui[1] (gvv_main-flow-help).
---EN : Path of each tab element from gui[1] (gvv_main-flow-help).
---@return table
local function getContent()
    return {
        flow = {
            wrap = { "flow-wrap" },
            panel = { "flow-wrap", "flow-panel" },
        },
        pane = {
            list = { "flow-wrap", "flow-panel", "pane-list" },
            page = { "flow-wrap", "flow-panel", "pane-page" },
        },
    }
end


---------------------------------------------------------------------------------------------
-- FR : Fonctions exportées et préfixe
-- EN : Exported functions and prefix
return {
    getElement = getElement,
    getPageButton = getPageButton,
    getContent = getContent,
    GUI_NAME = GUI_NAME,
}
