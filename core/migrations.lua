---------------------------------------------------------------------------------------------
-- MIGRATIONS
---------------------------------------------------------------------------------------------
-- FR : Migrations exécutées dans on_configuration_changed quand gvv est mis à jour dans une partie.
--      Sur le modèle de RitnCoreGame (core/migrations.lua) : une migration par version.
--      Chaque migration dont la version est plus récente que l'ancienne version de gvv est
--      exécutée, dans l'ordre de la liste.
-- EN : Migrations run in on_configuration_changed when gvv is updated in a game.
--      Modelled on RitnCoreGame (core/migrations.lua): one migration per version.
--      Each migration whose version is newer than gvv's old version is run,
--      in the list order.
---------------------------------------------------------------------------------------------
local check = require(gvv.defines.lualib.common.check)
---------------------------------------------------------------------------------------------


---FR : Découpe une version « 0.5.21 » en nombres {0, 5, 21}. Renvoie nil si le format est inconnu.
---EN : Splits a "0.5.21" version into numbers {0, 5, 21}. Returns nil if the format is unknown.
---@param version any
---@return integer[]?
local function parseVersion(version)
    -- FR : Pas un texte : version inconnue
    -- EN : Not a text: unknown version
    if not check.isString(version) then
        return nil
    end

    -- FR : Trois nombres séparés par des points
    -- EN : Three numbers separated by dots
    local major, minor, patch = version:match("^(%d+)%.(%d+)%.(%d+)$")
    if major == nil then
        return nil
    end
    return { tonumber(major), tonumber(minor), tonumber(patch) }
end


---FR : Vrai si la version old est plus ancienne que la version target.
---     Une ancienne version illisible est considérée comme plus ancienne (la migration s'exécute).
---EN : True if version old is older than version target.
---     An unreadable old version is considered older (the migration runs).
---@param old any
---@param target string
---@return boolean
local function isOlder(old, target)
    local old_numbers = parseVersion(old)
    local target_numbers = parseVersion(target)

    -- FR : Ancienne version illisible : on migre par précaution
    -- EN : Unreadable old version: migrate as a precaution
    if old_numbers == nil or target_numbers == nil then
        return true
    end

    -- FR : Comparaison nombre par nombre : majeur, puis mineur, puis correctif
    -- EN : Number by number comparison: major, then minor, then patch
    for index = 1, 3 do
        if old_numbers[index] < target_numbers[index] then
            return true
        end
        if old_numbers[index] > target_numbers[index] then
            return false
        end
    end

    -- FR : Versions égales : pas plus ancienne
    -- EN : Equal versions: not older
    return false
end


---------------------------------------------------------------------------------------------
-- FR : 0.6.0 : la fenêtre principale est reconstruite avec de nouveaux noms (gvv_main-...).
--      Pour chaque joueur : sauvegarde des dossiers ouverts, fermeture de l'ancienne fenêtre
--      et des petites fenêtres, puis effacement des anciennes références d'éléments.
--      Le joueur rouvre gvv avec Ctrl+Shift+V ; ses données (suivi, objets ajoutés, taille) sont gardées.
-- EN : 0.6.0: the main window is rebuilt with new names (gvv_main-...).
--      For each player: save the opened folders, close the old window and the small windows,
--      then clear the old element references.
--      The player reopens gvv with Ctrl+Shift+V; their data (tracking, added objects, size) is kept.
---------------------------------------------------------------------------------------------
local function migration_0_6_0()
    -- FR : Aucun joueur n'a jamais ouvert gvv : rien à migrer
    -- EN : No player ever opened gvv: nothing to migrate
    if not storage.players then
        return
    end

    for index, data in pairs(storage.players) do
        -- FR : Ancienne fenêtre encore ouverte : détruite. Ses dossiers ouverts ne sont pas gardés
        --      (l'ancien code des arbres a été supprimé en 3.7) ; ceux gardés à sa dernière fermeture restent.
        -- EN : Old window still open: destroyed. Its opened folders are not kept
        --      (the old trees code was removed in 3.7); those kept when it was last closed remain.
        local old_frame = check.getPath(data, {"gui", "frame"})
        if check.isValidLuaObject(old_frame) then
            old_frame.destroy()
        end

        -- FR : Anciennes petites fenêtres de gvv encore ouvertes (joueur toujours présent seulement)
        -- EN : Old gvv small windows still open (player still present only)
        GvvGuiDialog({ player_index = index }):destroyLegacy()

        -- FR : Les anciennes références d'éléments GUI gardées dans storage ne servent plus :
        --      fenêtre (data.gui), lignes des arbres (tree_item_*), résultats de recherche (search)
        -- EN : The old GUI element references kept in storage are no longer used:
        --      window (data.gui), tree rows (tree_item_*), search results (search)
        data.gui = nil
        if data.data then
            data.data.tree_item_glob = nil
            data.data._G_tree_item_glob = nil
            data.data.tree_item_prop = nil
            data.data.tree_item_gobj = nil
            data.data.search = nil
        end
    end

    log('> gvv migration 0.6.0 : done')
end


---------------------------------------------------------------------------------------------
-- FR : Liste des migrations, de la plus ancienne à la plus récente
-- EN : Migrations list, from oldest to newest
local migration_list = {
    { version = "0.6.0", run = migration_0_6_0 },
}


---FR : Exécute les migrations plus récentes que old_version (l'ancienne version de gvv dans la partie).
---EN : Runs the migrations newer than old_version (gvv's old version in the game).
---@param old_version string?
local function run(old_version)
    log('>>> gvv migrations from ' .. tostring(old_version) .. ' : start')
    for _, migration in ipairs(migration_list) do
        if isOlder(old_version, migration.version) then
            log('>>> gvv migration ' .. migration.version)
            migration.run()
        end
    end
    log('>>> gvv migrations : finish')
end


---------------------------------------------------------------------------------------------
-- FR : Fonctions exportées (isOlder est exportée pour les tests)
-- EN : Exported functions (isOlder is exported for tests)
return {
    run = run,
    isOlder = isOlder,
}
