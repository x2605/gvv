--로드

local Util = require(gvv.defines.lualib.common.util)
local Migrations = require(gvv.defines.migrations)

local Load = {}

---**EN**
---
---Description: Example data shown in the storage tree (forces, surface), written again on each init / configuration change.
---
---──────────────────────────────
---
---**FR**
---
---Description: Données d'exemple affichées dans l'arbre storage (forces, surface), réécrites à chaque init / changement de configuration.
Load.example_load = function()
  storage.example = {
    forces = {
      player_force = game.forces.player,
      biter_force = game.forces['enemy'],
      tree_force = game.forces[3],
    },
    initial_surface = game.get_surface(1),
  }
end

--중복해서 require(gvv.defines.modules.events) 호출해도 한번만 실행되도록
--run single time if called require(gvv.defines.modules.events) multiple times
if not _initiated_session_ then
  -- session global variables not inside of storage table
  _on_tick_function_ = GvvGuiTracking.onTick --constant
  _one_of_three_volatiles_executed_ = false
  _initiated_on_tick_ = false
  _initiated_session_ = true
  ------
end

---**EN**
---
---Description: gvv (or another mod) updated in an existing game.
---Migrations (core/migrations.lua) run when gvv itself changes version;
---they replace the old 0.4 migration, covered by the 0.6.0 one.
---
---──────────────────────────────
---
---**FR**
---
---Description: Mise à jour de gvv (ou d'un autre mod) dans une partie existante.
---Les migrations (core/migrations.lua) s'exécutent quand gvv lui-même change de version ;
---elles remplacent l'ancienne migration 0.4, couverte par celle de 0.6.0.
---@param data ConfigurationChangedData
Load.on_configuration_changed = function(data)
  Load.register_meta_data()
  Load.register_volatiles()
  Load.example_load()

  -- FR : Changement de version de gvv : old_version est absent si gvv vient d'être ajouté (rien à migrer)
  -- EN : gvv version change: old_version is missing if gvv was just added (nothing to migrate)
  local gvv_changes = data.mod_changes and data.mod_changes['gvv']
  if gvv_changes and gvv_changes.old_version then
    Migrations.run(gvv_changes.old_version)
  end
end

---**EN**
---
---Description: New game: meta data, on_tick, example data.
---
---──────────────────────────────
---
---**FR**
---
---Description: Nouvelle partie : méta-données, on_tick, données d'exemple.
Load.on_init = function()
  Load.register_meta_data()
  Load.register_volatiles()
  Load.example_load()
end

---**EN**
---
---Description: Game loaded: registers on_tick again according to `storage.meta_data` (no storage write).
---
---──────────────────────────────
---
---**FR**
---
---Description: Partie chargée : enregistre à nouveau on_tick selon `storage.meta_data` (aucune écriture dans storage).
Load.on_load = function()
  Load.register_volatiles()
end

---**EN**
---
---Description: Creates / completes `storage.meta_data` (version, markers, settings, default tracking list read from the
---mod settings on the first start).
---
---──────────────────────────────
---
---**FR**
---
---Description: Crée / complète `storage.meta_data` (version, marqueurs, paramètres, liste de suivi par défaut lue dans les
---paramètres du mod au premier démarrage).
Load.register_meta_data = function()
  if not storage.meta_data then storage.meta_data = {} end
  local version = script.active_mods['gvv']
  storage.meta_data.version = version
  if not storage.meta_data._nil_ then storage.meta_data._nil_ = {Used_for_categorizing=''} end
  if not storage.meta_data._function_ then storage.meta_data._function_ = {Used_for_categorizing=''} end
  if not storage.meta_data._na_ then storage.meta_data._na_ = {Used_for_categorizing=''} end
  if storage.meta_data['enable-on-tick'] == nil then
    storage.meta_data['enable-on-tick'] = settings.global['gvv-mod_enable-on-tick'].value
    if not _initiated_on_tick_ and storage.meta_data['enable-on-tick'] then
      script.on_event(defines.events.on_tick, _on_tick_function_)
      _initiated_on_tick_ = true
    elseif not _initiated_on_tick_ and not storage.meta_data['enable-on-tick'] then
      script.on_event(defines.events.on_tick, nil)
      _initiated_on_tick_ = true
    end
  end
  if not storage.meta_data.initiated then
    storage.meta_data.initiated = true

    if settings.global['gvv-mod_on_start'].value then
      local raw = settings.global['gvv-mod_preinput_code'].value
      local r, codes = true, {}
      local final_codes = {}
      local c = 0
      while r do
        codes[#codes + 1] = raw:match('^(.-)(%-%-%[%[%]%]%-%-)')
        raw, c = raw:gsub('^(.-)(%-%-%[%[%]%]%-%-)','')
        if c == 0 then
          codes[#codes + 1] = raw
          r = false
        end
      end
      for i, v in ipairs(codes) do
        codes[i] = v:gsub('^%s*(.-)%s*$', '%1')
        if codes[i] ~= '' then final_codes[#final_codes + 1] = codes[i] end
      end
      storage.meta_data.default_tracking_list = {}
      for _, v in pairs(final_codes) do
        storage.meta_data.default_tracking_list[v] = v
      end
    end

  end
end

---**EN**
---
---Description: Registers on_tick (or removes it) once per session, according to `storage.meta_data["enable-on-tick"]`.
---
---⚠ on_tick is registered with script.on_event, outside the event handler.
---
---──────────────────────────────
---
---**FR**
---
---Description: Enregistre on_tick (ou le retire) une fois par session, selon `storage.meta_data["enable-on-tick"]`.
---
---⚠ on_tick est enregistré avec script.on_event, en dehors de l'event handler.
Load.register_volatiles = function()
  if not _one_of_three_volatiles_executed_ then
    if not _initiated_on_tick_ and storage.meta_data and storage.meta_data['enable-on-tick'] then
      script.on_event(defines.events.on_tick, _on_tick_function_)
      _initiated_on_tick_ = true
    elseif not _initiated_on_tick_ and storage.meta_data and storage.meta_data['enable-on-tick'] == false then
      script.on_event(defines.events.on_tick, nil)
      _initiated_on_tick_ = true
    end
    _one_of_three_volatiles_executed_ = true
  end
end

---------------------------------------------------------------------------------------------
---@type GvvModule
local module = {events = {}}
---------------------------------------------------------------------------------------------
-- FR : Cycle de vie du mod
-- EN : Mod life cycle
module.on_init = Load.on_init
module.on_load = Load.on_load
module.on_configuration_changed = Load.on_configuration_changed
---------------------------------------------------------------------------------------------
return module
