package game

import "core:fmt"
import "core:slice"

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

// Java: ProNonCombatMoveAi#lambda$moveUnitsToDefendTerritories$0(ProTerritory)
//   () -> calc.estimateDefendBattleResults(
//             proData, proTerritory, proTerritory.getEligibleDefenders(player))
// Supplier<ProBattleResult> passed to setBattleResultIfNull from the
// non-air defender loop. Captures `this` (calc, proData, player) and the
// local `proTerritory`; ported static-style with the captured instance
// fields passed explicitly.
pro_non_combat_move_ai_lambda__move_units_to_defend_territories__0 :: proc(
	calc: ^Pro_Odds_Calculator,
	pro_data: ^Pro_Data,
	player: ^Game_Player,
	pro_territory: ^Pro_Territory,
) -> ^Pro_Battle_Result {
	eligible := pro_territory_get_eligible_defenders(pro_territory, player)
	return pro_odds_calculator_estimate_defend_battle_results_3(
		calc,
		pro_data,
		pro_territory,
		eligible,
	)
}

// Java: ProNonCombatMoveAi#lambda$moveUnitsToDefendTerritories$1(ProTerritory)
//   () -> calc.estimateDefendBattleResults(
//             proData, proTerritory, proTerritory.getEligibleDefenders(player))
// Supplier<ProBattleResult> passed to setBattleResultIfNull from the
// air-unit defender loop. Same body as $0; javac emits a separate
// synthetic per lambda site.
pro_non_combat_move_ai_lambda__move_units_to_defend_territories__1 :: proc(
	calc: ^Pro_Odds_Calculator,
	pro_data: ^Pro_Data,
	player: ^Game_Player,
	pro_territory: ^Pro_Territory,
) -> ^Pro_Battle_Result {
	eligible := pro_territory_get_eligible_defenders(pro_territory, player)
	return pro_odds_calculator_estimate_defend_battle_results_3(
		calc,
		pro_data,
		pro_territory,
		eligible,
	)
}

// Java: ProNonCombatMoveAi#lambda$moveUnitsToDefendTerritories$2(ProTerritory)
//   () -> calc.estimateDefendBattleResults(
//             proData, proTerritory, proTerritory.getAllDefenders())
// Supplier<ProBattleResult> from the transport-defense loop; uses
// getAllDefenders() (Map<^Unit,struct{}>) flattened to a [dynamic]^Unit
// to feed the existing estimate_defend_battle_results_3 signature.
pro_non_combat_move_ai_lambda__move_units_to_defend_territories__2 :: proc(
	calc: ^Pro_Odds_Calculator,
	pro_data: ^Pro_Data,
	pro_territory: ^Pro_Territory,
) -> ^Pro_Battle_Result {
	all_defenders := pro_territory_get_all_defenders(pro_territory)
	defer delete(all_defenders)
	defenders: [dynamic]^Unit
	for u in all_defenders {
		append(&defenders, u)
	}
	return pro_odds_calculator_estimate_defend_battle_results_3(
		calc,
		pro_data,
		pro_territory,
		defenders,
	)
}

// Java: ProNonCombatMoveAi#lambda$moveUnitsToDefendTerritories$3(ProTerritory)
//   () -> calc.estimateDefendBattleResults(
//             proData, proTerritory, proTerritory.getAllDefenders())
// Supplier<ProBattleResult> from the amphib-defense loop. Same body as
// $2; javac emits a separate synthetic per lambda site.
pro_non_combat_move_ai_lambda__move_units_to_defend_territories__3 :: proc(
	calc: ^Pro_Odds_Calculator,
	pro_data: ^Pro_Data,
	pro_territory: ^Pro_Territory,
) -> ^Pro_Battle_Result {
	all_defenders := pro_territory_get_all_defenders(pro_territory)
	defer delete(all_defenders)
	defenders: [dynamic]^Unit
	for u in all_defenders {
		append(&defenders, u)
	}
	return pro_odds_calculator_estimate_defend_battle_results_3(
		calc,
		pro_data,
		pro_territory,
		defenders,
	)
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

// File-scope holder bridging a ctx-form Predicate<Territory>
// (canMoveThrough) into the bare-`proc(^Territory) -> bool` cond consumed
// by `game_map_get_route_for_unit`, `game_map_get_route_for_unit_or_else_throw`,
// and `breadth_first_search_new_with_predicate`. The
// `find_destination_or_safe_territory_on_the_way` method is single-threaded
// and constructed-then-traversed; the holder is set immediately before
// each route lookup / BFS construction, matching the holder pattern used
// by `breadth_first_search.odin` and `pro_territory_manager.odin`.
@(private = "file")
pro_non_combat_move_ai_active_can_move_through: proc(rawptr, ^Territory) -> bool

@(private = "file")
pro_non_combat_move_ai_active_can_move_through_ctx: rawptr

@(private = "file")
pro_non_combat_move_ai_can_move_through_trampoline :: proc(t: ^Territory) -> bool {
	return pro_non_combat_move_ai_active_can_move_through(
		pro_non_combat_move_ai_active_can_move_through_ctx,
		t,
	)
}

// Lambda: findDestinationOrSafeTerritoryOnTheWay  bfs.traverse((t, distance) -> { ... })
// Java synthetic name: lambda$findDestinationOrSafeTerritoryOnTheWay$15.
// Captures finalDestinationTest, from, canMoveThrough, unit, moveMap,
// validateMove, and destination (MutableObject<Territory> -> ^^Territory)
// per Java desugaring (passed as leading params). `this` (self) is the
// implicit receiver for the synthetic instance lambda — it carries
// `self.data`, `self.pro_data`, and `self.player`.
pro_non_combat_move_ai_lambda__find_destination_or_safe_territory_on_the_way__15 :: proc(
	self: ^Pro_Non_Combat_Move_Ai,
	final_destination_test: proc(rawptr, ^Territory) -> bool,
	final_destination_test_ctx: rawptr,
	from: ^Territory,
	can_move_through: proc(rawptr, ^Territory) -> bool,
	can_move_through_ctx: rawptr,
	unit: ^Unit,
	move_map: map[^Territory]^Pro_Territory,
	validate_move: proc(rawptr, ^Route) -> bool,
	validate_move_ctx: rawptr,
	destination: ^^Territory,
	t: ^Territory,
	distance: i32,
) -> bool {
	// If it's a desired final destination, see if we can move towards it.
	if final_destination_test(final_destination_test_ctx, t) {
		pro_non_combat_move_ai_active_can_move_through = can_move_through
		pro_non_combat_move_ai_active_can_move_through_ctx = can_move_through_ctx
		route := game_map_get_route_for_unit(
			game_data_get_map(self.data),
			from,
			t,
			pro_non_combat_move_ai_can_move_through_trampoline,
			unit,
			self.player,
		)
		if route != nil {
			for route_has_steps(route) {
				pro_destination := pro_data_get_pro_territory(
					self.pro_data,
					move_map,
					route_get_end(route),
				)
				if pro_territory_is_can_hold(pro_destination) &&
				   validate_move(validate_move_ctx, route) {
					destination^ = route_get_end(route)
					// End the search.
					return false
				}
				route = route_new(from, route_get_middle_steps(route))
			}
		}
	}
	return true
}

// Visitor adapter for the bfs.traverse lambda inside
// findDestinationOrSafeTerritoryOnTheWay. Captures the lambda's full
// closure (predicates with their ctx, the route-building inputs, the
// MutableObject<Territory> out-param as ^^Territory, and `self`) so the
// synthetic lambda$15 can be invoked from the Breadth_First_Search_Visitor
// vtable slot, mirroring Pro_Territory_Manager_Find_Closest_Territory_Visitor.
Pro_Non_Combat_Move_Ai_Find_Destination_Visitor :: struct {
	using visitor:              Breadth_First_Search_Visitor,
	self_ai:                    ^Pro_Non_Combat_Move_Ai,
	final_destination_test:     proc(rawptr, ^Territory) -> bool,
	final_destination_test_ctx: rawptr,
	from:                       ^Territory,
	can_move_through:           proc(rawptr, ^Territory) -> bool,
	can_move_through_ctx:       rawptr,
	unit:                       ^Unit,
	move_map:                   map[^Territory]^Pro_Territory,
	validate_move:              proc(rawptr, ^Route) -> bool,
	validate_move_ctx:          rawptr,
	destination:                ^^Territory,
}

@(private = "file")
pro_non_combat_move_ai_find_destination_visit :: proc(
	self: ^Breadth_First_Search_Visitor,
	territory: ^Territory,
	distance: i32,
) -> bool {
	me := cast(^Pro_Non_Combat_Move_Ai_Find_Destination_Visitor)self
	return pro_non_combat_move_ai_lambda__find_destination_or_safe_territory_on_the_way__15(
		me.self_ai,
		me.final_destination_test,
		me.final_destination_test_ctx,
		me.from,
		me.can_move_through,
		me.can_move_through_ctx,
		me.unit,
		me.move_map,
		me.validate_move,
		me.validate_move_ctx,
		me.destination,
		territory,
		distance,
	)
}

// games.strategy.triplea.ai.pro.ProNonCombatMoveAi#findDestinationOrSafeTerritoryOnTheWay(Unit, Collection<Territory>, Predicate<Route>, Predicate<Territory>, Predicate<Territory>)
// Java: returns Optional<Territory>; modeled in Odin as ^Territory (nil = empty).
//
// possibleMoves: the per-unit reachable set from `infraUnitMoveMap.get(u)`,
// which the existing port stores as `map[^Territory]struct{}`.
// MutableObject<Territory> destination is modeled as a local `^Territory`
// (the visitor receives `&destination`), matching the convention used by
// `pro_territory_manager_find_closest_territory`.
pro_non_combat_move_ai_find_destination_or_safe_territory_on_the_way :: proc(
	self: ^Pro_Non_Combat_Move_Ai,
	unit: ^Unit,
	possible_moves: map[^Territory]struct {},
	validate_move: proc(rawptr, ^Route) -> bool,
	validate_move_ctx: rawptr,
	can_move_through: proc(rawptr, ^Territory) -> bool,
	can_move_through_ctx: rawptr,
	final_destination_test: proc(rawptr, ^Territory) -> bool,
	final_destination_test_ctx: rawptr,
) -> ^Territory {
	from := self.unit_territory_map[unit]
	if final_destination_test(final_destination_test_ctx, from) {
		// Already at a desired destination, no need to move.
		return from
	}
	pro_non_combat_move_ai_active_can_move_through = can_move_through
	pro_non_combat_move_ai_active_can_move_through_ctx = can_move_through_ctx
	game_map_ref := game_data_get_map(self.data)
	for t, _ in possible_moves {
		if !final_destination_test(final_destination_test_ctx, t) {
			continue
		}
		r := game_map_get_route_for_unit_or_else_throw(
			game_map_ref,
			from,
			t,
			pro_non_combat_move_ai_can_move_through_trampoline,
			unit,
			self.player,
		)
		if validate_move(validate_move_ctx, r) {
			// Found a reachable destination. Return directly.
			return t
		}
	}

	move_map := pro_my_move_options_get_territory_map(
		pro_territory_manager_get_defend_options(self.territory_manager),
	)
	// No destination can be reached directly. Consider multi-turn moves.
	// Move to a territory that can be held on a path to a final destination.
	destination: ^Territory = nil
	start_territories := make([dynamic]^Territory, 0, 1)
	append(&start_territories, from)
	bfs := breadth_first_search_new_with_predicate(
		start_territories,
		pro_non_combat_move_ai_can_move_through_trampoline,
	)
	visitor := new(Pro_Non_Combat_Move_Ai_Find_Destination_Visitor)
	visitor.visit = pro_non_combat_move_ai_find_destination_visit
	visitor.self_ai = self
	visitor.final_destination_test = final_destination_test
	visitor.final_destination_test_ctx = final_destination_test_ctx
	visitor.from = from
	visitor.can_move_through = can_move_through
	visitor.can_move_through_ctx = can_move_through_ctx
	visitor.unit = unit
	visitor.move_map = move_map
	visitor.validate_move = validate_move
	visitor.validate_move_ctx = validate_move_ctx
	visitor.destination = &destination
	breadth_first_search_traverse(bfs, &visitor.visitor)

	// If nothing chosen and we can't hold the current territory, try to move
	// somewhere safe. Mirrors Java:
	//   possibleMoves.stream().filter(t -> canHold(moveMap, t)).findAny()
	//                .ifPresent(destination::setValue);
	if destination == nil && !pro_territory_is_can_hold(move_map[from]) {
		for t, _ in possible_moves {
			if pro_non_combat_move_ai_lambda__find_destination_or_safe_territory_on_the_way__16(
				self,
				move_map,
				t,
			) {
				destination = t
				break
			}
		}
	}
	return destination
}

// games.strategy.triplea.ai.pro.ProNonCombatMoveAi#determineIfMoveTerritoriesCanBeHeld()
pro_non_combat_move_ai_determine_if_move_territories_can_be_held :: proc(
	self: ^Pro_Non_Combat_Move_Ai,
) {
	pro_logger_info("Find max enemy attackers and if territories can be held")

	move_map := pro_my_move_options_get_territory_map(
		pro_territory_manager_get_defend_options(self.territory_manager),
	)
	enemy_attack_options := pro_territory_manager_get_enemy_attack_options(self.territory_manager)

	aa_p, aa_c := matches_unit_is_aa_for_anything()
	factory_p, factory_c := pro_matches_territory_has_infra_factory_and_is_land()

	// Determine which territories can possibly be held
	for t, patd in move_map {
		// Check if no enemy attackers
		enemy_attack_max := pro_other_move_options_get_max(enemy_attack_options, t)
		if enemy_attack_max == nil {
			pro_logger_debug(
				fmt.tprintf(
					"Territory=%s, CanHold=true since has no enemy attackers",
					default_named_get_name(&t.named_attachable.default_named),
				),
			)
			continue
		}

		// Build enemy attacking units (Set<Unit> = max + amphib)
		enemy_set: map[^Unit]struct {}
		defer delete(enemy_set)
		for u, _ in pro_territory_get_max_units(enemy_attack_max) {
			enemy_set[u] = {}
		}
		for u in pro_territory_get_max_amphib_units(enemy_attack_max) {
			enemy_set[u] = {}
		}
		enemy_attacking_units := make([dynamic]^Unit, 0, len(enemy_set))
		for u, _ in enemy_set {
			append(&enemy_attacking_units, u)
		}
		pro_territory_set_max_enemy_units(patd, enemy_attacking_units)
		pro_territory_set_max_enemy_bombard_units(
			patd,
			pro_territory_get_max_bombard_units(enemy_attack_max),
		)

		bombarding_list := make([dynamic]^Unit, 0)
		for u, _ in pro_territory_get_max_bombard_units(enemy_attack_max) {
			append(&bombarding_list, u)
		}

		// Check if min defenders can hold it (not considering AA)
		min_defending_units_and_not_aa := make([dynamic]^Unit, 0)
		for u, _ in pro_territory_get_cant_move_units(patd) {
			if !aa_p(aa_c, u) {
				append(&min_defending_units_and_not_aa, u)
			}
		}
		min_result := pro_odds_calculator_calculate_battle_results(
			self.calc,
			self.pro_data,
			t,
			enemy_attacking_units,
			min_defending_units_and_not_aa,
			bombarding_list,
		)
		pro_territory_set_min_battle_result(patd, min_result)
		if pro_battle_result_get_tuv_swing(min_result) <= 0 &&
		   len(min_defending_units_and_not_aa) > 0 {
			pro_logger_debug(
				fmt.tprintf(
					"Territory=%s, CanHold=true, MinDefenders=%d, EnemyAttackers=%d, win%%=%f, EnemyTUVSwing=%f, hasLandUnitRemaining=%v",
					default_named_get_name(&t.named_attachable.default_named),
					len(min_defending_units_and_not_aa),
					len(enemy_attacking_units),
					pro_battle_result_get_win_percentage(min_result),
					pro_battle_result_get_tuv_swing(min_result),
					pro_battle_result_is_has_land_unit_remaining(min_result),
				),
			)
			continue
		}

		// Check if max defenders can hold it (not considering AA)
		def_set: map[^Unit]struct {}
		defer delete(def_set)
		for u, _ in pro_territory_get_max_units(patd) {
			def_set[u] = {}
		}
		for u in pro_territory_get_max_amphib_units(patd) {
			def_set[u] = {}
		}
		for u, _ in pro_territory_get_cant_move_units(patd) {
			def_set[u] = {}
		}
		defending_units_and_not_aa := make([dynamic]^Unit, 0)
		for u, _ in def_set {
			if !aa_p(aa_c, u) {
				append(&defending_units_and_not_aa, u)
			}
		}
		result := pro_odds_calculator_calculate_battle_results(
			self.calc,
			self.pro_data,
			t,
			enemy_attacking_units,
			defending_units_and_not_aa,
			bombarding_list,
		)
		is_factory: i32 = 0
		if factory_p(factory_c, t) {
			is_factory = 1
		}
		is_my_capital: i32 = 0
		if t == pro_data_get_my_capital(self.pro_data) {
			is_my_capital = 1
		}
		// extraUnits = defendingUnitsAndNotAa - minDefendingUnitsAndNotAa
		min_set: map[^Unit]struct {}
		defer delete(min_set)
		for u in min_defending_units_and_not_aa {
			min_set[u] = {}
		}
		extra_units := make([dynamic]^Unit, 0)
		for u in defending_units_and_not_aa {
			if _, in_min := min_set[u]; !in_min {
				append(&extra_units, u)
			}
		}
		costs := new(Integer_Map_Unit_Type)
		costs.entries = pro_data_get_unit_value_map(self.pro_data)
		extra_unit_value := f64(tuv_utils_get_tuv(extra_units, costs))
		hold_value :=
			extra_unit_value / 8.0 *
			(1.0 + 0.5 * f64(is_factory)) *
			(1.0 + 2.0 * f64(is_my_capital))
		if len(min_defending_units_and_not_aa) != len(defending_units_and_not_aa) &&
		   (pro_battle_result_get_tuv_swing(result) - hold_value) <
			   pro_battle_result_get_tuv_swing(min_result) {
			pro_logger_debug(
				fmt.tprintf(
					"Territory=%s, CanHold=true, MaxDefenders=%d, EnemyAttackers=%d, minTUVSwing=%f, win%%=%f, EnemyTUVSwing=%f, hasLandUnitRemaining=%v, holdValue=%f",
					default_named_get_name(&t.named_attachable.default_named),
					len(defending_units_and_not_aa),
					len(enemy_attacking_units),
					pro_battle_result_get_tuv_swing(min_result),
					pro_battle_result_get_win_percentage(result),
					pro_battle_result_get_tuv_swing(result),
					pro_battle_result_is_has_land_unit_remaining(result),
					hold_value,
				),
			)
			continue
		}

		// Can't hold territory
		pro_territory_set_can_hold(patd, false)
		pro_logger_debug(
			fmt.tprintf(
				"Can't hold Territory=%s, MaxDefenders=%d, EnemyAttackers=%d, minTUVSwing=%f, win%%=%f, EnemyTUVSwing=%f, hasLandUnitRemaining=%v, holdValue=%f",
				default_named_get_name(&t.named_attachable.default_named),
				len(defending_units_and_not_aa),
				len(enemy_attacking_units),
				pro_battle_result_get_tuv_swing(min_result),
				pro_battle_result_get_win_percentage(result),
				pro_battle_result_get_tuv_swing(result),
				pro_battle_result_is_has_land_unit_remaining(result),
				hold_value,
			),
		)
	}
}

// Closure ctx for the moveConsumablesToFactories validateMove lambda:
//   r -> { if r==null||!r.hasSteps() return false;
//          return validator.validateMove(new MoveDescription(List.of(u), r), player).isMoveValid(); }
@(private = "file")
Pro_Non_Combat_Move_Ai_Validate_Move_Ctx :: struct {
	self_ai:   ^Pro_Non_Combat_Move_Ai,
	validator: ^Move_Validator,
	u:         ^Unit,
}

@(private = "file")
pro_non_combat_move_ai_pred_validate_move :: proc(ctx_ptr: rawptr, r: ^Route) -> bool {
	ctx := cast(^Pro_Non_Combat_Move_Ai_Validate_Move_Ctx)ctx_ptr
	if r == nil || !route_has_steps(r) {
		return false
	}
	units := []^Unit{ctx.u}
	md := move_description_new_units_route(units, r)
	res := move_validator_validate_move(ctx.validator, md, ctx.self_ai.player)
	return move_validation_result_is_move_valid(res)
}

// Closure ctx for the moveConsumablesToFactories desiredDestination predicate:
//   ProMatches.territoryHasInfraFactoryAndIsLand()
//     .and(Matches.isTerritoryOwnedBy(player))
//     .and(t -> canHold(moveMap, t))
@(private = "file")
Pro_Non_Combat_Move_Ai_Desired_Dest_Ctx :: struct {
	self_ai:  ^Pro_Non_Combat_Move_Ai,
	move_map: map[^Territory]^Pro_Territory,
	player:   ^Game_Player,
}

@(private = "file")
pro_non_combat_move_ai_pred_desired_dest :: proc(ctx_ptr: rawptr, t: ^Territory) -> bool {
	ctx := cast(^Pro_Non_Combat_Move_Ai_Desired_Dest_Ctx)ctx_ptr
	factory_p, factory_c := pro_matches_territory_has_infra_factory_and_is_land()
	if !factory_p(factory_c, t) {
		return false
	}
	owned_p, owned_c := matches_is_territory_owned_by(ctx.player)
	if !owned_p(owned_c, t) {
		return false
	}
	return pro_non_combat_move_ai_lambda__move_consumables_to_factories__13(
		ctx.self_ai,
		ctx.move_map,
		t,
	)
}

// games.strategy.triplea.ai.pro.ProNonCombatMoveAi#moveConsumablesToFactories(boolean,java.util.Map,java.util.Map,games.strategy.triplea.delegate.move.validation.MoveValidator)
pro_non_combat_move_ai_move_consumables_to_factories :: proc(
	self: ^Pro_Non_Combat_Move_Ai,
	is_combat_move: bool,
	infra_unit_move_map: map[^Unit]map[^Territory]struct {},
	move_map: map[^Territory]^Pro_Territory,
	validator: ^Move_Validator,
) {
	// First, determine which unit types can be consumed during purchase phase.
	consumables: map[^Unit_Type]struct {}
	defer delete(consumables)
	for option in pro_purchase_option_map_get_all_options(
		pro_data_get_purchase_options(self.pro_data),
	) {
		// Skip construction purchase options, since these can be placed without factory.
		if pro_purchase_option_is_consumes_units(option) &&
		   !pro_purchase_option_is_construction(option) {
			ut := pro_purchase_option_get_unit_type(option)
			ua := unit_type_get_unit_attachment(ut)
			for k, _ in unit_attachment_get_consumes_units(ua) {
				consumables[k] = {}
			}
		}
	}

	if len(consumables) == 0 {
		return
	}
	pro_logger_debug("Move consumable units to factories")

	desired_ctx := new(Pro_Non_Combat_Move_Ai_Desired_Dest_Ctx)
	desired_ctx.self_ai = self
	desired_ctx.move_map = move_map
	desired_ctx.player = self.player

	land_p, land_c := matches_unit_is_land()

	// Snapshot the current keys so we can safely remove from the underlying
	// map while iterating, mirroring Java's Iterator.remove().
	keys := make([dynamic]^Unit, 0, len(infra_unit_move_map))
	defer delete(keys)
	for u, _ in infra_unit_move_map {
		append(&keys, u)
	}
	mutable_map := infra_unit_move_map

	for u in keys {
		// Skip non-consumable units and non-land units (for now).
		if _, ok := consumables[unit_get_type(u)]; !ok {
			continue
		}
		if !land_p(land_c, u) {
			continue
		}

		validate_ctx := new(Pro_Non_Combat_Move_Ai_Validate_Move_Ctx)
		validate_ctx.self_ai = self
		validate_ctx.validator = validator
		validate_ctx.u = u

		from := self.unit_territory_map[u]
		empty_enemy: [dynamic]^Territory
		can_move_p, can_move_c := pro_matches_territory_can_move_land_units_through(
			self.player,
			u,
			from,
			is_combat_move,
			empty_enemy,
		)

		possible := infra_unit_move_map[u]
		to := pro_non_combat_move_ai_find_destination_or_safe_territory_on_the_way(
			self,
			u,
			possible,
			pro_non_combat_move_ai_pred_validate_move,
			rawptr(validate_ctx),
			can_move_p,
			can_move_c,
			pro_non_combat_move_ai_pred_desired_dest,
			rawptr(desired_ctx),
		)
		if to != nil {
			if to != from {
				pro_logger_debug(
					fmt.tprintf(
						"Consumable %s moved from %s to %s",
						default_named_get_name(
							&unit_get_type(u).named_attachable.default_named,
						),
						default_named_get_name(&from.named_attachable.default_named),
						default_named_get_name(&to.named_attachable.default_named),
					),
				)
			}
			target_pt, ok := move_map[to]
			if ok && target_pt != nil {
				pro_territory_add_unit(target_pt, u)
			}
			delete_key(&mutable_map, u)
		}
	}
}

// Java: ProNonCombatMoveAi#doMove(boolean, Map<Territory, ProTerritory>, IMoveDelegate, GameData, GamePlayer)
//   this.data = data;
//   this.player = player;
//   ProMoveUtils.doMove(
//       proData, ProMoveUtils.calculateMoveRoutes(proData, player, moveMap, isCombatMove), moveDel);
//   ProMoveUtils.doMove(
//       proData, ProMoveUtils.calculateAmphibRoutes(proData, player, moveMap, isCombatMove), moveDel);
pro_non_combat_move_ai_do_move :: proc(
	self: ^Pro_Non_Combat_Move_Ai,
	is_combat_move: bool,
	move_map: map[^Territory]^Pro_Territory,
	move_del: ^I_Move_Delegate,
	data: ^Game_Data,
	player: ^Game_Player,
) {
	self.data = data
	self.player = player

	move_routes := pro_move_utils_calculate_move_routes(self.pro_data, player, move_map, is_combat_move)
	pro_move_utils_do_move(self.pro_data, &move_routes, move_del)

	amphib_routes := pro_move_utils_calculate_amphib_routes(self.pro_data, player, move_map, is_combat_move)
	pro_move_utils_do_move(self.pro_data, &amphib_routes, move_del)
}

// Lambda: moveUnitsToBestTerritories  () -> calc.calculateBattleResults(proData, proTerritory, defendingUnits)
// Captures: proTerritory, defendingUnits — desugared to (ProTerritory, Collection<Unit>) -> ProBattleResult
pro_non_combat_move_ai_lambda__move_units_to_best_territories__10 :: proc(
	self: ^Pro_Non_Combat_Move_Ai,
	pro_territory: ^Pro_Territory,
	defending_units: [dynamic]^Unit,
) -> ^Pro_Battle_Result {
	return pro_odds_calculator_calculate_battle_results_3(
		self.calc,
		self.pro_data,
		pro_territory,
		defending_units,
	)
}

// Lambda: checkCanHold  () -> calc.calculateBattleResults(proData, proTerritory)
// Java synthetic name: lambda$checkCanHold$12. Captures `this` (calc, proData)
// and the proTerritory parameter.
pro_non_combat_move_ai_lambda__check_can_hold__12 :: proc(
	self: ^Pro_Non_Combat_Move_Ai,
	pro_territory: ^Pro_Territory,
) -> ^Pro_Battle_Result {
	return pro_odds_calculator_calculate_battle_results_2(
		self.calc,
		self.pro_data,
		pro_territory,
	)
}

// games.strategy.triplea.ai.pro.ProNonCombatMoveAi#findUnitsThatCantMove(java.util.Map, java.util.List)
// Java accepts a nullable Map<Territory, ProPurchaseTerritory> for purchase
// territories. Odin can't model `nil` directly on a value-typed map without
// a sentinel, so we add a `has_purchase_territories` flag — `true` selects
// the "use given purchase plan" branch, `false` selects the
// "max defenders that can be purchased" fallback (Java's `else` branch).
pro_non_combat_move_ai_find_units_that_cant_move :: proc(
	self: ^Pro_Non_Combat_Move_Ai,
	purchase_territories: map[^Territory]^Pro_Purchase_Territory,
	has_purchase_territories: bool,
	land_purchase_options: [dynamic]^Pro_Purchase_Option,
) {
	pro_logger_info("Find units that can't move")

	move_map := pro_my_move_options_get_territory_map(
		pro_territory_manager_get_defend_options(self.territory_manager),
	)
	unit_move_map := pro_my_move_options_get_unit_move_map(
		pro_territory_manager_get_defend_options(self.territory_manager),
	)

	// Add all units that can't move (to be consumed, allied units, 0 move units, etc.)
	units_to_be_consumed := pro_data_get_units_to_be_consumed(self.pro_data)
	for t, pro_territory in move_map {
		assert(len(pro_territory_get_cant_move_units(pro_territory)) == 0)
		cant_be_moved_p, cant_be_moved_c := pro_matches_unit_cant_be_moved_and_is_allied_defender(
			self.player,
			t,
		)
		// Combined predicate:
		//   ProMatches.unitCantBeMovedAndIsAlliedDefender(player, t)
		//     .or(proData.getUnitsToBeConsumed()::contains)
		cant_move_units := make([dynamic]^Unit, 0)
		for u in unit_collection_get_units(territory_get_unit_collection(t)) {
			matched := false
			if cant_be_moved_p(cant_be_moved_c, u) {
				matched = true
			} else if _, in_consumed := units_to_be_consumed[u]; in_consumed {
				matched = true
			}
			if matched {
				append(&cant_move_units, u)
			}
		}
		pro_territory_add_cant_move_units(pro_territory, cant_move_units)
		delete(cant_move_units)
	}

	// Add all units that only have 1 move option and can't be transported.
	// Java uses Iterator.remove(); we collect first, mutate after.
	unit_move_map_mut := unit_move_map
	to_remove_single_option := make([dynamic]^Unit, 0)
	defer delete(to_remove_single_option)
	for u, territories in unit_move_map_mut {
		if len(territories) != 1 {
			continue
		}
		// CollectionUtils.getAny: pick any element of the set.
		only_territory: ^Territory = nil
		for tt in territories {
			only_territory = tt
			break
		}
		if only_territory == self.unit_territory_map[u] &&
		   !pro_non_combat_move_ai_can_potentially_be_transported(self, only_territory) {
			pro_territory_add_cant_move_unit(move_map[only_territory], u)
			append(&to_remove_single_option, u)
		}
	}
	for u in to_remove_single_option {
		delete_key(&unit_move_map_mut, u)
	}

	// Check if purchase units are known yet.
	if has_purchase_territories {
		// Add all units that will be purchased.
		for _, ppt in purchase_territories {
			for place_territory in pro_purchase_territory_get_can_place_territories(ppt) {
				t := pro_place_territory_get_territory(place_territory)
				if pro_territory_at, ok := move_map[t]; ok && pro_territory_at != nil {
					pro_territory_add_cant_move_units(
						pro_territory_at,
						pro_place_territory_get_place_units(place_territory),
					)
				}
			}
		}
	} else {
		// Add max defenders that can be purchased to each territory.
		factory_p, factory_c := pro_matches_territory_has_non_mobile_factory_and_is_not_conquered_owned_land(
			self.player,
		)
		for t, _ in move_map {
			if factory_p(factory_c, t) {
				defenders_to_purchase := pro_purchase_utils_find_max_purchase_defenders(
					self.pro_data,
					self.player,
					t,
					land_purchase_options,
				)
				pro_territory_add_cant_move_units(move_map[t], defenders_to_purchase)
			}
		}
	}

	// Log can't move units per territory.
	for t, pro_territory in move_map {
		if len(pro_territory_get_cant_move_units(pro_territory)) > 0 {
			pro_logger_trace(
				fmt.tprintf(
					"%s has units that can't move: %d unit(s)",
					territory_to_string(t),
					len(pro_territory_get_cant_move_units(pro_territory)),
				),
			)
		}
	}
}

// File-scope ctx + trampoline pairs used by moveUnitsToBestTerritories
// to feed lambdas with environment into APIs that take bare
// `proc(^Territory) -> bool` predicates (game_map_get_route_for_units etc).
@(private = "file")
Move_Best_Sea_Through_Ctx :: struct {
	player:         ^Game_Player,
	is_combat_move: bool,
	cant_hold:      map[^Territory]struct {},
}

@(private = "file")
move_best_sea_through_active: ^Move_Best_Sea_Through_Ctx

@(private = "file")
move_best_sea_through_pred :: proc(t: ^Territory) -> bool {
	ctx := move_best_sea_through_active
	if _, in_cant_hold := ctx.cant_hold[t]; in_cant_hold {
		return false
	}
	p, c := pro_matches_territory_can_move_sea_units_through(ctx.player, ctx.is_combat_move)
	return p(c, t)
}

// File-scope holder for `pro_matches_territory_can_move_sea_units` used by
// `game_map_get_distance_ignore_end_for_condition` (which takes a bare
// `proc(^Territory) -> bool` — same trampoline pattern as the existing
// can_move_through holder above).
@(private = "file")
move_best_sea_active_pred: proc(rawptr, ^Territory) -> bool

@(private = "file")
move_best_sea_active_ctx: rawptr

@(private = "file")
move_best_sea_trampoline :: proc(t: ^Territory) -> bool {
	return move_best_sea_active_pred(move_best_sea_active_ctx, t)
}

// games.strategy.triplea.ai.pro.ProNonCombatMoveAi#moveUnitsToBestTerritories(boolean)
pro_non_combat_move_ai_move_units_to_best_territories :: proc(
	self: ^Pro_Non_Combat_Move_Ai,
	is_combat_move: bool,
) {
	move_map := pro_my_move_options_get_territory_map(
		pro_territory_manager_get_defend_options(self.territory_manager),
	)
	unit_move_map := pro_my_move_options_get_unit_move_map(
		pro_territory_manager_get_defend_options(self.territory_manager),
	)
	transport_move_map := pro_my_move_options_get_transport_move_map(
		pro_territory_manager_get_defend_options(self.territory_manager),
	)
	transport_map_list := pro_my_move_options_get_transport_list(
		pro_territory_manager_get_defend_options(self.territory_manager),
	)

	// Java uses iterator.remove() on transportMapList — we represent it as a
	// mutable [dynamic]^Pro_Transport that we rebuild after each pass.
	transport_map_list_mut := make([dynamic]^Pro_Transport, 0, len(transport_map_list))
	for tr in transport_map_list {
		append(&transport_map_list_mut, tr)
	}

	for {
		pro_logger_info("Move units to best value territories")
		territories_to_defend := make(map[^Territory]struct {})
		defer delete(territories_to_defend)

		// Snapshot the current iteration state of unit/transport maps.
		current_unit_move_map := make(map[^Unit]map[^Territory]struct {})
		defer delete(current_unit_move_map)
		for u, ts in unit_move_map {
			current_unit_move_map[u] = ts
		}
		current_transport_move_map := make(map[^Unit]map[^Territory]struct {})
		defer delete(current_transport_move_map)
		for u, ts in transport_move_map {
			current_transport_move_map[u] = ts
		}
		current_transport_map_list := make([dynamic]^Pro_Transport, 0, len(transport_map_list_mut))
		defer delete(current_transport_map_list)
		for tr in transport_map_list_mut {
			append(&current_transport_map_list, tr)
		}

		// Reset lists.
		for _, t in move_map {
			clear(&t.temp_units)
			for transport in t.temp_amphib_attack_map {
				delete_key(&t.transport_territory_map, transport)
			}
			clear(&t.temp_amphib_attack_map)
			pro_territory_set_battle_result(t, nil)
		}

		pro_logger_debug("Move amphib units")

		// Transport amphib units to best territory.
		// We rebuild the list to model Java's it.remove() during iteration.
		next_transport_map_list := make([dynamic]^Pro_Transport, 0, len(current_transport_map_list))
		for amphib_data in current_transport_map_list {
			transport := pro_transport_get_transport(amphib_data)

			already_moved_units := make([dynamic]^Unit, 0)
			for _, t in move_map {
				for u in pro_territory_get_units(t) {
					append(&already_moved_units, u)
				}
				for u in pro_territory_get_temp_units(t) {
					append(&already_moved_units, u)
				}
			}
			already_moved_set := make(map[^Unit]struct {})
			for u in already_moved_units {
				already_moved_set[u] = {}
			}

			max_value_territory: ^Pro_Territory = nil
			max_amphib_units_to_add: [dynamic]^Unit
			max_value: f64 = 4.9e-324 // Java Double.MIN_VALUE (smallest positive denormal).
			max_sea_value: f64 = 0
			max_unload_from_territory: ^Territory = nil

			for t in pro_transport_get_transport_map(amphib_data) {
				pro_territory := move_map[t]
				if pro_territory_get_value(pro_territory) >= max_value {
					territories_can_load_from := pro_transport_get_transport_map(amphib_data)[t]
					amphib_units_to_add := pro_transport_utils_get_units_to_transport_that_cant_move_to_higher_value(
						self.player,
						transport,
						self.pro_data,
						territories_can_load_from,
						already_moved_units,
						move_map,
						current_unit_move_map,
						pro_territory_get_value(pro_territory),
					)
					if len(amphib_units_to_add) == 0 {
						delete(amphib_units_to_add)
						continue
					}

					load_from_territories := make(map[^Territory]struct {})
					for u in amphib_units_to_add {
						load_from_territories[self.unit_territory_map[u]] = {}
					}
					can_move_p, can_move_c := pro_matches_territory_can_move_sea_units(
						self.player,
						is_combat_move,
					)
					territories_to_move_transport := game_map_get_neighbors_predicate(
						game_data_get_map(self.data),
						t,
						can_move_p,
						can_move_c,
					)
					for territory_to_move_transport in territories_to_move_transport {
						pro_destination, has_dest := move_map[territory_to_move_transport]
						sea_map := pro_transport_get_sea_transport_map(amphib_data)
						sea_set, has_sea := sea_map[territory_to_move_transport]
						if !has_sea {
							continue
						}
						all_load_in_sea := true
						for lf in load_from_territories {
							if _, ok := sea_set[lf]; !ok {
								all_load_in_sea = false
								break
							}
						}
						if !all_load_in_sea {
							continue
						}
						if has_dest && pro_destination != nil &&
						   pro_territory_is_can_hold(pro_destination) &&
						   (pro_territory_get_value(pro_territory) > max_value ||
								   pro_territory_get_value(pro_destination) > max_sea_value) {
							max_value_territory = pro_territory
							if max_amphib_units_to_add != nil {
								delete(max_amphib_units_to_add)
							}
							max_amphib_units_to_add = make([dynamic]^Unit, 0, len(amphib_units_to_add))
							for au in amphib_units_to_add {
								append(&max_amphib_units_to_add, au)
							}
							max_value = pro_territory_get_value(pro_territory)
							max_sea_value = pro_territory_get_value(pro_destination)
							max_unload_from_territory = territory_to_move_transport
						}
					}
					delete(amphib_units_to_add)
					delete(load_from_territories)
					delete(territories_to_move_transport)
				}
			}

			if max_value_territory != nil {
				pro_logger_trace(
					fmt.tprintf(
						"transport moved to unload at %s, value=%v",
						territory_to_string(max_unload_from_territory),
						max_value,
					),
				)
				pro_territory_add_temp_units(max_value_territory, max_amphib_units_to_add)
				pro_territory_put_temp_amphib_attack_map(
					max_value_territory,
					transport,
					max_amphib_units_to_add,
				)
				pro_territory_get_transport_territory_map(max_value_territory)[transport] =
					max_unload_from_territory
				delete_key(&current_transport_move_map, transport)
				for unit in max_amphib_units_to_add {
					delete_key(&current_unit_move_map, unit)
				}
				territories_to_defend[max_unload_from_territory] = {}
				delete(already_moved_units)
				delete(already_moved_set)
				continue // amphib_data removed (not appended to next list)
			}

			// Transport amphib units to best sea territory.
			for t in pro_transport_get_sea_transport_map(amphib_data) {
				pro_territory, has := move_map[t]
				if !has || pro_territory == nil {
					continue
				}
				if pro_territory_get_value(pro_territory) > max_value {
					sea_set := pro_transport_get_sea_transport_map(amphib_data)[t]
					// territoriesCanLoadFrom.removeAll(data.getMap().getNeighbors(t))
					filtered := make(map[^Territory]struct {})
					neighbors := game_map_get_neighbors(game_data_get_map(self.data), t)
					for tt in sea_set {
						if _, in_n := neighbors[tt]; !in_n {
							filtered[tt] = {}
						}
					}
					delete(neighbors)
					amphib_units_to_add := pro_transport_utils_get_units_to_transport_that_cant_move_to_higher_value(
						self.player,
						transport,
						self.pro_data,
						filtered,
						already_moved_units,
						move_map,
						current_unit_move_map,
						0.1,
					)
					delete(filtered)
					if len(amphib_units_to_add) > 0 {
						max_value_territory = pro_territory
						if max_amphib_units_to_add != nil {
							delete(max_amphib_units_to_add)
						}
						max_amphib_units_to_add = amphib_units_to_add
						max_value = pro_territory_get_value(pro_territory)
					} else {
						delete(amphib_units_to_add)
					}
				}
			}

			if max_value_territory != nil {
				can_move_p, can_move_c := pro_matches_territory_can_move_land_units_and_is_allied(
					self.player,
				)
				adj_enemy_p, adj_enemy_c := pro_matches_territory_is_or_adjacent_to_enemy_not_neutral_land(
					self.player,
				)
				unload_to_territory: ^Pro_Territory = nil
				max_num_sea_neighbors: i32 = 0
				neighbors_of_max := pro_territory_get_neighbors(
					max_value_territory,
					can_move_p,
					can_move_c,
				)
				for possible_unload in neighbors_of_max {
					pro_territory, has := move_map[possible_unload]
					if !has || pro_territory == nil {
						continue
					}
					if pro_territory_is_can_hold(pro_territory) ||
					   !adj_enemy_p(adj_enemy_c, possible_unload) {
						water_p, water_c := matches_territory_is_water()
						sea_neighbors := pro_territory_get_neighbors(
							pro_territory,
							water_p,
							water_c,
						)
						num_sea_neighbors := i32(len(sea_neighbors))
						delete(sea_neighbors)
						if num_sea_neighbors > max_num_sea_neighbors {
							unload_to_territory = pro_territory
							max_num_sea_neighbors = num_sea_neighbors
						}
					}
				}
				delete(neighbors_of_max)

				if unload_to_territory != nil {
					pro_territory_add_temp_units(unload_to_territory, max_amphib_units_to_add)
					pro_territory_put_temp_amphib_attack_map(
						unload_to_territory,
						transport,
						max_amphib_units_to_add,
					)
					pro_territory_get_transport_territory_map(unload_to_territory)[transport] =
						pro_territory_get_territory(max_value_territory)
					pro_logger_trace(
						fmt.tprintf(
							"transport moved to best sea, unloading to %s, value=%v",
							territory_to_string(pro_territory_get_territory(unload_to_territory)),
							max_value,
						),
					)
				} else {
					pro_territory_add_temp_units(max_value_territory, max_amphib_units_to_add)
					pro_territory_put_temp_amphib_attack_map(
						max_value_territory,
						transport,
						max_amphib_units_to_add,
					)
					pro_territory_get_transport_territory_map(max_value_territory)[transport] =
						pro_territory_get_territory(max_value_territory)
					pro_logger_trace(
						fmt.tprintf(
							"transport moved to best sea, value=%v",
							max_value,
						),
					)
				}
				delete_key(&current_transport_move_map, transport)
				for unit in max_amphib_units_to_add {
					delete_key(&current_unit_move_map, unit)
				}
				territories_to_defend[pro_territory_get_territory(max_value_territory)] = {}
				delete(already_moved_units)
				delete(already_moved_set)
				continue
			}

			// Not removed — keep in next iteration's list.
			append(&next_transport_map_list, amphib_data)
			delete(already_moved_units)
			delete(already_moved_set)
		}
		delete(current_transport_map_list)
		current_transport_map_list = next_transport_map_list

		pro_logger_debug("Move empty transports to best loading territory")

		// Move remaining transports to best loading territory if safe.
		empty_transport_keys := make([dynamic]^Unit, 0, len(current_transport_move_map))
		defer delete(empty_transport_keys)
		for u in current_transport_move_map {
			append(&empty_transport_keys, u)
		}
		for transport in empty_transport_keys {
			if _, still := current_transport_move_map[transport]; !still {
				continue
			}
			current_territory := self.unit_territory_map[transport]
			moves := i32(unit_get_movement_left(transport))
			if unit_is_transporting_in_territory_arg(transport, current_territory) || moves <= 0 {
				continue
			}

			prioritized_load_territories := make([dynamic]^Pro_Territory, 0)
			defer delete(prioritized_load_territories)
			for t, pro_territory in move_map {
				transportable_pred, transportable_ctx := pro_matches_unit_is_owned_transportable_unit_and_can_be_loaded(
					self.player,
					transport,
					is_combat_move,
				)
				has_match_p, has_match_c := matches_territory_has_units_that_match(
					transportable_pred,
					transportable_ctx,
				)
				territory_has_transportable_units := has_match_p(has_match_c, t)

				sea_p, sea_c := pro_matches_territory_can_move_sea_units(self.player, true)
				move_best_sea_active_pred = sea_p
				move_best_sea_active_ctx = sea_c
				distance := game_map_get_distance_ignore_end_for_condition(
					game_data_get_map(self.data),
					current_territory,
					t,
					move_best_sea_trampoline,
				)

				water_p, water_c := matches_territory_is_water()
				has_neighbor_p, has_neighbor_c := matches_territory_has_neighbor_matching(
					game_data_get_map(self.data),
					water_p,
					water_c,
				)
				has_sea_neighbor := has_neighbor_p(has_neighbor_c, t)

				factory_p, factory_c := pro_matches_territory_has_infra_factory_and_is_owned_land(
					self.player,
				)
				has_factory := factory_p(factory_c, t)

				if !territory_is_water(t) &&
				   has_sea_neighbor &&
				   distance > 0 &&
				   !(distance == 1 && territory_has_transportable_units && !has_factory) {
					territory_value := pro_territory_get_value(pro_territory)

					transportable_p, transportable_c := pro_matches_unit_is_owned_transportable_unit(
						self.player,
					)
					num_units_to_load: i32 = 0
					all_def := pro_territory_get_all_defenders(pro_territory)
					for u in all_def {
						if transportable_p(transportable_c, u) {
							num_units_to_load += 1
						}
					}

					owned_factory_p, owned_factory_c := pro_matches_territory_has_infra_factory_and_is_owned_land(
						self.player,
					)
					tracker := abstract_move_delegate_get_battle_tracker(self.data)
					has_unconquered_factory :=
						owned_factory_p(owned_factory_c, t) &&
						!battle_tracker_was_conquered(tracker, t)
					factory_production: i32 = 0
					if has_unconquered_factory {
						factory_production = territory_attachment_static_get_production(t)
					}
					num_turns_away := (distance - 1) / moves
					if distance <= moves {
						num_turns_away = 0
					}
					value :=
						territory_value +
						0.5 * f64(num_turns_away) -
						0.1 * f64(num_units_to_load) -
						0.1 * f64(factory_production)
					pro_territory_set_load_value(pro_territory, value)
					append(&prioritized_load_territories, pro_territory)
				}
			}

			// Sort prioritized territories by load value ascending (Java's
			// natural Comparator.comparingDouble order).
			slice.sort_by(
				prioritized_load_territories[:],
				proc(a, b: ^Pro_Territory) -> bool {
					return pro_territory_get_load_value(a) < pro_territory_get_load_value(b)
				},
			)

			moved_transport := false
			for patd in prioritized_load_territories {
				if moved_transport {
					break
				}
				cant_hold_territories := make(map[^Territory]struct {})
				for {
					move_best_sea_through_active = new(Move_Best_Sea_Through_Ctx)
					move_best_sea_through_active.player = self.player
					move_best_sea_through_active.is_combat_move = is_combat_move
					move_best_sea_through_active.cant_hold = cant_hold_territories
					units_for_route := make([dynamic]^Unit, 0, 1)
					append(&units_for_route, transport)
					route := game_map_get_route_for_units(
						game_data_get_map(self.data),
						current_territory,
						pro_territory_get_territory(patd),
						move_best_sea_through_pred,
						units_for_route,
						self.player,
					)
					delete(units_for_route)
					if route == nil {
						break
					}
					territories_in_route := route_get_all_territories(route)
					if len(territories_in_route) == 0 {
						break
					}
					// territories.remove(territories.size() - 1)
					pop(&territories_in_route)
					if len(territories_in_route) == 0 {
						break
					}
					idx := len(territories_in_route) - 1
					if i32(idx) > moves {
						idx = int(moves)
					}
					move_to_territory := territories_in_route[idx]
					patd2, has := move_map[move_to_territory]
					if has && patd2 != nil && pro_territory_is_can_hold(patd2) {
						pro_logger_trace(
							fmt.tprintf(
								"transport moved towards best loading territory %s and moved to %s",
								territory_to_string(pro_territory_get_territory(patd)),
								territory_to_string(move_to_territory),
							),
						)
						pro_territory_add_temp_unit(patd2, transport)
						territories_to_defend[move_to_territory] = {}
						delete_key(&current_transport_move_map, transport)
						moved_transport = true
						break
					}
					if _, already := cant_hold_territories[move_to_territory]; already {
						break
					}
					cant_hold_territories[move_to_territory] = {}
				}
				delete(cant_hold_territories)
			}
		}

		pro_logger_debug("Move remaining transports to safest territory")

		// Move remaining transports to safest territory.
		safest_keys := make([dynamic]^Unit, 0, len(current_transport_move_map))
		defer delete(safest_keys)
		for u in current_transport_move_map {
			append(&safest_keys, u)
		}
		for transport in safest_keys {
			if _, still := current_transport_move_map[transport]; !still {
				continue
			}

			already_moved_units := make([dynamic]^Unit, 0)
			for _, t in move_map {
				for u in pro_territory_get_units(t) {
					append(&already_moved_units, u)
				}
			}
			already_moved_set := make(map[^Unit]struct {})
			for u in already_moved_units {
				already_moved_set[u] = {}
			}

			min_strength_difference: f64 = max(f64)
			min_territory: ^Territory = nil
			for t in current_transport_move_map[transport] {
				pro_territory := move_map[t]
				attackers := pro_territory_get_max_enemy_units(pro_territory)
				max_def := pro_territory_get_max_defenders(pro_territory)
				defenders := make([dynamic]^Unit, 0, len(max_def))
				for u in max_def {
					if _, in_moved := already_moved_set[u]; !in_moved {
						append(&defenders, u)
					}
				}
				for u in pro_territory_get_units(pro_territory) {
					append(&defenders, u)
				}
				cant_land := pro_transport_utils_get_air_that_cant_land_on_carrier(
					self.player,
					t,
					defenders,
				)
				cant_land_set := make(map[^Unit]struct {})
				for u in cant_land {
					cant_land_set[u] = {}
				}
				delete(cant_land)
				filtered_defenders := make([dynamic]^Unit, 0, len(defenders))
				for u in defenders {
					if _, in_cant := cant_land_set[u]; !in_cant {
						append(&filtered_defenders, u)
					}
				}
				delete(defenders)
				delete(cant_land_set)
				strength_difference := pro_battle_utils_estimate_strength_difference(
					t,
					attackers,
					filtered_defenders,
				)
				delete(filtered_defenders)
				if strength_difference < min_strength_difference {
					min_strength_difference = strength_difference
					min_territory = t
				}
			}
			delete(already_moved_units)
			delete(already_moved_set)

			if min_territory == nil {
				continue
			}

			amphib_units := unit_get_transporting_no_args(transport)
			defer delete(amphib_units)
			if len(amphib_units) > 0 {
				allied_p, allied_c := pro_matches_territory_can_move_land_units_and_is_allied(
					self.player,
				)
				possible_unload_territories := game_map_get_neighbors_predicate(
					game_data_get_map(self.data),
					min_territory,
					allied_p,
					allied_c,
				)
				pro_destination: ^Pro_Territory = nil
				if len(possible_unload_territories) > 0 {
					unload_to_territory: ^Territory = nil
					// findAny() filtering by canHold; fall back to getAny().
					for tt in possible_unload_territories {
						if pro_non_combat_move_ai_can_hold(self, move_map, tt) {
							unload_to_territory = tt
							break
						}
					}
					if unload_to_territory == nil {
						for tt in possible_unload_territories {
							unload_to_territory = tt
							break
						}
					}
					pro_destination = pro_data_get_pro_territory(
						self.pro_data,
						move_map,
						unload_to_territory,
					)
				} else {
					pro_destination = pro_data_get_pro_territory(
						self.pro_data,
						move_map,
						min_territory,
					)
				}
				delete(possible_unload_territories)
				pro_territory_add_temp_units(pro_destination, amphib_units)
				pro_territory_put_temp_amphib_attack_map(pro_destination, transport, amphib_units)
				pro_territory_get_transport_territory_map(pro_destination)[transport] =
					min_territory
				for unit in amphib_units {
					delete_key(&current_unit_move_map, unit)
				}
			} else {
				pro_logger_trace(
					fmt.tprintf(
						"transport moved to safest territory %s, strengthDifference=%v",
						territory_to_string(min_territory),
						min_strength_difference,
					),
				)
				pro_territory_add_temp_unit(move_map[min_territory], transport)
			}
			delete_key(&current_transport_move_map, transport)
		}

		// Get all transport final territories.
		amphib_routes := pro_move_utils_calculate_amphib_routes(
			self.pro_data,
			self.player,
			move_map,
			is_combat_move,
		)
		_ = amphib_routes
		for _, t in move_map {
			for unit, terr in pro_territory_get_transport_territory_map(t) {
				territory := move_map[terr]
				if territory != nil {
					pro_territory_add_temp_unit(territory, unit)
				}
			}
		}

		pro_logger_debug("Move sea units")

		// Move sea units to defend transports.
		sea_unit_keys := make([dynamic]^Unit, 0, len(current_unit_move_map))
		defer delete(sea_unit_keys)
		for u in current_unit_move_map {
			append(&sea_unit_keys, u)
		}
		sea_p, sea_c := matches_unit_is_sea()
		owned_transport_p, owned_transport_c := pro_matches_unit_is_owned_transport(self.player)
		for u in sea_unit_keys {
			if _, still := current_unit_move_map[u]; !still {
				continue
			}
			if !sea_p(sea_c, u) {
				continue
			}
			for t in current_unit_move_map[u] {
				pro_territory := move_map[t]
				if !pro_territory_is_can_hold(pro_territory) {
					continue
				}
				has_owned_transport := false
				all_def := pro_territory_get_all_defenders(pro_territory)
				for du in all_def {
					if owned_transport_p(owned_transport_c, du) {
						has_owned_transport = true
						break
					}
				}
				if !has_owned_transport {
					continue
				}
				if !pro_transport_utils_check_transport_defense(
					self.pro_data,
					self.calc,
					pro_territory,
				) {
					continue
				}
				pro_territory_add_temp_unit(pro_territory, u)
				pro_territory_set_battle_result(pro_territory, nil)
				territories_to_defend[t] = {}
				pro_non_combat_move_ai_move_allied_carried_fighters(self, u, pro_territory)
				delete_key(&current_unit_move_map, u)
				break
			}
		}

		// Move air units to defend transports.
		air_def_keys := make([dynamic]^Unit, 0, len(current_unit_move_map))
		defer delete(air_def_keys)
		for u in current_unit_move_map {
			append(&air_def_keys, u)
		}
		can_carrier_p, can_carrier_c := matches_unit_can_land_on_carrier()
		for u in air_def_keys {
			if _, still := current_unit_move_map[u]; !still {
				continue
			}
			if !can_carrier_p(can_carrier_c, u) {
				continue
			}
			for t in current_unit_move_map[u] {
				pro_territory := move_map[t]
				if !territory_is_water(t) {
					continue
				}
				if !pro_territory_is_can_hold(pro_territory) {
					continue
				}
				has_owned_transport := false
				all_def := pro_territory_get_all_defenders(pro_territory)
				for du in all_def {
					if owned_transport_p(owned_transport_c, du) {
						has_owned_transport = true
						break
					}
				}
				if !has_owned_transport {
					continue
				}
				carrier_calcs := pro_territory_get_all_defenders_for_carrier_calcs(
					pro_territory,
					self.data,
					self.player,
				)
				carrier_list := make([dynamic]^Unit, 0, len(carrier_calcs))
				for du in carrier_calcs {
					append(&carrier_list, du)
				}
				if !pro_transport_utils_validate_carrier_capacity(
					self.player,
					t,
					carrier_list,
					u,
				) {
					delete(carrier_list)
					delete(carrier_calcs)
					continue
				}
				delete(carrier_list)
				delete(carrier_calcs)
				if !pro_transport_utils_check_transport_defense(
					self.pro_data,
					self.calc,
					pro_territory,
				) {
					continue
				}
				pro_territory_add_temp_unit(pro_territory, u)
				pro_territory_set_battle_result(pro_territory, nil)
				territories_to_defend[t] = {}
				delete_key(&current_unit_move_map, u)
				break
			}
		}

		// Move sea units to best location or safest location.
		sea_best_keys := make([dynamic]^Unit, 0, len(current_unit_move_map))
		defer delete(sea_best_keys)
		for u in current_unit_move_map {
			append(&sea_best_keys, u)
		}
		for u in sea_best_keys {
			if _, still := current_unit_move_map[u]; !still {
				continue
			}
			if !sea_p(sea_c, u) {
				continue
			}
			max_value_t: ^Territory = nil
			max_value: f64 = 0
			for t in current_unit_move_map[u] {
				pro_territory := move_map[t]
				if !pro_territory_is_can_hold(pro_territory) {
					continue
				}
				transports: i32 = 0
				all_def := pro_territory_get_all_defenders(pro_territory)
				for du in all_def {
					if owned_transport_p(owned_transport_c, du) {
						transports += 1
					}
				}
				value :=
					f64(1 + transports) * pro_territory_get_sea_value(pro_territory) +
					(1.0 + f64(transports) * 100.0) * pro_territory_get_value(pro_territory) /
						10000.0
				if value > max_value {
					max_value = value
					max_value_t = t
				}
			}
			if max_value_t != nil {
				to := move_map[max_value_t]
				pro_territory_add_temp_unit(to, u)
				pro_territory_set_battle_result(to, nil)
				territories_to_defend[max_value_t] = {}
				pro_non_combat_move_ai_move_allied_carried_fighters(self, u, to)
				delete_key(&current_unit_move_map, u)
			} else {
				already_moved_units := make([dynamic]^Unit, 0)
				for _, t in move_map {
					for unit in pro_territory_get_units(t) {
						append(&already_moved_units, unit)
					}
				}
				already_moved_set := make(map[^Unit]struct {})
				for unit in already_moved_units {
					already_moved_set[unit] = {}
				}
				min_strength_difference: f64 = max(f64)
				min_territory: ^Territory = nil
				for t in current_unit_move_map[u] {
					pro_territory := move_map[t]
					attackers := pro_territory_get_max_enemy_units(pro_territory)
					max_def := pro_territory_get_max_defenders(pro_territory)
					defenders := make([dynamic]^Unit, 0, len(max_def))
					for du in max_def {
						if _, in_moved := already_moved_set[du]; !in_moved {
							append(&defenders, du)
						}
					}
					for du in pro_territory_get_units(pro_territory) {
						append(&defenders, du)
					}
					strength_difference := pro_battle_utils_estimate_strength_difference(
						t,
						attackers,
						defenders,
					)
					delete(defenders)
					if strength_difference < min_strength_difference {
						min_strength_difference = strength_difference
						min_territory = t
					}
				}
				delete(already_moved_units)
				delete(already_moved_set)
				if min_territory != nil {
					to := move_map[min_territory]
					pro_territory_add_temp_unit(to, u)
					pro_territory_set_battle_result(to, nil)
					pro_non_combat_move_ai_move_allied_carried_fighters(self, u, to)
					delete_key(&current_unit_move_map, u)
				} else {
					current_t := self.unit_territory_map[u]
					pro_territory_add_temp_unit(move_map[current_t], u)
					pro_territory_set_battle_result(move_map[current_t], nil)
					delete_key(&current_unit_move_map, u)
				}
			}
		}

		// Determine if all defenses are successful.
		pro_logger_debug(
			fmt.tprintf(
				"Checking if all sea moves are safe for %d territories",
				len(territories_to_defend),
			),
		)
		costs := new(Integer_Map_Unit_Type)
		costs.entries = pro_data_get_unit_value_map(self.pro_data)

		are_successful := true
		for t in territories_to_defend {
			pro_territory := move_map[t]
			result := pro_odds_calculator_calculate_battle_results_2(
				self.calc,
				self.pro_data,
				pro_territory,
			)
			pro_territory_set_battle_result(pro_territory, result)
			is_water: i32 = 0
			if territory_is_water(t) {
				is_water = 1
			}
			extra_unit_value := f64(
				tuv_utils_get_tuv(pro_territory_get_temp_units(pro_territory), costs),
			)
			hold_value :=
				pro_battle_result_get_tuv_swing(result) -
				(extra_unit_value / 8.0 * f64(1 + is_water))

			defending_units := pro_territory_get_all_defenders(pro_territory)
			min_defending_units := make([dynamic]^Unit, 0, len(defending_units))
			temp_set := make(map[^Unit]struct {})
			for tu in pro_territory_get_temp_units(pro_territory) {
				temp_set[tu] = {}
			}
			for du in defending_units {
				if _, in_temp := temp_set[du]; !in_temp {
					append(&min_defending_units, du)
				}
			}
			delete(temp_set)
			min_result := pro_odds_calculator_calculate_battle_results_3(
				self.calc,
				self.pro_data,
				pro_territory,
				min_defending_units,
			)
			delete(min_defending_units)
			delete(defending_units)

			if hold_value > pro_battle_result_get_tuv_swing(min_result) {
				are_successful = false
				pro_territory_set_can_hold(pro_territory, false)
				pro_territory_set_value(pro_territory, 0)
				pro_territory_set_sea_value(pro_territory, 0)
				pro_logger_trace(
					fmt.tprintf(
						"%s unable to defend so removing with holdValue=%v, minTUVSwing=%v",
						territory_to_string(t),
						hold_value,
						pro_battle_result_get_tuv_swing(min_result),
					),
				)
			}
			pro_logger_trace(
				fmt.tprintf(
					"%s, holdValue=%v, minTUVSwing=%v",
					pro_territory_get_result_string(pro_territory),
					hold_value,
					pro_battle_result_get_tuv_swing(min_result),
				),
			)
		}

		if are_successful {
			break
		}
	}

	// Add temp units to move lists.
	owned_p, owned_c := matches_unit_is_owned_by(self.player)
	sea_transport_p, sea_transport_c := matches_unit_is_sea_transport()
	for _, t in move_map {
		// Handle allied units (not owned-by player).
		allied_units := make([dynamic]^Unit, 0)
		for u in t.temp_units {
			if !owned_p(owned_c, u) {
				append(&allied_units, u)
			}
		}
		for au in allied_units {
			pro_territory_add_cant_move_unit(t, au)
			// Remove au from t.temp_units in-place.
			for i := 0; i < len(t.temp_units); i += 1 {
				if t.temp_units[i] == au {
					ordered_remove(&t.temp_units, i)
					break
				}
			}
		}
		delete(allied_units)

		pro_territory_add_units(t, t.temp_units)
		pro_territory_put_all_amphib_attack_map(t, t.temp_amphib_attack_map)
		for u in t.temp_units {
			if sea_transport_p(sea_transport_c, u) {
				delete_key(&transport_move_map, u)
				new_list := make([dynamic]^Pro_Transport, 0, len(transport_map_list_mut))
				for tr in transport_map_list_mut {
					if pro_transport_get_transport(tr) != u {
						append(&new_list, tr)
					}
				}
				delete(transport_map_list_mut)
				transport_map_list_mut = new_list
			} else {
				delete_key(&unit_move_map, u)
			}
		}
		for u in t.temp_amphib_attack_map {
			delete_key(&transport_move_map, u)
			new_list := make([dynamic]^Pro_Transport, 0, len(transport_map_list_mut))
			for tr in transport_map_list_mut {
				if pro_transport_get_transport(tr) != u {
					append(&new_list, tr)
				}
			}
			delete(transport_map_list_mut)
			transport_map_list_mut = new_list
		}
		clear(&t.temp_units)
		clear(&t.temp_amphib_attack_map)
	}

	pro_logger_info("Move land units")

	// Move land units to territory with highest value and highest transport capacity.
	can_move_sea_p, can_move_sea_c := pro_matches_territory_can_move_sea_units(self.player, true)
	added_units := make([dynamic]^Unit, 0)
	defer delete(added_units)
	added_set := make(map[^Unit]struct {})
	defer delete(added_set)

	land_p, land_c := matches_unit_is_land()
	land_keys := make([dynamic]^Unit, 0, len(unit_move_map))
	defer delete(land_keys)
	for u in unit_move_map {
		append(&land_keys, u)
	}
	for u in land_keys {
		if !land_p(land_c, u) {
			continue
		}
		if _, was_added := added_set[u]; was_added {
			continue
		}
		max_value_t: ^Territory = nil
		max_value: f64 = 0
		max_need_amphib_unit_value: i32 = min(i32)
		for t in unit_move_map[u] {
			pro_territory := move_map[t]
			if !pro_territory_is_can_hold(pro_territory) ||
			   pro_territory_get_value(pro_territory) < max_value {
				continue
			}
			sea_neighbors := game_map_get_neighbors_predicate(
				game_data_get_map(self.data),
				t,
				can_move_sea_p,
				can_move_sea_c,
			)
			sea_neighbor_list := make([dynamic]^Territory, 0, len(sea_neighbors))
			for sn in sea_neighbors {
				append(&sea_neighbor_list, sn)
			}
			transport_capacity_1: i32 = 0
			transports_1 := pro_transport_utils_get_transports(
				self.player,
				move_map,
				sea_neighbor_list,
			)
			for tr in transports_1 {
				transport_capacity_1 += unit_attachment_get_transport_capacity(
					unit_get_unit_attachment(tr),
				)
			}
			delete(transports_1)
			delete(sea_neighbor_list)

			nearby_sea := game_map_get_neighbors_distance_predicate(
				game_data_get_map(self.data),
				t,
				2,
				can_move_sea_p,
				can_move_sea_c,
			)
			// nearbySeaTerritories.removeAll(seaNeighbors)
			nearby_sea_list := make([dynamic]^Territory, 0, len(nearby_sea))
			for sn in nearby_sea {
				if _, in_close := sea_neighbors[sn]; !in_close {
					append(&nearby_sea_list, sn)
				}
			}
			transport_capacity_2: i32 = 0
			transports_2 := pro_transport_utils_get_transports(
				self.player,
				move_map,
				nearby_sea_list,
			)
			for tr in transports_2 {
				transport_capacity_2 += unit_attachment_get_transport_capacity(
					unit_get_unit_attachment(tr),
				)
			}
			delete(transports_2)
			delete(nearby_sea_list)

			transportable_p, transportable_c := pro_matches_unit_is_owned_transportable_unit(
				self.player,
			)
			all_def := pro_territory_get_all_defenders(pro_territory)
			units_to_transport := make([dynamic]^Unit, 0)
			for du in all_def {
				if transportable_p(transportable_c, du) {
					append(&units_to_transport, du)
				}
			}
			transport_cost: i32 = 0
			for unit in units_to_transport {
				transport_cost += unit_attachment_get_transport_cost(
					unit_get_unit_attachment(unit),
				)
			}
			delete(units_to_transport)

			factory_adj_sea_p, factory_adj_sea_c := pro_matches_territory_has_infra_factory_and_is_owned_land_adjacent_to_sea(
				self.player,
			)
			has_factory: i32 = 0
			if factory_adj_sea_p(factory_adj_sea_c, t) {
				has_factory = 1
			}
			needed_neighbor := i32(max(0, transport_capacity_1 - transport_cost))
			needed_nearby := i32(max(0, transport_capacity_1 + transport_capacity_2 - transport_cost))
			need_amphib_unit_value :=
				1000 * needed_neighbor +
				100 * needed_nearby +
				(1 + 10 * has_factory) * i32(len(sea_neighbors))
			delete(sea_neighbors)
			delete(nearby_sea)

			if pro_territory_get_value(pro_territory) > max_value ||
			   need_amphib_unit_value > max_need_amphib_unit_value {
				max_value = pro_territory_get_value(pro_territory)
				max_need_amphib_unit_value = need_amphib_unit_value
				max_value_t = t
			}
		}
		if max_value_t != nil {
			units_to_add := pro_transport_utils_get_units_to_add(
				self.pro_data,
				u,
				added_units,
				move_map,
			)
			pro_territory_add_units(move_map[max_value_t], units_to_add)
			for au in units_to_add {
				append(&added_units, au)
				added_set[au] = {}
			}
			delete(units_to_add)
		}
	}
	for au in added_units {
		delete_key(&unit_move_map, au)
	}

	// Move land units towards nearest factory adjacent to sea.
	factory_adj_sea_p, factory_adj_sea_c := pro_matches_territory_has_infra_factory_and_is_owned_land_adjacent_to_sea(
		self.player,
	)
	all_terrs := game_map_get_territories(game_data_get_map(self.data))
	my_factories_adjacent_to_sea := make([dynamic]^Territory, 0)
	for t in all_terrs {
		if factory_adj_sea_p(factory_adj_sea_c, t) {
			append(&my_factories_adjacent_to_sea, t)
		}
	}
	can_move_land_p, can_move_land_c := pro_matches_territory_can_move_land_units(self.player, true)
	land_keys2 := make([dynamic]^Unit, 0, len(unit_move_map))
	defer delete(land_keys2)
	for u in unit_move_map {
		append(&land_keys2, u)
	}
	for u in land_keys2 {
		if !land_p(land_c, u) {
			continue
		}
		if _, was_added := added_set[u]; was_added {
			continue
		}
		min_distance: i32 = max(i32)
		min_territory: ^Territory = nil
		for t in unit_move_map[u] {
			if !pro_territory_is_can_hold(move_map[t]) {
				continue
			}
			for factory in my_factories_adjacent_to_sea {
				distance := game_map_get_distance_predicate(
					game_data_get_map(self.data),
					t,
					factory,
					can_move_land_p,
					can_move_land_c,
				)
				if distance < 0 {
					distance = 10 * game_map_get_distance(
						game_data_get_map(self.data),
						t,
						factory,
					)
				}
				if distance >= 0 && distance < min_distance {
					min_distance = distance
					min_territory = t
				}
			}
		}
		if min_territory != nil {
			units_to_add := pro_transport_utils_get_units_to_add(
				self.pro_data,
				u,
				added_units,
				move_map,
			)
			pro_territory_add_units(move_map[min_territory], units_to_add)
			for au in units_to_add {
				append(&added_units, au)
				added_set[au] = {}
			}
			delete(units_to_add)
		}
	}
	delete(my_factories_adjacent_to_sea)
	for au in added_units {
		delete_key(&unit_move_map, au)
	}

	pro_logger_info("Move land units to safest territory")

	// Move any remaining land units to safest territory.
	land_keys3 := make([dynamic]^Unit, 0, len(unit_move_map))
	defer delete(land_keys3)
	for u in unit_move_map {
		append(&land_keys3, u)
	}
	for u in land_keys3 {
		if !land_p(land_c, u) {
			continue
		}
		if _, was_added := added_set[u]; was_added {
			continue
		}
		already_moved_units := make([dynamic]^Unit, 0)
		for _, t in move_map {
			for unit in pro_territory_get_units(t) {
				append(&already_moved_units, unit)
			}
		}
		already_moved_set := make(map[^Unit]struct {})
		for unit in already_moved_units {
			already_moved_set[unit] = {}
		}
		min_strength_difference: f64 = max(f64)
		min_territory: ^Territory = nil
		for t in unit_move_map[u] {
			pro_territory := move_map[t]
			attackers := pro_territory_get_max_enemy_units(pro_territory)
			max_def := pro_territory_get_max_defenders(pro_territory)
			defenders := make([dynamic]^Unit, 0, len(max_def))
			for du in max_def {
				if _, in_moved := already_moved_set[du]; !in_moved {
					append(&defenders, du)
				}
			}
			for du in pro_territory_get_units(pro_territory) {
				append(&defenders, du)
			}
			strength_difference := pro_battle_utils_estimate_strength_difference(
				t,
				attackers,
				defenders,
			)
			delete(defenders)
			if strength_difference < min_strength_difference {
				min_strength_difference = strength_difference
				min_territory = t
			}
		}
		delete(already_moved_units)
		delete(already_moved_set)
		if min_territory != nil {
			units_to_add := pro_transport_utils_get_units_to_add(
				self.pro_data,
				u,
				added_units,
				move_map,
			)
			pro_territory_add_units(move_map[min_territory], units_to_add)
			for au in units_to_add {
				append(&added_units, au)
				added_set[au] = {}
			}
			delete(units_to_add)
		}
	}
	for au in added_units {
		delete_key(&unit_move_map, au)
	}

	pro_logger_info("Move air units")

	// List of territories that can't be held.
	territories_that_cant_be_held := make([dynamic]^Territory, 0)
	defer delete(territories_that_cant_be_held)
	for t, pt in move_map {
		if !pro_territory_is_can_hold(pt) {
			append(&territories_that_cant_be_held, t)
		}
	}

	// Move air units to safe territory with most attack options.
	air_safe_keys := make([dynamic]^Unit, 0, len(unit_move_map))
	defer delete(air_safe_keys)
	for u in unit_move_map {
		append(&air_safe_keys, u)
	}
	not_air_p, not_air_c := matches_unit_is_not_air()
	for u in air_safe_keys {
		if _, still := unit_move_map[u]; !still {
			continue
		}
		if not_air_p(not_air_c, u) {
			continue
		}
		max_air_value: f64 = 0
		max_t: ^Territory = nil
		for t in unit_move_map[u] {
			pro_territory := move_map[t]
			if !pro_territory_is_can_hold(pro_territory) {
				continue
			}
			carrier_calcs := pro_territory_get_all_defenders_for_carrier_calcs(
				pro_territory,
				self.data,
				self.player,
			)
			carrier_list := make([dynamic]^Unit, 0, len(carrier_calcs))
			for du in carrier_calcs {
				append(&carrier_list, du)
			}
			delete(carrier_calcs)
			if territory_is_water(t) &&
			   !pro_transport_utils_validate_carrier_capacity(
				   self.player,
				   t,
				   carrier_list,
				   u,
			   ) {
				delete(carrier_list)
				continue
			}
			delete(carrier_list)

			defending_set := pro_territory_get_all_defenders(pro_territory)
			defending_units := make([dynamic]^Unit, 0, len(defending_set) + 1)
			for du in defending_set {
				append(&defending_units, du)
			}
			append(&defending_units, u)
			delete(defending_set)

			if pro_territory_get_battle_result(pro_territory) == nil {
				pro_territory_set_battle_result(
					pro_territory,
					pro_odds_calculator_calculate_battle_results_3(
						self.calc,
						self.pro_data,
						pro_territory,
						defending_units,
					),
				)
			}
			result := pro_territory_get_battle_result(pro_territory)
			if pro_battle_result_get_win_percentage(result) >= self.pro_data.min_win_percentage ||
			   pro_battle_result_get_tuv_swing(result) > 0 {
				pro_territory_set_can_hold(pro_territory, false)
				delete(defending_units)
				continue
			}

			my_defenders := make([dynamic]^Unit, 0, len(defending_units))
			for du in defending_units {
				if owned_p(owned_c, du) {
					append(&my_defenders, du)
				}
			}
			result_2 := pro_odds_calculator_calculate_battle_results_3(
				self.calc,
				self.pro_data,
				pro_territory,
				my_defenders,
			)
			delete(my_defenders)
			cant_hold_without_allies: i32 = 0
			if pro_battle_result_get_win_percentage(result_2) >= self.pro_data.min_win_percentage ||
			   pro_battle_result_get_tuv_swing(result_2) > 0 {
				cant_hold_without_allies = 1
			}

			range_v := unit_get_max_movement_allowed(u)
			can_move_air_p, can_move_air_c := pro_matches_territory_can_move_air_units(
				self.data,
				self.player,
				true,
			)
			possible_attack_territories := game_map_get_neighbors_distance_predicate(
				game_data_get_map(self.data),
				t,
				range_v / 2,
				can_move_air_p,
				can_move_air_c,
			)
			enemy_not_passive_p, enemy_not_passive_c := pro_matches_territory_is_enemy_not_passive_neutral_land(
				self.player,
			)
			num_enemy_attack: i32 = 0
			for at in possible_attack_territories {
				if enemy_not_passive_p(enemy_not_passive_c, at) {
					num_enemy_attack += 1
				}
			}
			enemy_or_cant_hold_p, enemy_or_cant_hold_c := pro_matches_territory_is_enemy_or_cant_be_held_and_is_adjacent_to_my_land_units(
				self.player,
				territories_that_cant_be_held,
			)
			num_land_attack: i32 = 0
			for at in possible_attack_territories {
				if enemy_or_cant_hold_p(enemy_or_cant_hold_c, at) {
					num_land_attack += 1
				}
			}
			has_enemy_sea_p, has_enemy_sea_c := matches_territory_has_enemy_sea_units(self.player)
			sub_p, sub_c := matches_unit_has_sub_battle_abilities()
			num_sea_attack: i32 = 0
			for at in possible_attack_territories {
				if !has_enemy_sea_p(has_enemy_sea_c, at) {
					continue
				}
				// territoryHasUnitsThatMatch(unitHasSubBattleAbilities().negate())
				has_non_sub := false
				for unit in unit_collection_get_units(territory_get_unit_collection(at)) {
					if !sub_p(sub_c, unit) {
						has_non_sub = true
						break
					}
				}
				if has_non_sub {
					num_sea_attack += 1
				}
			}
			delete(possible_attack_territories)

			possible_move_territories := game_map_get_neighbors_distance_predicate(
				game_data_get_map(self.data),
				t,
				range_v,
				can_move_air_p,
				can_move_air_c,
			)
			num_nearby_enemy: i32 = 0
			for mt in possible_move_territories {
				if enemy_not_passive_p(enemy_not_passive_c, mt) {
					num_nearby_enemy += 1
				}
			}
			delete(possible_move_territories)

			factory_land_p, factory_land_c := pro_matches_territory_has_infra_factory_and_is_land()
			isnt_factory: i32 = 1
			if factory_land_p(factory_land_c, t) {
				isnt_factory = 0
			}
			owned_carrier_p, owned_carrier_c := pro_matches_unit_is_owned_carrier(self.player)
			has_owned_carrier: i32 = 0
			all_def := pro_territory_get_all_defenders(pro_territory)
			for du in all_def {
				if owned_carrier_p(owned_carrier_c, du) {
					has_owned_carrier = 1
					break
				}
			}
			delete(all_def)

			air_value :=
				(200.0 * f64(num_sea_attack) +
						100.0 * f64(num_land_attack) +
						10.0 * f64(num_enemy_attack) +
						f64(num_nearby_enemy)) /
				f64(1 + cant_hold_without_allies) /
				(1.0 + f64(cant_hold_without_allies) * f64(isnt_factory)) *
				f64(1 + has_owned_carrier)
			if air_value > max_air_value {
				max_air_value = air_value
				max_t = t
			}
			delete(defending_units)
		}
		if max_t != nil {
			pro_territory_add_unit(move_map[max_t], u)
			pro_territory_set_battle_result(move_map[max_t], nil)
			delete_key(&unit_move_map, u)
		}
	}

	// Move air units to safest territory.
	air_safest_keys := make([dynamic]^Unit, 0, len(unit_move_map))
	defer delete(air_safest_keys)
	for u in unit_move_map {
		append(&air_safest_keys, u)
	}
	for u in air_safest_keys {
		if _, still := unit_move_map[u]; !still {
			continue
		}
		if not_air_p(not_air_c, u) {
			continue
		}
		min_strength_difference: f64 = max(f64)
		min_territory: ^Territory = nil
		for t in unit_move_map[u] {
			pro_territory := move_map[t]
			carrier_calcs := pro_territory_get_all_defenders_for_carrier_calcs(
				pro_territory,
				self.data,
				self.player,
			)
			carrier_list := make([dynamic]^Unit, 0, len(carrier_calcs))
			for du in carrier_calcs {
				append(&carrier_list, du)
			}
			delete(carrier_calcs)
			if territory_is_water(t) &&
			   !pro_transport_utils_validate_carrier_capacity(
				   self.player,
				   t,
				   carrier_list,
				   u,
			   ) {
				delete(carrier_list)
				continue
			}
			delete(carrier_list)
			attackers := pro_territory_get_max_enemy_units(pro_territory)
			defending_set := pro_territory_get_all_defenders(pro_territory)
			defenders := make([dynamic]^Unit, 0, len(defending_set) + 1)
			for du in defending_set {
				append(&defenders, du)
			}
			append(&defenders, u)
			delete(defending_set)
			strength_difference := pro_battle_utils_estimate_strength_difference(
				t,
				attackers,
				defenders,
			)
			delete(defenders)
			if strength_difference < min_strength_difference {
				min_strength_difference = strength_difference
				min_territory = t
			}
		}
		if min_territory != nil {
			pro_territory_add_unit(move_map[min_territory], u)
			delete_key(&unit_move_map, u)
		}
	}

	delete(transport_map_list_mut)
}

