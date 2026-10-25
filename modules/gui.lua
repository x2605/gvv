---------------------------------------------------------------------------------------------
-- MODULE : GUI
---------------------------------------------------------------------------------------------
-- FR : Aiguillage des évènements GUI. Chaque évènement est d'abord proposé aux fenêtres déjà
--      migrées (classes Gvv*, liste gui_classes) ; si aucune ne le traite, il part vers l'ancien
--      code (legacy/gui_event.lua). Pendant l'étape 3, on ajoute une fenêtre à gui_classes et on retire
--      ses branches de l'ancien code ; à la fin, l'ancien code disparaît.
-- EN : GUI events dispatcher. Each event is first offered to the already migrated windows
--      (Gvv* classes, gui_classes list); if none handles it, it goes to the old code
--      (legacy/gui_event.lua). During step 3, a window is added to gui_classes and its branches
--      are removed from the old code; at the end, the old code disappears.
---------------------------------------------------------------------------------------------
local Legacy_Gui_Event = require(gvv.defines.legacy.gui_event)
---------------------------------------------------------------------------------------------

-- FR : Fenêtres migrées, dans l'ordre où elles reçoivent les évènements
-- EN : Migrated windows, in the order they receive events
local gui_classes = {
    GvvGuiMain,     -- FR : fenêtre principale (3.1) / EN : main window (3.1)
    GvvGuiDialog,   -- FR : petites fenêtres (3.2) / EN : small windows (3.2)
}


-- FR : Exécute un handler GUI dans un pcall : une erreur est affichée au joueur au lieu de planter.
-- EN : Runs a GUI handler inside a pcall: an error is shown to the player instead of crashing.
local function protected(handler)
    return function(event)
        -- FR : Exécution protégée du handler
        -- EN : Protected run of the handler
        local success, message = pcall(handler, event)

        -- FR : En cas d'erreur, le message est affiché dans le chat du joueur concerné
        -- EN : On error, the message is printed in the chat of the player concerned
        if not success and event.player_index then
            game.get_player(event.player_index).print('[font=var-outline-gvv-mod]' .. message .. '[/font]', {1, 0.85, 0.7, 1})
        end
    end
end


-- FR : Construit le handler d'un évènement GUI : fenêtres migrées d'abord, puis ancien code.
--      method_name : nom de la méthode à appeler, ex. « on_gui_click ».
-- EN : Builds the handler of a GUI event: migrated windows first, then old code.
--      method_name : name of the method to call, e.g. "on_gui_click".
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

        -- FR : Aucune fenêtre migrée ne l'a traité : l'ancien code s'en charge
        -- EN : No migrated window handled it: the old code takes care of it
        local legacy_handler = Legacy_Gui_Event[method_name]
        if legacy_handler then
            legacy_handler(event)
        end
    end)
end


---------------------------------------------------------------------------------------------
-- FR : Module envoyé à l'event handler (core/modules.lua)
-- EN : Module sent to the event handler (core/modules.lua)
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
-- FR : Raccourci Shift+X (rafraîchir), encore géré par l'ancien code
-- EN : Shift+X shortcut (refresh), still handled by the old code
module.events['refresh_gvv-mod'] = Legacy_Gui_Event['refresh_gvv-mod']
---------------------------------------------------------------------------------------------
return module
