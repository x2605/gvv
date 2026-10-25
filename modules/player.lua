---------------------------------------------------------------------------------------------
-- MODULE : PLAYER
---------------------------------------------------------------------------------------------

-- FR : Un nouveau joueur peut reprendre l'index d'un joueur supprimé :
--      on efface les données gvv restées à cet index.
-- EN : A new player can take the index of a removed player:
--      clear the gvv data left at that index.
local function on_player_created(event)
    if storage.players then
        storage.players[event.player_index] = nil
    end
end

---------------------------------------------------------------------------------------------
local module = {events = {}}
---------------------------------------------------------------------------------------------
module.events[defines.events.on_player_created] = on_player_created
---------------------------------------------------------------------------------------------
return module
