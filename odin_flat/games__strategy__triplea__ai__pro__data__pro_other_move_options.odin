package game

Pro_Other_Move_Options :: struct {
	max_move_map: map[^Territory]^Pro_Territory,
	move_maps:    map[^Territory][dynamic]^Pro_Territory,
}

pro_other_move_options_new :: proc() -> ^Pro_Other_Move_Options {
	self := new(Pro_Other_Move_Options)
	self.max_move_map = make(map[^Territory]^Pro_Territory)
	self.move_maps = make(map[^Territory][dynamic]^Pro_Territory)
	return self
}

pro_other_move_options_new_with_moves :: proc(
	move_map_list: [dynamic]map[^Territory]^Pro_Territory,
	player:        ^Game_Player,
	is_attacker:   bool,
) -> ^Pro_Other_Move_Options {
	self := new(Pro_Other_Move_Options)
	self.max_move_map = pro_other_move_options_new_max_move_map(move_map_list, player, is_attacker)
	self.move_maps = pro_other_move_options_new_move_maps(move_map_list)
	return self
}

pro_other_move_options_get_max :: proc(self: ^Pro_Other_Move_Options, t: ^Territory) -> ^Pro_Territory {
	return self.max_move_map[t]
}

pro_other_move_options_get_all :: proc(self: ^Pro_Other_Move_Options, t: ^Territory) -> [dynamic]^Pro_Territory {
	if t in self.move_maps {
		return self.move_maps[t]
	}
	return make([dynamic]^Pro_Territory)
}

pro_other_move_options_lambda_new_move_maps_0 :: proc(key: ^Territory) -> [dynamic]^Pro_Territory {
	return make([dynamic]^Pro_Territory)
}

pro_other_move_options_new_move_maps :: proc(move_map_list: [dynamic]map[^Territory]^Pro_Territory) -> map[^Territory][dynamic]^Pro_Territory {
	result := make(map[^Territory][dynamic]^Pro_Territory)
	for move_map in move_map_list {
		for t, pro_terr in move_map {
			if !(t in result) {
				result[t] = pro_other_move_options_lambda_new_move_maps_0(t)
			}
			list := result[t]
			append(&list, pro_terr)
			result[t] = list
		}
	}
	return result
}

pro_other_move_options_new_max_move_map :: proc(
	move_maps:   [dynamic]map[^Territory]^Pro_Territory,
	player:      ^Game_Player,
	is_attacker: bool,
) -> map[^Territory]^Pro_Territory {
	result := make(map[^Territory]^Pro_Territory)
	players := pro_utils_get_other_players_in_turn_order(player)
	defer delete(players)
	land_pred, land_ctx := matches_unit_is_land()
	empty_units := make([dynamic]^Unit)
	defer delete(empty_units)

	for move_map in move_maps {
		for t, pro_territory in move_map {
			current_units := make(map[^Unit]struct {})
			for u in pro_territory_get_max_units(pro_territory) {
				current_units[u] = {}
			}
			for u in pro_territory_get_max_amphib_units(pro_territory) {
				current_units[u] = {}
			}
			if len(current_units) == 0 {
				delete(current_units)
				continue
			}

			move_player: ^Game_Player
			for u in current_units {
				move_player = unit_get_owner(u)
				break
			}

			if game_player_is_allied(player, move_player) &&
			   !pro_utils_is_players_turn_first(players, move_player, territory_get_owner(t)) {
				delete(current_units)
				continue
			}

			if !(t in result) {
				result[t] = pro_territory
			} else {
				pro_result := result[t]
				max_units := make(map[^Unit]struct {})
				for u in pro_territory_get_max_units(pro_result) {
					max_units[u] = {}
				}
				for u in pro_territory_get_max_amphib_units(pro_result) {
					max_units[u] = {}
				}

				max_strength := 0.0
				if len(max_units) > 0 {
					max_units_list := make([dynamic]^Unit)
					defer delete(max_units_list)
					for u in max_units {
						append(&max_units_list, u)
					}
					max_strength = pro_battle_utils_estimate_strength(t, max_units_list, empty_units, is_attacker)
				}

				current_units_list := make([dynamic]^Unit)
				defer delete(current_units_list)
				for u in current_units {
					append(&current_units_list, u)
				}
				current_strength := pro_battle_utils_estimate_strength(t, current_units_list, empty_units, is_attacker)

				current_has_land_units := false
				for u in current_units {
					if land_pred(land_ctx, u) {
						current_has_land_units = true
						break
					}
				}
				max_has_land_units := false
				for u in max_units {
					if land_pred(land_ctx, u) {
						max_has_land_units = true
						break
					}
				}
				delete(max_units)

				t_is_water := territory_is_water(t)
				if (current_has_land_units &&
					   ((!max_has_land_units && !t_is_water) || current_strength > max_strength)) ||
				   ((!max_has_land_units || t_is_water) && current_strength > max_strength) {
					result[t] = pro_territory
				}
			}
			delete(current_units)
		}
	}
	return result
}

