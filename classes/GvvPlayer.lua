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
-- FR : Utilisation : GvvPlayer(LuaPlayer) crée un objet temporaire, jamais rangé dans storage.
--      On en crée un nouveau à chaque évènement : il reflète toujours l'état actuel du joueur.
-- EN : Usage: GvvPlayer(LuaPlayer) creates a temporary object, never stored in storage.
--      A new one is created on each event: it always reflects the current player state.
---------------------------------------------------------------------------------------------
local check = require(gvv.defines.lualib.common.check)
---------------------------------------------------------------------------------------------


---**EN**
---
---Description: Wrapper of a LuaPlayer for gvv: copies the useful player fields (snapshot), gives access to the
---player's gvv data (`storage.players[index]`) and to the right to use gvv. Base of every gvv window.
---
---⚠ Temporary wrapper, created on each event. Do not store the instance in `storage`.
---
---──────────────────────────────
---
---**FR**
---
---Description: Wrapper d'un LuaPlayer pour gvv : copie les champs utiles du joueur (instantané), donne accès aux
---données gvv du joueur (`storage.players[index]`) et au droit d'utiliser gvv. Base de toutes les fenêtres.
---
---⚠ Wrapper temporaire, créé à chaque évènement. Ne pas stocker l'instance dans `storage`.
---@class GvvPlayer
---@field object_name string     "GvvPlayer" (overridden by sub-classes)
---@field isPresent boolean      True if the player is valid; otherwise methods do nothing
---@field player LuaPlayer       Wrapped player (live reference)
---@field index uint             Player index (key of `storage.players`)
---@field name string            Player name (snapshot)
---@field admin boolean          Admin flag (snapshot)
---@field connected boolean      Connected flag (snapshot)
---@operator call(LuaPlayer?): GvvPlayer
---@type GvvPlayer
GvvPlayer = gvv.classFactory.newclass(function(self, LuaPlayer)
    -- FR : Nom de la classe, utile dans les logs
    -- EN : Class name, useful in logs
    self.object_name = "GvvPlayer"

    -- FR : Vérification du paramètre : il faut un LuaPlayer encore valide.
    --      Sinon l'objet reste « absent » (isPresent = false) et ses méthodes ne font rien.
    -- EN : Parameter check: a LuaPlayer still valid is required.
    --      Otherwise the object stays "absent" (isPresent = false) and its methods do nothing.
    self.isPresent = false
    if check.dataType(LuaPlayer) ~= "LuaPlayer" or not check.isValidLuaObject(LuaPlayer) then
        log('> GvvPlayer : not a valid LuaPlayer !')
        return
    end
    self.isPresent = true

    --------------------------------------------------
    -- FR : Copie des informations du joueur utiles à gvv
    -- EN : Copy of the player information useful to gvv
    -- FR : le LuaPlayer lui-même
    -- EN : the LuaPlayer itself
    self.player = LuaPlayer

    -- FR : index, clé de storage.players
    -- EN : index, key of storage.players
    self.index = LuaPlayer.index

    -- FR : nom affiché
    -- EN : displayed name
    self.name = LuaPlayer.name

    -- FR : admin ? (droit d'utiliser gvv en multijoueur)
    -- EN : admin? (right to use gvv in multiplayer)
    self.admin = LuaPlayer.admin

    -- FR : connecté ?
    -- EN : connected?
    self.connected = LuaPlayer.connected
    --------------------------------------------------
end) --[[@as GvvPlayer]]
----------------------------------------------------------------


---**EN**
---
---Description: Prints a message to the player. A table is printed with serpent, any other value with tostring.
---A localised string ({"key", ...}) is printed as is.
---
---──────────────────────────────
---
---**FR**
---
---Description: Affiche un message au joueur. Une table est affichée avec serpent, une autre valeur avec tostring.
---Un texte localisé ({"clé", ...}) est affiché tel quel.
---@param text any
---@param color? Color
---@return GvvPlayer
function GvvPlayer:print(text, color)
    -- FR : Joueur absent ou invalide : rien à afficher
    -- EN : Missing or invalid player: nothing to print
    if not self.isPresent then
        return self
    end

    if check.isTable(text) and not check.isString(text[1]) then
        -- FR : Table ordinaire (pas un texte localisé) : on l'affiche en texte lisible
        -- EN : Ordinary table (not a localised string): print it as readable text
        text = serpent.block(text)
    elseif not check.isString(text) and not check.isTable(text) then
        -- FR : Nombre, booléen, nil... : converti en texte
        -- EN : Number, boolean, nil...: converted to text
        text = tostring(text)
    end

    -- FR : Affichage dans le chat du joueur
    -- EN : Print in the player's chat
    self.player.print(text, color)
    return self
end


---**EN**
---
---Description: True if the player can use gvv: always in single player, only admins in multiplayer.
---
---──────────────────────────────
---
---**FR**
---
---Description: Vrai si le joueur peut utiliser gvv : toujours en solo, seulement les admins en multijoueur.
---@return boolean
function GvvPlayer:canUseGvv()
    -- FR : Joueur absent ou invalide : pas le droit
    -- EN : Missing or invalid player: no right
    if not self.isPresent then
        return false
    end

    -- FR : Admin, ou partie solo
    -- EN : Admin, or single player game
    return self.admin or not game.is_multiplayer()
end


---**EN**
---
---Description: The player's gvv data (storage.players[index]), or nil if it does not exist yet
---(the player never opened gvv).
---
---──────────────────────────────
---
---**FR**
---
---Description: Données gvv du joueur (storage.players[index]), ou nil si elles n'existent pas encore
---(le joueur n'a jamais ouvert gvv).
---@return table?
function GvvPlayer:getData()
    -- FR : Joueur absent ou invalide : pas de données
    -- EN : Missing or invalid player: no data
    if not self.isPresent then
        return nil
    end

    -- FR : storage.players[index], sans erreur si storage.players n'existe pas encore
    -- EN : storage.players[index], without error if storage.players doesn't exist yet
    return check.getPath(storage, {"players", self.index})
end


---**EN**
---
---Description: Creates the player's gvv data if needed, and fills missing values with their default value.
---Returns the data, and true if it was just created (first time gvv is opened).
---Taken from the old Gui.open_main (legacy/gui.lua), without changing values.
---
---──────────────────────────────
---
---**FR**
---
---Description: Crée les données gvv du joueur si besoin, et complète les valeurs manquantes par leur valeur par défaut.
---Renvoie les données, et true si elles viennent d'être créées (première ouverture de gvv).
---Repris de l'ancien Gui.open_main (legacy/gui.lua), sans changement de valeurs.
---@return table? data
---@return boolean first_time
function GvvPlayer:initData()
    -- FR : Joueur absent ou invalide : pas de données
    -- EN : Missing or invalid player: no data
    if not self.isPresent then
        return nil, false
    end

    -- FR : Table de tous les joueurs, créée au premier joueur qui ouvre gvv
    -- EN : Table of all players, created by the first player who opens gvv
    if not storage.players then
        storage.players = {}
    end

    -- FR : Données de ce joueur : créées à sa première ouverture de gvv
    -- EN : This player's data: created the first time they open gvv
    local first_time = false
    if not storage.players[self.index] then
        storage.players[self.index] = {}
        first_time = true
    end
    local data = storage.players[self.index]
    data.index = self.index

    --------------------------------------------------
    -- FR : Réglages de la fenêtre et de l'affichage
    -- EN : Window and display settings
    if not data.track_interval_tick then

        -- FR : intervalle du suivi (ticks)
        -- EN : tracking interval (ticks)
        data.track_interval_tick = 60
    end
    if not data.last_width then

        -- FR : largeur de la fenêtre
        -- EN : window width
        data.last_width = 900
    end
    if not data.last_height then

        -- FR : hauteur de la fenêtre
        -- EN : window height
        data.last_height = 600
    end
    if data.show_na == nil then

        -- FR : afficher les n/a
        -- EN : show n/a
        data.show_na = true
    end
    if data.show_nil == nil then

        -- FR : afficher les nil
        -- EN : show nil
        data.show_nil = true
    end
    if data.show_func == nil then

        -- FR : afficher les méthodes
        -- EN : show methods
        data.show_func = false
    end

    --------------------------------------------------
    -- FR : Réglages de la recherche, un par arbre (storage/_G, objets Lua, objets globaux)
    -- EN : Search settings, one per tree (storage/_G, Lua objects, global objects)
    if not data.search_settings then
        data.search_settings = {}
    end
    for _, tree_name in ipairs({"glob", "prop", "gobj"}) do
        if not data.search_settings[tree_name] then
            data.search_settings[tree_name] = {}
        end
    end
    for _, settings in pairs(data.search_settings) do
        if not settings.text then

            -- FR : texte cherché
            -- EN : searched text
            settings.text = ''
        end
        if settings.key == nil then

            -- FR : chercher dans les clés
            -- EN : search in keys
            settings.key = true
        end
        if settings.value == nil then

            -- FR : chercher dans les valeurs
            -- EN : search in values
            settings.value = false
        end
        if settings.regexp == nil then

            -- FR : motif Lua
            -- EN : Lua pattern
            settings.regexp = false
        end
        if settings.case == nil then

            -- FR : respecter la casse
            -- EN : case sensitive
            settings.case = false
        end
    end
    if data.show_search == nil then

        -- FR : panneau de recherche visible
        -- EN : search panel visible
        data.show_search = false
    end

    --------------------------------------------------
    -- FR : Données de travail : objets ajoutés, liste de suivi, résultats de recherche
    -- EN : Working data: added objects, tracking list, search results
    if not data.data then
        data.data = {}
    end
    if not data.data.docked_luaobj then
        data.data.docked_luaobj = {}
    end
    if not data.data.tracking_list then
        data.data.tracking_list = {}
    end

    return data, first_time
end
