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

