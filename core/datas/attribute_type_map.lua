--[[
  Ce fichier définit explicitement le mapping entre les attributs d'une classe mère Factorio
  et leur type exact (classe enfant) pour gérer correctement la descente récursive.

  This file explicitly defines the mapping between a Factorio parent class's attributes
  and their exact type (child class), to properly handle recursive attribute walking.

  Utilisé dans luaobj_prop.lua
  Used in luaobj_prop.lua
]]

local attribute_type_map = {
  LuaMapSettings = {
    pollution = "PollutionMapSettings",
    asteroids = "AsteroidMapSettings",
    enemy_expansion = "EnemyExpansionMapSettings",
    enemy_evolution = "EnemyEvolutionMapSettings",
    path_finder = "PathFinderMapSettings",
    steering = "SteeringMapSetting",
    unit_group = "UnitGroupMapSettings",
  },
  -- Tu peux ajouter ici d'autres classes mères et mappings si besoin
  -- You can add other parent classes and mappings here if needed
}

return attribute_type_map
