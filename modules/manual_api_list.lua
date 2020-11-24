--수동입력 manual input
--some LuaObjects without .help() method
--base 1.1

-- https://lua-api.factorio.com/latest/index.html
-- 에서 복사해와서 정규식 [(][^()]*[)]으로 괄호내용 등을 없앰
-- 추가 테이블 포맷 : https://lua-api.factorio.com/latest/Concepts.html

local list = {


LuaGameViewSettings = [[

show_controller_gui [RW]
show_minimap [RW]
show_research_info [RW]
show_entity_info [RW]
show_alert_gui [RW]
update_entity_selection [RW]
show_rail_block_visualisation [RW]
show_side_menu [RW]
show_map_view_options [RW]
show_quickbar [RW]
show_shortcut_bar [RW]
]],


LuaTileProperties = [[

tier_from_start [RW]	
roughness [RW]	
elevation [RW]	
available_water [RW]	
temperature [RW]
]],


LuaMapViewSettings = [[

show-logistic-network [R]
show-electric-network [R]
show-turret-range [R]
show-pollution [R]
show-train-station-names [R]
show-player-names [R]
show-networkless-logistic-members [R]
show-non-standard-map-info [R]
]],


LuaMapSettings = [[

pollution [R]
enabled [R]
diffusion_ratio [R]
min_to_diffuse [R]
ageing [R]
expected_max_per_chunk [R]
min_to_show_per_chunk [R]
min_pollution_to_damage_trees [R]
pollution_with_max_forest_damage [R]
pollution_per_tree_damage [R]
pollution_restored_per_tree_damage [R]
max_pollution_to_restore_trees [R]
enemy_attack_pollution_consumption_modifier [R]
enemy_evolution [R]
enabled [R]
time_factor [R]
destroy_factor [R]
pollution_factor [R]
enemy_expansion [R]
enabled [R]
max_expansion_distance [R]
friendly_base_influence_radius [R]
enemy_building_influence_radius [R]
building_coefficient [R]
other_base_coefficient [R]
neighbouring_chunk_coefficient [R]
neighbouring_base_chunk_coefficient [R]
max_colliding_tiles_coefficient [R]
settler_group_min_size [R]
settler_group_max_size [R]
min_expansion_cooldown [R]
max_expansion_cooldown [R]
unit_group [R]
min_group_gathering_time [R]
max_group_gathering_time [R]
max_wait_time_for_late_members [R]
max_group_radius [R]
min_group_radius [R]
max_member_speedup_when_behind [R]
max_member_slowdown_when_ahead [R]
max_group_slowdown_factor [R]
max_group_member_fallback_factor [R]
member_disown_distance [R]
tick_tolerance_when_member_arrives [R]
max_gathering_unit_groups [R]
max_unit_group_size [R]
steering [R]
default [R]
radius [R]
separation_force [R]
separation_factor [R]
force_unit_fuzzy_goto_behavior [R]
moving [R]
radius [R]
separation_force [R]
separation_factor [R]
force_unit_fuzzy_goto_behavior [R]
path_finder [R]
fwd2bwd_ratio [R]
goal_pressure_ratio [R]
max_steps_worked_per_tick [R]
max_work_done_per_tick [R]
use_path_cache [R]
short_cache_size [R]
long_cache_size [R]
short_cache_min_cacheable_distance [R]
short_cache_min_algo_steps_to_cache [R]
long_cache_min_cacheable_distance [R]
cache_max_connect_to_cache_steps_multiplier [R]
cache_accept_path_start_distance_ratio [R]
cache_accept_path_end_distance_ratio [R]
negative_cache_accept_path_start_distance_ratio [R]
negative_cache_accept_path_end_distance_ratio [R]
cache_path_start_distance_rating_multiplier [R]
cache_path_end_distance_rating_multiplier [R]
stale_enemy_with_same_destination_collision_penalty [R]
ignore_moving_enemy_collision_distance [R]
enemy_with_different_destination_collision_penalty [R]
general_entity_collision_penalty [R]
general_entity_subsequent_collision_penalty [R]
extended_collision_penalty [R]
max_clients_to_accept_any_new_request [R]
max_clients_to_accept_short_new_request [R]
direct_distance_to_consider_short_request [R]
short_request_max_steps [R]
short_request_ratio [R]
min_steps_to_check_path_find_termination [R]
start_to_goal_cost_multiplier_to_terminate_path_find [R]
overload_levels [R]
overload_multipliers [R]
negative_path_cache_delay_interval [R]
max_failed_behavior_count [R]
difficulty_settings [R]
recipe_difficulty [R]
technology_difficulty [R]
technology_price_multiplier [R]
research_queue_setting [R]
]],


LuaDifficultySettings = [[

recipe_difficulty [R]
technology_difficulty [R]
technology_price_multiplier [R]
research_queue_setting [R]
]],



}
for k, v in pairs(list) do
  list[k] = v:gsub(string.char(194), string.char(32))..''
end

return function(name)
  return list[name]
end
