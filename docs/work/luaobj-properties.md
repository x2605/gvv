# Propriétés des objets Lua : affichage à corriger et à enrichir

> Tâche à prévoir **après la migration 0.6** (étape 3.7 et suivantes), probablement en **0.6.1**.
> Idée notée le 2026-10-27, à partir des tests en jeu avec RitnTest.

## Constat

Dans les onglets **property** et **LuaObject**, deux défauts, **identiques en 0.5.21 publiée et en 0.6**
(comparés par captures d'écran : ce ne sont pas des régressions de la restructuration) :

| Objet | Affiché | Attendu |
|---|---|---|
| `LuaGuiElement` (un `frame`) | `allow_decimal = "<unknown>"`, `anchor = "<unknown>"`... | ligne grise **n/a**, cachable par la case n/a |
| `game` (`LuaGameScript`) | `finished = true`, `player = true` | `finished = false`, `player = nil` (ligne nil, cachable par la case nil) |

Conséquence : les cases **n/a** et **nil** de la barre d'outils ne font plus rien (plus aucune ligne ne porte
leurs marqueurs) ; seule la case **method** marche encore (les méthodes sont de vraies fonctions).
Certaines valeurs affichées sont fausses, ce qui est gênant pour un outil de débogage.

## Cause

Fichier : `lualib/common/luaobj_prop.lua` (liste des propriétés d'un objet Lua).

- **`"<unknown>"`** (ligne ~105) : chaque attribut reçoit d'abord le texte `"<unknown>"` ; si la lecture
  échoue (propriété qui ne s'applique pas à cet objet, ex. `allow_decimal` sur un `frame`), il reste ce texte.
  L'arbre l'affiche comme une valeur normale (chaîne).
- **`= true`** (lignes ~116 et ~127) : piège Lua `add_value and value or true` : si `value` vaut `false` ou
  `nil`, l'expression donne `true`.
- Les méthodes dont la lecture échoue reçoivent aussi `"<unknown>"` (ligne ~140).

Historique : le code d'origine (x2605, jusqu'à fin 2024) renvoyait des **marqueurs**, des tables avec une
métatable de `storage.meta_data`, que l'arbre sait toujours afficher (`classes/GvvGuiTree.lua`, `drawItems`) :

| Marqueur | Cas | Affichage |
|---|---|---|
| `storage.meta_data._na_` | lecture impossible | ligne grise « n/a », case n/a |
| `storage.meta_data._nil_` | valeur `nil` | ligne « nil », case nil |
| `storage.meta_data._function_` | méthode | ligne grise `nom(...)`, case method |

Ils ont disparu avec la réécriture pour Factorio 2.0 (commit `b342f69`, « implement LuaObjects logic »,
2024-10-27). Depuis la 2.0, le jeu ne permet plus de lister les propriétés d'un objet : gvv utilise
`runtime-api.json` converti en Lua (`generated/runtime-api-stable.lua`, par `generated/converter.mjs` et
`shortener.mjs`, actuellement version 2.1.23). Ce fichier n'est **pas** la cause des deux défauts : la liste
des propriétés est juste, c'est leur traitement dans `luaobj_prop.lua` qui l'est moins.

## Limite : pas de JSON « dynamique » en jeu

Un mod ne peut lire aucun fichier : `require` ne charge que des `.lua` des mods, et `helpers` sait écrire
(`write_file`) mais pas lire. Impossible donc de lire `doc-html/runtime-api.json` de la version chargée.
Seule voie : **générer le Lua hors du jeu** (script existant) à partir du JSON de la version visée.
Un écart de version a peu d'effet : une propriété nouvelle manque dans la liste, une propriété retirée
échoue à la lecture (donc n/a).

## Ce que le JSON permet (vérifié sur le 2.1.23)

Champs utiles que la conversion jette aujourd'hui :

- `subclasses` : types concernés par une propriété. Ex. `LuaGuiElement.allow_decimal` → `["textfield"]`.
- `optional` : la valeur peut être `nil`. Ex. `LuaGuiElement.anchor`, `LuaGameScript.player`.
- `read_type` / `write_type` : type de la valeur ; une propriété sans `read_type` est en écriture seule.
  Ex. `LuaGameScript.finished` → `boolean`, `player` → `LuaPlayer` (optionnel).
- Paramètres et retours des méthodes (signatures).

## Plan proposé

### Partie 1 : retrouver le comportement d'origine (correctif)

- `luaobj_prop.lua` : lecture impossible → marqueur `_na_` ; valeur `nil` → marqueur `_nil_` ;
  méthode → fonction (ou `_function_`) ; corriger `add_value and value or true`
  (tester `add_value` d'abord, puis garder la valeur telle quelle, `false` compris).
- Vérifier les cases n/a, nil et method sur `game` et sur un `LuaGuiElement`.

### Partie 2 : afficher mieux que « n/a » (ce qu'on lit directement)

1. **Valeurs `defines` en clair** : `direction = defines.direction.east (4)` (type `defines.*` du JSON).
2. **n/a avec la raison** : `allow_decimal  n/a (textfield seulement)` (`subclasses`), toujours grisé et
   cachable par la case n/a.
3. **Écriture seule** : `écriture seule` au lieu d'un échec de lecture (pas de `read_type`).

### Partie 3 : confort

4. **Infobulle de la clé** : type et caractère optionnel (`anchor : GuiAnchor (optionnel)`) ; un `nil` sur
   une propriété obligatoire devient un signal.
5. **Signature des méthodes** : `get_inventory(inventory: defines.inventory) → LuaInventory?`
   (au moins en infobulle).
6. **Lien vers la doc** en infobulle : `lua-api.factorio.com/<version>/classes/<Classe>.html#<propriété>`
   (pas cliquable, mais recopiable).

## Coût et points d'attention

- Le fichier généré grossit : garder types, `subclasses`, `optional`, signatures ; **ne pas** garder les
  descriptions complètes (l'essentiel des 2 Mo du JSON), le lien vers la doc les remplace.
- Modifier `generated/converter.mjs` / `shortener.mjs` pour garder ces champs, puis régénérer.
- `luaobj_prop.lua` doit transmettre ces informations, et l'arbre (`GvvGuiTree:drawItems`) les afficher
  (ligne grisée avec raison, infobulle). Les tags des lignes (`kind`) servent déjà aux cases n/a, nil, method.

## Tests

Avec RitnTest (en jeu, par RCON) :

- onglet LuaObject → `game` : `finished`, `player`, nombre de lignes n/a, nil et méthodes, effet des cases ;
- onglet property → un `LuaGuiElement` (`frame`) : lignes n/a (avec la raison en partie 2) ;
- une entité (direction → `defines.direction`) ;
- captures d'écran avant / après, et comparaison avec la 0.5.21.
