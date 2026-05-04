package game

import "core:fmt"

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

// games.strategy.triplea.ai.pro.ProNonCombatMoveAi#findInfraUnitsThatCanMove()
pro_non_combat_move_ai_find_infra_units_that_can_move :: proc(
	self: ^Pro_Non_Combat_Move_Ai,
) -> map[^Unit]map[^Territory]struct {} {
	pro_logger_info("Find non-combat infra units that can move")

	unit_move_map := pro_my_move_options_get_unit_move_map(
		pro_territory_manager_get_defend_options(self.territory_manager),
	)

	infra_unit_move_map := make(map[^Unit]map[^Territory]struct {})

	moved_p, moved_c := pro_matches_unit_can_be_moved_and_is_owned(self.player)
	infra_p, infra_c := matches_unit_is_infrastructure()

	to_remove: [dynamic]^Unit
	defer delete(to_remove)
	for u, ts in unit_move_map {
		if moved_p(moved_c, u) && infra_p(infra_c, u) {
			infra_unit_move_map[u] = ts
			pro_logger_trace(
				fmt.tprintf(
					"%s is infra unit with move options: %v",
					unit_to_string_no_owner(u),
					ts,
				),
			)
			append(&to_remove, u)
		}
	}
	unit_move_map_mut := unit_move_map
	for u in to_remove {
		delete_key(&unit_move_map_mut, u)
	}
	return infra_unit_move_map
}

// games.strategy.triplea.ai.pro.ProNonCombatMoveAi#moveOneDefenderToLandTerritoriesBorderingEnemy()
pro_non_combat_move_ai_move_one_defender_to_land_territories_bordering_enemy :: proc(
	self: ^Pro_Non_Combat_Move_Ai,
) -> [dynamic]^Territory {
	pro_logger_info("Determine which territories to defend with one land unit")

	move_map := pro_my_move_options_get_territory_map(
		pro_territory_manager_get_defend_options(self.territory_manager),
	)
	unit_move_map := pro_my_move_options_get_unit_move_map(
		pro_territory_manager_get_defend_options(self.territory_manager),
	)

	territories_to_defend_with_one_unit := make([dynamic]^Territory)
	allied_p, allied_c := pro_matches_unit_is_allied_land_and_not_infra(self.player)
	enemies := pro_utils_get_potential_enemy_players(self.player)
	defer delete(enemies)
	has_neighbor_p, has_neighbor_c := pro_matches_territory_has_neighbor_owned_by_and_has_land_unit(
		game_data_get_map(self.data),
		enemies,
	)

	for t, pt in move_map {
		if territory_is_water(t) {
			continue
		}
		has_allied_land_units := false
		for u in pro_territory_get_cant_move_units(pt) {
			if allied_p(allied_c, u) {
				has_allied_land_units = true
				break
			}
		}
		if !has_allied_land_units && has_neighbor_p(has_neighbor_c, t) {
			append(&territories_to_defend_with_one_unit, t)
		}
	}

	sorted_unit_move_options := pro_sort_move_options_utils_sort_unit_move_options(
		self.pro_data,
		unit_move_map,
	)

	land_p, land_c := matches_unit_is_land()
	has_units_p, has_units_c := matches_territory_has_units_owned_by(self.player)

	unit_move_map_mut := unit_move_map
	for unit, ts in sorted_unit_move_options {
		if !land_p(land_c, unit) {
			continue
		}
		for t in ts {
			unit_value := pro_data_get_unit_value(self.pro_data, unit_get_type(unit))
			production := territory_attachment_static_get_production(t)

			t_idx := -1
			for tt, i in territories_to_defend_with_one_unit {
				if tt == t {
					t_idx = i
					break
				}
			}
			if t_idx >= 0 &&
			   (unit_value <= production + 3 || has_units_p(has_units_c, t)) {
				pro_territory_add_unit(move_map[t], unit)
				delete_key(&unit_move_map_mut, unit)
				ordered_remove(&territories_to_defend_with_one_unit, t_idx)
				pro_logger_debug(
					fmt.tprintf(
						"%s, added one land unit: %s",
						territory_to_string(t),
						unit_to_string_no_owner(unit),
					),
				)
				break
			}
		}
		if len(territories_to_defend_with_one_unit) == 0 {
			break
		}
	}

	return territories_to_defend_with_one_unit
}

// games.strategy.triplea.ai.pro.ProNonCombatMoveAi#buildFactoryMoveMap(java.util.Map,java.util.Map)
pro_non_combat_move_ai_build_factory_move_map :: proc(
	self: ^Pro_Non_Combat_Move_Ai,
	move_map: map[^Territory]^Pro_Territory,
	infra_unit_move_map: map[^Unit]map[^Territory]struct {},
) -> map[^Territory]^Pro_Territory {
	factory_move_map := make(map[^Territory]^Pro_Territory)

	can_produce_p, can_produce_c := matches_unit_can_produce_units()
	not_conquered_p, not_conquered_c := pro_matches_territory_is_not_conquered_owned_land(self.player)
	can_produce_infra_p, can_produce_infra_c := matches_unit_can_produce_units_and_is_infrastructure()

	to_remove: [dynamic]^Unit
	defer delete(to_remove)

	for u, ts in infra_unit_move_map {
		if !can_produce_p(can_produce_c, u) {
			continue
		}

		max_value_territory: ^Territory = nil
		max_value: f64 = 0
		for t in ts {
			pro_territory := move_map[t]
			if !pro_non_combat_move_ai_check_can_hold(self, pro_territory) {
				continue
			}

			production := territory_attachment_static_get_production(t)
			value := 0.1 * pro_territory_get_value(pro_territory)

			has_factory := false
			for cu in pro_territory_get_cant_move_units(pro_territory) {
				if can_produce_infra_p(can_produce_infra_c, cu) {
					has_factory = true
					break
				}
			}
			if !has_factory {
				for cu in pro_territory_get_units(pro_territory) {
					if can_produce_infra_p(can_produce_infra_c, cu) {
						has_factory = true
						break
					}
				}
			}

			if not_conquered_p(not_conquered_c, t) && !has_factory {
				value =
					pro_territory_get_value(pro_territory) * f64(production) +
					0.01 * f64(production)
			}

			pro_logger_trace(
				fmt.tprintf(
					"%s has value=%v, strategicValue=%v, production=%v",
					territory_to_string(t),
					value,
					pro_territory_get_value(pro_territory),
					production,
				),
			)

			if value > max_value {
				max_value = value
				max_value_territory = t
			}
		}
		if max_value_territory != nil {
			ut_name := default_named_get_name(&unit_get_type(u).named_attachable.default_named)
			pro_logger_debug(
				fmt.tprintf(
					"%s moved to %s with value=%v",
					ut_name,
					territory_to_string(max_value_territory),
					max_value,
				),
			)
			pro_territory_add_unit(move_map[max_value_territory], u)
			pro_territory_add_unit(
				pro_data_get_pro_territory(self.pro_data, factory_move_map, max_value_territory),
				u,
			)
			append(&to_remove, u)
		}
	}

	infra_map_mut := infra_unit_move_map
	for u in to_remove {
		delete_key(&infra_map_mut, u)
	}
	return factory_move_map
}

// games.strategy.triplea.ai.pro.ProNonCombatMoveAi#logAttackMoves(java.util.List)
pro_non_combat_move_ai_log_attack_moves :: proc(
	self: ^Pro_Non_Combat_Move_Ai,
	prioritized_territories: [dynamic]^Pro_Territory,
) {
	move_map := pro_my_move_options_get_territory_map(
		pro_territory_manager_get_defend_options(self.territory_manager),
	)

	pro_logger_debug("Prioritized territories:")
	for ptd in prioritized_territories {
		pro_logger_trace(
			fmt.tprintf(
				"  %v  %s",
				pro_territory_get_value(ptd),
				territory_to_string(pro_territory_get_territory(ptd)),
			),
		)
	}

	pro_logger_debug("Territories that can be attacked:")
	count := 0
	for t, pt in move_map {
		count += 1
		pro_logger_trace(fmt.tprintf("%d. ---%s", count, territory_to_string(t)))

		combined := make(map[^Unit]struct {})
		for u in pro_territory_get_max_units(pt) {
			combined[u] = {}
		}
		for u in pro_territory_get_max_amphib_units(pt) {
			combined[u] = {}
		}
		for u in pro_territory_get_cant_move_units(pt) {
			combined[u] = {}
		}

		pro_logger_trace("  --- My max units ---")
		print_map := make(map[string]i32)
		for u in combined {
			k := unit_to_string_no_owner(u)
			print_map[k] = print_map[k] + 1
		}
		for k, v in print_map {
			pro_logger_trace(fmt.tprintf("    %d %s", v, k))
		}
		delete(print_map)
		delete(combined)

		pro_logger_trace("  --- My max amphib units ---")
		print_map5 := make(map[string]i32)
		for u in pro_territory_get_max_amphib_units(pt) {
			k := unit_to_string_no_owner(u)
			print_map5[k] = print_map5[k] + 1
		}
		for k, v in print_map5 {
			pro_logger_trace(fmt.tprintf("    %d %s", v, k))
		}
		delete(print_map5)

		pro_logger_trace("  --- My actual units ---")
		print_map3 := make(map[string]i32)
		for u in pro_territory_get_units(pt) {
			if u == nil {
				continue
			}
			k := unit_to_string_no_owner(u)
			print_map3[k] = print_map3[k] + 1
		}
		for k, v in print_map3 {
			pro_logger_trace(fmt.tprintf("    %d %s", v, k))
		}
		delete(print_map3)

		pro_logger_trace("  --- Enemy units ---")
		print_map2 := make(map[string]i32)
		for u in pro_territory_get_max_enemy_units(pt) {
			k := unit_to_string_no_owner(u)
			print_map2[k] = print_map2[k] + 1
		}
		for k, v in print_map2 {
			pro_logger_trace(fmt.tprintf("    %d %s", v, k))
		}
		delete(print_map2)

		pro_logger_trace("  --- Enemy bombard units ---")
		print_map4 := make(map[string]i32)
		for u in pro_territory_get_max_enemy_bombard_units(pt) {
			k := unit_to_string_no_owner(u)
			print_map4[k] = print_map4[k] + 1
		}
		for k, v in print_map4 {
			pro_logger_trace(fmt.tprintf("    %d %s", v, k))
		}
		delete(print_map4)
	}
}

