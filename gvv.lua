--[[
  gvv.lua - Global Variable Viewer Remote Interface

  Ce fichier définit une interface remote pour inspecter et copier en toute sécurité 
  les variables globales et le storage d'un mod Factorio via remote.call.

  This file defines a remote interface to safely inspect and copy
  global variables and storage of a Factorio mod via remote.call.

  Compatible avec la protection stricte des globals (_ENV) utilisée dans certains mods.
  Compatible with strict global (_ENV) protections used in some mods.

  Version: 0.5.12+
  Auteur original : x2605, maintenu par Ritn
  Original author: x2605, maintained by Ritn
]]

local wrap_object -- forward declaration


-- Classes à exclure du wrapping complet
-- Classes to exclude from full wrapping
local exclude_classes = {
  LuaGameScript = true, LuaBootstrap = true, LuaRemote = true,
  LuaCommandProcessor = true, LuaSettings = true, LuaRCON = true,
  LuaRendering = true, LuaLazyLoadedValue = true, LuaCustomTable = true,
  LuaDifficultySettings = true, LuaFlowStatistics = true, LuaPrototypes = true,
  LuaHelpers = true, LuaDebugAdapter = true,
}


-- copy_object :
-- FR : Fonction qui encapsule la copie d'un objet en utilisant pcall pour éviter les erreurs.
--      Elle appelle wrap_object et capture toute erreur éventuelle.
-- EN : Function that wraps object copying using pcall to avoid runtime errors.
--      It calls wrap_object and safely catches any possible errors.
local function copy_object(o, parents, is_key, counters)
  local success, res = pcall(function() return wrap_object(o, parents, is_key, counters) end)
  if success then
    return res
  else
    return { ["<ERROR>"] = "<" .. res .. ">" }
  end
end

-- key_name :
-- FR : Nom texte d'une clé non copiable, numéroté par type dans la table : <table_1>, <table_2>, <LuaEntity_1>...
--      counters : compteurs propres à la table parcourue, pour garder des clés uniques.
-- EN : Text name of a non-copyable key, numbered per type within the table: <table_1>, <table_2>, <LuaEntity_1>...
--      counters : counters of the table being copied, to keep keys unique.
local function key_name(counters, name)
  counters[name] = (counters[name] or 0) + 1
  return "<" .. name .. "_" .. counters[name] .. ">"
end

-- wrap_object :
-- FR : Fonction principale qui crée une copie sûre d'un objet Lua.
--      - Évite les cycles en vérifiant la récursivité (parents).
--      - Remplace les clés ou valeurs non copiables (function, userdata, thread, nil) par une représentation texte.
--      - Pour les userdata Factorio, si c’est une clé ou une classe exclue, remplace par un tag.
-- EN : Main function that creates a safe copy of a Lua object.
--      - Avoids cycles by checking recursion (parents).
--      - Replaces non-copyable keys or values (function, userdata, thread, nil) with text representation.
--      - For Factorio userdata, if it's a key or an excluded class, replaces it with a tag.
function wrap_object(obj, parents, is_key, counters)
  local obj_type = type(obj)
  local representation

  if obj_type == "userdata" and getmetatable(obj) == "private" and obj.object_name then
    -- FR : Si clé ou classe exclue, on simplifie. Les clés sont numérotées, pas les valeurs.
    -- EN : If key or excluded class, simplify. Keys are numbered, values are not.
    if is_key then
      representation = key_name(counters, obj.object_name)
    elseif exclude_classes[obj.object_name] or obj.object_name:match('^LuaMapSettings') then
      representation = "<" .. obj.object_name .. ">"
    else
      representation = obj
    end

  elseif obj_type == "table" then
    if is_key then
      -- FR : Simplification pour les clés qui sont des tables.
      -- EN : Simplify table keys.
      representation = key_name(counters, "table")
    else
      -- FR : Vérifie la récursivité pour éviter les boucles infinies.
      -- EN : Check recursion to avoid infinite loops.
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
        local new_counters = {}
        for k, v in next, obj, nil do
          representation[copy_object(k, new_parents, true, new_counters)] = copy_object(v, new_parents, false)
        end
      end
    end

  elseif obj_type == "function" or obj_type == "thread" or obj_type == "userdata" or obj_type == "nil" then
    -- FR : Remplace les types non copiables.
    -- EN : Replace non-copyable types.
    if is_key then
      representation = key_name(counters, obj_type)
    else
      representation = "<" .. obj_type .. ">"
    end

  else
    -- FR : Valeurs simples copiées directement.
    -- EN : Simple values copied directly.
    representation = obj
  end

  return representation
end




-- diag, fix, c :
-- FR : Construites à partir des modèles du code de console (lualib/remote_code), pour n'avoir qu'une
--      seule source : le code collé dans la console et cette interface font exactement la même chose.
--      Ces fonctions avaient disparu de cette interface lors de sa réécriture en 0.5.x : le diagnostic
--      et le nettoyage de l'onglet aide échouaient (« function "diag" ... is not found »).
--      Le code est chargé dans l'environnement du mod qui charge gvv : il lit donc le storage de ce mod.
-- EN : Built from the console code templates (lualib/remote_code), to have a single source:
--      the code pasted in the console and this interface do exactly the same thing.
--      These functions had disappeared from this interface when it was rewritten in 0.5.x: the help tab
--      diagnosis and fixing failed ("function "diag" ... is not found").
--      The code is loaded in the environment of the mod that loads gvv: it reads that mod's storage.
local diag_n_fix_code = require("__gvv__.lualib.remote_code.diag_n_fix")
local lua_command_code = require("__gvv__.lualib.remote_code.lua_command")

-- FR : Transforme un modèle « =function() ... end, » en fonction utilisable
-- EN : Turns a "=function() ... end," template into a usable function
local function functionFromTemplate(template)
  local code = template:gsub('^%s*=', 'return ', 1)
  code = code:gsub(',%s*$', '')
  return assert(loadstring(code))()
end


return function()
-- contents of following line is came from the Helper tab of the mod's GUI.
-- source at __gvv__/lualib/common/copy_code.lua
--  & __gvv__/lualib/remote_code/get_g.lua
--  & __gvv__/lualib/remote_code/get_global.lua
--  & __gvv__/lualib/remote_code/diag_n_fix.lua


  -- Ajoute une interface remote pour interagir avec le mod via remote.call
  -- Add a remote interface to interact with the mod via remote.call
  remote.add_interface("__" .. script.mod_name .. "__gvv", {

    -- Fonction pour retourner le contenu de storage
    -- Function to return the storage contents
    storage = function()
      local root = storage
      local exclude_keys = {}
      local counters = {}
      local result = {}

      -- Parcours de storage
      -- Iterate over storage
      for key, value in next, root, nil do
        if not exclude_keys[key] then
          result[copy_object(key, { root }, true, counters)] = copy_object(value, { root }, false)
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
      local counters = {}
      local result = {}

      -- Parcours de _G
      -- Iterate over _G
      for key, value in next, root, nil do
        if not exclude_keys[key] then
          result[copy_object(key, { root }, true, counters)] = copy_object(value, { root }, false)
        end
      end

      return result
    end,

    -- FR : Diagnostic du storage : chemins des entrées que remote.call ne peut pas transmettre
    -- EN : Storage diagnosis: paths of the entries that remote.call cannot send
    diag = functionFromTemplate(diag_n_fix_code('')),

    -- FR : Nettoyage du storage : comme diag, mais supprime ces entrées
    -- EN : Storage fixing: like diag, but removes these entries
    fix = functionFromTemplate(diag_n_fix_code('b[k]=nil')),

    -- FR : Exécute du code Lua dans ce mod : remote.call("__<mod>__gvv", "c", code, ...)
    -- EN : Runs Lua code in this mod: remote.call("__<mod>__gvv", "c", code, ...)
    c = functionFromTemplate(lua_command_code()),

    -- Version info
    version = function()
      return "8"
    end
  })
end
