package game

Pro_Non_Combat_Move_Ai :: struct {
	calc:               ^Pro_Odds_Calculator,
	pro_data:           ^Pro_Data,
	data:               ^Game_Data,
	player:             ^Game_Player,
	unit_territory_map: map[^Unit]^Territory,
	territory_manager:  ^Pro_Territory_Manager,
}

pro_non_combat_move_ai_combined_stream :: proc(
	units1: [dynamic]^Unit,
	units2: [dynamic]^Unit,
	allocator := context.allocator,
) -> [dynamic]^Unit {
	combined := make([dynamic]^Unit, 0, len(units1) + len(units2), allocator)
	for u in units1 {
		append(&combined, u)
	}
	for u in units2 {
		append(&combined, u)
	}
	return combined
}

pro_non_combat_move_ai_new :: proc(ai: ^Abstract_Pro_Ai, allocator := context.allocator) -> ^Pro_Non_Combat_Move_Ai {
	self := new(Pro_Non_Combat_Move_Ai, allocator)
	self.calc = abstract_pro_ai_get_calc(ai)
	self.pro_data = abstract_pro_ai_get_pro_data(ai)
	return self
}

pro_non_combat_move_ai_can_hold :: proc(
	self: ^Pro_Non_Combat_Move_Ai,
	move_map: map[^Territory]^Pro_Territory,
	t: ^Territory,
) -> bool {
	// Note: move_map[t] may be null if none of our units can get there this turn,
	// but this function is used in BFS that looks at potential paths over many moves.
	pro_territory, ok := move_map[t]
	return ok && pro_territory != nil && pro_territory_is_can_hold(pro_territory)
}

pro_non_combat_move_ai_can_potentially_be_transported :: proc(
	self: ^Pro_Non_Combat_Move_Ai,
	unit_territory: ^Territory,
) -> bool {
	transport_map_list := pro_my_move_options_get_transport_list(
		pro_territory_manager_get_defend_options(self.territory_manager),
	)
	for pad in transport_map_list {
		for t, inner in pro_transport_get_transport_map(pad) {
			if unit_territory in inner {
				return true
			}
		}
		for t, inner in pro_transport_get_sea_transport_map(pad) {
			if unit_territory in inner {
				return true
			}
		}
	}
	return false
}

// Lambda: moveAlliedCarriedFighters  fighters -> to.getTempUnits().addAll(fighters)
pro_non_combat_move_ai_lambda__move_allied_carried_fighters__11 :: proc(
	to: ^Pro_Territory,
	fighters: [dynamic]^Unit,
) {
	for f in fighters {
		append(&to.temp_units, f)
	}
}

// Lambda: moveUnitsToBestTerritories  e -> !e.getValue().isCanHold()
pro_non_combat_move_ai_lambda__move_units_to_best_territories__9 :: proc(
	key: ^Territory,
	value: ^Pro_Territory,
) -> bool {
	return !pro_territory_is_can_hold(value)
}

