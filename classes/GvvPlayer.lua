---------------------------------------------------------------------------------------------
-- GVV PLAYER
---------------------------------------------------------------------------------------------
-- FR : Source : RitnLib (Ritn), classes/LuaClass/RitnPlayer.lua (RitnLibPlayer), version 0.10.7.
--      Wrapper temporaire d'un LuaPlayer, copié et adapté pour que gvv reste autonome.
--      Différences : seuls les champs utiles à gvv sont repris (pas de surface, force, véhicule...),
--      vérifications via check.lua, ajout de l'accès aux données gvv du joueur (storage.players)
--      et du droit d'utiliser gvv (canUseGvv).
-- EN : Source: RitnLib (Ritn), classes/LuaClass/RitnPlayer.lua (RitnLibPlayer), version 0.10.7.
--      Temporary wrapper of a LuaPlayer, copied and adapted so gvv stays standalone.
--      Differences: only the fields useful to gvv are kept (no surface, force, vehicle...),
--      checks through check.lua, added access to the player's gvv data (storage.players)
--      and to the right to use gvv (canUseGvv).
---------------------------------------------------------------------------------------------
local check = require(gvv.defines.lualib.common.check)
---------------------------------------------------------------------------------------------

---@class GvvPlayer
---@field object_name string
---@field isPresent boolean   Vrai si le joueur est valide / True if the player is valid
---@field player LuaPlayer
---@field index uint
---@field name string
---@field admin boolean
---@field connected boolean
GvvPlayer = gvv.classFactory.newclass(function(self, LuaPlayer)
    self.object_name = "GvvPlayer"
    -- FR : Vérification du paramètre : un LuaPlayer encore valide
    -- EN : Parameter check: a LuaPlayer still valid
    self.isPresent = false
    if check.dataType(LuaPlayer) ~= "LuaPlayer" or not check.isValidLuaObject(LuaPlayer) then
        log('> GvvPlayer : not a valid LuaPlayer !')
        return
    end
    self.isPresent = true
    --------------------------------------------------
    self.player = LuaPlayer
    self.index = LuaPlayer.index
    self.name = LuaPlayer.name
    self.admin = LuaPlayer.admin
    self.connected = LuaPlayer.connected
    --------------------------------------------------
end)
----------------------------------------------------------------


---FR : Affiche un message au joueur. Une table est affichée avec serpent, une autre valeur avec tostring.
---EN : Prints a message to the player. A table is printed with serpent, any other value with tostring.
---@param text any
---@param color? Color
---@return GvvPlayer
function GvvPlayer:print(text, color)
    if not self.isPresent then return self end
    if check.isTable(text) and not check.isString(text[1]) then
        text = serpent.block(text)
    elseif not check.isString(text) and not check.isTable(text) then
        text = tostring(text)
    end
    self.player.print(text, color)
    return self
end


---FR : Vrai si le joueur peut utiliser gvv : toujours en solo, seulement les admins en multijoueur.
---EN : True if the player can use gvv: always in single player, only admins in multiplayer.
---@return boolean
function GvvPlayer:canUseGvv()
    if not self.isPresent then return false end
    return self.admin or not game.is_multiplayer()
end


---FR : Données gvv du joueur (storage.players[index]), ou nil si elles n'existent pas encore.
---EN : The player's gvv data (storage.players[index]), or nil if it does not exist yet.
---@return table?
function GvvPlayer:getData()
    if not self.isPresent then return nil end
    return check.getPath(storage, {"players", self.index})
end
