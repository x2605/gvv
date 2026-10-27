---------------------------------------------------------------------------------------------
-- MODULE : PLAYER
---------------------------------------------------------------------------------------------
-- FR : Évènements liés aux joueurs.
-- EN : Player related events.
---------------------------------------------------------------------------------------------

---**EN**
---
---Description: A new player can take the index of a removed player:
---clear the gvv data left at that index, so they start from scratch.
---
---──────────────────────────────
---
---**FR**
---
---Description: Un nouveau joueur peut reprendre l'index d'un joueur supprimé :
---on efface les données gvv restées à cet index, pour qu'il reparte de zéro.
---@param event EventData.on_player_created
local function on_player_created(event)
    -- FR : storage.players n'existe que si un joueur a déjà ouvert gvv
    -- EN : storage.players only exists if a player has already opened gvv
    if storage.players then
        storage.players[event.player_index] = nil
    end
end

---------------------------------------------------------------------------------------------
-- FR : Module envoyé à l'event handler (core/modules.lua)
-- EN : Module sent to the event handler (core/modules.lua)

---@type GvvModule
local module = {events = {}}
---------------------------------------------------------------------------------------------
-- FR : Création d'un joueur
-- EN : Player creation
module.events[defines.events.on_player_created] = on_player_created
---------------------------------------------------------------------------------------------
return module
