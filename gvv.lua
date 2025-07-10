return function()
-- contents of following line is came from the Helper tab of the mod's GUI.
-- source at __gvv__/modules/copy_code.lua
--  & __gvv__/modules/remote_code/get_g.lua
--  & __gvv__/modules/remote_code/get_global.lua
--  & __gvv__/modules/remote_code/diag_n_fix.lua


  -- Ajoute une interface remote pour interagir avec le mod via remote.call
  -- Add a remote interface to interact with the mod via remote.call
  remote.add_interface("__" .. script.mod_name .. "__gvv", {

    -- Fonction pour retourner le contenu de storage
    -- Function to return the storage contents
    storage = function()
      local root = storage
      local exclude_keys = {}
      local counter = 0
      local result = {}

      -- Classes à exclure du wrapping complet
      -- Classes to exclude from full wrapping
      local exclude_classes = {
        LuaGameScript = true, LuaBootstrap = true, LuaRemote = true,
        LuaCommandProcessor = true, LuaSettings = true, LuaRCON = true,
        LuaRendering = true, LuaLazyLoadedValue = true, LuaCustomTable = true,
        LuaDifficultySettings = true, LuaFlowStatistics = true, LuaPrototypes = true,
        LuaHelpers = true,
      }

      -- Fonction qui crée une copie sûre de l'objet (évite les récursions infinies, remplace userdata/fonctions)
      -- Function that safely copies objects (avoids infinite recursion, replaces userdata/functions)
      local function wrap_object(obj, parents, is_key)
        local obj_type = type(obj)
        local representation

        if obj_type == "userdata" and getmetatable(obj) == "private" and obj.object_name then
          -- Pour les clés ou si explicitement demandé, on met une représentation simplifiée
          -- For keys or explicit cases, use simplified representation
          if is_key or (exclude_classes[obj.object_name] or obj.object_name:match('^LuaMapSettings')) then
            counter = counter + 1
            representation = "<" .. obj.object_name .. counter .. ">"
          else
            representation = obj
          end

        elseif obj_type == "table" then
          if is_key then
            -- Pour les clés tables, on simplifie
            -- Simplify table keys
            counter = counter + 1
            representation = "<table" .. counter .. ">"
          else
            -- Vérifie la récursivité
            -- Check for recursion
            local is_recursive = false
            for _, v in ipairs(parents) do
              if v == obj then
                is_recursive = true
                break
              end
            end
            if is_recursive then
              representation = "<recursive table>"
            else
              representation = {}
              local new_parents = {}
              for i, v in ipairs(parents) do
                new_parents[i] = v
              end
              table.insert(new_parents, obj)
              for k, v in next, obj, nil do
                representation[copy_object(k, new_parents, true)] = copy_object(v, new_parents, false)
              end
            end
          end

        elseif obj_type == "function" or obj_type == "thread" or obj_type == "userdata" or obj_type == "nil" then
          -- Remplacement des types non copiables
          -- Replace non-copyable types
          if is_key then
            counter = counter + 1
            representation = "<" .. obj_type .. counter .. ">"
          else
            representation = "<" .. obj_type .. ">"
          end

        else
          -- Copie directe des valeurs simples
          -- Direct copy for primitive values
          representation = obj
        end

        return representation
      end

      -- Fonction d'encapsulation avec pcall pour sécuriser
      -- Helper function using pcall to secure access
      function copy_object(o, parents, is_key)
        local success, res = pcall(function() return wrap_object(o, parents, is_key) end)
        if success then
          return res
        else
          return { ["<ERROR>"] = "<" .. res .. ">" }
        end
      end

      -- Parcours de storage
      -- Iterate over storage
      for key, value in next, root, nil do
        if not exclude_keys[key] then
          result[copy_object(key, { root }, true)] = copy_object(value, { root }, false)
        end
      end

      return result
    end,

    -- Fonction pour retourner le contenu global (_G)
    -- Function to return global contents (_G)
    _G = function()
      local root = _G
      local exclude_keys = {
        _G = true, assert = true, collectgarbage = true, error = true, getmetatable = true,
        ipairs = true, load = true, loadstring = true, next = true, pairs = true, pcall = true,
        print = true, rawequal = true, rawlen = true, rawget = true, rawset = true, select = true,
        setmetatable = true, tonumber = true, tostring = true, type = true, xpcall = true,
        _VERSION = true, unpack = true, table = true, string = true, bit32 = true, math = true,
        debug = true, serpent = true, log = true, localised_print = true, table_size = true,
        package = true, require = true, storage = true, remote = true, commands = true,
        settings = true, rcon = true, rendering = true, script = true, defines = true, game = true,
        prototypes = true, helpers = true, copy_object = true,
      }
      local counter = 0
      local result = {}

      local exclude_classes = {
        LuaGameScript = true, LuaBootstrap = true, LuaRemote = true,
        LuaCommandProcessor = true, LuaSettings = true, LuaRCON = true,
        LuaRendering = true, LuaLazyLoadedValue = true, LuaCustomTable = true,
        LuaDifficultySettings = true, LuaFlowStatistics = true, LuaPrototypes = true,
        LuaHelpers = true,
      }

      local function wrap_object(obj, parents, is_key)
        local obj_type = type(obj)
        local representation

        if obj_type == "userdata" and getmetatable(obj) == "private" and obj.object_name then
          if is_key or (exclude_classes[obj.object_name] or obj.object_name:match('^LuaMapSettings')) then
            counter = counter + 1
            representation = "<" .. obj.object_name .. counter .. ">"
          else
            representation = obj
          end

        elseif obj_type == "table" then
          if is_key then
            counter = counter + 1
            representation = "<table" .. counter .. ">"
          else
            local is_recursive = false
            for _, v in ipairs(parents) do
              if v == obj then
                is_recursive = true
                break
              end
            end
            if is_recursive then
              representation = "<recursive table>"
            else
              representation = {}
              local new_parents = {}
              for i, v in ipairs(parents) do
                new_parents[i] = v
              end
              table.insert(new_parents, obj)
              for k, v in next, obj, nil do
                representation[copy_object(k, new_parents, true)] = copy_object(v, new_parents, false)
              end
            end
          end

        elseif obj_type == "function" or obj_type == "thread" or obj_type == "userdata" or obj_type == "nil" then
          if is_key then
            counter = counter + 1
            representation = "<" .. obj_type .. counter .. ">"
          else
            representation = "<" .. obj_type .. ">"
          end

        else
          representation = obj
        end

        return representation
      end

      function copy_object(o, parents, is_key)
        local success, res = pcall(function() return wrap_object(o, parents, is_key) end)
        if success then
          return res
        else
          return { ["<ERROR>"] = "<" .. res .. ">" }
        end
      end

      -- Parcours de _G
      -- Iterate over _G
      for key, value in next, root, nil do
        if not exclude_keys[key] then
          result[copy_object(key, { root }, true)] = copy_object(value, { root }, false)
        end
      end

      return result
    end,

    -- Version info
    version = function()
      return "8"
    end
  })
end

