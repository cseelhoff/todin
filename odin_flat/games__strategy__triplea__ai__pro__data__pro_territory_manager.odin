package game

import "core:slice"

Pro_Territory_Manager :: struct {
	calc:                     ^Pro_Odds_Calculator,
	pro_data:                 ^Pro_Data,
	player:                   ^Game_Player,
	attack_options:           ^Pro_My_Move_Options,
	potential_attack_options: ^Pro_My_Move_Options,
	defend_options:           ^Pro_My_Move_Options,
	allied_attack_options:    ^Pro_Other_Move_Options,
	enemy_defend_options:     ^Pro_Other_Move_Options,
	enemy_attack_options:     ^Pro_Other_Move_Options,
}

pro_territory_manager_get_attack_options :: proc(self: ^Pro_Territory_Manager) -> ^Pro_My_Move_Options {
	return self.attack_options
}

pro_territory_manager_get_defend_options :: proc(self: ^Pro_Territory_Manager) -> ^Pro_My_Move_Options {
	return self.defend_options
}

pro_territory_manager_get_allied_attack_options :: proc(self: ^Pro_Territory_Manager) -> ^Pro_Other_Move_Options {
	return self.allied_attack_options
}

pro_territory_manager_get_enemy_defend_options :: proc(self: ^Pro_Territory_Manager) -> ^Pro_Other_Move_Options {
	return self.enemy_defend_options
}

pro_territory_manager_get_enemy_attack_options :: proc(self: ^Pro_Territory_Manager) -> ^Pro_Other_Move_Options {
	return self.enemy_attack_options
}

// Lambda: findNavalMoveOptions  transportMoveMap.computeIfAbsent(mySeaUnit, k -> new HashSet<>())
pro_territory_manager_lambda_find_naval_move_options_1 :: proc(k: ^Unit) -> map[^Territory]struct {} {
	return make(map[^Territory]struct {})
}

// Lambda: findNavalMoveOptions  unitMoveMap.computeIfAbsent(mySeaUnit, k -> new HashSet<>())
pro_territory_manager_lambda_find_naval_move_options_2 :: proc(k: ^Unit) -> map[^Territory]struct {} {
	return make(map[^Territory]struct {})
}

// Lambda: findLandMoveOptions  landRoutesMap.computeIfAbsent(t, k -> new HashSet<>())
pro_territory_manager_lambda_find_land_move_options_3 :: proc(k: ^Territory) -> map[^Territory]struct {} {
	return make(map[^Territory]struct {})
}

// Lambda: findLandMoveOptions  unitMoveMap.computeIfAbsent(u, k -> new HashSet<>())
pro_territory_manager_lambda_find_land_move_options_4 :: proc(k: ^Unit) -> map[^Territory]struct {} {
	return make(map[^Territory]struct {})
}

// Lambda: findAirMoveOptions  unitMoveMap.computeIfAbsent(myAirUnit, k -> new HashSet<>())
pro_territory_manager_lambda_find_air_move_options_5 :: proc(k: ^Unit) -> map[^Territory]struct {} {
	return make(map[^Territory]struct {})
}

// Lambda: findBombardOptions  bombardMap.computeIfAbsent(mySeaUnit, k -> new HashSet<>())
pro_territory_manager_lambda_find_bombard_options_7 :: proc(k: ^Unit) -> map[^Territory]struct {} {
	return make(map[^Territory]struct {})
}

// Lambda: findClosestTerritory  bfs.traverse((territory, distance) -> { ... })
// Captures Predicate<Territory> isDestination and MutableObject<Territory> destination,
// passed explicitly as leading parameters per Java desugaring. Predicate uses the
// (proc, ctx) closure-capture convention; MutableObject<Territory> is modeled as ^^Territory.
pro_territory_manager_lambda_find_closest_territory_8 :: proc(
	is_destination: proc(rawptr, ^Territory) -> bool,
	is_destination_ctx: rawptr,
	destination: ^^Territory,
	territory: ^Territory,
	distance: i32,
) -> bool {
	if is_destination(is_destination_ctx, territory) {
		destination^ = territory
		return false
	}
	return true
}

pro_territory_manager_new :: proc(calc: ^Pro_Odds_Calculator, pro_data: ^Pro_Data) -> ^Pro_Territory_Manager {
	self := new(Pro_Territory_Manager)
	self.calc = calc
	self.pro_data = pro_data
	self.player = pro_data_get_player(pro_data)
	self.attack_options = pro_my_move_options_new()
	self.potential_attack_options = pro_my_move_options_new()
	self.defend_options = pro_my_move_options_new()
	self.allied_attack_options = pro_other_move_options_new()
	self.enemy_defend_options = pro_other_move_options_new()
	self.enemy_attack_options = pro_other_move_options_new()
	return self
}

pro_territory_manager_find_bombing_options :: proc(self: ^Pro_Territory_Manager) {
	pred, ctx := matches_unit_is_strategic_bomber()
	unit_move_map := pro_my_move_options_get_unit_move_map(self.attack_options)
	bomber_move_map := pro_my_move_options_get_bomber_move_map(self.attack_options)
	for unit, dests in unit_move_map {
		if pred(ctx, unit) {
			copy_set := make(map[^Territory]struct {})
			for t, _ in dests {
				copy_set[t] = struct {}{}
			}
			bomber_move_map[unit] = copy_set
		}
	}
}

pro_territory_manager_get_defend_territories :: proc(self: ^Pro_Territory_Manager) -> [dynamic]^Territory {
	result: [dynamic]^Territory
	territory_map := pro_my_move_options_get_territory_map(self.defend_options)
	for t, _ in territory_map {
		append(&result, t)
	}
	return result
}

pro_territory_manager_get_strafing_territories :: proc(self: ^Pro_Territory_Manager) -> [dynamic]^Territory {
	strafing_territories: [dynamic]^Territory
	territory_map := pro_my_move_options_get_territory_map(self.attack_options)
	for t, patd in territory_map {
		if pro_territory_is_strafing(patd) {
			append(&strafing_territories, t)
		}
	}
	return strafing_territories
}

pro_territory_manager_get_cant_hold_territories :: proc(self: ^Pro_Territory_Manager) -> [dynamic]^Territory {
	territories_that_cant_be_held: [dynamic]^Territory
	territory_map := pro_my_move_options_get_territory_map(self.defend_options)
	for t, patd in territory_map {
		if !pro_territory_is_can_hold(patd) {
			append(&territories_that_cant_be_held, t)
		}
	}
	return territories_that_cant_be_held
}

pro_territory_manager_have_used_all_attack_transports :: proc(self: ^Pro_Territory_Manager) -> bool {
	moved_transports: map[^Unit]struct {}
	territory_map := pro_my_move_options_get_territory_map(self.attack_options)
	is_sea_transport, is_sea_transport_ctx := matches_unit_is_sea_transport()
	for _, patd in territory_map {
		amphib := pro_territory_get_amphib_attack_map(patd)
		for u in amphib {
			moved_transports[u] = {}
		}
		units := pro_territory_get_units(patd)
		for u in units {
			if is_sea_transport(is_sea_transport_ctx, u) {
				moved_transports[u] = {}
			}
		}
	}
	transport_list := pro_my_move_options_get_transport_list(self.attack_options)
	return len(moved_transports) >= len(transport_list)
}

// games.strategy.triplea.ai.pro.data.ProTerritoryManager#<init>(ProOddsCalculator, ProData, ProTerritoryManager)
// Java copy-style constructor: delegates to the (calc, proData) ctor, then
// rebuilds the Pro_My_Move_Options via their copy ctor and shares the
// other-move-options refs from the source manager.
pro_territory_manager_new_with_existing :: proc(
	calc: ^Pro_Odds_Calculator,
	pro_data: ^Pro_Data,
	territory_manager: ^Pro_Territory_Manager,
) -> ^Pro_Territory_Manager {
	self := pro_territory_manager_new(calc, pro_data)
	self.attack_options = pro_my_move_options_new_copy(territory_manager.attack_options, pro_data)
	self.potential_attack_options = pro_my_move_options_new_copy(
		territory_manager.potential_attack_options,
		pro_data,
	)
	self.defend_options = pro_my_move_options_new_copy(territory_manager.defend_options, pro_data)
	self.allied_attack_options = pro_territory_manager_get_allied_attack_options(territory_manager)
	self.enemy_defend_options = pro_territory_manager_get_enemy_defend_options(territory_manager)
	self.enemy_attack_options = pro_territory_manager_get_enemy_attack_options(territory_manager)
	return self
}

// File-scope holder bridging two ctx-form Predicate<Territory> values
// (canMove and isDestination) into the BiPredicate-shaped neighborCondition
// that BreadthFirstSearch consumes. BFS is single-threaded and constructed-
// then-traversed, matching the holder pattern used by breadth_first_search.odin.
@(private = "file")
pro_territory_manager_find_closest_territory_active_can_move: proc(
	ctx: rawptr,
	t: ^Territory,
) -> bool

@(private = "file")
pro_territory_manager_find_closest_territory_active_can_move_ctx: rawptr

@(private = "file")
pro_territory_manager_find_closest_territory_active_is_destination: proc(
	ctx: rawptr,
	t: ^Territory,
) -> bool

@(private = "file")
pro_territory_manager_find_closest_territory_active_is_destination_ctx: rawptr

@(private = "file")
pro_territory_manager_find_closest_territory_or_predicate :: proc(
	it: ^Territory,
	it2: ^Territory,
) -> bool {
	if pro_territory_manager_find_closest_territory_active_can_move(
		pro_territory_manager_find_closest_territory_active_can_move_ctx,
		it2,
	) {
		return true
	}
	return pro_territory_manager_find_closest_territory_active_is_destination(
		pro_territory_manager_find_closest_territory_active_is_destination_ctx,
		it2,
	)
}

// Visitor adapter for the bfs.traverse lambda inside findClosestTerritory.
// Captures the isDestination Predicate (ctx-form) and the MutableObject<Territory>
// out-param (modeled as ^^Territory) so the synthetic
// pro_territory_manager_lambda_find_closest_territory_8 can be invoked from
// the Breadth_First_Search_Visitor vtable slot.
Pro_Territory_Manager_Find_Closest_Territory_Visitor :: struct {
	using visitor:      Breadth_First_Search_Visitor,
	is_destination:     proc(ctx: rawptr, t: ^Territory) -> bool,
	is_destination_ctx: rawptr,
	destination:        ^^Territory,
}

@(private = "file")
pro_territory_manager_find_closest_territory_visit :: proc(
	self: ^Breadth_First_Search_Visitor,
	territory: ^Territory,
	distance: i32,
) -> bool {
	me := cast(^Pro_Territory_Manager_Find_Closest_Territory_Visitor)self
	return pro_territory_manager_lambda_find_closest_territory_8(
		me.is_destination,
		me.is_destination_ctx,
		me.destination,
		territory,
		distance,
	)
}

// games.strategy.triplea.ai.pro.data.ProTerritoryManager#findClosestTerritory(Collection, Predicate, Predicate)
// Java:
//   BreadthFirstSearch bfs = new BreadthFirstSearch(fromTerritories, canMove.or(isDestination));
//   MutableObject<Territory> destination = new MutableObject<>();
//   bfs.traverse((territory, distance) -> { if (isDestination.test(territory)) { destination.setValue(territory); return false; } return true; });
//   return Optional.ofNullable(destination.getValue());
//
// Optional<Territory> is modeled as a (possibly nil) ^Territory return.
pro_territory_manager_find_closest_territory :: proc(
	self: ^Pro_Territory_Manager,
	from_territories: [dynamic]^Territory,
	can_move: proc(ctx: rawptr, t: ^Territory) -> bool,
	can_move_ctx: rawptr,
	is_destination: proc(ctx: rawptr, t: ^Territory) -> bool,
	is_destination_ctx: rawptr,
) -> ^Territory {
	pro_territory_manager_find_closest_territory_active_can_move = can_move
	pro_territory_manager_find_closest_territory_active_can_move_ctx = can_move_ctx
	pro_territory_manager_find_closest_territory_active_is_destination = is_destination
	pro_territory_manager_find_closest_territory_active_is_destination_ctx = is_destination_ctx
	bfs := breadth_first_search_new(
		from_territories,
		pro_territory_manager_find_closest_territory_or_predicate,
	)
	destination: ^Territory = nil
	visitor := new(Pro_Territory_Manager_Find_Closest_Territory_Visitor)
	visitor.visit = pro_territory_manager_find_closest_territory_visit
	visitor.is_destination = is_destination
	visitor.is_destination_ctx = is_destination_ctx
	visitor.destination = &destination
	breadth_first_search_traverse(bfs, &visitor.visitor)
	return destination
}

// Lambda: findAmphibMoveOptions  canBeTransported.and(u -> u.getUnitAttachment().getTransportCost() <= capacity)
// Captures the local int `capacity`; per Java desugaring the captured value
// is supplied as the leading parameter of the synthetic lambda$N.
pro_territory_manager_lambda_find_amphib_move_options_6 :: proc(
	capacity: i32,
	u: ^Unit,
) -> bool {
	return unit_attachment_get_transport_cost(unit_get_unit_attachment(u)) <= capacity
}

// games.strategy.triplea.ai.pro.data.ProTerritoryManager#getUnitRange(Unit, Territory, GamePlayer, boolean)
//
// Java: returns BigDecimal; for enemy-attack analysis uses the unit-attachment
// movement value (plus a +1 bonus when the unit is in a facility-bonus
// territory), otherwise returns the unit's current remaining movement.
// BigDecimal → f64 per the Odin port convention.
pro_territory_manager_get_unit_range :: proc(
	unit: ^Unit,
	unit_territory: ^Territory,
	player: ^Game_Player,
	is_checking_enemy_attacks: bool,
) -> f64 {
	if is_checking_enemy_attacks {
		range := f64(unit_attachment_get_movement(unit_get_unit_attachment(unit), player))
		bonus_p, bonus_c := matches_unit_can_be_given_bonus_movement_by_facilities_in_its_territory(
			unit_territory,
			player,
		)
		if bonus_p(bonus_c, unit) {
			return range + 1.0
		}
		return range
	}
	return unit_get_movement_left(unit)
}

// games.strategy.triplea.ai.pro.data.ProTerritoryManager#findNavalMoveOptions(
//     ProData, GamePlayer, List<Territory>, Map<Territory, ProTerritory>,
//     Map<Unit, Set<Territory>>, Map<Unit, Set<Territory>>,
//     Predicate<Territory>, List<Territory>, boolean, boolean)
//
// BigDecimal -> f64. Predicate<Territory> rendered with the rawptr-ctx
// closure-capture convention. Java's `gameMap.getRouteForUnit(...)` is
// expressed via `route_finder_new_with_units_player` +
// `route_finder_find_route_by_cost_pair` because the bare
// `game_map_get_route_for_unit` helper takes a non-capturing predicate
// while our `canMove` Predicate (built from
// `pro_matches_territory_can_move_sea_units*`) carries a ctx — same
// substitution used in `pro_territory_value_utils_calculate_territory_value_to_targets`.
// `Set<Territory>` is `map[^Territory]struct{}`; `List<Territory>`
// produced by `CollectionUtils.getMatches` is materialized as
// `[dynamic]^Territory`.
pro_territory_manager_find_naval_move_options :: proc(
	pro_data: ^Pro_Data,
	player: ^Game_Player,
	my_unit_territories: [dynamic]^Territory,
	move_map: map[^Territory]^Pro_Territory,
	unit_move_map: map[^Unit]map[^Territory]struct {},
	transport_move_map: map[^Unit]map[^Territory]struct {},
	move_to_territory_match: proc(rawptr, ^Territory) -> bool,
	move_to_territory_match_ctx: rawptr,
	cleared_territories: [dynamic]^Territory,
	is_combat_move: bool,
	is_checking_enemy_attacks: bool,
) {
	data := pro_data_get_data(pro_data)
	game_map := game_data_get_map(data)

	can_move_p: proc(rawptr, ^Territory) -> bool
	can_move_c: rawptr
	if is_checking_enemy_attacks {
		can_move_p, can_move_c = pro_matches_territory_can_move_sea_units(player, is_combat_move)
	} else {
		empty_not: [dynamic]^Territory
		can_move_p, can_move_c =
			pro_matches_territory_can_move_sea_units_through_or_cleared_and_not_in_list(
				player,
				is_combat_move,
				cleared_territories,
				empty_not,
			)
	}

	owned_sea_p, owned_sea_c := pro_matches_unit_can_be_moved_and_is_owned_sea(
		player,
		is_combat_move,
	)
	sea_p, sea_c := pro_matches_territory_can_move_sea_units(player, is_combat_move)
	transport_p, transport_c := matches_unit_is_sea_transport()

	unit_move_map := unit_move_map
	transport_move_map := transport_move_map

	for my_unit_territory in my_unit_territories {
		// myUnitTerritory.getMatches(ProMatches.unitCanBeMovedAndIsOwnedSea(player, isCombatMove))
		my_sea_units := territory_get_matches(my_unit_territory, owned_sea_p, owned_sea_c)

		for my_sea_unit in my_sea_units {
			if is_combat_move && !is_checking_enemy_attacks {
				carrier_map := move_validator_carrier_must_move_with_territory(
					my_unit_territory,
					player,
				)
				if carrying, ok := carrier_map[my_sea_unit]; ok && len(carrying) > 0 {
					continue
				}
			}

			range := pro_territory_manager_get_unit_range(
				my_sea_unit,
				my_unit_territory,
				player,
				is_checking_enemy_attacks,
			)

			possible_move_territories := game_map_get_neighbors_by_movement_cost(
				game_map,
				my_unit_territory,
				range,
				sea_p,
				sea_c,
			)
			possible_move_territories[my_unit_territory] = {}

			potential_territories: [dynamic]^Territory
			for t in possible_move_territories {
				if move_to_territory_match(move_to_territory_match_ctx, t) {
					append(&potential_territories, t)
				}
			}
			if !is_combat_move {
				found := false
				for t in potential_territories {
					if t == my_unit_territory {
						found = true
						break
					}
				}
				if !found {
					append(&potential_territories, my_unit_territory)
				}
			}

			units_one := make([dynamic]^Unit, 0, 1)
			append(&units_one, my_sea_unit)

			for potential_territory in potential_territories {
				rf := route_finder_new_with_units_player(
					game_map,
					can_move_p,
					can_move_c,
					units_one,
					player,
				)
				optional_route := route_finder_find_route_by_cost_pair(
					rf,
					my_unit_territory,
					potential_territory,
				)
				if optional_route == nil {
					continue
				}
				my_route_length := route_get_movement_cost(optional_route, my_sea_unit)
				if my_route_length > range {
					continue
				}

				pt := pro_data_get_pro_territory(pro_data, move_map, potential_territory)
				pro_territory_add_max_unit(pt, my_sea_unit)

				if transport_p(transport_c, my_sea_unit) {
					inner, ok := transport_move_map[my_sea_unit]
					if !ok {
						inner = make(map[^Territory]struct {})
					}
					inner[potential_territory] = {}
					transport_move_map[my_sea_unit] = inner
				} else {
					inner, ok := unit_move_map[my_sea_unit]
					if !ok {
						inner = make(map[^Territory]struct {})
					}
					inner[potential_territory] = {}
					unit_move_map[my_sea_unit] = inner
				}
			}
		}
	}
}

// games.strategy.triplea.ai.pro.data.ProTerritoryManager#findBombardOptions(
//     ProData, GamePlayer, List<Territory>, Map<Territory, ProTerritory>,
//     Map<Unit, Set<Territory>>, List<ProTransport>, boolean)
//
// BigDecimal -> f64. Predicate<Territory> rendered with the ctx-form
// convention. Set retainAll mirrored by intersecting with the unload-from
// / unload-to membership sets. The route lookup is expressed through
// `route_finder_*` for the same ctx-Predicate reason as
// findNavalMoveOptions.
pro_territory_manager_find_bombard_options :: proc(
	pro_data: ^Pro_Data,
	player: ^Game_Player,
	my_unit_territories: [dynamic]^Territory,
	move_map: map[^Territory]^Pro_Territory,
	bombard_map: map[^Unit]map[^Territory]struct {},
	transport_map_list: [dynamic]^Pro_Transport,
	is_checking_enemy_attacks: bool,
) {
	data := pro_data_get_data(pro_data)
	game_map := game_data_get_map(data)

	// Find all transport unload from and to territories.
	unload_from_territories := make(map[^Territory]struct {})
	unload_to_territories := make(map[^Territory]struct {})
	for amphib_data in transport_map_list {
		for t in pro_transport_get_sea_transport_map(amphib_data) {
			unload_from_territories[t] = {}
		}
		for t in pro_transport_get_transport_map(amphib_data) {
			unload_to_territories[t] = {}
		}
	}

	can_move_p: proc(rawptr, ^Territory) -> bool
	can_move_c: rawptr
	if is_checking_enemy_attacks {
		can_move_p, can_move_c = pro_matches_territory_can_move_sea_units(player, true)
	} else {
		can_move_p, can_move_c = pro_matches_territory_can_move_sea_units_through(player, true)
	}

	owned_bombard_p, owned_bombard_c := pro_matches_unit_can_be_moved_and_is_owned_bombard(player)
	sea_p, sea_c := pro_matches_territory_can_move_sea_units(player, true)

	bombard_map := bombard_map

	for my_unit_territory in my_unit_territories {
		my_sea_units := territory_get_matches(my_unit_territory, owned_bombard_p, owned_bombard_c)

		for my_sea_unit in my_sea_units {
			range := pro_territory_manager_get_unit_range(
				my_sea_unit,
				my_unit_territory,
				player,
				is_checking_enemy_attacks,
			)

			potential_territories := game_map_get_neighbors_by_movement_cost(
				game_map,
				my_unit_territory,
				range,
				sea_p,
				sea_c,
			)
			potential_territories[my_unit_territory] = {}
			// retainAll(unloadFromTerritories)
			for t, _ in potential_territories {
				if _, ok := unload_from_territories[t]; !ok {
					delete_key(&potential_territories, t)
				}
			}

			units_one := make([dynamic]^Unit, 0, 1)
			append(&units_one, my_sea_unit)

			for bombard_from_territory in potential_territories {
				rf := route_finder_new_with_units_player(
					game_map,
					can_move_p,
					can_move_c,
					units_one,
					player,
				)
				optional_route := route_finder_find_route_by_cost_pair(
					rf,
					my_unit_territory,
					bombard_from_territory,
				)
				if optional_route == nil {
					continue
				}
				my_route_length := route_get_movement_cost(optional_route, my_sea_unit)
				if my_route_length > range {
					continue
				}

				// new HashSet<>(gameMap.getNeighbors(bombardFromTerritory))
				// then retainAll(unloadToTerritories).
				neighbors := game_map_get_neighbors(game_map, bombard_from_territory)
				bombard_to_territories := make(map[^Territory]struct {})
				for n in neighbors {
					if _, ok := unload_to_territories[n]; ok {
						bombard_to_territories[n] = {}
					}
				}

				for bombard_to_territory in bombard_to_territories {
					if pt, in_map := move_map[bombard_to_territory]; in_map {
						pro_territory_add_max_bombard_unit(pt, my_sea_unit)
						pro_territory_add_bombard_options_map(
							pt,
							my_sea_unit,
							bombard_from_territory,
						)
					}
				}

				inner, ok := bombard_map[my_sea_unit]
				if !ok {
					inner = make(map[^Territory]struct {})
				}
				for t in bombard_to_territories {
					inner[t] = {}
				}
				bombard_map[my_sea_unit] = inner
			}
		}
	}
}

// games.strategy.triplea.ai.pro.data.ProTerritoryManager#isLandMoveOption(
//     boolean, GamePlayer, Unit, Territory, Territory, BigDecimal,
//     Predicate<Territory>)
//
// BigDecimal -> f64. Predicate<Territory> rendered with the rawptr-ctx
// convention. The route lookup uses `route_finder_*` for the same reason
// as findNavalMoveOptions (capturing canMove Predicate).
pro_territory_manager_is_land_move_option :: proc(
	is_combat_move: bool,
	player: ^Game_Player,
	u: ^Unit,
	from: ^Territory,
	to: ^Territory,
	range: f64,
	can_move: proc(rawptr, ^Territory) -> bool,
	can_move_ctx: rawptr,
) -> bool {
	game_map := game_data_get_map(game_player_get_data(player))
	units_one := make([dynamic]^Unit, 0, 1)
	append(&units_one, u)
	rf := route_finder_new_with_units_player(game_map, can_move, can_move_ctx, units_one, player)
	optional_route := route_finder_find_route_by_cost_pair(rf, from, to)
	if optional_route == nil {
		return false
	}
	route := optional_route
	if route_has_more_than_one_step(route) {
		middle_steps := route_get_middle_steps(route)
		enemy_p, enemy_c := matches_is_territory_enemy(player)
		any_enemy := false
		for ms in middle_steps {
			if enemy_p(enemy_c, ms) {
				any_enemy = true
				break
			}
		}
		if any_enemy {
			lost_blitz_types := territory_effect_helper_get_unit_types_that_lost_blitz(
				route_get_all_territories(route),
			)
			of_types_p, of_types_c := matches_unit_is_of_types(lost_blitz_types)
			if of_types_p(of_types_c, u) {
				// If blitzing then make sure none of the territories
				// cause blitz ability to be lost.
				return false
			}
		}
	}
	if route_get_movement_cost(route, u) > range {
		return false
	}

	// Skip units that can't participate in combat during combat moves except
	// for land transports.
	if is_combat_move {
		land_transport_p, land_transport_c := matches_unit_is_land_transport()
		if !land_transport_p(land_transport_c, u) {
			enemy_unit_p, enemy_unit_c := matches_unit_is_enemy_of(player)
			to_units := territory_get_units(to)
			enemy_units: [dynamic]^Unit
			for tu in to_units {
				if enemy_unit_p(enemy_unit_c, tu) {
					append(&enemy_units, tu)
				}
			}
			combat_p, combat_c := matches_unit_can_participate_in_combat(
				true,
				player,
				to,
				1,
				enemy_units,
			)
			return combat_p(combat_c, u)
		}
	}
	return true
}

// File-scope holder for the comparator used to sort scramblers by
// estimated strength. slice.sort_by takes a non-capturing
// `proc(a, b) -> bool`, so the captured destination Territory is parked
// here. findScrambleOptions is single-threaded and the comparator is
// only consulted while the holder is set, mirroring the sibling
// find_closest_territory pattern.
@(private = "file")
pro_territory_manager_find_scramble_options_active_to: ^Territory

@(private = "file")
pro_territory_manager_find_scramble_options_strength_descending :: proc(a: ^Unit, b: ^Unit) -> bool {
	to := pro_territory_manager_find_scramble_options_active_to
	empty: [dynamic]^Unit
	one_a := make([dynamic]^Unit, 0, 1)
	append(&one_a, a)
	one_b := make([dynamic]^Unit, 0, 1)
	append(&one_b, b)
	sa := pro_battle_utils_estimate_strength(to, one_a, empty, false)
	sb := pro_battle_utils_estimate_strength(to, one_b, empty, false)
	return sa > sb
}

// games.strategy.triplea.ai.pro.data.ProTerritoryManager#findScrambleOptions(
//     ProData, GamePlayer, Map<Territory, ProTerritory>)
//
// Mirrors the Java body verbatim: bails out when scramble rules are off,
// delegates per-destination scramble enumeration to ScrambleLogic, and
// either appends every scrambler to the destination's max-scramble list
// (when there is room) or sorts the scrambler set by descending strength
// estimate and appends the top `maxCanScramble`. The Java sort is
// `Comparator.comparingDouble(strength).reversed()` followed by
// `limit(maxCanScramble).forEachOrdered(addTo::add)` — translated as a
// non-capturing comparator parked through a file-scope holder, since
// slice.sort_by takes a bare `proc(a, b) -> bool`.
pro_territory_manager_find_scramble_options :: proc(
	pro_data: ^Pro_Data,
	player: ^Game_Player,
	move_map: map[^Territory]^Pro_Territory,
) {
	data := pro_data_get_data(pro_data)
	if !properties_get_scramble_rules_in_effect(game_data_get_properties(data)) {
		return
	}

	territories_with_battles := make(map[^Territory]struct {})
	for t, _ in move_map {
		territories_with_battles[t] = {}
	}
	scramble_logic := scramble_logic_new_with_battles(
		&data.game_state,
		player,
		territories_with_battles,
	)

	by_destination := scramble_logic_get_units_that_can_scramble_by_destination(scramble_logic)
	for to, inner in by_destination {
		for _, airbases_and_scramblers in inner {
			airbases := tuple_get_first(airbases_and_scramblers)
			scramblers := tuple_get_second(airbases_and_scramblers)
			max_can_scramble := scramble_logic_get_max_scramble_count(airbases)

			pt := move_map[to]
			if i32(len(scramblers)) <= max_can_scramble {
				for u in scramblers {
					append(&pt.max_scramble_units, u)
				}
			} else {
				sorted := make([dynamic]^Unit, 0, len(scramblers))
				for u in scramblers {
					append(&sorted, u)
				}
				pro_territory_manager_find_scramble_options_active_to = to
				slice.sort_by(
					sorted[:],
					pro_territory_manager_find_scramble_options_strength_descending,
				)
				count: i32 = 0
				for u in sorted {
					if count >= max_can_scramble {
						break
					}
					append(&pt.max_scramble_units, u)
					count += 1
				}
			}
		}
	}
}

