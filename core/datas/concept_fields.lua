--[[
  Ce fichier définit explicitement les champs des "LuaStruct" Factorio (concepts),
  pour permettre de descendre proprement dans les structures non introspectables.

  This file explicitly defines the fields of Factorio "LuaStruct" (concepts),
  to allow correct recursive exploration of non-introspectable structures.

  Utilisé dans luaobj_prop.lua
  Used in luaobj_prop.lua
]]

local concept_fields = {
  PollutionMapSettings = {
    "enabled",
    "diffusion_ratio",
    "min_to_diffuse",
    "ageing",
    "expected_max_per_chunk",
    "min_to_show_per_chunk",
    "min_pollution_to_damage_trees",
    "pollution_with_max_forest_damage",
    "pollution_per_tree_damage",
    "pollution_restored_per_tree_damage",
    "max_pollution_to_restore_trees",
    "enemy_attack_pollution_consumption_modifier"
  },

  EnemyExpansionMapSettings = {
    "enabled",
    "max_expansion_distance",
    "friendly_base_influence_radius",
    "enemy_building_influence_radius",
    "building_coefficient",
    "other_base_coefficient",
    "neighbouring_chunk_coefficient",
    "neighbouring_base_chunk_coefficient",
    "max_colliding_tiles_coefficient",
    "settler_group_min_size",
    "settler_group_max_size",
    "min_expansion_cooldown",
    "max_expansion_cooldown"
  },

  UnitGroupMapSettings = {
    "min_group_radius",
    "max_group_radius",
    "min_group_gathering_time",
    "max_group_gathering_time",
    "max_wait_time_for_late_members",
    "max_gathering_unit_groups",
    "max_unit_group_size",
    "min_group_radius",
    "max_group_slowdown_factor",
    "max_member_speedup_when_behind",
    "max_member_slowdown_when_ahead",
    "max_group_member_fallback_factor",
    "member_disown_distance",
    "tick_tolerance_when_member_arrives"
  },

  SteeringMapSetting = {
    "radius",
    "separation_force",
    "separation_factor",
    "force_unit_fuzzy_goto_behavior"
  },

  PathFinderMapSettings = {
    "fwd2bwd_ratio",
    "goal_pressure_ratio",
    "max_clients_to_accept_any_new_request",
    "max_clients_to_accept_short_new_request",
    "max_steps_worked_per_tick",
    "max_work_done_per_tick",
    "short_request_max_steps",
    "short_request_ratio",
    "min_steps_to_check_path_find_termination",
    "start_to_goal_cost_multiplier_to_terminate_path_find",
    "overload_levels",
    "overload_multipliers",
    "negative_path_cache_delay_interval",
    "cache_accept_path_start_distance_ratio",
    "cache_accept_path_end_distance_ratio",
    "cache_path_start_distance_rating_multiplier",
    "cache_path_end_distance_rating_multiplier",
    "cache_max_connect_to_cache_steps_multiplier",
    "short_cache_size",
    "short_cache_min_cacheable_distance",
    "short_cache_min_algo_steps_to_cache",
    "long_cache_size",
    "long_cache_min_cacheable_distance",
    "direct_distance_to_consider_short_request",
    "stale_enemy_with_same_destination_collision_penalty",
    "enemy_with_different_destination_collision_penalty",
    "general_entity_collision_penalty",
    "general_entity_subsequent_collision_penalty",
    "extended_collision_penalty",
    "ignore_moving_enemy_collision_distance",
    "use_path_cache"
  },

  AsteroidMapSettings = {
    "spawning_rate",
    "max_ray_portals_expanded_per_tick"
  },

  EnemyEvolutionMapSettings = {
    "enabled",
    "time_factor",
    "destroy_factor",
    "pollution_factor"
  }
}

return concept_fields
