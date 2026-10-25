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
local TOKEN_EMPTY_STRING = ""

-- FR : table.unpack (Lua 5.2, Factorio) ou unpack (Lua 5.1)
-- EN : table.unpack (Lua 5.2, Factorio) or unpack (Lua 5.1)
local unpack_results = table.unpack or unpack
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

---FR : Vrai si la valeur n'est pas nil.
---EN : True if the value is not nil.
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

---FR : Vrai si la valeur est nil ou une chaîne vide.
---EN : True if the value is nil or an empty string.
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
    if default == nil then default = TOKEN_EMPTY_STRING end
    if isEmptyString(value) then return default end
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
    if not isString(str) or not isString(start) then return false end
    return str:sub(1, #start) == start
end


---------------------------------------------------------------------------------------------
-- TABLE
---------------------------------------------------------------------------------------------

---FR : Vrai si la valeur est une table Lua.
---EN : True if the value is a Lua table.
---@param value any
---@return boolean
local function isTable(value)
    return type(value) == "table"
end

---FR : Nombre d'éléments de la table (toutes les clés), -1 si ce n'est pas une table.
---EN : Number of elements in the table (all keys), -1 if it is not a table.
---@param value any
---@return integer
local function length(value)
    if not isTable(value) then return -1 end
    return table_size(value)
end

---FR : Vrai si ce n'est pas une table, ou si la table est vide.
---EN : True if it is not a table, or if the table is empty.
---@param value any
---@return boolean
local function isEmpty(value)
    return length(value) <= 0
end

---FR : Vrai si c'est une table avec au moins un élément.
---EN : True if it is a table with at least one element.
---@param value any
---@return boolean
local function isNotEmpty(value)
    return not isEmpty(value)
end

---FR : Vrai si la table contient la clé.
---EN : True if the table contains the key.
---@param value any
---@param key any
---@return boolean
local function containsKey(value, key)
    if not isTable(value) or key == nil then return false end
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
    if type(value) ~= "userdata" then return false end
    local ok, name = pcall(function() return value.object_name end)
    return ok and isString(name)
end

---FR : Vrai si la valeur est un objet Lua encore utilisable (non détruit).
---EN : True if the value is a Lua object still usable (not destroyed).
---@param value any
---@return boolean
local function isValidLuaObject(value)
    if not isLuaObject(value) then return false end
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
    if isLuaObject(value) then return value.object_name end
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
    if key == nil then return nil end
    local value_type = type(value)
    if value_type ~= "table" and value_type ~= "userdata" then return nil end
    local ok, result = pcall(function() return value[key] end)
    if ok then return result end
    return nil
end

---FR : Suit un chemin de clés depuis root et renvoie la valeur trouvée, ou nil dès qu'une étape manque.
---     from : index du premier élément du chemin à suivre (1 par défaut ; 2 pour les chemins de l'arbre,
---     dont le premier élément est le nom de la racine).
---EN : Follows a path of keys from root and returns the value found, or nil as soon as a step is missing.
---     from : index of the first path element to follow (1 by default; 2 for tree paths,
---     whose first element is the root name).
---@param root any
---@param path table
---@param from? integer
---@return any
local function getPath(root, path, from)
    if not isTable(path) then return nil end
    local value = root
    for index = from or 1, #path do
        value = tryGet(value, path[index])
        if value == nil then return nil end
    end
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
    if type(funcTry) ~= "function" then
        log("[ERROR] > gvv tryCatch(funcTry, funcCatch) : funcTry is not a function")
        return nil
    end
    -- FR : n garde le nombre exact de résultats, même si certains valent nil
    -- EN : n keeps the exact number of results, even if some of them are nil
    local results = pack_results(pcall(funcTry))
    if results[1] then
        return unpack_results(results, 2, results.n)
    end
    log("[ERROR] > " .. tostring(results[2]))
    if type(funcCatch) == "function" then
        return funcCatch(results[2])
    end
    return nil
end


---------------------------------------------------------------------------------------------
local check = {
    -- Constants
    TOKEN_EMPTY_STRING = TOKEN_EMPTY_STRING,
    -- nil
    isNil = isNil,
    isNotNil = isNotNil,
    -- string
    isString = isString,
    isEmptyString = isEmptyString,
    isNotEmptyString = isNotEmptyString,
    defaultValue = defaultValue,
    startsWith = startsWith,
    -- table
    isTable = isTable,
    length = length,
    isEmpty = isEmpty,
    isNotEmpty = isNotEmpty,
    containsKey = containsKey,
    -- Lua objects
    isLuaObject = isLuaObject,
    isValidLuaObject = isValidLuaObject,
    dataType = dataType,
    -- protected access
    tryGet = tryGet,
    getPath = getPath,
    tryCatch = tryCatch,
}
---------------------------------------------------------------------------------------------
return check
