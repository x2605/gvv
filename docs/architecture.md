---
title: Architecture interne gvv
audience: mainteneur
status: living
last_review: 2026-10-28
pinned_version: 0.6.0
---

# Architecture interne — gvv

> Document interne mainteneur. Vue d'ensemble de la structure du code, des dépendances et des choix de conception.
> Mis à jour à chaque refactor structurel — section « Historique » en bas.
>
> **Version auditée : 0.6.0 (Factorio 2.1)**, juste après la restructuration 0.6 (architecture des mods Ritn).
> Liens GitHub épinglés sur le commit `0fbb93a` (aucun tag `v0.6.0` au moment de l'audit) :
> base `https://github.com/x2605/gvv/blob/0fbb93a/`.
> Matière détaillée pour les annotations et la doc : [`docs/audit/handoff.md`](audit/handoff.md).

## 1. Identité

gvv (« Lua API global Variable Viewer ») est un **outil de débogage** : une fenêtre en jeu (Ctrl+Shift+V, `/gvv`)
qui affiche le `storage` et le `_G` des mods, les propriétés des objets Lua de l'API, et un suivi de variables
(codes Lua réévalués en continu). Créé par x2605, repris et maintenu par Ritn depuis la 0.6.

| Trait | Constat |
|---|---|
| **Provider** | `gvv.lua` est chargé **dans la VM des autres mods** (`require("__gvv__.gvv")()`) et y crée l'interface `__<mod>__gvv` (`storage`, `_G`, `diag`, `fix`, `c`, `version`) |
| **Consumer** | gvv appelle ces interfaces chez chaque mod qui les a chargées (arbres, suivi, commandes, aide) |
| Socle / extension | Non — aucune classe exposée aux autres mods, aucun héritage inter-mod |

- `info.json` : `factorio_version = "2.1"`, **aucune dépendance**. Autonome : n'utilise pas RitnLib (décision de Ritn).
- Seul état multijoueur : réservé aux admins (`GvvPlayer:canUseGvv`).

## 2. Vue d'ensemble en couches

```
 settings.lua            data.lua ──► prototypes/  (custom-inputs, sprites, fonts, styles)
                                         ▲ chemins via gvv.defines.prototypes
 control.lua
   ├─ core/defines.lua ........ registre de chemins global  gvv.defines
   ├─ core/setup-classes.lua .. factory (core/class.lua) + chargement des classes
   ├─ core/modules.lua ........ modules/*.lua ──► __core__.lualib.event_handler
   │     modules/events.lua    cycle de vie, on_tick dynamique, migrations (core/migrations.lua)
   │     modules/player.lua    on_player_created
   │     modules/gui.lua       aiguillage des évènements GUI + raccourcis
   │     modules/commands.lua  /gvv /gdump* /gmods + paramètres du mod
   ├─ (RitnTest, dev seulement)
   └─ gvv.lua ................. interface __gvv__gvv (gvv se lit lui-même)

 classes/  GvvPlayer ─► GvvGui ─► GvvGuiMain, GvvGuiDialog, GvvGuiHelp,
                                  GvvGuiTracking, GvvGuiSearch, GvvGuiTree
           GvvGuiElement (description d'un élément)
 gui/      description des fenêtres (getElement / getContent) ; gui/tree/<onglet>.lua = config des arbres
 lualib/   common/ (util, check, table_to_str, sprite, luaobj_prop, copy_code, doctor)
           api/ (tables écrites à la main)   remote_code/ (modèles de code injecté)
 generated/runtime-api-stable.lua  (API runtime convertie depuis runtime-api.json, 2.1.23)
```

## 3. Entrypoints

| Stage | Fichier | Action |
|---|---|---|
| settings | [`settings.lua`](https://github.com/x2605/gvv/blob/0fbb93a/settings.lua) | 3 paramètres runtime-global : code de suivi par défaut, l'activer au démarrage, `on_tick` |
| data | [`data.lua`](https://github.com/x2605/gvv/blob/0fbb93a/data.lua) | `core/defines.lua` puis les 4 fichiers de `prototypes/` |
| control | [`control.lua`](https://github.com/x2605/gvv/blob/0fbb93a/control.lua) | registre (l.14), classes (l.17), modules → event_handler (l.20), RitnTest si actif (l.23), `gvv.lua` pour gvv lui-même (l.40) |
| (autres mods) | [`gvv.lua`](https://github.com/x2605/gvv/blob/0fbb93a/gvv.lua) | chargé par les mods inspectés ; **chemin `__gvv__.gvv` à ne jamais changer** |

## 4. Registre global / modules

- **`gvv.defines`** ([`core/defines.lua`](https://github.com/x2605/gvv/blob/0fbb93a/core/defines.lua)) : tous les chemins de `require`
  (classes, gui, trees, prototypes, modules, lualib, generated). Aucun fichier n'écrit de chemin en dur, sauf
  `gvv.lua` qui doit rester autonome. Chargé au control **et** au data stage.
- **Modules** : chaque `modules/*.lua` renvoie `{ events = {...}, on_init?, on_load?, on_configuration_changed? }`,
  envoyé à `__core__.lualib.event_handler` par [`core/modules.lua`](https://github.com/x2605/gvv/blob/0fbb93a/core/modules.lua).
- **Pas de `require` pendant le jeu** : toutes les configurations sont chargées au parsing de control.lua
  (`CONFIGS` dans `GvvGuiTree.lua`).

## 5. Système de classes

- Factory locale [`core/class.lua`](https://github.com/x2605/gvv/blob/0fbb93a/core/class.lua) (copie de celle de RitnLib, gvv reste autonome), exposée en `gvv.classFactory`.
- Classes **globales** (`_G`), préfixe `Gvv`, **wrappers temporaires** : créées à chaque évènement, jamais stockées dans `storage`.

```
GvvPlayer            joueur + données gvv (storage.players[i]), canUseGvv
 └─ GvvGui           base des fenêtres : gui_name, gui[1], content, gui_action, dispatch(), on_gui_*
     ├─ GvvGuiMain       fenêtre principale, onglets, redimensionnement
     ├─ GvvGuiDialog     6 petites fenêtres (dump, anycode, copy, edit, export, import)
     ├─ GvvGuiHelp       onglet aide (pages, diagnostic / réparation)
     ├─ GvvGuiTracking   onglet suivi + on_tick
     ├─ GvvGuiSearch     loupe + panneaux de recherche
     └─ GvvGuiTree       moteur générique des 3 arbres + outils des arbres (gvv_trees-*)
GvvGuiElement        constructeur de descriptions d'éléments (chaînable)
```

**Conventions GUI** (gvv, repris de RitnLib) :
- noms `gui_name-type-name` (ex. `gvv_main-button-close`), aucun des trois morceaux ne contient `-` ;
- action = `type-name[-évènement]` → méthode via `self.gui_action` ; données dynamiques dans `element.tags` ;
- **aucune référence d'élément GUI dans `storage`** (depuis 3.7) ;
- **arbres** : une seule classe `GvvGuiTree(event, "storage"|"property"|"luaobject")`, les différences d'onglet dans `gui/tree/<onglet>.lua`.

## 6. Flux d'exécution

```
Ctrl+Shift+V / /gvv
  └─ modules/gui.lua (raccourci) ─► GvvGuiMain:toggle ─► open()
        ├─ initData (storage.players[i])
        ├─ fenêtre + barre d'outils + onglets
        ├─ GvvGuiTracking:build, GvvGuiTree.buildTools, GvvGuiSearch:buildButton
        ├─ GvvGuiTree:build  ×3 (storage, property, luaobject)
        └─ GvvGuiHelp:build

Évènement GUI
  └─ modules/gui.lua dispatcher(on_gui_*)  [xpcall : erreur → chat + log avec pile]
        ├─ Tracking, Main, Dialog, Help, Search, GvvGuiTree.fromEvent  (1er qui renvoie true)
        └─ sinon (clic) : clic dans la fenêtre principale → GvvGuiDialog:closeOnMainFocus

Arbre storage d'un mod
  GvvGuiTree:draw ─► config.read ─► remote.call("__<mod>__gvv","storage"|"_G")
                                     └─ (VM du mod) gvv.lua copy_object : copie transportable
```

## 7. Persistance

| Aspect | Statut |
|---|---|
| `storage.players[i]` | réglages, taille, suivi, objets ajoutés, dossiers ouverts, recherche (détail dans le handoff C.5) |
| `storage.meta_data` | version, paramètres, `treelimit`, liste de suivi par défaut, marqueurs n/a / nil / méthode |
| `storage.example` | données de démonstration, réécrites à chaque init / changement de configuration |
| `storage.report` | résultats diagnostic / réparation (aide) |
| `storage` du mod **hôte** | `gvv.lua` `c()` y range ses arguments le temps de l'appel (`storage[#storage+1]`) |
| `script.register_metatable` | aucun |
| Références GUI dans `storage` | aucune (retirées en 3.7, nettoyées par la migration 0.6.0) |

## 8. Évènements

- `on_init`, `on_load`, `on_configuration_changed` ([`modules/events.lua`](https://github.com/x2605/gvv/blob/0fbb93a/modules/events.lua)) ;
- 8 évènements GUI + 2 custom inputs ([`modules/gui.lua:118-157`](https://github.com/x2605/gvv/blob/0fbb93a/modules/gui.lua#L118)) ;
- `on_player_created` ([`modules/player.lua:27`](https://github.com/x2605/gvv/blob/0fbb93a/modules/player.lua#L27)) ;
- `on_runtime_mod_setting_changed` ([`modules/commands.lua:217`](https://github.com/x2605/gvv/blob/0fbb93a/modules/commands.lua#L217)) ;
- **`on_tick` hors event_handler** : `script.on_event` direct, posé ou retiré selon `storage.meta_data["enable-on-tick"]`,
  rétabli en `on_load` (`modules/events.lua:69,108`, `modules/commands.lua:158,165`).
- Aucun `on_nth_tick`, aucun custom event.

## 9. Interfaces remote

**Exposée** (dans la VM de chaque mod qui charge `gvv.lua`) : `__<mod>__gvv` — [`gvv.lua:165`](https://github.com/x2605/gvv/blob/0fbb93a/gvv.lua#L165)

| Fonction | Rôle | Consommateurs |
|---|---|---|
| `storage()` | copie transportable du `storage` du mod | gvv (arbre storage, suivi, `/gdump*`) |
| `_G()` | copie du `_G` du mod (fonctions de base exclues) | gvv (arbre storage, racine `_G`) |
| `diag()` / `fix()` | entrées non transmissibles ; `fix` les **supprime** | gvv (onglet aide) |
| `c(code, ...)` | exécute du Lua dans le mod | gvv (aide, exemples), console |
| `version()` | `"8"` | — |

Mods qui chargent `gvv.lua` (vérifié par grep) : RitnLib (`control.lua:4`), helmod (`src/control.lua:1`) ; chemin
référencé par RitnTeleportation (`defines.lua:22`) et RitnLib (`defines.lua:98`). GuiEditor dépend de `gvv >= 0.4`
et utilise ses icônes (`GuiEditor/core/defines.lua:95`).

**Consommées** : les mêmes fonctions chez les autres mods (`gui/tree/storage.lua:104-106`, `GvvGuiTree.readFullPath`,
`modules/commands.lua:52,68`, `lualib/common/doctor.lua:22`) ; liste des mods lisibles via `remote.interfaces`
(`lualib/common/util.lua:9-14`).

## 10. APIs Factorio touchées

| Surface | Where | Usage |
|---|---|---|
| `remote.add_interface` / `call` / `interfaces` | gvv.lua, gui/tree, commands, doctor, util | fournisseur + lecture des autres mods |
| `script.on_event(on_tick)` | modules/events, commands | suivi |
| `commands.add_command` | modules/commands | 5 commandes |
| `LuaGuiElement` (`add`, `tags`, `scroll_to_element`, `auto_center`) | classes/, gui/ | toute l'interface |
| `settings.global` | events, commands | 3 paramètres |
| `loadstring` | suivi, readFullPath, luaobject, gvv.lua | code utilisateur, objets globaux |
| `helpers.is_valid_sprite_path` | lualib/common/sprite | icônes des objets |
| `localised_print`, `serpent` | commands, GvvPlayer | sortie console |

## 11. Dette / erreurs résiduelles (synthèse)

- Propriétés des objets Lua (`lualib/common/luaobj_prop.lua`) : `"<unknown>"` au lieu de n/a, `and value or true` →
  défaut confirmé (identique en 0.5.21), prévu 0.6.1 : [`docs/work/luaobj-properties.md`](work/luaobj-properties.md).
- `on_tick` enregistré hors event_handler (risque si un module ajoute un jour `on_tick`).
- Effets mineurs : variables de session globales, `storage.players` et `opened_data` jamais purgés.
- Détail et classification : handoff §C.6.

## 12. Sortie attendue post-refactor

| Version | Vague | Contenu |
|---|---|---|
| 0.6.0 | restructuration | architecture Ritn (étapes 1 à 4) — fait |
| 0.6.1 | correctifs | propriétés des objets Lua (marqueurs n/a / nil, valeurs, enrichissement via runtime-api.json) |
| — | doc | annotations LuaLS (skill 2), doc bilingue (skill 3) |

## Historique

| Date | Version pin | Changement |
|---|---|---|
| 2026-10-28 | 0.6.0 | Document initial (audit après la restructuration 0.6) |
