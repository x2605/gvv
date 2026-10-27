---------------------------------------------------------------------------------------------
-- GUI : TRACKING
---------------------------------------------------------------------------------------------
-- FR : Description de l'onglet suivi de variables, utilisée par classes/GvvGuiTracking.lua.
--      Deux endroits :
--        - le contenu de l'onglet (dans gvv_main-flow-tracking) :
--            flow-wrap > empty-fill, pane-scroll > flow-panel > entrées
--        - les outils du suivi, dans la barre d'outils de la fenêtre principale (gvv_main-flow-tools) :
--            button-refresh, slider-interval, label-interval, textfield-interval, button-remove,
--            frame-confirm (button-confirm_remove, button-cancel_remove), button-up, button-down,
--            button-check, button-export_import
--      Une entrée du suivi est un conteneur sans nom (plusieurs entrées côte à côte) ; son code est
--      dans ses tags (tags.path). Elle contient :
--        flow-header > checkbox-remove, label-key (nom de la clé, si l'entrée vient de l'arbre), label-path (code)
--        flow-body > label-equal (« = »), label-output (valeur)
--        line (séparateur)
-- EN : Description of the variable tracking tab, used by classes/GvvGuiTracking.lua.
--      Two places: the tab content (inside gvv_main-flow-tracking) and the tracking tools,
--      inside the main window toolbar (gvv_main-flow-tools). See the lists above.
--      A tracking entry is an unnamed container (several entries side by side); its code is
--      in its tags (tags.path). Its content: see the list above.
---------------------------------------------------------------------------------------------

-- FR : Préfixe des noms de l'onglet suivi
-- EN : Tracking tab names prefix
local GUI_NAME = "gvv_tracking"


---**EN**
---
---Description: Description of the tab, tools and entry elements.
---
---──────────────────────────────
---
---**FR**
---
---Description: Description des éléments de l'onglet, des outils et d'une entrée.
---@param gui_name string  Names prefix ("gvv_tracking")
---@return table
local function getElement(gui_name)
    local element = {
        -- FR : Contenu de l'onglet
        -- EN : Tab content
        flow = {
            wrap = GvvGuiElement(gui_name, "flow", "wrap"):vertical():style("vflow_gvv-mod"):get(),
            panel = GvvGuiElement(gui_name, "flow", "panel"):vertical():style("vflow_gvv-mod"):get(),
            header = GvvGuiElement(gui_name, "flow", "header"):horizontal():style("hflow_gvv-mod"):get(),
            body = GvvGuiElement(gui_name, "flow", "body"):horizontal():style("hflow_gvv-mod"):get(),
            -- FR : Une entrée : sans nom (plusieurs entrées dans le même panneau), code dans ses tags
            -- EN : An entry: unnamed (several entries in the same panel), code in its tags
            entry = { type = "flow", direction = "vertical", style = "vflow_gvv-mod" },
        },
        empty = {
            fill = GvvGuiElement(gui_name, "empty-widget", "fill"):style("empty-tabbed_pane_frame-bg_gvv-mod"):get(),
        },
        pane = {
            scroll = GvvGuiElement(gui_name, "scroll-pane", "scroll"):verticalScrollPolicy("auto")
                :horizontalScrollPolicy("auto"):style("scroll_pane_gvv-mod"):get(),
        },
        -- FR : Éléments d'une entrée
        -- EN : Entry elements
        checkbox = {
            remove = GvvGuiElement(gui_name, "checkbox", "remove"):checked(false)
                :tooltip({"gvv-mod.check-for-remove", '[img=utility/trash_white]', '[img=gvv-mod_arrow-up][img=gvv-mod_arrow-down]'}):get(),
        },
        label = {
            key = GvvGuiElement(gui_name, "label", "key"):get(),
            path = GvvGuiElement(gui_name, "label", "path"):tooltip({"gvv-mod.right-to-copy-edit-code"}):get(),
            equal = GvvGuiElement(gui_name, "label", "equal"):caption("  =  "):get(),
            output = GvvGuiElement(gui_name, "label", "output"):tooltip({"gvv-mod.right-to-copy-code"}):get(),
            -- FR : Outil : intervalle affiché (clic gauche pour le saisir)
            -- EN : Tool: displayed interval (left click to type it)
            interval = GvvGuiElement(gui_name, "label", "interval"):tooltip({"gvv-mod.track-interval-control"}):get(),
        },
        -- FR : Outils de la barre d'outils
        -- EN : Toolbar tools
        button = {
            refresh = GvvGuiElement(gui_name, "sprite-button", "refresh"):spritePath("utility/reset_white")
                :style("frame_action_button"):mouseButtonFilter({"left"}):tooltip({"gvv-mod.track-refresh"}):get(),
            remove = GvvGuiElement(gui_name, "sprite-button", "remove"):spritePath("utility/trash_white")
                :style("frame_action_button"):mouseButtonFilter({"left"}):tooltip({"gvv-mod.remove-checked-button"}):get(),
            confirm_remove = GvvGuiElement(gui_name, "sprite-button", "confirm_remove"):spritePath("gvv-mod_red-check")
                :style("frame_action_button"):mouseButtonFilter({"left"}):tooltip({"gvv-mod.remove-checked-button"}):get(),
            cancel_remove = GvvGuiElement(gui_name, "sprite-button", "cancel_remove"):spritePath("gvv-mod_green-close")
                :style("frame_action_button"):mouseButtonFilter({"left"}):get(),
            up = GvvGuiElement(gui_name, "sprite-button", "up"):spritePath("gvv-mod_arrow-up")
                :style("frame_action_button"):mouseButtonFilter({"left", "right"}):tooltip({"gvv-mod.move-up-checked"}):get(),
            down = GvvGuiElement(gui_name, "sprite-button", "down"):spritePath("gvv-mod_arrow-down")
                :style("frame_action_button"):mouseButtonFilter({"left", "right"}):tooltip({"gvv-mod.move-down-checked"}):get(),
            check = GvvGuiElement(gui_name, "sprite-button", "check"):spritePath("utility/check_mark_white")
                :style("frame_action_button"):mouseButtonFilter({"left", "right"}):tooltip({"gvv-mod.check-process-btn"}):get(),
            export_import = GvvGuiElement(gui_name, "sprite-button", "export_import"):spritePath("gvv-mod_export-import")
                :style("frame_action_button"):mouseButtonFilter({"left", "right"}):tooltip({"gvv-mod.export-import-btn"}):get(),
        },
        -- FR : Curseur de l'intervalle de rafraîchissement (en ticks)
        -- EN : Refresh interval slider (in ticks)
        slider = {
            interval = GvvGuiElement(gui_name, "slider", "interval"):get(),
        },
        -- FR : Saisie de l'intervalle (cachée tant qu'on ne clique pas sur le nombre)
        -- EN : Interval input (hidden until the number is clicked)
        textfield = {
            interval = GvvGuiElement(gui_name, "textfield", "interval"):visible(false)
                :tooltip({"gvv-mod.track-interval-control"}):get(),
        },
        -- FR : Cadre de confirmation de la suppression (caché au départ)
        -- EN : Removal confirmation frame (hidden at first)
        frame = {
            confirm = GvvGuiElement(gui_name, "frame", "confirm"):visible(false):get(),
        },
    }

    -- FR : Réglages propres au curseur et à la saisie, donnés à la création (pas modifiables ensuite)
    -- EN : Slider and input specific settings, given at creation (not modifiable afterwards)
    element.slider.interval.minimum_value = 1
    element.slider.interval.maximum_value = 180
    element.slider.interval.value_step = 1
    element.slider.interval.discrete_slider = false
    element.slider.interval.discrete_values = true
    element.textfield.interval.numeric = true
    element.textfield.interval.allow_decimal = false
    element.textfield.interval.allow_negative = false
    element.textfield.interval.lose_focus_on_confirm = true
    element.textfield.interval.clear_and_focus_on_right_click = true

    return element
end


---**EN**
---
---Description: Paths of the tab elements from gui[1] (gvv_main-flow-tracking).
---Tools are looked up directly in gvv_main-flow-tools (see GvvGuiTracking:getTool).
---
---──────────────────────────────
---
---**FR**
---
---Description: Chemins des éléments de l'onglet depuis gui[1] (gvv_main-flow-tracking).
---Les outils sont cherchés directement dans gvv_main-flow-tools (voir GvvGuiTracking:getTool).
---@return table
local function getContent()
    return {
        flow = {
            wrap = { "flow-wrap" },
            panel = { "flow-wrap", "pane-scroll", "flow-panel" },
        },
        pane = {
            scroll = { "flow-wrap", "pane-scroll" },
        },
    }
end


---------------------------------------------------------------------------------------------
-- FR : Fonctions exportées et préfixe
-- EN : Exported functions and prefix
return {
    getElement = getElement,
    getContent = getContent,
    GUI_NAME = GUI_NAME,
}
