--수동입력 manual input
--some LuaObjects without .help() method
--base 1.0

-- https://lua-api.factorio.com/latest/index.html
-- 에서 복사해와서 정규식 [(][^()]*[)]으로 괄호내용 등을 없앰
-- 추가 테이블 포맷 : https://lua-api.factorio.com/latest/Concepts.html

local list = {


LuaBootstrap = [[

on_init()
on_load()
on_configuration_changed()
on_event()
on_nth_tick()
register_on_entity_destroyed()
generate_event_name()
get_event_handler()
get_event_order()
set_event_filter()
get_event_filter()
raise_event()
raise_console_chat()
raise_player_crafted_item()
raise_player_fast_transferred()
raise_biter_base_built()
raise_market_item_purchased()
raise_script_built()
raise_script_destroy()
raise_script_revive()
raise_script_set_tiles()
mod_name [R]
active_mods [R]
is_game_in_debug_mode [R]
object_name [R]
]],


LuaRemote = [[

add_interface()
remove_interface()
call()
object_name [R]
interfaces [R]
]],


LuaCommandProcessor = [[

add_command()
remove_command()
commands [R]
game_commands [R]
object_name [R]
]],


LuaSettings = [[

get_player_settings()
object_name [R]
startup [R]
global [R]
player [R]
]],


LuaRCON = [[

print()
object_name [R]
]],


LuaRendering = [[

draw_line() 
draw_text() 
draw_circle() 
draw_rectangle() 
draw_arc() 
draw_polygon() 
draw_sprite() 
draw_light() 
draw_animation() 
destroy()
is_font_valid() 
is_valid() 
get_all_ids() 
clear()
get_type() 
bring_to_front()
get_surface() 
get_time_to_live() 
set_time_to_live()
get_forces() 
set_forces()
get_players() 
set_players()
get_visible() 
set_visible()
get_draw_on_ground() 
set_draw_on_ground()
get_only_in_alt_mode() 
set_only_in_alt_mode()
get_color() 
set_color()
get_width() 
set_width()
get_from() 
set_from()
get_to() 
set_to()
get_dash_length() 
set_dash_length()
get_gap_length() 
set_gap_length()
set_dashes()
get_target() 
set_target()
get_orientation() 
set_orientation()
get_scale() 
set_scale()
get_text() 
set_text()
get_font() 
set_font()
get_alignment() 
set_alignment()
get_scale_with_zoom() 
set_scale_with_zoom()
get_filled() 
set_filled()
get_radius() 
set_radius()
get_left_top() 
set_left_top()
get_right_bottom() 
set_right_bottom()
set_corners()
get_max_radius() 
set_max_radius()
get_min_radius() 
set_min_radius()
get_start_angle() 
set_start_angle()
get_angle() 
set_angle()
get_vertices() 
set_vertices()
get_sprite() 
set_sprite()
get_x_scale() 
set_x_scale()
get_y_scale() 
set_y_scale()
get_render_layer() 
set_render_layer()
get_orientation_target() 
set_orientation_target()
get_oriented_offset() 
set_oriented_offset()
get_intensity() 
set_intensity()
get_minimum_darkness() 
set_minimum_darkness()
get_oriented() 
set_oriented()
get_animation() 
set_animation()
get_animation_speed() 
set_animation_speed()
get_animation_offset() 
set_animation_offset()
object_name [R]
]],


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
max_failed_behavior_count [R]
difficulty_settings  [R]
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
