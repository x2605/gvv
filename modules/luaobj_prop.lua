--[[
    Module luaobj_prop.lua

    Version avec logs détaillés pour comprendre chaque étape de descente et d'injection.

    Version with detailed logs to understand each traversal and injection step.

    Utilise runtime-api-stable.lua, attribute_type_map.lua et concept_fields.lua
    Uses runtime-api-stable.lua, attribute_type_map.lua, and concept_fields.lua
]]

-- Activer le mode debug (logs détaillés) / Enable debug mode (detailed logs)
local debug = false

-- Charger runtime_api stable ou latest en fonction de la version de base
-- Load runtime_api stable or latest depending on base version
local runtime_api = {}
if (script.active_mods.base == "2.0.55") then 
    runtime_api = require('generated.runtime-api-stable')
else
    runtime_api = require('generated.runtime-api-latest')
end

-- Charger les modules de mapping
-- Load mapping modules
local attribute_type_map = require("modules.attribute_type_map")
local concept_fields = require("modules.concept_fields")

-- Fonction helper pour log
-- Logging helper function
local function log_message(msg)
    if debug then log("[luaobj_prop] " .. msg) end
end


-- Injecter object_name si nécessaire
-- Inject object_name if needed
local function inject_object_name(value, name)
    if type(value) == "table" and not value.object_name then
        value.object_name = name
        log_message(">>> Injected object_name: " .. name)
    end
end


-- Fonction principale récursive pour explorer les propriétés
-- Main recursive function to explore object properties
local function alt_prop(obj, add_value)
    local result_table = {}

    -- Nom initial d'objet (ex: LuaMapSettings.pollution)
    -- Initial object name (e.g., LuaMapSettings.pollution)
    local object_name = obj.object_name
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

            if sub_class then
                if runtime_api.classes[sub_class] then
                    -- Cas sous-classe Factorio
                    -- Factorio sub-class case
                    log_message("    Sub-class detected: " .. sub_class)
                    inject_object_name(value, sub_class)
                    result_table[attribute_name] = alt_prop(value, add_value)

                elseif concept_fields[sub_class] then
                    -- Cas concept Factorio
                    -- Factorio concept case
                    log_message("    Concept detected: " .. sub_class)
                    inject_object_name(value, sub_class)

                    local concept_tbl = {}
                    for _, field_name in ipairs(concept_fields[sub_class]) do
                        local ok_field, val_field = pcall(function() return value[field_name] end)
                        log_message("      Field " .. field_name .. ": " .. (ok_field and "OK" or "FAIL"))
                        concept_tbl[field_name] = ok_field and (add_value and val_field or true) or "<cannot read>"
                    end

                    result_table[attribute_name] = alt_prop(value, add_value)
                else
                    -- Fallback générique
                    -- Generic fallback
                    log_message("    Sub-class fallback: " .. sub_class)
                    inject_object_name(value, sub_class)
                    result_table[attribute_name] = alt_prop(value, add_value)
                end
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
    for method_name, _ in pairs(class.methods) do
        result_table[method_name] = obj[method_name]
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
