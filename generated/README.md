I've added a sort of fix to gvv:

1. in generated there is the converter script that transform runtime-api.json into runtime-api.lua, it patches some parts to make them accessible and remove unused properties to minimize the size of the mod

2. luaobj_prop/lua now use runtime-api.lua to access LuaObjects

----

J'ai ajouté une sorte de correctif à gvv :

1. Dans le dossier generated, il y a le script converter qui transforme runtime-api.json en runtime-api.lua. Ce script modifie certaines parties pour les rendre accessibles et supprime les propriétés inutilisées afin de minimiser la taille du mod.

2. luaobj_prop/lua utilise maintenant runtime-api.lua pour accéder aux LuaObjects.