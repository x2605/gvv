---------------------------------------------------------------------------------------------
-- CHECK
---------------------------------------------------------------------------------------------
-- FR : Source : RitnLib (Ritn), version 0.10.7 :
--        lualib/string-functions.lua : isNil, isNotNil, isString, isEmptyString, isNotEmptyString,
--                                      defaultValue, startsWith
--        lualib/table-functions.lua  : isTable, length, isEmpty, isNotEmpty, containsKey
--        lualib/other-functions.lua  : data_type (ici dataType), tryCatch
--      Copiées et adaptées pour que gvv reste autonome. Aucune ne lève d'erreur,
--      quelle que soit la valeur reçue (nil, objet Lua invalide...).
--      Différences : startsWith sans motif Lua, defaultValue garde nombres et booléens,
--      dataType renvoie "string" pour une chaîne, tryCatch renvoie les résultats.
--      Ajouts propres à gvv : isLuaObject, isValidLuaObject, tryGet, getPath.
-- EN : Source: RitnLib (Ritn), version 0.10.7:
--        lualib/string-functions.lua : isNil, isNotNil, isString, isEmptyString, isNotEmptyString,
--                                      defaultValue, startsWith
--        lualib/table-functions.lua  : isTable, length, isEmpty, isNotEmpty, containsKey
--        lualib/other-functions.lua  : data_type (here dataType), tryCatch
--      Copied and adapted so gvv stays standalone. None of them raises an error,
--      whatever the value received (nil, invalid Lua object...).
--      Differences: startsWith without Lua pattern, defaultValue keeps numbers and booleans,
--      dataType returns "string" for a string, tryCatch returns the results.
--      gvv's own additions: isLuaObject, isValidLuaObject, tryGet, getPath.
---------------------------------------------------------------------------------------------
-- FR : Utilisation : local check = require(gvv.defines.lualib.common.check), puis check.isNil(valeur)...
-- EN : Usage: local check = require(gvv.defines.lualib.common.check), then check.isNil(value)...
---------------------------------------------------------------------------------------------

-- FR : Chaîne vide, valeur par défaut de defaultValue
-- EN : Empty string, default value of defaultValue
local TOKEN_EMPTY_STRING = ""

-- FR : table.unpack (Lua 5.2, Factorio) ou unpack (Lua 5.1) : redonne les valeurs d'une liste
-- EN : table.unpack (Lua 5.2, Factorio) or unpack (Lua 5.1): gives back the values of a list
local unpack_results = table.unpack or unpack

-- FR : Range toutes les valeurs reçues dans une liste, avec leur nombre exact dans n
--      (# ne suffit pas : il s'arrête au premier nil)
-- EN : Stores all received values in a list, with their exact count in n
--      (# is not enough: it stops at the first nil)
local function pack_results(...)
    return {n = select("#", ...), ...}
end


---------------------------------------------------------------------------------------------
-- NIL
---------------------------------------------------------------------------------------------

---FR : Vrai si la valeur est nil.
---EN : True if the value is nil.
---@param value any
---@return boolean
local function isNil(value)
    return value == nil
end

---FR : Vrai si la valeur n'est pas nil (false compris : false n'est pas nil).
---EN : True if the value is not nil (false included: false is not nil).
---@param value any
---@return boolean
local function isNotNil(value)
    return value ~= nil
end


---------------------------------------------------------------------------------------------
-- STRING
---------------------------------------------------------------------------------------------

---FR : Vrai si la valeur est une chaîne de caractères.
---EN : True if the value is a string.
---@param value any
---@return boolean
local function isString(value)
    return type(value) == "string"
end

---FR : Vrai si la valeur est nil ou une chaîne vide. Une chaîne d'espaces n'est pas vide.
---EN : True if the value is nil or an empty string. A string of spaces is not empty.
---@param value any
---@return boolean
local function isEmptyString(value)
    return value == nil or value == TOKEN_EMPTY_STRING
end

---FR : Vrai si la valeur est une chaîne non vide.
---EN : True if the value is a non-empty string.
---@param value any
---@return boolean
local function isNotEmptyString(value)
    return isString(value) and value ~= TOKEN_EMPTY_STRING
end

---FR : Renvoie la valeur, ou la valeur par défaut si elle est nil ou une chaîne vide.
---     Différence avec RitnLib : un nombre ou un booléen est gardé tel quel.
---EN : Returns the value, or the default value if it is nil or an empty string.
---     Difference with RitnLib: a number or a boolean is kept as is.
---@param value any
---@param default? any  Valeur par défaut, "" si absente / Default value, "" if missing
---@return any
local function defaultValue(value, default)
    -- FR : Sans valeur par défaut donnée : chaîne vide
    -- EN : Without a given default value: empty string
    if default == nil then
        default = TOKEN_EMPTY_STRING
    end

    -- FR : Valeur absente ou vide : on renvoie la valeur par défaut
    -- EN : Missing or empty value: return the default value
    if isEmptyString(value) then
        return default
    end

    -- FR : Sinon la valeur elle-même
    -- EN : Otherwise the value itself
    return value
end

---FR : Vrai si la chaîne commence par le texte donné. Le texte est comparé tel quel
---     (différence avec RitnLib : pas de motif Lua, donc ".", "(", "%"... sans effet spécial).
---EN : True if the string starts with the given text. The text is compared as is
---     (difference with RitnLib: no Lua pattern, so ".", "(", "%"... have no special effect).
---@param str any
---@param start any
---@return boolean
local function startsWith(str, start)
    -- FR : Les deux valeurs doivent être des chaînes
    -- EN : Both values must be strings
    if not isString(str) or not isString(start) then
        return false
    end

    -- FR : On compare le début de str (de la longueur de start) avec start
    -- EN : Compare the beginning of str (as long as start) with start
    return str:sub(1, #start) == start
end


---------------------------------------------------------------------------------------------
-- TABLE
---------------------------------------------------------------------------------------------

---FR : Vrai si la valeur est une table Lua (un objet Lua de Factorio n'en est pas une).
---EN : True if the value is a Lua table (a Factorio Lua object is not one).
---@param value any
---@return boolean
local function isTable(value)
    return type(value) == "table"
end

---FR : Nombre d'éléments de la table (toutes les clés, pas seulement 1, 2, 3...), -1 si ce n'est pas une table.
---EN : Number of elements in the table (all keys, not only 1, 2, 3...), -1 if it is not a table.
---@param value any
---@return integer
local function length(value)
    -- FR : Pas une table : -1
    -- EN : Not a table: -1
    if not isTable(value) then
        return -1
    end

    -- FR : table_size (fourni par Factorio) compte toutes les clés
    -- EN : table_size (provided by Factorio) counts all keys
    return table_size(value)
end

---FR : Vrai si ce n'est pas une table, ou si la table est vide.
---EN : True if it is not a table, or if the table is empty.
---@param value any
---@return boolean
local function isEmpty(value)
    -- FR : length vaut -1 (pas une table) ou 0 (table vide)
    -- EN : length is -1 (not a table) or 0 (empty table)
    return length(value) <= 0
end

---FR : Vrai si c'est une table avec au moins un élément.
---EN : True if it is a table with at least one element.
---@param value any
---@return boolean
local function isNotEmpty(value)
    return not isEmpty(value)
end

---FR : Vrai si la table contient la clé (même si sa valeur est false).
---EN : True if the table contains the key (even if its value is false).
---@param value any
---@param key any
---@return boolean
local function containsKey(value, key)
    -- FR : Pas une table, ou clé nil (impossible dans une table Lua) : non
    -- EN : Not a table, or nil key (impossible in a Lua table): no
    if not isTable(value) or key == nil then
        return false
    end

    -- FR : rawget lit la table sans passer par une éventuelle métatable
    -- EN : rawget reads the table without going through a possible metatable
    return rawget(value, key) ~= nil
end


---------------------------------------------------------------------------------------------
-- LUA OBJECTS (Factorio)
---------------------------------------------------------------------------------------------

---FR : Vrai si la valeur est un objet Lua de Factorio (LuaEntity, LuaPlayer...), valide ou non.
---EN : True if the value is a Factorio Lua object (LuaEntity, LuaPlayer...), valid or not.
---@param value any
---@return boolean
local function isLuaObject(value)
    -- FR : Les objets Lua de Factorio sont des userdata
    -- EN : Factorio Lua objects are userdata
    if type(value) ~= "userdata" then
        return false
    end

    -- FR : Un objet Lua a un object_name (ex. « LuaEntity ») ; lecture protégée au cas où
    -- EN : A Lua object has an object_name (e.g. "LuaEntity"); protected read just in case
    local ok, name = pcall(function() return value.object_name end)
    return ok and isString(name)
end

---FR : Vrai si la valeur est un objet Lua encore utilisable (non détruit).
---EN : True if the value is a Lua object still usable (not destroyed).
---@param value any
---@return boolean
local function isValidLuaObject(value)
    -- FR : Pas un objet Lua : non
    -- EN : Not a Lua object: no
    if not isLuaObject(value) then
        return false
    end

    -- FR : valid vaut false quand l'objet a été détruit (entité minée, joueur supprimé...)
    -- EN : valid is false when the object was destroyed (mined entity, removed player...)
    local ok, valid = pcall(function() return value.valid end)
    return ok and valid ~= false
end

---FR : Type de la valeur : le nom de classe pour un objet Lua (« LuaEntity »), sinon type() (« table », « nil »...).
---     Différence avec RitnLib : une chaîne renvoie bien « string ».
---EN : Type of the value: the class name for a Lua object ("LuaEntity"), otherwise type() ("table", "nil"...).
---     Difference with RitnLib: a string does return "string".
---@param value any
---@return string
local function dataType(value)
    -- FR : Objet Lua : son nom de classe
    -- EN : Lua object: its class name
    if isLuaObject(value) then
        return value.object_name
    end

    -- FR : Sinon le type Lua
    -- EN : Otherwise the Lua type
    return type(value)
end


---------------------------------------------------------------------------------------------
-- PROTECTED ACCESS / ACCÈS PROTÉGÉ
---------------------------------------------------------------------------------------------

---FR : Lit value[key] sans jamais lever d'erreur (nil, objet invalide, clé inconnue d'un objet Lua...).
---EN : Reads value[key] without ever raising an error (nil, invalid object, unknown key of a Lua object...).
---@param value any
---@param key any
---@return any  nil si la lecture est impossible / nil if reading is impossible
local function tryGet(value, key)
    -- FR : Clé nil : rien à lire
    -- EN : nil key: nothing to read
    if key == nil then
        return nil
    end

    -- FR : Seules les tables et les userdata (objets Lua) se lisent avec [key]
    -- EN : Only tables and userdata (Lua objects) can be read with [key]
    local value_type = type(value)
    if value_type ~= "table" and value_type ~= "userdata" then
        return nil
    end

    -- FR : Lecture protégée : un objet invalide ou une clé inconnue lève une erreur, ici rattrapée
    -- EN : Protected read: an invalid object or an unknown key raises an error, caught here
    local ok, result = pcall(function() return value[key] end)
    if ok then
        return result
    end

    -- FR : Lecture impossible
    -- EN : Reading impossible
    return nil
end

---FR : Suit un chemin de clés depuis root et renvoie la valeur trouvée, ou nil dès qu'une étape manque.
---     from : index du premier élément du chemin à suivre (1 par défaut ; 2 pour les chemins de l'arbre,
---     dont le premier élément est le nom de la racine).
---     Ex. getPath(storage, {"players", 1, "data"}) lit storage.players[1].data.
---EN : Follows a path of keys from root and returns the value found, or nil as soon as a step is missing.
---     from : index of the first path element to follow (1 by default; 2 for tree paths,
---     whose first element is the root name).
---     E.g. getPath(storage, {"players", 1, "data"}) reads storage.players[1].data.
---@param root any
---@param path table
---@param from? integer
---@return any
local function getPath(root, path, from)
    -- FR : Pas de chemin : rien à suivre
    -- EN : No path: nothing to follow
    if not isTable(path) then
        return nil
    end

    -- FR : On part de root et on lit chaque clé du chemin, l'une après l'autre
    -- EN : Start from root and read each key of the path, one after the other
    local value = root
    for index = from or 1, #path do
        value = tryGet(value, path[index])

        -- FR : Étape manquante : on s'arrête
        -- EN : Missing step: stop
        if value == nil then
            return nil
        end
    end

    -- FR : Valeur au bout du chemin
    -- EN : Value at the end of the path
    return value
end

---FR : Exécute funcTry dans un pcall et renvoie ses résultats. En cas d'erreur, l'écrit dans le log,
---     puis appelle funcCatch(message) s'il est donné et renvoie ses résultats.
---     Différence avec RitnLib : les résultats sont renvoyés, et funcCatch reçoit le message d'erreur.
---EN : Runs funcTry inside a pcall and returns its results. On error, writes it to the log,
---     then calls funcCatch(message) if given and returns its results.
---     Difference with RitnLib: results are returned, and funcCatch receives the error message.
---@param funcTry function
---@param funcCatch? fun(message: string): ...
---@return ...
local function tryCatch(funcTry, funcCatch)
    -- FR : funcTry doit être une fonction : sinon on le note dans le log
    -- EN : funcTry must be a function: otherwise it is written to the log
    if type(funcTry) ~= "function" then
        log("[ERROR] > gvv tryCatch(funcTry, funcCatch) : funcTry is not a function")
        return nil
    end

    -- FR : Exécution protégée. results[1] : succès ou non ; puis les résultats ou le message d'erreur.
    --      n garde le nombre exact de résultats, même si certains valent nil
    -- EN : Protected run. results[1]: success or not; then the results or the error message.
    --      n keeps the exact number of results, even if some of them are nil
    local results = pack_results(pcall(funcTry))

    -- FR : Succès : on renvoie les résultats de funcTry (tout sauf results[1])
    -- EN : Success: return funcTry's results (everything except results[1])
    if results[1] then
        return unpack_results(results, 2, results.n)
    end

    -- FR : Erreur : écrite dans le log
    -- EN : Error: written to the log
    log("[ERROR] > " .. tostring(results[2]))

    -- FR : Puis funcCatch, qui reçoit le message d'erreur, s'il est donné
    -- EN : Then funcCatch, which receives the error message, if given
    if type(funcCatch) == "function" then
        return funcCatch(results[2])
    end
    return nil
end

---------------------------------------------------------------------------------------------
-- FR : Fonctions exportées
-- EN : Exported functions
local check = {
    -- FR : Constantes / EN : Constants
    TOKEN_EMPTY_STRING = TOKEN_EMPTY_STRING,
    -- FR : nil / EN : nil
    isNil = isNil,
    isNotNil = isNotNil,
    -- FR : chaînes / EN : strings
    isString = isString,
    isEmptyString = isEmptyString,
    isNotEmptyString = isNotEmptyString,
    defaultValue = defaultValue,
    startsWith = startsWith,
    -- FR : tables / EN : tables
    isTable = isTable,
    length = length,
    isEmpty = isEmpty,
    isNotEmpty = isNotEmpty,
    containsKey = containsKey,
    -- FR : objets Lua / EN : Lua objects
    isLuaObject = isLuaObject,
    isValidLuaObject = isValidLuaObject,
    dataType = dataType,
    -- FR : accès protégé / EN : protected access
    tryGet = tryGet,
    getPath = getPath,
    tryCatch = tryCatch,
}
---------------------------------------------------------------------------------------------
return check
