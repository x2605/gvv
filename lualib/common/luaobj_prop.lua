--[[
    Module luaobj_prop.lua

    Version avec logs détaillés pour comprendre chaque étape de descente et d'injection.

    Version with detailed logs to understand each traversal and injection step.

    Utilise runtime-api-stable.lua, attribute_type_map.lua et concept_fields.lua
    Uses runtime-api-stable.lua, attribute_type_map.lua, and concept_fields.lua
]]

-- Activer le mode debug (logs détaillés) / Enable debug mode (detailed logs)
-- FR : Nommé debug_mode pour ne pas masquer la bibliothèque Lua debug
-- EN : Named debug_mode so it doesn't hide the Lua debug library
local debug_mode = false

-- Charger runtime_api stable ou latest en fonction de la version de base
-- Load runtime_api stable or latest depending on base version
local runtime_api = require(gvv.defines.generated.runtime_api_stable)
--[[ 
if (script.active_mods.base == "2.0.60") then 
    runtime_api = require(gvv.defines.generated.runtime_api_stable)
else
    runtime_api = require(gvv.defines.generated.runtime_api_latest)
end 
]]

-- Charger les modules de mapping
-- Load mapping modules
local attribute_type_map = require(gvv.defines.lualib.api.attribute_type_map)
local concept_fields = require(gvv.defines.lualib.api.concept_fields)

-- Fonction helper pour log
-- Logging helper function

---**EN**
---
---Description: Writes a message to the log, only when `debug_mode` is on.
---
---──────────────────────────────
---
---**FR**
---
---Description: Écrit un message dans le log, seulement si `debug_mode` est activé.
---@param msg string
local function log_message(msg)
    if debug_mode then log("[luaobj_prop] " .. msg) end
end


-- Nom de classe à utiliser pour une valeur : une table sans object_name reçoit le nom donné.
-- La valeur lue n'est plus modifiée (avant, on lui ajoutait un champ object_name).
-- Class name to use for a value: a table without object_name gets the given name.
-- The read value is no longer modified (it used to get an object_name field added).

---**EN**
---
---Description: Class name to use for a value: a table without object_name gets the given name, otherwise nil.
---
---──────────────────────────────
---
---**FR**
---
---Description: Nom de classe à utiliser pour une valeur : une table sans object_name reçoit le nom donné, sinon nil.
---@param value any
---@param name string
---@return string?
local function class_name_for(value, name)
    if type(value) == "table" and not value.object_name then
        log_message(">>> Class name given: " .. name)
        return name
    end
end


-- Fonction principale récursive pour explorer les propriétés
-- Main recursive function to explore object properties
-- forced_name : nom de classe imposé (table sans object_name) / forced class name (table without object_name)

---**EN**
---
---Description: Lists the properties of a Lua object from the runtime API description (generated/runtime-api-stable.lua),
---recursively for the sub-classes and concepts.
---
---⚠ An unreadable property is written as the text "<unknown>" (not the n/a marker) and
---`add_value and value or true` shows `true` for a `false` or `nil` value. Planned for 0.6.1:
---docs/work/luaobj-properties.md.
---
---──────────────────────────────
---
---**FR**
---
---Description: Liste les propriétés d'un objet Lua d'après la description de l'API runtime (generated/runtime-api-stable.lua),
---récursivement pour les sous-classes et les concepts.
---
---⚠ Une propriété illisible est écrite comme le texte « <unknown> » (pas le marqueur n/a) et
---`add_value and value or true` affiche `true` pour une valeur `false` ou `nil`. Prévu en 0.6.1 :
---docs/work/luaobj-properties.md.
---@param obj any  Lua object, or table with a class name
---@param add_value boolean?  true: values, otherwise `true` for each property
---@param forced_name string?  Class name forced for a table without object_name
---@return table<string, any>
local function alt_prop(obj, add_value, forced_name)
    local result_table = {}

    -- Nom initial d'objet (ex: LuaMapSettings.pollution)
    -- Initial object name (e.g., LuaMapSettings.pollution)
    local object_name = forced_name or obj.object_name
    local base_class = object_name

    -- Correction éventuelle si c'est une sous-classe mapée
    -- Fix if it's a mapped sub-class
    local parent_class, sub_attr = object_name:match("([^%.]+)%.(.+)")
    if parent_class and sub_attr and attribute_type_map[parent_class] then
        local sub_class = attribute_type_map[parent_class][sub_attr]
        if sub_class then
            log_message(">>> Corrected base_class from attribute_type_map: " .. sub_class)
            base_class = sub_class
        end
    elseif string.find(base_class, "%.") then
        -- Fallback si le nom contient un point
        -- Fallback if name contains dot
        base_class = string.match(base_class, "^[^%.]+%.(.+)$")
    end

    local class = runtime_api.classes[base_class]

    -- Si pas trouvé dans runtime_api, vérifier concept_fields
    -- If not found in runtime_api, check concept_fields
    if not class and concept_fields[base_class] then
        log_message("Concept detected directly: " .. base_class)
        local concept_tbl = {}
        for _, field_name in ipairs(concept_fields[base_class]) do
            local ok_field, val_field = pcall(function() return obj[field_name] end)
            log_message("  Field " .. field_name .. ": " .. (ok_field and "OK" or "FAIL"))
            concept_tbl[field_name] = ok_field and (add_value and val_field or true) or "<cannot read>"
        end
        return concept_tbl
    end

    if not class then
        log_message("Unknown class for object_name: " .. tostring(base_class))
        return { ["<unknown>"] = true }
    end

    log_message("Processing class: " .. base_class)

    -- Explorer les attributs
    -- Explore attributes
    for attribute_name, _ in pairs(class.attributes) do
        log_message("  Checking attribute: " .. attribute_name)
        local ok, value = pcall(function() return obj[attribute_name] end)
        result_table[attribute_name] = "<unknown>"

        if ok then
            log_message("    Attribute OK: " .. attribute_name)
            local parent_map = attribute_type_map[base_class]
            local sub_class = parent_map and parent_map[attribute_name]
            log_message(">>>> sub_class: " .. tostring(sub_class))

            if sub_class and type(value) ~= "table" and type(value) ~= "userdata" then
                -- FR : Valeur absente ou simple (nil, nombre...) : rien à explorer
                -- EN : Missing or simple value (nil, number...): nothing to explore
                result_table[attribute_name] = add_value and value or true
            elseif sub_class then
                -- FR : Sous-classe ou concept Factorio : alt_prop gère les deux cas
                --      (runtime_api pour une classe, concept_fields pour un concept)
                -- EN : Factorio sub-class or concept: alt_prop handles both cases
                --      (runtime_api for a class, concept_fields for a concept)
                log_message("    Sub-class or concept: " .. sub_class)
                result_table[attribute_name] = alt_prop(value, add_value, class_name_for(value, sub_class))
            else
                -- Attribut simple
                -- Simple attribute
                result_table[attribute_name] = add_value and value or true
            end
        else
            log_message("    Attribute FAILED: " .. attribute_name)
        end
    end

    -- Copier méthodes
    -- Copy methods
    -- FR : Protégé comme les attributs : sur un objet devenu invalide, la lecture lève une erreur
    -- EN : Protected like attributes: on an object that became invalid, reading raises an error
    for method_name, _ in pairs(class.methods) do
        local ok, method = pcall(function() return obj[method_name] end)
        result_table[method_name] = ok and method or "<unknown>"
    end

    -- Opérateurs spéciaux
    -- Special operators
    if class.operators.call then
        result_table["<callable>"] = true
    end

    if class.operators.index then
        result_table.__index = function() end
        pcall(function()
            for k, v in pairs(obj) do
                result_table[k] = add_value and v or true
            end
        end)
    end

    return result_table
end

-- Pour une table normale (non Factorio)
-- For normal Lua table (not Factorio)

---**EN**
---
---Description: Plain Lua table (not a Factorio object): the table itself, or its keys with `true` as value.
---
---──────────────────────────────
---
---**FR**
---
---Description: Table Lua simple (pas un objet Factorio) : la table elle-même, ou ses clés avec `true` pour valeur.
---@param obj table
---@param add_value boolean?
---@return table
local function normal_table(obj, add_value)
    if add_value then return obj end
    local tbl = {}
    for k in pairs(obj) do
        tbl[k] = true
    end
    return tbl
end

-- Point d'entrée principal
-- Main entry point
return function(obj, add_value)
    if type(obj) == 'userdata' and obj.object_name then
        log_message("Root: userdata with object_name: " .. obj.object_name)
        return alt_prop(obj, add_value)
    elseif type(obj) == 'table' and obj.object_name and runtime_api.classes[obj.object_name] then
        log_message("Root: table with object_name: " .. obj.object_name)
        return alt_prop(obj, add_value)
    elseif type(obj) == 'table' then
        log_message("Root: normal Lua table")
        return normal_table(obj, add_value)
    else
        log_message("Root: unsupported type (" .. type(obj) .. ")")
        return error('Given value is not a table or userdata.')
    end
end
