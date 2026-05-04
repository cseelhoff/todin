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

// Lambda: moveUnitsToDefendTerritories  proTransport -> proTransport.getTransport().equals(u)
pro_non_combat_move_ai_lambda__move_units_to_defend_territories__4 :: proc(
	u: ^Unit,
	pro_transport: ^Pro_Transport,
) -> bool {
	return pro_transport_get_transport(pro_transport) == u
}

// Lambda: moveUnitsToDefendTerritories  proTransport -> proTransport.getTransport().equals(u)
pro_non_combat_move_ai_lambda__move_units_to_defend_territories__5 :: proc(
	u: ^Unit,
	pro_transport: ^Pro_Transport,
) -> bool {
	return pro_transport_get_transport(pro_transport) == u
}

// Lambda: moveUnitsToBestTerritories  t -> canHold(moveMap, t)
pro_non_combat_move_ai_lambda__move_units_to_best_territories__6 :: proc(
	self: ^Pro_Non_Combat_Move_Ai,
	move_map: map[^Territory]^Pro_Territory,
	t: ^Territory,
) -> bool {
	return pro_non_combat_move_ai_can_hold(self, move_map, t)
}

// Lambda: moveUnitsToBestTerritories  proTransport -> proTransport.getTransport().equals(u)
pro_non_combat_move_ai_lambda__move_units_to_best_territories__7 :: proc(
	u: ^Unit,
	pro_transport: ^Pro_Transport,
) -> bool {
	return pro_transport_get_transport(pro_transport) == u
}

// Lambda: moveUnitsToBestTerritories  proTransport -> proTransport.getTransport().equals(u)
pro_non_combat_move_ai_lambda__move_units_to_best_territories__8 :: proc(
	u: ^Unit,
	pro_transport: ^Pro_Transport,
) -> bool {
	return pro_transport_get_transport(pro_transport) == u
}

// Lambda: moveConsumablesToFactories  t -> canHold(moveMap, t)
pro_non_combat_move_ai_lambda__move_consumables_to_factories__13 :: proc(
	self: ^Pro_Non_Combat_Move_Ai,
	move_map: map[^Territory]^Pro_Territory,
	t: ^Territory,
) -> bool {
	return pro_non_combat_move_ai_can_hold(self, move_map, t)
}

// Lambda: findDestinationOrSafeTerritoryOnTheWay  t -> canHold(moveMap, t)
pro_non_combat_move_ai_lambda__find_destination_or_safe_territory_on_the_way__16 :: proc(
	self: ^Pro_Non_Combat_Move_Ai,
	move_map: map[^Territory]^Pro_Territory,
	t: ^Territory,
) -> bool {
	return pro_non_combat_move_ai_can_hold(self, move_map, t)
}

// games.strategy.triplea.ai.pro.ProNonCombatMoveAi#checkCanHold(games.strategy.triplea.ai.pro.data.ProTerritory)
pro_non_combat_move_ai_check_can_hold :: proc(
	self: ^Pro_Non_Combat_Move_Ai,
	pro_territory: ^Pro_Territory,
) -> bool {
	if !pro_territory_is_can_hold(pro_territory) {
		return false
	}

	// Check if territory is safe after all current moves
	if pro_territory_get_battle_result(pro_territory) == nil {
		pro_territory_set_battle_result(
			pro_territory,
			pro_odds_calculator_calculate_battle_results(self.calc, self.pro_data, pro_territory),
		)
	}
	result := pro_territory_get_battle_result(pro_territory)
	if pro_battle_result_get_win_percentage(result) >= self.pro_data.min_win_percentage ||
	   pro_battle_result_get_tuv_swing(result) > 0 {
		pro_territory_set_can_hold(pro_territory, false)
		return false
	}
	return true
}

// games.strategy.triplea.ai.pro.ProNonCombatMoveAi#moveAlliedCarriedFighters(Unit, ProTerritory)
pro_non_combat_move_ai_move_allied_carried_fighters :: proc(
	self: ^Pro_Non_Combat_Move_Ai,
	u: ^Unit,
	to: ^Pro_Territory,
) {
	carrier_p, carrier_c := matches_unit_is_carrier()
	if carrier_p(carrier_c, u) {
		unit_territory := self.unit_territory_map[u]
		carrier_must_move_with := move_validator_carrier_must_move_with_territory(
			unit_territory,
			self.player,
		)
		if fighters, ok := carrier_must_move_with[u]; ok {
			pro_non_combat_move_ai_lambda__move_allied_carried_fighters__11(to, fighters)
		}
	}
}

