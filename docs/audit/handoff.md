---
title: Dossier de passation — gvv
mod: gvv
profile: provider + consumer
factorio_version: "2.1"
pinned_version: 0.6.0
audit_date: 2026-10-28
---

# Dossier de passation — gvv

> Matière pour la skill 2 (annotations LuaLS) et la skill 3 (documentation). Faits vérifiés dans le code
> au commit `0fbb93a` ; `(hypothèse)` / `(à confirmer)` sinon. Vue d'ensemble : [`../architecture.md`](../architecture.md).

## A. Métadonnées & périmètre

- **Profil** : provider (interface `__<mod>__gvv` injectée par `gvv.lua` dans la VM des autres mods) + consumer
  (gvv lit ces interfaces). Outil de débogage, admins seulement en multijoueur. Aucune dépendance (`info.json`).
- **Origine** : créé par x2605 ; repris par Ritn, restructuré en 0.6 (architecture des mods Ritn, autonome sans RitnLib).
- **Arborescence explorée** : tout le dépôt.
- **Zones exclues** :
  - `generated/runtime-api-stable.lua` (6000 lignes, généré depuis `runtime-api.json` 2.1.23 par `generated/*.mjs`) → ni annotation ni doc détaillée, une note d'origine.
  - `generated/*.mjs` : scripts de génération (Node), exclus du zip (`.gitattributes`), hors Lua.
  - `lualib/remote_code/*.lua` : **modèles de texte** (chaînes de code injecté) → annoter seulement le module (fonction renvoyant une chaîne), pas le contenu.
  - `locale/`, `icons/`, `.github/` : hors annotation.
- **Fichiers bilingues** : commentaires FR + EN partout dans le code 0.6 (convention de Ritn).

## B. Pour la skill 2 — surface d'API à annoter (LuaLS)

### B.1 Table des cibles

| Fichier | Symbole | Nature | Hérite de | Accès | Miroir meta-file ? | Statut |
|---|---|---|---|---|---|---|
| `core/defines.lua` | `gvv` / `gvv.defines` | registre global (table) | — | global `_G` | oui (à confirmer : pas de `types/` aujourd'hui) | à annoter |
| `core/class.lua` | factory (`gvv.classFactory`) | module `local…return` | — | `gvv.classFactory` | oui (champ de `gvv`) | partiellement annoté |
| `classes/GvvPlayer.lua` | `GvvPlayer` | classe global `_G` | — | global | oui | partiellement annoté (15 `---@`) |
| `classes/GvvGui.lua` | `GvvGui` | classe global | `GvvPlayer` | global | oui | partiellement annoté (28) |
| `classes/GvvGuiElement.lua` | `GvvGuiElement` | classe global | — | global | oui | partiellement annoté (44) |
| `classes/GvvGuiMain.lua` | `GvvGuiMain` | classe global | `GvvGui` | global | oui | peu annoté (8) |
| `classes/GvvGuiDialog.lua` | `GvvGuiDialog` | classe global | `GvvGui` | global | oui | partiellement annoté (45) |
| `classes/GvvGuiHelp.lua` | `GvvGuiHelp` | classe global | `GvvGui` | global | oui | partiellement annoté (31) |
| `classes/GvvGuiTracking.lua` | `GvvGuiTracking` | classe global | `GvvGui` | global | oui | partiellement annoté (37) |
| `classes/GvvGuiSearch.lua` | `GvvGuiSearch` | classe global | `GvvGui` | global | oui | partiellement annoté (25) |
| `classes/GvvGuiTree.lua` | `GvvGuiTree` | classe global | `GvvGui` | global | oui | partiellement annoté (82) |
| `gui/main.lua`, `dialogs.lua`, `help.lua`, `help_pages.lua`, `tracking.lua`, `search.lua`, `tree.lua` | modules de description | module `local…return` | — | `require(gvv.defines.gui.*)` | non | à annoter |
| `gui/tree/storage.lua`, `property.lua`, `luaobject.lua` | config d'arbre | module (table `config`) | — | `require(gvv.defines.gui.trees.*)` | non (type commun `GvvTreeConfig` à créer) | à annoter |
| `lualib/common/check.lua` | `check` | module | — | `require` | non | annoté (copie RitnLib) |
| `lualib/common/util.lua` | `Util` | module | — | `require` | non | à annoter |
| `lualib/common/table_to_str.lua` | `Table_to_str` | module | — | `require` | non | à annoter |
| `lualib/common/sprite.lua`, `doctor.lua`, `copy_code.lua` | `Sprite`, `Doctor`, `Copy_Code` | modules | — | `require` | non | à annoter |
| `lualib/common/luaobj_prop.lua` | fonction (liste de propriétés) | module renvoyant une fonction | — | `Util.get_property_list` | non | à annoter + ⚠ (C.6) |
| `lualib/api/*.lua` | tables de données | module | — | `require` | non | annoter le type de la table seulement |
| `lualib/remote_code/*.lua` | modèles de code | module renvoyant une fonction → chaîne | — | `require` | non | annoter la signature seulement |
| `modules/*.lua` | modules event_handler | module `{events=…}` | — | `core/modules.lua` | non | à annoter (type commun) |
| `core/migrations.lua` | `{run, isOlder}` | module | — | `require(gvv.defines.migrations)` | non | à annoter |
| `gvv.lua` | fonction d'installation de l'interface | module renvoyant une fonction | — | `require("__gvv__.gvv")()` (autres mods) | non | à annoter ; **aucun global autorisé** |
| `prototypes/*.lua` | data stage | scripts | — | `data.lua` | non | commentaires seulement |

Globals de session (à déclarer dans le meta-file, avec ⚠ effet mineur) : `_initiated_session_`, `_on_tick_function_`,
`_one_of_three_volatiles_executed_`, `_initiated_on_tick_` (`control.lua:10`, `modules/events.lua:22-26`).

### B.2 Détail par classe (matière des `@field` / `@param` / `@return`)

Champs communs (`GvvPlayer`) : `isPresent: boolean`, `player: LuaPlayer`, `index`, `name`, `admin`, `connected`
(copies au moment de la création — **snapshot**). Méthodes : `print(text, color) → self`, `canUseGvv() → boolean`,
`getData() → table?`, `initData() → data, first_time`.

`GvvGui` (+ champs) : `event`, `element: LuaGuiElement?`, `gui_name`, `main_gui`, `gui: LuaGuiElement[]` (`gui[1]` =
conteneur, **rempli par la sous-classe** — contrat d'extension), `content` (chemins), `gui_action` (action → méthode).
Méthodes : `splitName(name)` (statique), `getMainElement`, `getElement(type, name)`, `actionGui`, `dispatch(suffix)`,
`on_gui_*` (renvoient `true` si traité).

Liste complète des méthodes par classe (signatures observées) :
- `GvvGuiElement` (chaînable, renvoie `self` ; `get()` → table de description) : `add, get, horizontal, vertical, autoCenter, visible, enabled, caption, tooltip, index, text, style, spritePath, horizontalScrollPolicy, verticalScrollPolicy, resizeSprite, checked, progress, mouseButtonFilter, tags`.
- `GvvGuiMain` : `isOpen, toggle, open, close(ignore_save), changeTab(tab_index)` + actions.
- `GvvGuiDialog` : `openDump(text, title), openAnycode, openCopy, openEdit, openExport, openImport, closeWithMain, closeOnMainFocus, destroyLegacy` + construction (`buildFrame, addReadOnlyText, addConfirmFooter, addCode`) + actions `confirm*`.
- `GvvGuiHelp` : `build, drawPage(page)`, constructeurs de page (`add, addText, addTitle, addSubtitle, addLine, openRow, openColumn, closeContainer, addCopyable, setCopyableText, addDemo`), `runDoctor(action)` + actions.
- `GvvGuiTracking` : `build(first_time), buildTools, buildTab, fillEntries, drawEntry, add(full_path, preinput), redraw, replaceEntry, importCodes, exportText, refreshValues, onTick` (statique), `updateTickWarning, updateTools` + actions.
- `GvvGuiSearch` : `getEngine, getTree, getPanel, getPart, findTreeName, buildButton, buildPanel, updateTools, refresh(tree_name) → self, run(tree_name) → found[], refreshAll` + actions.
- `GvvGuiTree` : statiques `fromEvent, fromTab, all, readFullPath(full_path), objectCaption, buildTools, changeTab, refreshTab` ; instance `build, fillList, draw(selection), refresh, saveOpened, removeItem, setVisible(kind, state), searchReset, searchScan(state) → boolean`, accès (`getPane, child, rowOf, parentRow, pathOf, readPath, expand, getRoots, getItemButton`) + actions.

**Type à créer** : `GvvTreeConfig` (commun aux 3 fichiers `gui/tree/*.lua`) — champs `gui_name, tab, tab_index, search, opened,
last_selection, prop_allowed, item_buttons, refill_on_tab` ; fonctions `getItems(tree) → {value, caption, tooltip?}[]`,
`getRoots(tree, selection) → {key, caption, bottom_padding}[]`, `read(tree, root_key)`, `isBlocked(tree, path)`,
`fullPath(tree, path)`, optionnelles `forget(tree, item)`, `addObject(tree, key, full_path, caption)` (property).

Avertissements factuels (⚠) à porter :
- `luaobj_prop.lua` : `"<unknown>"` et `add_value and value or true` (C.6).
- `GvvGuiTree.readFullPath` : une étape manquante lève une erreur (voulu, attrapé par l'appelant).
- `gvv.lua` `c()` : écrit temporairement dans le `storage` du mod hôte.
- `GvvPlayer` : champs snapshot, ne pas stocker l'objet.

## C. Pour la skill 3 — matière de documentation

### C.1 Carte des classes

| Classe | Fichier | Rôle | Accès | Hérite de | Description courte |
|---|---|---|---|---|---|
| GvvPlayer | classes/GvvPlayer.lua | wrappe `LuaPlayer` | global | — | joueur + données gvv |
| GvvGui | classes/GvvGui.lua | base fenêtre | global | GvvPlayer | nommage, chemins, aiguillage d'actions |
| GvvGuiElement | classes/GvvGuiElement.lua | description d'élément | global | — | constructeur chaînable de specs `add{}` |
| GvvGuiMain | classes/GvvGuiMain.lua | fenêtre principale | global | GvvGui | ouverture, onglets, taille |
| GvvGuiDialog | classes/GvvGuiDialog.lua | 6 petites fenêtres | global | GvvGui | dump, code, copie, édition, export, import |
| GvvGuiHelp | classes/GvvGuiHelp.lua | onglet aide | global | GvvGui | pages, diagnostic / réparation |
| GvvGuiTracking | classes/GvvGuiTracking.lua | onglet suivi | global | GvvGui | codes réévalués, on_tick |
| GvvGuiSearch | classes/GvvGuiSearch.lua | recherche | global | GvvGui | loupe, panneaux, résultats |
| GvvGuiTree | classes/GvvGuiTree.lua | moteur d'arbres | global | GvvGui | storage / property / LuaObject + outils |

### C.2 Détail par classe publique — exemples réels (sourcés gvv)

- Ouverture : `GvvGuiMain({player_index = data.player_index}):toggle()` — `modules/commands.lua:23`.
- Petite fenêtre : `GvvGuiDialog({player_index = …}):openDump(text, title)` — `modules/commands.lua:90`.
- Arbres : `for _, tree in ipairs(GvvGuiTree.all(self.event)) do tree:build() end` — `classes/GvvGuiMain.lua:233-234` ; outils `GvvGuiTree.buildTools(self.event)` — `classes/GvvGuiMain.lua:226`.
- Ajout au suivi : `GvvGuiTracking(self.event):add(full_path)` — `classes/GvvGuiTree.lua:1335`, `classes/GvvGuiDialog.lua:672`.
- Spec d'élément : `GvvGuiElement(gui_name, "button", "key"):get()` — `gui/tree.lua:73`.
- Droit d'utilisation : `if main:canUseGvv() then main:toggle() end` — `modules/gui.lua:130`.

Pièges : wrappers temporaires (jamais dans `storage`) ; `gui[1]` vaut `nil` si la fenêtre principale est fermée (toutes
les méthodes le tolèrent) ; `require` interdit pendant le jeu (configs préchargées dans `CONFIGS`).

### C.3 Interface remote

| Fonction exposée | Paramètres | Retour | Effets de bord | Consommateurs | Invariants / risques |
|---|---|---|---|---|---|
| `storage` | — | copie du `storage` du mod | aucun | gvv (`gui/tree/storage.lua:106`, `GvvGuiTree.readFullPath`, `modules/commands.lua:52,68`) | objets Lua gardés, fonctions/threads → texte, récursion → `<recursive table>`, clés non transmissibles → `<type_n>`, erreur → `<ERROR>` |
| `_G` | — | copie du `_G` du mod | aucun | gvv (`gui/tree/storage.lua:104`) | fonctions de base exclues (`gvv.lua:191-200`) |
| `diag` | — | chemins non transmissibles | aucun | gvv (`lualib/common/doctor.lua:22`) | modèle `lualib/remote_code/diag_n_fix.lua` |
| `fix` | — | idem | **supprime** ces entrées du `storage` du mod | gvv (aide, bouton « fix ») | destructif, volontaire |
| `c` | `code: string, ...` | `pcall` : `ok, résultat` | exécute du code dans le mod ; arguments rangés temporairement dans `storage[#storage+1]` du mod | aide de gvv, console | code arbitraire (admins) |
| `version` | — | `"8"` | — | — | — |

Mods qui chargent l'interface : RitnLib (`RitnLib/control.lua:4`), helmod (`helmod/src/control.lua:1`) ; chemin référencé
dans RitnTeleportation (`RitnTeleportation/defines.lua:22`) et RitnLib (`RitnLib/defines.lua:98`). GuiEditor : dépend de
`gvv >= 0.4` (`GuiEditor/info.json:11`) et pointe `__gvv__/icons/` (`GuiEditor/core/defines.lua:95`) → **les icônes sont
aussi un contrat**.

Remote calls sortants : les mêmes fonctions chez `level` et chaque mod listé par `remote.interfaces`
(`lualib/common/util.lua:9-14`).

### C.4 Event Map

| Évènement | Handler | Rôle |
|---|---|---|
| `on_init` / `on_load` / `on_configuration_changed` | `modules/events.lua:123-125` | meta_data, données d'exemple, `on_tick`, migrations (`core/migrations.lua`) |
| `on_gui_click`, `closed`, `value_changed`, `confirmed`, `selected_tab_changed`, `checked_state_changed`, `text_changed`, `selection_state_changed` | `modules/gui.lua:118-125` (dispatcher) | classes de fenêtres, dans l'ordre Tracking, Main, Dialog, Help, Search, Tree ; clic non traité → fermeture des petites fenêtres |
| `toggle-main-frame_gvv-mod` (Ctrl+Shift+V) | `modules/gui.lua:128` | ouvrir / fermer |
| `refresh_gvv-mod` (Shift+X) | `modules/gui.lua:138` | rafraîchir l'onglet affiché |
| `on_player_created` | `modules/player.lua:27` | efface `storage.players[i]` |
| `on_runtime_mod_setting_changed` | `modules/commands.lua:217` | active / coupe `on_tick` |
| `on_tick` (dynamique, hors event_handler) | `GvvGuiTracking.onTick` | rafraîchit le suivi à l'intervalle de chaque joueur |
| Commandes | `modules/commands.lua:183-` | `/gvv`, `/gdump`, `/gdump-luaon`, `/gdump-json`, `/gmods` |

Erreurs : chaque gestionnaire GUI est protégé (`xpcall`) → message dans le chat + `[ERROR] gvv GUI` avec la pile dans
`factorio-current.log` (`modules/gui.lua:58-80`).

### C.5 Persistence Map

| Structure | Créée par | Lue / modifiée par | Cycle de vie | Risques |
|---|---|---|---|---|
| `storage.players[i]` | `GvvPlayer:initData` (1re ouverture) | toutes les classes | effacée par `on_player_created` ; jamais pour un joueur supprimé | croissance mineure |
| ↳ `last_width/height`, `show_na/nil/func`, `show_search`, `track_interval_tick`, `search_settings` | initData | Main, Tree, Search, Tracking | permanents | — |
| ↳ `data.tracking_list` | initData / Tracking | Tracking | permanent | codes arbitraires |
| ↳ `data.docked_luaobj` | `gui/tree/property.lua addObject` | property | retiré au clic droit ou si l'objet disparaît | objets Lua (dont éléments GUI) qui deviennent invalides → détectés |
| ↳ `data.opened_data`, `data.opened_root` | GvvGuiTree | GvvGuiTree | jamais purgés | croissance avec chaque mod/objet consulté |
| ↳ `tabs` | GvvGuiMain:open | arbres | remis à zéro à chaque ouverture | — |
| `storage.meta_data` | `modules/events.lua register_meta_data` | partout | permanent | marqueurs `_nil_/_na_/_function_` sans producteur (C.6) |
| `storage.example` | `modules/events.lua example_load` | (démonstration) | réécrit à chaque init / config changée | `game.forces[3]` peut être nil (voulu, démo) |
| `storage.report` | `lualib/common/doctor.lua:32` | aide | effacé par bouton | — |
| `storage[n]` du mod hôte | `gvv.lua c()` | `c()` | le temps de l'appel | entrée résiduelle si erreur avant nettoyage (hypothèse, non observée) |

Aucun `script.register_metatable`. Aucune référence d'élément GUI dans `storage` (depuis 3.7 ; migration 0.6.0 nettoie
`data.gui`, `tree_item_*`, `search`).

### C.6 Classification des défauts

- **Défaut confirmé (prod, identique 0.5.21)** : `lualib/common/luaobj_prop.lua` — lecture impossible → `"<unknown>"`
  (l.~105, ~140) au lieu du marqueur n/a ; `add_value and value or true` (l.~116, ~127) affiche `true` pour `false`/`nil`.
  Cases n/a et nil sans effet. Prévu 0.6.1 : `docs/work/luaobj-properties.md`.
- **Effets de bord mineurs** : 4 variables de session globales dans le `_G` de gvv ; `storage.players` / `opened_*` jamais
  purgés ; `on_tick` posé hors event_handler (conflit si un module déclare un jour `on_tick`).
- **Code beta** : aucun.
- **Résidus 1.x** : aucun trouvé (le code 0.6 utilise `storage`, `helpers`, `prototypes`).
- **Ce qui n'est PAS un bug** :
  - `fix` supprime des données du mod : c'est son rôle ;
  - `c` exécute du code arbitraire : outil admin ;
  - le diagnostic d'un mod sans interface lève « interface is not found » : message attendu (log `[ERROR]` normal) ;
  - `storage.example` avec forces / surfaces possiblement nil : démonstration.

### C.7 Plan de documentation recommandé

1. **Tier 0** : page « Rendre un mod lisible par gvv » (la ligne `require("__gvv__.gvv")()`, interfaces `storage/_G/c`),
   commandes, raccourcis, paramètres.
2. **Tier 1 référence mainteneur** : conventions GUI (nommage, `gui_action`, tags), moteur d'arbres + `GvvTreeConfig`,
   cycle de vie / `on_tick`, migrations.
3. **Tests** : procédure RitnTest (skill `factorio-mod-ritntest`).
- Zones difficiles : `GvvGuiTree` (1366 lignes), `gvv.lua` (copie transportable), modèles `remote_code` (code dans des chaînes).
- À refactorer avant de documenter en détail : `luaobj_prop.lua` (0.6.1).

## D. Questions ouvertes pour Ritn — réponses (2026-10-28)

1. **Meta-file des globals** : créer `types/gvv-globals.lua` et **le garder dans le zip** (les développeurs le récupèrent
   avec le mod).
2. **Liens GitHub** : rester sur `x2605/gvv` (dépôt de x2605, qui a donné les droits à Ritn pour le maintenir).
3. **Doc utilisateur** : le README (page du portail) + l'onglet Helper suffisent ; pas de doc bilingue complète côté
   joueurs. La skill 3 se limite à la doc mainteneur / développeur (à confirmer au lancement de la skill 3).
4. **`version()`** : renvoie la version du code d'interface injecté (« 8 », héritée de x2605, du temps où ce code était
   copié à la main dans le `control.lua` des mods). Aujourd'hui les mods chargent `gvv.lua` depuis gvv lui-même : la
   version est toujours celle du gvv installé, et rien n'appelle `version()`. Proposition : la **garder figée** (des
   copies anciennes peuvent encore exister) et la documenter comme informative (à confirmer).
