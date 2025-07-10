-- Importation du module luaobj_prop qui gère déjà la descente récursive
-- Importing luaobj_prop module that already handles recursive attribute exploration
local get_property_list = require("modules.luaobj_prop")

return function()
-- contents of following line is came from the Helper tab of the mod's GUI.
-- source at __gvv__/modules/copy_code.lua
--  & __gvv__/modules/remote_code/get_g.lua
--  & __gvv__/modules/remote_code/get_global.lua
--  & __gvv__/modules/remote_code/diag_n_fix.lua
remote.add_interface("__" .. script.mod_name .. "__gvv", {
  -- Fonction principale pour sérialiser le storage global
  -- Main function to serialize global storage
  storage = function()
    local global_storage_table = storage
    local serialized_result = {}
    local keys_to_skip = {}

    -- Fonction qui appelle get_property_list en toute sécurité
    -- Function that safely calls get_property_list
    local function serialize_value(value)
      local success, processed = pcall(get_property_list, value, true)
      if success then
        return processed
      else
        return { ["<ERROR>"] = "<" .. tostring(processed) .. ">" }
      end
    end

    -- Parcours du storage et sérialisation clé/valeur
    -- Iterate over storage and serialize keys/values
    for key, val in next, global_storage_table, nil do
      if not keys_to_skip[key] then
        local serialized_key = serialize_value(key)
        local serialized_val = serialize_value(val)
        serialized_result[serialized_key] = serialized_val
      end
    end

    return serialized_result
  end,

  -- Interface globale originale (_G)
  -- Original global interface (_G)
  _G = function()
    return _G
  end,

  -- Diagnostic placeholder (diag)
  diag = function()
    return { message = "Diagnostic not implemented in this clean version." }
  end,

  -- Fonction de correction placeholder (fix)
  fix = function()
    return { message = "Fix not implemented in this clean version." }
  end,

  -- Fonction d'exécution de code (c)
  -- Code runner function
  c = function(code_string, ...)
    local new_index = #storage + 1
    storage[new_index] = table.pack(...)
    local temp_context = setmetatable({}, storage[new_index])
    local success, result = pcall(function()
      assert(loadstring("local arg=storage[" .. new_index .. "] storage[" .. new_index .. "]=nil " .. code_string))()
    end)
    if not success then
      if getmetatable(temp_context) == storage[new_index] then
        storage[new_index] = nil
      end
    end
    return success, result
  end,

  -- Version de l'interface
  -- Interface version
  version = function() return '8' end,
})
end
