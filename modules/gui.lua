---------------------------------------------------------------------------------------------
-- MODULE : GUI
---------------------------------------------------------------------------------------------
-- FR : Aiguillage des évènements GUI. Chaque évènement est proposé aux fenêtres (classes Gvv*,
--      liste gui_classes), dans l'ordre ; la première qui le traite arrête la recherche.
--      Un clic que personne ne traite, dans la fenêtre principale, ferme les petites fenêtres
--      concernées (comme l'ancien legacy/gui_event.lua, supprimé en 3.6b).
-- EN : GUI events dispatcher. Each event is offered to the windows (Gvv* classes,
--      gui_classes list), in order; the first one that handles it stops the search.
--      A click nobody handles, inside the main window, closes the small windows concerned
--      (as the old legacy/gui_event.lua did, removed in 3.6b).
---------------------------------------------------------------------------------------------

-- FR : Fenêtres migrées, dans l'ordre où elles reçoivent les évènements
-- EN : Migrated windows, in the order they receive events
local gui_classes = {
    -- FR : Le suivi passe en premier : à chaque clic, il valide l'intervalle en cours de saisie
    --      et cache la confirmation de suppression (comme l'ancien code), puis laisse la main
    -- EN : Tracking comes first: on each click, it confirms the interval being typed
    --      and hides the removal confirmation (as the old code did), then passes on
    GvvGuiTracking, -- FR : onglet suivi (3.4) / EN : tracking tab (3.4)
    GvvGuiMain,     -- FR : fenêtre principale (3.1) / EN : main window (3.1)
    GvvGuiDialog,   -- FR : petites fenêtres (3.2) / EN : small windows (3.2)
    GvvGuiHelp,     -- FR : onglet aide (3.3) / EN : help tab (3.3)
    GvvGuiSearch,   -- FR : recherche dans les arbres (3.5) / EN : search in the trees (3.5)
    -- FR : Arbres (3.6) et leurs outils : l'arbre est choisi par le préfixe de l'élément
    -- EN : Trees (3.6) and their tools: the tree is chosen by the element prefix
    GvvGuiTree.fromEvent,
}


---**EN**
---
---Description: Click nobody handled: if it is inside the main window, the small windows
---concerned close (anycode only if empty). Taken from the old Gui_Event.on_gui_click.
---
---──────────────────────────────
---
---**FR**
---
---Description: Clic que personne n'a traité : s'il est dans la fenêtre principale, les petites fenêtres
---concernées se ferment (anycode seulement si vide). Repris de l'ancien Gui_Event.on_gui_click.
---@param event EventData.on_gui_click
local function onUnhandledClick(event)
    local frame = GvvGuiMain(event):getMainElement()

    -- FR : Fenêtre principale fermée : rien à faire
    -- EN : Main window closed: nothing to do
    if frame == nil then
        return
    end

    -- FR : On remonte les parents de l'élément cliqué jusqu'à trouver la fenêtre principale
    -- EN : Go up the clicked element parents until the main window is found
    local element = event.element
    while element ~= nil and element.valid do
        if element == frame then
            GvvGuiDialog(event):closeOnMainFocus()
            return
        end
        element = element.parent
    end
end


---**EN**
---
---Description: Runs a GUI handler in a protected way: an error is shown to the player instead of crashing,
---and written to factorio-current.log with the call stack (for bug reports and tests).
---
---──────────────────────────────
---
---**FR**
---
---Description: Exécute un handler GUI de façon protégée : une erreur est affichée au joueur au lieu de planter,
---et écrite dans factorio-current.log avec la pile d'appels (pour les rapports de bug et les tests).
---@param handler fun(event: table)
---@return fun(event: table)
local function protected(handler)
    return function(event)
        -- FR : Exécution protégée du handler ; en cas d'erreur, la pile d'appels est gardée pour le log
        -- EN : Protected run of the handler; on error, the call stack is kept for the log
        local traceback = nil
        local success, message = xpcall(handler, function(error_message)
            traceback = debug.traceback(tostring(error_message), 2)
            return error_message
        end, event)

        if not success then
            -- FR : Message complet dans le log
            -- EN : Full message inside the log
            log('[ERROR] gvv GUI : ' .. tostring(traceback or message))

            -- FR : Message court dans le chat du joueur concerné
            -- EN : Short message inside the chat of the player concerned
            if event.player_index then
                game.get_player(event.player_index).print('[font=var-outline-gvv-mod]' .. tostring(message) .. '[/font]', {1, 0.85, 0.7, 1})
            end
        end
    end
end


---**EN**
---
---Description: Builds the handler of a GUI event: migrated windows first, then old code.
---method_name : name of the method to call, e.g. "on_gui_click".
---
---──────────────────────────────
---
---**FR**
---
---Description: Construit le handler d'un évènement GUI : fenêtres migrées d'abord, puis ancien code.
---method_name : nom de la méthode à appeler, ex. « on_gui_click ».
---@param method_name string  e.g. "on_gui_click"
---@return fun(event: table)
local function dispatcher(method_name)
    return protected(function(event)
        -- FR : Chaque fenêtre migrée reçoit l'évènement ; la première qui le traite (true) arrête la recherche
        -- EN : Each migrated window receives the event; the first one that handles it (true) stops the search
        for _, gui_class in ipairs(gui_classes) do
            local gui = gui_class(event)
            if gui[method_name] and gui[method_name](gui) then
                return
            end
        end

        -- FR : Clic que personne n'a traité
        -- EN : Click nobody handled
        if method_name == "on_gui_click" then
            onUnhandledClick(event)
        end
    end)
end


---------------------------------------------------------------------------------------------
-- FR : Module envoyé à l'event handler (core/modules.lua)
-- EN : Module sent to the event handler (core/modules.lua)

---@type GvvModule
local module = {events = {}}
---------------------------------------------------------------------------------------------
-- FR : Évènements GUI
-- EN : GUI events
module.events[defines.events.on_gui_click] = dispatcher("on_gui_click")
module.events[defines.events.on_gui_closed] = dispatcher("on_gui_closed")
module.events[defines.events.on_gui_value_changed] = dispatcher("on_gui_value_changed")
module.events[defines.events.on_gui_confirmed] = dispatcher("on_gui_confirmed")
module.events[defines.events.on_gui_selected_tab_changed] = dispatcher("on_gui_selected_tab_changed")
module.events[defines.events.on_gui_checked_state_changed] = dispatcher("on_gui_checked_state_changed")
module.events[defines.events.on_gui_text_changed] = dispatcher("on_gui_text_changed")
module.events[defines.events.on_gui_selection_state_changed] = dispatcher("on_gui_selection_state_changed")
-- FR : Raccourci Ctrl+Shift+V : ouvre ou ferme la fenêtre principale (admins seulement en multijoueur)
-- EN : Ctrl+Shift+V shortcut: opens or closes the main window (admins only in multiplayer)
module.events['toggle-main-frame_gvv-mod'] = protected(function(event)
    local main = GvvGuiMain(event)
    if main:canUseGvv() then
        main:toggle()
    end
end)
-- FR : Raccourci Shift+X : rafraîchit l'onglet affiché (suivi : les valeurs ; arbres : l'arbre)
--      (admins seulement en multijoueur). Repris de l'ancien Gui_Event['refresh_gvv-mod'].
-- EN : Shift+X shortcut: refreshes the displayed tab (tracking: the values; trees: the tree)
--      (admins only in multiplayer). Taken from the old Gui_Event['refresh_gvv-mod'].
module.events['refresh_gvv-mod'] = protected(function(event)
    local main = GvvGuiMain(event)
    local tabbed = main:getElement("tabbed", "tabs")

    -- FR : Droit d'utiliser gvv, et fenêtre ouverte
    -- EN : Right to use gvv, and window open
    if not main:canUseGvv() or tabbed == nil then
        return
    end

    -- FR : Onglet suivi : ses valeurs ; onglets des arbres : l'arbre affiché
    -- EN : Tracking tab: its values; trees tabs: the displayed tree
    if tabbed.selected_tab_index == 1 then
        GvvGuiTracking(event):refreshValues()
    else
        GvvGuiTree.refreshTab(event)
    end
end)
---------------------------------------------------------------------------------------------
return module
