package game

import "core:fmt"
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

// games.strategy.triplea.ai.pro.data.ProTerritoryManager#findAirMoveOptions(
//     ProData, GamePlayer, List<Territory>, Map<Territory, ProTerritory>,
//     Map<Unit, Set<Territory>>, Predicate<Territory>, List<Territory>,
//     List<Territory>, boolean, boolean, boolean)
//
// BigDecimal -> f64. Predicate<Territory> rendered with the rawptr-ctx
// closure-capture convention. The route lookup uses the route_finder_*
// pair (same reason as findNavalMoveOptions: the canFlyOver Predicate
// carries a ctx). `possibleCarrierTerritories::contains` is mirrored as
// a direct map membership probe rather than a synthetic predicate.
pro_territory_manager_find_air_move_options :: proc(
	pro_data: ^Pro_Data,
	player: ^Game_Player,
	my_unit_territories: [dynamic]^Territory,
	move_map: map[^Territory]^Pro_Territory,
	unit_move_map: map[^Unit]map[^Territory]struct {},
	move_to_territory_match: proc(rawptr, ^Territory) -> bool,
	move_to_territory_match_ctx: rawptr,
	enemy_territories: [dynamic]^Territory,
	allied_territories: [dynamic]^Territory,
	is_combat_move: bool,
	is_checking_enemy_attacks: bool,
	is_ignoring_relationships: bool,
) {
	data := pro_data_get_data(pro_data)
	game_map := game_data_get_map(data)

	// Find possible carrier landing territories.
	possible_carrier_territories := make(map[^Territory]struct {})
	if is_checking_enemy_attacks || !is_combat_move {
		unit_move_map_2 := make(map[^Unit]map[^Territory]struct {})
		empty_move_map := make(map[^Territory]^Pro_Territory)
		empty_transport_move_map := make(map[^Unit]map[^Territory]struct {})
		water_p, water_c := matches_territory_is_water()
		pro_territory_manager_find_naval_move_options(
			pro_data,
			player,
			my_unit_territories,
			empty_move_map,
			unit_move_map_2,
			empty_transport_move_map,
			water_p,
			water_c,
			enemy_territories,
			false,
			true,
		)
		carrier_p, carrier_c := matches_unit_is_carrier()
		for u, ts in unit_move_map_2 {
			if carrier_p(carrier_c, u) {
				for t in ts {
					possible_carrier_territories[t] = {}
				}
			}
		}
		allied_carrier_p, allied_carrier_c := matches_unit_is_allied_carrier(player)
		for t in game_map_get_territories(game_map) {
			if territory_any_units_match(t, allied_carrier_p, allied_carrier_c) {
				possible_carrier_territories[t] = {}
			}
		}
	}

	can_move_p: proc(rawptr, ^Territory) -> bool
	can_move_c: rawptr
	if is_ignoring_relationships {
		can_move_p, can_move_c = pro_matches_territory_can_potentially_move_air_units(player)
	} else {
		can_move_p, can_move_c = pro_matches_territory_can_move_air_units(
			&data.game_state,
			player,
			is_combat_move,
		)
	}
	can_fly_over_p: proc(rawptr, ^Territory) -> bool
	can_fly_over_c: rawptr
	if is_checking_enemy_attacks {
		can_fly_over_p, can_fly_over_c = pro_matches_territory_can_move_air_units(
			&data.game_state,
			player,
			is_combat_move,
		)
	} else {
		can_fly_over_p, can_fly_over_c = pro_matches_territory_can_move_air_units_and_no_aa(
			&data.game_state,
			player,
			is_combat_move,
		)
	}

	unit_match_p, unit_match_c := pro_matches_unit_can_be_moved_and_is_owned_air(
		player,
		is_combat_move,
	)
	carrier_landable_p, carrier_landable_c := matches_unit_can_land_on_carrier()

	unit_move_map := unit_move_map

	for my_unit_territory in my_unit_territories {
		my_air_units := territory_get_matches(my_unit_territory, unit_match_p, unit_match_c)

		for my_air_unit in my_air_units {
			range := pro_territory_manager_get_unit_range(
				my_air_unit,
				my_unit_territory,
				player,
				is_checking_enemy_attacks,
			)

			possible_move_territories := game_map_get_neighbors_by_movement_cost(
				game_map,
				my_unit_territory,
				range,
				can_move_p,
				can_move_c,
			)
			possible_move_territories[my_unit_territory] = {}

			potential_territories := make(map[^Territory]struct {})
			for t in possible_move_territories {
				if move_to_territory_match(move_to_territory_match_ctx, t) {
					potential_territories[t] = {}
				}
			}
			if !is_combat_move && carrier_landable_p(carrier_landable_c, my_air_unit) {
				for t in possible_move_territories {
					if _, ok := possible_carrier_territories[t]; ok {
						potential_territories[t] = {}
					}
				}
			}

			units_one := make([dynamic]^Unit, 0, 1)
			append(&units_one, my_air_unit)

			for potential_territory in potential_territories {
				rf := route_finder_new_with_units_player(
					game_map,
					can_fly_over_p,
					can_fly_over_c,
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
				my_route_length := route_get_movement_cost(optional_route, my_air_unit)
				remaining_moves := range - my_route_length
				if remaining_moves < 0 {
					continue
				}

				if is_combat_move &&
				   (remaining_moves < my_route_length || territory_is_water(my_unit_territory)) {
					possible_landing_territories := game_map_get_neighbors_by_movement_cost(
						game_map,
						potential_territory,
						remaining_moves,
						can_fly_over_p,
						can_fly_over_c,
					)
					land_air_p, land_air_c := pro_matches_territory_can_land_air_units(
						player,
						is_combat_move,
						enemy_territories,
						allied_territories,
					)
					landing_count := 0
					for plt in possible_landing_territories {
						if land_air_p(land_air_c, plt) {
							landing_count += 1
						}
					}
					carrier_count := 0
					if carrier_landable_p(carrier_landable_c, my_air_unit) {
						for plt in possible_landing_territories {
							if _, ok := possible_carrier_territories[plt]; ok {
								carrier_count += 1
							}
						}
					}
					if landing_count == 0 && carrier_count == 0 {
						continue
					}
				}

				pt := pro_data_get_pro_territory(pro_data, move_map, potential_territory)
				pro_territory_add_max_unit(pt, my_air_unit)

				inner, ok := unit_move_map[my_air_unit]
				if !ok {
					inner = make(map[^Territory]struct {})
				}
				inner[potential_territory] = {}
				unit_move_map[my_air_unit] = inner
			}
		}
	}
}

// games.strategy.triplea.ai.pro.data.ProTerritoryManager#findLandMoveOptions(
//     ProData, GamePlayer, List<Territory>, Map<Territory, ProTerritory>,
//     Map<Unit, Set<Territory>>, Map<Territory, Set<Territory>>,
//     Predicate<Territory>, List<Territory>, List<Territory>, boolean,
//     boolean, boolean)
//
// BigDecimal -> f64. Predicate<Territory> rendered with the rawptr-ctx
// convention. Per-unit canMove varies between the
// territoryCanMoveLandUnitsThrough / IgnoreEnemyUnits Pro_Matches
// builders. The route lookup uses route_finder_* via
// pro_territory_manager_is_land_move_option, mirroring the Java
// extracted helper.
pro_territory_manager_find_land_move_options :: proc(
	pro_data: ^Pro_Data,
	player: ^Game_Player,
	my_unit_territories: [dynamic]^Territory,
	move_map: map[^Territory]^Pro_Territory,
	unit_move_map: map[^Unit]map[^Territory]struct {},
	land_routes_map: map[^Territory]map[^Territory]struct {},
	move_to_territory_match: proc(rawptr, ^Territory) -> bool,
	move_to_territory_match_ctx: rawptr,
	enemy_territories: [dynamic]^Territory,
	cleared_territories: [dynamic]^Territory,
	is_combat_move: bool,
	is_checking_enemy_attacks: bool,
	is_ignoring_relationships: bool,
) {
	data := pro_data_get_data(pro_data)
	game_map := game_data_get_map(data)

	owned_land_p, owned_land_c := pro_matches_unit_can_be_moved_and_is_owned_land(
		player,
		is_combat_move,
	)

	unit_move_map := unit_move_map
	land_routes_map := land_routes_map

	for my_unit_territory in my_unit_territories {
		my_land_units := territory_get_matches(my_unit_territory, owned_land_p, owned_land_c)

		for u in my_land_units {
			start_territory := pro_data_get_unit_territory(pro_data, u)
			range := unit_get_movement_left(u)

			move_pred: proc(rawptr, ^Territory) -> bool
			move_ctx: rawptr
			if is_ignoring_relationships {
				move_pred, move_ctx = pro_matches_territory_can_potentially_move_specific_land_unit(
					player,
					u,
				)
			} else {
				move_pred, move_ctx = pro_matches_territory_can_move_specific_land_unit(
					player,
					is_combat_move,
					u,
				)
			}

			possible_move_territories := game_map_get_neighbors_by_movement_cost(
				game_map,
				my_unit_territory,
				range,
				move_pred,
				move_ctx,
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

			can_move_p: proc(rawptr, ^Territory) -> bool
			can_move_c: rawptr
			if is_checking_enemy_attacks {
				can_move_p, can_move_c =
					pro_matches_territory_can_move_land_units_through_ignore_enemy_units(
						player,
						u,
						start_territory,
						is_combat_move,
						enemy_territories,
						cleared_territories,
					)
			} else {
				can_move_p, can_move_c = pro_matches_territory_can_move_land_units_through(
					player,
					u,
					start_territory,
					is_combat_move,
					enemy_territories,
				)
			}

			for t in potential_territories {
				if !pro_territory_manager_is_land_move_option(
					is_combat_move,
					player,
					u,
					my_unit_territory,
					t,
					range,
					can_move_p,
					can_move_c,
				) {
					continue
				}

				route_inner, route_ok := land_routes_map[t]
				if !route_ok {
					route_inner = make(map[^Territory]struct {})
				}
				route_inner[my_unit_territory] = {}
				land_routes_map[t] = route_inner

				potential_territory_move := pro_data_get_pro_territory(pro_data, move_map, t)
				units_to_add := pro_transport_utils_find_best_units_to_land_transport(
					u,
					start_territory,
					pro_territory_get_max_units(potential_territory_move),
				)
				pro_territory_add_max_units(potential_territory_move, units_to_add)

				unit_inner, unit_ok := unit_move_map[u]
				if !unit_ok {
					unit_inner = make(map[^Territory]struct {})
				}
				unit_inner[t] = {}
				unit_move_map[u] = unit_inner
			}
		}
	}
}

// games.strategy.triplea.ai.pro.data.ProTerritoryManager#findAmphibMoveOptions(
//     ProData, GamePlayer, List<Territory>, Map<Territory, ProTerritory>,
//     List<ProTransport>, Map<Territory, Set<Territory>>,
//     Predicate<Territory>, boolean, boolean, boolean)
//
// BigDecimal -> f64. Predicate<Territory> rendered with the rawptr-ctx
// convention. The combined `canBeTransported.and(u -> ... <= capacity)`
// predicate is inlined per territory rather than expressed as a
// freshly-built compound Predicate, matching how
// `loadTerritory.anyUnitsMatch(...)` consumes it. moveValidator.validateCanal
// returns a non-nil error string on failure (Java: returns null on success).
pro_territory_manager_find_amphib_move_options :: proc(
	pro_data: ^Pro_Data,
	player: ^Game_Player,
	my_unit_territories: [dynamic]^Territory,
	move_map: map[^Territory]^Pro_Territory,
	transport_map_list: ^[dynamic]^Pro_Transport,
	land_routes_map: map[^Territory]map[^Territory]struct {},
	move_amphib_to_territory_match: proc(rawptr, ^Territory) -> bool,
	move_amphib_to_territory_match_ctx: rawptr,
	is_combat_move: bool,
	is_checking_enemy_attacks: bool,
	is_ignoring_relationships: bool,
) {
	data := pro_data_get_data(pro_data)
	game_map := game_data_get_map(data)
	is_transport_p, is_transport_c := pro_matches_unit_can_be_moved_and_is_owned_transport(
		player,
		is_combat_move,
	)
	can_move_sea_through_p, can_move_sea_through_c := pro_matches_territory_can_move_sea_units_through(
		player,
		is_combat_move,
	)
	can_move_sea_p, can_move_sea_c := pro_matches_territory_can_move_sea_units(
		player,
		is_combat_move,
	)

	unload_amphib_inner_p: proc(rawptr, ^Territory) -> bool
	unload_amphib_inner_c: rawptr
	if is_ignoring_relationships {
		unload_amphib_inner_p, unload_amphib_inner_c =
			pro_matches_territory_can_potentially_move_land_units(player)
	} else {
		unload_amphib_inner_p, unload_amphib_inner_c = pro_matches_territory_can_move_land_units(
			player,
			is_combat_move,
		)
	}

	for transport_territory in my_unit_territories {
		transports := territory_get_matches(transport_territory, is_transport_p, is_transport_c)

		for transport in transports {
			pro_transport_data := pro_transport_new(transport)
			append(transport_map_list, pro_transport_data)
			current_territories := make(map[^Territory]struct {})
			current_territories[transport_territory] = {}

			can_be_transported_p: proc(rawptr, ^Unit) -> bool
			can_be_transported_c: rawptr
			if is_checking_enemy_attacks {
				can_be_transported_p, can_be_transported_c =
					pro_matches_unit_is_owned_combat_transportable_unit(player)
			} else {
				can_be_transported_p, can_be_transported_c =
					pro_matches_unit_is_owned_transportable_unit_and_can_be_loaded(
						player,
						transport,
						is_combat_move,
					)
			}

			moves_left := i32(
				pro_territory_manager_get_unit_range(
					transport,
					transport_territory,
					player,
					is_checking_enemy_attacks,
				),
			)
			move_validator := move_validator_new(data, !is_combat_move)

			for moves_left >= 0 {
				next_territories := make(map[^Territory]struct {})
				for from in current_territories {
					// Find neighbors I can move to (passing canal validation).
					sea_through_neighbors := game_map_get_neighbors_predicate(
						game_map,
						from,
						can_move_sea_through_p,
						can_move_sea_through_c,
					)
					transports_one := make([dynamic]^Unit, 0, 1)
					append(&transports_one, transport)
					for neighbor in sea_through_neighbors {
						route := route_new_from_start_and_steps(from, neighbor)
						if move_validator_validate_canal(
							   move_validator,
							   route,
							   transports_one,
							   false,
							   player,
						   ) ==
						   nil {
							next_territories[neighbor] = {}
						}
					}

					// Get loaded units or units that can be loaded into current
					// territory if no enemy sea units present.
					have_units_to_transport := false
					load_from_territories := make(map[^Territory]struct {})
					existing_cargo := unit_get_transporting_in_territory(
						transport,
						transport_territory,
					)
					if len(existing_cargo) > 0 {
						have_units_to_transport = true
					} else {
						has_enemy_sea_p, has_enemy_sea_c :=
							matches_territory_has_enemy_sea_units(player)
						if !has_enemy_sea_p(has_enemy_sea_c, from) {
							capacity := unit_attachment_get_transport_capacity(
								unit_get_unit_attachment(transport),
							)
							neighbors := game_map_get_neighbors(game_map, from)
							for load_territory in neighbors {
								found_fit := false
								for u in territory_get_units(load_territory) {
									if !can_be_transported_p(can_be_transported_c, u) {
										continue
									}
									if unit_attachment_get_transport_cost(
										   unit_get_unit_attachment(u),
									   ) >
									   capacity {
										continue
									}
									found_fit = true
									break
								}
								if found_fit {
									load_from_territories[load_territory] = {}
									have_units_to_transport = true
								}
							}
						}
					}

					if !have_units_to_transport {
						continue
					}

					// Find all water territories I can move to.
					sea_move_territories := make(map[^Territory]struct {})
					sea_move_territories[from] = {}
					if moves_left > 0 {
						near_p: proc(rawptr, ^Territory) -> bool
						near_c: rawptr
						if is_checking_enemy_attacks {
							near_p, near_c = can_move_sea_p, can_move_sea_c
						} else {
							near_p, near_c = can_move_sea_through_p, can_move_sea_through_c
						}
						near := game_map_get_neighbors_distance_predicate(
							game_map,
							from,
							moves_left,
							near_p,
							near_c,
						)
						for to in near {
							rf := route_finder_new_with_units_player(
								game_map,
								can_move_sea_through_p,
								can_move_sea_through_c,
								transports_one,
								player,
							)
							route := route_finder_find_route_by_cost_pair(rf, from, to)
							if route != nil {
								sea_move_territories[to] = {}
							}
						}
					}

					// Find possible unload territories.
					unload_territories := make(map[^Territory]struct {})
					for to in sea_move_territories {
						unload_neighbors := game_map_get_neighbors_predicate(
							game_map,
							to,
							move_amphib_to_territory_match,
							move_amphib_to_territory_match_ctx,
						)
						for ut in unload_neighbors {
							if !unload_amphib_inner_p(unload_amphib_inner_c, ut) {
								continue
							}
							unload_territories[ut] = {}
						}
					}

					pro_transport_add_territories(
						pro_transport_data,
						unload_territories,
						load_from_territories,
					)
					pro_transport_add_sea_territories(
						pro_transport_data,
						sea_move_territories,
						load_from_territories,
					)
				}
				clear(&current_territories)
				for t in next_territories {
					current_territories[t] = {}
				}
				moves_left -= 1
			}
		}
	}

	// Remove any territories from transport map that I can move to on land
	// and transports with no amphib options.
	for pro_transport_data in transport_map_list^ {
		transport_map := pro_transport_get_transport_map(pro_transport_data)
		for t, inner in transport_map {
			if land_move_territories, ok := land_routes_map[t]; ok {
				inner_mut := inner
				for lmt in land_move_territories {
					delete_key(&inner_mut, lmt)
				}
				transport_map[t] = inner_mut
			}
		}
		// Java: transportMap.values().removeIf(Collection::isEmpty)
		empty_keys: [dynamic]^Territory
		for t, inner in transport_map {
			if len(inner) == 0 {
				append(&empty_keys, t)
			}
		}
		for t in empty_keys {
			delete_key(&transport_map, t)
		}
	}

	// Add transport units to attack map.
	for pro_transport_data in transport_map_list^ {
		transport_map := pro_transport_get_transport_map(pro_transport_data)
		transport := pro_transport_get_transport(pro_transport_data)
		for move_territory, territories_can_load_from in transport_map {
			already_added: [dynamic]^Unit
			if existing, ok := move_map[move_territory]; ok {
				already_added = pro_territory_get_max_amphib_units(existing)
			}
			amphib_units: [dynamic]^Unit
			if is_checking_enemy_attacks {
				combat_pred, combat_ctx :=
					pro_matches_unit_is_owned_combat_transportable_unit(player)
				amphib_units = pro_transport_utils_get_units_to_transport_from_territories(
					player,
					transport,
					territories_can_load_from,
					already_added,
					combat_pred,
					combat_ctx,
				)
			} else {
				amphib_units = pro_transport_utils_get_units_to_transport_from_territories_4(
					player,
					transport,
					territories_can_load_from,
					already_added,
				)
			}
			pt := pro_data_get_pro_territory(pro_data, move_map, move_territory)
			pro_territory_add_max_amphib_units(pt, amphib_units)
		}
	}
}

// games.strategy.triplea.ai.pro.data.ProTerritoryManager#findAttackOptions(
//     ProData, GamePlayer, List<Territory>, Map<Territory, ProTerritory>,
//     Map<Unit, Set<Territory>>, Map<Unit, Set<Territory>>,
//     Map<Unit, Set<Territory>>, List<ProTransport>, List<Territory>,
//     List<Territory>, Collection<Territory>, boolean, boolean)
//
// Static helper. transportMapList is mutated by findAmphibMoveOptions, so
// it is passed by pointer to mirror Java's List reference semantics (same
// pointer-list convention used elsewhere in this file).
pro_territory_manager_find_attack_options :: proc(
	pro_data:                  ^Pro_Data,
	player:                    ^Game_Player,
	my_unit_territories:       [dynamic]^Territory,
	move_map:                  map[^Territory]^Pro_Territory,
	unit_move_map:             map[^Unit]map[^Territory]struct {},
	transport_move_map:        map[^Unit]map[^Territory]struct {},
	bombard_map:               map[^Unit]map[^Territory]struct {},
	transport_map_list:        ^[dynamic]^Pro_Transport,
	enemy_territories:         [dynamic]^Territory,
	allied_territories:        [dynamic]^Territory,
	territories_to_check:      [dynamic]^Territory,
	is_checking_enemy_attacks: bool,
	is_ignoring_relationships: bool,
) {
	land_routes_map := make(map[^Territory]map[^Territory]struct {})
	territories_that_cant_be_held: [dynamic]^Territory
	for t in enemy_territories {
		append(&territories_that_cant_be_held, t)
	}
	for t in territories_to_check {
		append(&territories_that_cant_be_held, t)
	}

	naval_p, naval_c := pro_matches_territory_is_enemy_or_has_enemy_units_or_cant_be_held(
		player,
		territories_that_cant_be_held,
	)
	pro_territory_manager_find_naval_move_options(
		pro_data,
		player,
		my_unit_territories,
		move_map,
		unit_move_map,
		transport_move_map,
		naval_p,
		naval_c,
		enemy_territories,
		true,
		is_checking_enemy_attacks,
	)

	land_p, land_c := pro_matches_territory_is_enemy_or_cant_be_held(
		player,
		territories_that_cant_be_held,
	)
	pro_territory_manager_find_land_move_options(
		pro_data,
		player,
		my_unit_territories,
		move_map,
		unit_move_map,
		land_routes_map,
		land_p,
		land_c,
		enemy_territories,
		allied_territories,
		true,
		is_checking_enemy_attacks,
		is_ignoring_relationships,
	)

	air_p, air_c := pro_matches_territory_has_enemy_units_or_cant_be_held(
		player,
		territories_that_cant_be_held,
	)
	pro_territory_manager_find_air_move_options(
		pro_data,
		player,
		my_unit_territories,
		move_map,
		unit_move_map,
		air_p,
		air_c,
		enemy_territories,
		allied_territories,
		true,
		is_checking_enemy_attacks,
		is_ignoring_relationships,
	)

	amphib_p, amphib_c := pro_matches_territory_is_enemy_or_cant_be_held(
		player,
		territories_that_cant_be_held,
	)
	pro_territory_manager_find_amphib_move_options(
		pro_data,
		player,
		my_unit_territories,
		move_map,
		transport_map_list,
		land_routes_map,
		amphib_p,
		amphib_c,
		true,
		is_checking_enemy_attacks,
		is_ignoring_relationships,
	)

	pro_territory_manager_find_bombard_options(
		pro_data,
		player,
		my_unit_territories,
		move_map,
		bombard_map,
		transport_map_list^,
		is_checking_enemy_attacks,
	)
}

// games.strategy.triplea.ai.pro.data.ProTerritoryManager#findDefendOptions(
//     ProData, GamePlayer, List<Territory>, Map<Territory, ProTerritory>,
//     Map<Unit, Set<Territory>>, Map<Unit, Set<Territory>>,
//     List<ProTransport>, List<Territory>, boolean)
//
// Static helper. Mirrors Java verbatim: defensive naval/land/air/amphib
// passes scoped to friendly territory, with Matches.isTerritoryAllied as
// the land/amphib destination predicate.
pro_territory_manager_find_defend_options :: proc(
	pro_data:                  ^Pro_Data,
	player:                    ^Game_Player,
	my_unit_territories:       [dynamic]^Territory,
	move_map:                  map[^Territory]^Pro_Territory,
	unit_move_map:             map[^Unit]map[^Territory]struct {},
	transport_move_map:        map[^Unit]map[^Territory]struct {},
	transport_map_list:        ^[dynamic]^Pro_Transport,
	cleared_territories:       [dynamic]^Territory,
	is_checking_enemy_attacks: bool,
) {
	land_routes_map := make(map[^Territory]map[^Territory]struct {})

	naval_p, naval_c := pro_matches_territory_has_no_enemy_units_or_cleared(
		player,
		cleared_territories,
	)
	pro_territory_manager_find_naval_move_options(
		pro_data,
		player,
		my_unit_territories,
		move_map,
		unit_move_map,
		transport_move_map,
		naval_p,
		naval_c,
		cleared_territories,
		false,
		is_checking_enemy_attacks,
	)

	land_p, land_c := matches_is_territory_allied(player)
	empty_enemy: [dynamic]^Territory
	pro_territory_manager_find_land_move_options(
		pro_data,
		player,
		my_unit_territories,
		move_map,
		unit_move_map,
		land_routes_map,
		land_p,
		land_c,
		empty_enemy,
		cleared_territories,
		false,
		is_checking_enemy_attacks,
		false,
	)

	empty_enemy_air: [dynamic]^Territory
	empty_allied_air: [dynamic]^Territory
	land_air_p, land_air_c := pro_matches_territory_can_land_air_units(
		player,
		false,
		empty_enemy_air,
		empty_allied_air,
	)
	empty_enemy_air2: [dynamic]^Territory
	empty_allied_air2: [dynamic]^Territory
	pro_territory_manager_find_air_move_options(
		pro_data,
		player,
		my_unit_territories,
		move_map,
		unit_move_map,
		land_air_p,
		land_air_c,
		empty_enemy_air2,
		empty_allied_air2,
		false,
		is_checking_enemy_attacks,
		false,
	)

	amphib_p, amphib_c := matches_is_territory_allied(player)
	pro_territory_manager_find_amphib_move_options(
		pro_data,
		player,
		my_unit_territories,
		move_map,
		transport_map_list,
		land_routes_map,
		amphib_p,
		amphib_c,
		false,
		is_checking_enemy_attacks,
		false,
	)
}

// games.strategy.triplea.ai.pro.data.ProTerritoryManager#findPotentialAttackOptions(
//     ProData, GamePlayer, List<Territory>, Map<Territory, ProTerritory>,
//     Map<Unit, Set<Territory>>, Map<Unit, Set<Territory>>,
//     Map<Unit, Set<Territory>>, List<ProTransport>)
//
// Static helper for relationship-ignoring potential-attack analysis: the
// destination predicates use the *PotentialEnemy* Pro_Matches builders
// against the player's potential enemies, and the move passes set
// isIgnoringRelationships=true.
pro_territory_manager_find_potential_attack_options :: proc(
	pro_data:            ^Pro_Data,
	player:              ^Game_Player,
	my_unit_territories: [dynamic]^Territory,
	move_map:            map[^Territory]^Pro_Territory,
	unit_move_map:       map[^Unit]map[^Territory]struct {},
	transport_move_map:  map[^Unit]map[^Territory]struct {},
	bombard_map:         map[^Unit]map[^Territory]struct {},
	transport_map_list:  ^[dynamic]^Pro_Transport,
) {
	land_routes_map := make(map[^Territory]map[^Territory]struct {})
	other_players := pro_utils_get_potential_enemy_players(player)

	naval_p, naval_c := pro_matches_territory_is_potential_enemy_or_has_potential_enemy_units(
		player,
		other_players,
	)
	empty_enemy_naval: [dynamic]^Territory
	pro_territory_manager_find_naval_move_options(
		pro_data,
		player,
		my_unit_territories,
		move_map,
		unit_move_map,
		transport_move_map,
		naval_p,
		naval_c,
		empty_enemy_naval,
		true,
		false,
	)

	land_p, land_c := pro_matches_territory_is_potential_enemy(player, other_players)
	empty_enemy_land: [dynamic]^Territory
	empty_allied_land: [dynamic]^Territory
	pro_territory_manager_find_land_move_options(
		pro_data,
		player,
		my_unit_territories,
		move_map,
		unit_move_map,
		land_routes_map,
		land_p,
		land_c,
		empty_enemy_land,
		empty_allied_land,
		true,
		false,
		true,
	)

	air_p, air_c := pro_matches_territory_has_potential_enemy_units(player, other_players)
	empty_enemy_air: [dynamic]^Territory
	empty_allied_air: [dynamic]^Territory
	pro_territory_manager_find_air_move_options(
		pro_data,
		player,
		my_unit_territories,
		move_map,
		unit_move_map,
		air_p,
		air_c,
		empty_enemy_air,
		empty_allied_air,
		true,
		false,
		true,
	)

	amphib_p, amphib_c := pro_matches_territory_is_potential_enemy(player, other_players)
	pro_territory_manager_find_amphib_move_options(
		pro_data,
		player,
		my_unit_territories,
		move_map,
		transport_map_list,
		land_routes_map,
		amphib_p,
		amphib_c,
		true,
		false,
		true,
	)

	pro_territory_manager_find_bombard_options(
		pro_data,
		player,
		my_unit_territories,
		move_map,
		bombard_map,
		transport_map_list^,
		false,
	)
}

// Lambda: findScrambleOptions  Comparator.comparingDouble(
//     unit -> ProBattleUtils.estimateStrength(to, List.of(unit), List.of(), false))
// Captures the destination Territory `to`; per Java desugaring the
// captured value is supplied as the leading parameter of the synthetic
// lambda$0. The live comparator path used by find_scramble_options is the
// non-capturing file-scope helper find_scramble_options_strength_descending,
// which calls pro_battle_utils_estimate_strength directly with the same
// arguments; this proc is the by-name desugaring counterpart.
pro_territory_manager_lambda_find_scramble_options_0 :: proc(
	to:   ^Territory,
	unit: ^Unit,
) -> f64 {
	one := make([dynamic]^Unit, 0, 1)
	append(&one, unit)
	empty: [dynamic]^Unit
	return pro_battle_utils_estimate_strength(to, one, empty, false)
}

// games.strategy.triplea.ai.pro.data.ProTerritoryManager#populatePotentialAttackOptions()
// Delegates to the static find_potential_attack_options helper, passing the
// potential_attack_options sub-maps and a pointer to its transport_list so
// the helper's amphib pass can append in place.
pro_territory_manager_populate_potential_attack_options :: proc(self: ^Pro_Territory_Manager) {
	pro_territory_manager_find_potential_attack_options(
		self.pro_data,
		self.player,
		pro_data_get_my_unit_territories(self.pro_data),
		pro_my_move_options_get_territory_map(self.potential_attack_options),
		pro_my_move_options_get_unit_move_map(self.potential_attack_options),
		pro_my_move_options_get_transport_move_map(self.potential_attack_options),
		pro_my_move_options_get_bombard_map(self.potential_attack_options),
		&self.potential_attack_options.transport_list,
	)
}

// games.strategy.triplea.ai.pro.data.ProTerritoryManager#populateDefenseOptions(List<Territory>)
// Delegates to the static find_defend_options helper with the defend_options
// sub-maps; transport_list is taken by pointer so the helper's amphib pass
// can mutate the underlying dynamic array, and is_checking_enemy_attacks is
// false to mirror the Java call site.
pro_territory_manager_populate_defense_options :: proc(
	self:                ^Pro_Territory_Manager,
	cleared_territories: [dynamic]^Territory,
) {
	pro_territory_manager_find_defend_options(
		self.pro_data,
		self.player,
		pro_data_get_my_unit_territories(self.pro_data),
		pro_my_move_options_get_territory_map(self.defend_options),
		pro_my_move_options_get_unit_move_map(self.defend_options),
		pro_my_move_options_get_transport_move_map(self.defend_options),
		&self.defend_options.transport_list,
		cleared_territories,
		false,
	)
}

// games.strategy.triplea.ai.pro.data.ProTerritoryManager#findAlliedAttackOptions(GamePlayer)
//
// Instance helper. For each ally (in turn order) gather their unit
// territories and run the static find_attack_options pass with empty
// enemy/allied/check lists; the per-ally attack maps are aggregated into
// a Pro_Other_Move_Options keyed by the receiving player (is_attacker=true).
pro_territory_manager_find_allied_attack_options :: proc(
	self:   ^Pro_Territory_Manager,
	player: ^Game_Player,
) -> ^Pro_Other_Move_Options {
	data := pro_data_get_data(self.pro_data)
	allied_players := pro_utils_get_allied_players_in_turn_order(player)
	defer delete(allied_players)
	allied_attack_maps: [dynamic]map[^Territory]^Pro_Territory

	for allied_player in allied_players {
		has_units_p, has_units_c := matches_territory_has_units_owned_by(allied_player)
		allied_unit_territories := make([dynamic]^Territory)
		for t in game_map_get_territories(game_data_get_map(data)) {
			if has_units_p(has_units_c, t) {
				append(&allied_unit_territories, t)
			}
		}
		attack_map := make(map[^Territory]^Pro_Territory)
		unit_attack_map := make(map[^Unit]map[^Territory]struct {})
		transport_attack_map := make(map[^Unit]map[^Territory]struct {})
		bombard_map := make(map[^Unit]map[^Territory]struct {})
		transport_map_list: [dynamic]^Pro_Transport
		append(&allied_attack_maps, attack_map)
		empty_enemy: [dynamic]^Territory
		empty_allied: [dynamic]^Territory
		empty_check: [dynamic]^Territory
		pro_territory_manager_find_attack_options(
			self.pro_data,
			allied_player,
			allied_unit_territories,
			attack_map,
			unit_attack_map,
			transport_attack_map,
			bombard_map,
			&transport_map_list,
			empty_enemy,
			empty_allied,
			empty_check,
			false,
			false,
		)
	}
	return pro_other_move_options_new_with_moves(allied_attack_maps, player, true)
}

// games.strategy.triplea.ai.pro.data.ProTerritoryManager#findEnemyAttackOptions(
//     ProData, GamePlayer, Collection<Territory>, Collection<Territory>)
//
// Static helper. Walks each enemy in turn order, building the player's
// attack-options map with `is_checking_enemy_attacks=true` and
// `is_ignoring_relationships=true`; after each pass the conquered land
// territories are added to alliedTerritories and removed from the
// running enemyTerritories list, mirroring the Java accumulator.
pro_territory_manager_find_enemy_attack_options :: proc(
	pro_data:             ^Pro_Data,
	player:               ^Game_Player,
	cleared_territories:  [dynamic]^Territory,
	territories_to_check: [dynamic]^Territory,
) -> ^Pro_Other_Move_Options {
	data := pro_data_get_data(pro_data)
	enemy_players := pro_utils_get_enemy_players_in_turn_order(player)
	defer delete(enemy_players)
	enemy_attack_maps: [dynamic]map[^Territory]^Pro_Territory
	allied_territories := make(map[^Territory]struct {})
	defer delete(allied_territories)
	enemy_territories := make([dynamic]^Territory)
	for t in cleared_territories {
		append(&enemy_territories, t)
	}
	land_p, land_c := matches_territory_is_land()

	for enemy_player in enemy_players {
		has_units_p, has_units_c := matches_territory_has_units_owned_by(enemy_player)
		enemy_unit_territories := make([dynamic]^Territory)
		for t in game_map_get_territories(game_data_get_map(data)) {
			if !has_units_p(has_units_c, t) {
				continue
			}
			in_cleared := false
			for ct in cleared_territories {
				if ct == t {
					in_cleared = true
					break
				}
			}
			if !in_cleared {
				append(&enemy_unit_territories, t)
			}
		}
		attack_map := make(map[^Territory]^Pro_Territory)
		unit_attack_map := make(map[^Unit]map[^Territory]struct {})
		transport_attack_map := make(map[^Unit]map[^Territory]struct {})
		bombard_map := make(map[^Unit]map[^Territory]struct {})
		transport_map_list: [dynamic]^Pro_Transport
		append(&enemy_attack_maps, attack_map)
		// Java passes new ArrayList<>(alliedTerritories) — copy.
		allied_list := make([dynamic]^Territory)
		for t in allied_territories {
			append(&allied_list, t)
		}
		pro_territory_manager_find_attack_options(
			pro_data,
			enemy_player,
			enemy_unit_territories,
			attack_map,
			unit_attack_map,
			transport_attack_map,
			bombard_map,
			&transport_map_list,
			enemy_territories,
			allied_list,
			territories_to_check,
			true,
			true,
		)
		// alliedTerritories.addAll(getMatches(attackMap.keySet(), territoryIsLand()));
		for t, _ in attack_map {
			if land_p(land_c, t) {
				allied_territories[t] = {}
			}
		}
		// enemyTerritories.removeAll(alliedTerritories);
		new_enemy := make([dynamic]^Territory)
		for t in enemy_territories {
			if !(t in allied_territories) {
				append(&new_enemy, t)
			}
		}
		delete(enemy_territories)
		enemy_territories = new_enemy
	}
	return pro_other_move_options_new_with_moves(enemy_attack_maps, player, true)
}

// games.strategy.triplea.ai.pro.data.ProTerritoryManager#findEnemyDefendOptions(
//     ProData, GamePlayer)
//
// Static helper. Cleared territories are this player's friendly land
// (Matches.isTerritoryAllied). Each enemy's defend pass runs against
// every territory they own, with `is_checking_enemy_attacks=true`, and
// the per-enemy move maps feed a Pro_Other_Move_Options keyed by the
// receiving player with `is_attacker=false`.
pro_territory_manager_find_enemy_defend_options :: proc(
	pro_data: ^Pro_Data,
	player:   ^Game_Player,
) -> ^Pro_Other_Move_Options {
	data := pro_data_get_data(pro_data)
	enemy_players := pro_utils_get_enemy_players_in_turn_order(player)
	defer delete(enemy_players)
	enemy_move_maps: [dynamic]map[^Territory]^Pro_Territory

	allied_p, allied_c := matches_is_territory_allied(player)
	cleared_territories := make([dynamic]^Territory)
	for t in game_map_get_territories(game_data_get_map(data)) {
		if allied_p(allied_c, t) {
			append(&cleared_territories, t)
		}
	}

	for enemy_player in enemy_players {
		has_units_p, has_units_c := matches_territory_has_units_owned_by(enemy_player)
		enemy_unit_territories := make([dynamic]^Territory)
		for t in game_map_get_territories(game_data_get_map(data)) {
			if has_units_p(has_units_c, t) {
				append(&enemy_unit_territories, t)
			}
		}
		move_map := make(map[^Territory]^Pro_Territory)
		unit_move_map := make(map[^Unit]map[^Territory]struct {})
		transport_move_map := make(map[^Unit]map[^Territory]struct {})
		transport_map_list: [dynamic]^Pro_Transport
		append(&enemy_move_maps, move_map)
		pro_territory_manager_find_defend_options(
			pro_data,
			enemy_player,
			enemy_unit_territories,
			move_map,
			unit_move_map,
			transport_move_map,
			&transport_map_list,
			cleared_territories,
			true,
		)
	}
	return pro_other_move_options_new_with_moves(enemy_move_maps, player, false)
}

// games.strategy.triplea.ai.pro.data.ProTerritoryManager#removeTerritoriesThatCantBeConquered(
//     GamePlayer, Map<Territory, ProTerritory>, Map<Unit, Set<Territory>>,
//     Map<Unit, Set<Territory>>, ProOtherMoveOptions, ProOtherMoveOptions, boolean)
//
// Instance helper (uses calc + pro_data fields). For every attack target
// estimates the max-attack outcome with/without amphib, applies the
// allied-strafing rescue path for enemy capitals/factories, then drops
// every territory whose adjusted max win% falls below the win threshold
// (or whose strafing path leaves no land remaining), removing each
// dropped Territory from unit_attack_map and transport_attack_map's
// per-unit destination sets just like Java's HashMap value mutation.
pro_territory_manager_remove_territories_that_cant_be_conquered :: proc(
	self:                      ^Pro_Territory_Manager,
	player:                    ^Game_Player,
	attack_map:                map[^Territory]^Pro_Territory,
	unit_attack_map:           map[^Unit]map[^Territory]struct {},
	transport_attack_map:      map[^Unit]map[^Territory]struct {},
	allied_attack_options:     ^Pro_Other_Move_Options,
	enemy_defend_options:      ^Pro_Other_Move_Options,
	is_ignoring_relationships: bool,
) -> [dynamic]^Pro_Territory {
	pro_logger_info("Removing territories that can't be conquered")
	data := pro_data_get_data(self.pro_data)
	game_map := game_data_get_map(data)

	territories_to_remove := make([dynamic]^Territory)
	has_infra_p, has_infra_c := pro_matches_territory_has_infra_factory_and_is_land()

	for t, patd in attack_map {
		// Defenders: ignoring-relationships → t.units minus patd.maxUnits;
		// otherwise → patd.getMaxEnemyDefenders(player).
		defenders: [dynamic]^Unit
		if is_ignoring_relationships {
			uc := territory_get_unit_collection(t)
			max_units_set := pro_territory_get_max_units(patd)
			for u in unit_collection_get_units(uc) {
				if !(u in max_units_set) {
					append(&defenders, u)
				}
			}
		} else {
			defenders = pro_territory_get_max_enemy_defenders(patd, player)
		}

		// patd.setMaxBattleResult(calc.estimateAttackBattleResults(proData, t, max_units, defenders, Set.of()))
		max_units_list := make([dynamic]^Unit)
		for u in pro_territory_get_max_units(patd) {
			append(&max_units_list, u)
		}
		empty_bombard: [dynamic]^Unit
		first_result := pro_odds_calculator_estimate_attack_battle_results(
			self.calc,
			self.pro_data,
			t,
			max_units_list,
			defenders,
			empty_bombard,
		)
		pro_territory_set_max_battle_result(patd, first_result)

		// Add amphib units if can't win without them.
		if pro_battle_result_get_win_percentage(pro_territory_get_max_battle_result(patd)) <
			   pro_data_get_win_percentage(self.pro_data) &&
		   len(pro_territory_get_max_amphib_units(patd)) > 0 {
			combined := make(map[^Unit]struct {})
			for u in pro_territory_get_max_units(patd) {
				combined[u] = {}
			}
			for u in pro_territory_get_max_amphib_units(patd) {
				combined[u] = {}
			}
			combined_list := make([dynamic]^Unit)
			for u in combined {
				append(&combined_list, u)
			}
			bombard_list := make([dynamic]^Unit)
			for u in pro_territory_get_max_bombard_units(patd) {
				append(&bombard_list, u)
			}
			amphib_result := pro_odds_calculator_estimate_attack_battle_results(
				self.calc,
				self.pro_data,
				t,
				combined_list,
				defenders,
				bombard_list,
			)
			pro_territory_set_max_battle_result(patd, amphib_result)
			pro_territory_set_need_amphib_units(patd, true)
			delete(combined)
		}

		// Strafing / allied-attack rescue for enemy capital or factory.
		att := territory_attachment_get(t)
		is_capital := att != nil && territory_attachment_is_capital(att)
		is_enemy_capital_or_factory :=
			!pro_utils_is_neutral_land(t) && (is_capital || has_infra_p(has_infra_c, t))
		if pro_battle_result_get_win_percentage(pro_territory_get_max_battle_result(patd)) <
			   self.pro_data.min_win_percentage &&
		   is_enemy_capital_or_factory &&
		   pro_other_move_options_get_max(allied_attack_options, t) != nil {

			allied_attack := pro_other_move_options_get_max(allied_attack_options, t)
			allied_units := make(map[^Unit]struct {})
			for u in pro_territory_get_max_units(allied_attack) {
				allied_units[u] = {}
			}
			for u in pro_territory_get_max_amphib_units(allied_attack) {
				allied_units[u] = {}
			}
			if len(allied_units) > 0 {
				// CollectionUtils.getAny(alliedUnits).getOwner()
				allied_player: ^Game_Player
				for u in allied_units {
					allied_player = unit_get_owner(u)
					break
				}
				capital := territory_attachment_get_first_owned_capital_or_first_unowned_capital(
					allied_player,
					game_map,
				)
				if capital != nil {
					capital_neighbors := game_map_get_neighbors(game_map, capital)
					if !(t in capital_neighbors) {
						// Build additionalEnemyDefenders from each enemyDefendOption whose
						// owner takes a turn before allied_player in the turn order.
						additional_enemy_defenders := make(map[^Unit]struct {})
						players_in_order := pro_utils_get_other_players_in_turn_order(player)
						defer delete(players_in_order)
						all_options := pro_other_move_options_get_all(enemy_defend_options, t)
						for enemy_defend_option in all_options {
							enemy_units := make(map[^Unit]struct {})
							for u in pro_territory_get_max_units(enemy_defend_option) {
								enemy_units[u] = {}
							}
							for u in pro_territory_get_max_amphib_units(enemy_defend_option) {
								enemy_units[u] = {}
							}
							if len(enemy_units) > 0 {
								enemy_player: ^Game_Player
								for u in enemy_units {
									enemy_player = unit_get_owner(u)
									break
								}
								if pro_utils_is_players_turn_first(
									players_in_order,
									enemy_player,
									allied_player,
								) {
									for u in enemy_units {
										additional_enemy_defenders[u] = {}
									}
								}
							}
							delete(enemy_units)
						}

						// enemyDefendersBeforeStrafe = defenders ∪ additional
						before_set := make(map[^Unit]struct {})
						for u in defenders {
							before_set[u] = {}
						}
						for u in additional_enemy_defenders {
							before_set[u] = {}
						}
						before_list := make([dynamic]^Unit)
						for u in before_set {
							append(&before_list, u)
						}

						allied_units_list := make([dynamic]^Unit)
						for u in allied_units {
							append(&allied_units_list, u)
						}
						allied_bombard_list := make([dynamic]^Unit)
						for u in pro_territory_get_max_bombard_units(allied_attack) {
							append(&allied_bombard_list, u)
						}

						strafe_check := pro_odds_calculator_estimate_attack_battle_results(
							self.calc,
							self.pro_data,
							t,
							allied_units_list,
							before_list,
							allied_bombard_list,
						)

						if pro_battle_result_get_win_percentage(strafe_check) <
						   pro_data_get_win_percentage(self.pro_data) {
							pro_territory_set_strafing(patd, true)

							combined_set := make(map[^Unit]struct {})
							for u in pro_territory_get_max_units(patd) {
								combined_set[u] = {}
							}
							for u in pro_territory_get_max_amphib_units(patd) {
								combined_set[u] = {}
							}
							combined_list := make([dynamic]^Unit)
							for u in combined_set {
								append(&combined_list, u)
							}
							patd_bombard_list := make([dynamic]^Unit)
							for u in pro_territory_get_max_bombard_units(patd) {
								append(&patd_bombard_list, u)
							}
							strafe_result :=
								pro_odds_calculator_call_battle_calc_with_retreat_air(
									self.calc,
									self.pro_data,
									t,
									combined_list,
									defenders,
									patd_bombard_list,
								)

							after_set := make(map[^Unit]struct {})
							for u in pro_battle_result_get_average_defenders_remaining(
								strafe_result,
							) {
								after_set[u] = {}
							}
							for u in additional_enemy_defenders {
								after_set[u] = {}
							}
							after_list := make([dynamic]^Unit)
							for u in after_set {
								append(&after_list, u)
							}

							allied_units_list2 := make([dynamic]^Unit)
							for u in allied_units {
								append(&allied_units_list2, u)
							}
							allied_bombard_list2 := make([dynamic]^Unit)
							for u in pro_territory_get_max_bombard_units(allied_attack) {
								append(&allied_bombard_list2, u)
							}
							r2 := pro_odds_calculator_estimate_attack_battle_results(
								self.calc,
								self.pro_data,
								t,
								allied_units_list2,
								after_list,
								allied_bombard_list2,
							)
							pro_territory_set_max_battle_result(patd, r2)

							ap_name := default_named_get_name(
								&allied_player.named_attachable.default_named,
							)
							pro_logger_debug(
								fmt.aprintf(
									"Checking strafing territory: %s, alliedPlayer=%s, maxWin%%=%v, maxAttackers=%d, maxDefenders=%d",
									territory_to_string(t),
									ap_name,
									pro_battle_result_get_win_percentage(
										pro_territory_get_max_battle_result(patd),
									),
									len(allied_units),
									len(after_set),
								),
							)
							delete(combined_set)
							delete(after_set)
						}
						delete(before_set)
						delete(additional_enemy_defenders)
					}
				}
			}
			delete(allied_units)
		}

		max_pct := pro_battle_result_get_win_percentage(pro_territory_get_max_battle_result(patd))
		if max_pct < self.pro_data.min_win_percentage ||
		   (pro_territory_is_strafing(patd) &&
				   (max_pct < pro_data_get_win_percentage(self.pro_data) ||
						   !pro_battle_result_is_has_land_unit_remaining(
							   pro_territory_get_max_battle_result(patd),
						   ))) {
			append(&territories_to_remove, t)
		}
	}

	// Java: Collections.sort(territoriesToRemove);  — Territory natural order.
	slice.sort_by(territories_to_remove[:], proc(a, b: ^Territory) -> bool {
		return territory_compare_to(a, b) < 0
	})

	// Build the result list as attackMap.values() minus removed entries,
	// while pruning each removed territory from unit/transport attack maps.
	remove_set := make(map[^Pro_Territory]struct {})
	defer delete(remove_set)
	for t in territories_to_remove {
		pt := attack_map[t]
		remove_set[pt] = {}
		combined := make(map[^Unit]struct {})
		for u in pro_territory_get_max_units(pt) {
			combined[u] = {}
		}
		for u in pro_territory_get_max_amphib_units(pt) {
			combined[u] = {}
		}
		pro_logger_debug(
			fmt.aprintf(
				"Removing territory that we can't successfully attack: %s, maxWin%%=%v, maxAttackers=%d",
				territory_to_string(t),
				pro_battle_result_get_win_percentage(pro_territory_get_max_battle_result(pt)),
				len(combined),
			),
		)
		delete(combined)
		t_local := t
		for _, territories in unit_attack_map {
			delete_key(&territories, t_local)
		}
		for _, territories in transport_attack_map {
			delete_key(&territories, t_local)
		}
	}

	result := make([dynamic]^Pro_Territory)
	for _, v in attack_map {
		if !(v in remove_set) {
			append(&result, v)
		}
	}
	return result
}

// games.strategy.triplea.ai.pro.data.ProTerritoryManager#populateAttackOptions()
// Sets attack_options via the static find_attack_options helper (empty
// enemy/allied/check lists, not checking enemy attacks, not ignoring
// relationships), then runs the bombing pass and refreshes
// allied_attack_options.
pro_territory_manager_populate_attack_options :: proc(self: ^Pro_Territory_Manager) {
	empty_enemy: [dynamic]^Territory
	empty_allied: [dynamic]^Territory
	empty_check: [dynamic]^Territory
	pro_territory_manager_find_attack_options(
		self.pro_data,
		self.player,
		pro_data_get_my_unit_territories(self.pro_data),
		pro_my_move_options_get_territory_map(self.attack_options),
		pro_my_move_options_get_unit_move_map(self.attack_options),
		pro_my_move_options_get_transport_move_map(self.attack_options),
		pro_my_move_options_get_bombard_map(self.attack_options),
		&self.attack_options.transport_list,
		empty_enemy,
		empty_allied,
		empty_check,
		false,
		false,
	)
	pro_territory_manager_find_bombing_options(self)
	self.allied_attack_options = pro_territory_manager_find_allied_attack_options(
		self,
		self.player,
	)
}

// games.strategy.triplea.ai.pro.data.ProTerritoryManager#populateEnemyAttackOptions(
//     Collection<Territory>, Collection<Territory>)
pro_territory_manager_populate_enemy_attack_options :: proc(
	self:                 ^Pro_Territory_Manager,
	cleared_territories:  [dynamic]^Territory,
	territories_to_check: [dynamic]^Territory,
) {
	self.enemy_attack_options = pro_territory_manager_find_enemy_attack_options(
		self.pro_data,
		self.player,
		cleared_territories,
		territories_to_check,
	)
}

// games.strategy.triplea.ai.pro.data.ProTerritoryManager#populateEnemyDefenseOptions()
pro_territory_manager_populate_enemy_defense_options :: proc(self: ^Pro_Territory_Manager) {
	pro_territory_manager_find_scramble_options(
		self.pro_data,
		self.player,
		pro_my_move_options_get_territory_map(self.attack_options),
	)
	self.enemy_defend_options = pro_territory_manager_find_enemy_defend_options(
		self.pro_data,
		self.player,
	)
}

// games.strategy.triplea.ai.pro.data.ProTerritoryManager#removePotentialTerritoriesThatCantBeConquered()
// Delegates to the multi-arg instance helper using potential_attack_options
// with is_ignoring_relationships=true (per Java).
pro_territory_manager_remove_potential_territories_that_cant_be_conquered :: proc(
	self: ^Pro_Territory_Manager,
) -> [dynamic]^Pro_Territory {
	return pro_territory_manager_remove_territories_that_cant_be_conquered(
		self,
		self.player,
		pro_my_move_options_get_territory_map(self.potential_attack_options),
		pro_my_move_options_get_unit_move_map(self.potential_attack_options),
		pro_my_move_options_get_transport_move_map(self.potential_attack_options),
		self.allied_attack_options,
		self.enemy_defend_options,
		true,
	)
}

// games.strategy.triplea.ai.pro.data.ProTerritoryManager#removeTerritoriesThatCantBeConquered()
// No-arg public overload. Suffix _0 disambiguates from the multi-arg
// instance helper of the same Java name already ported above.
pro_territory_manager_remove_territories_that_cant_be_conquered_0 :: proc(
	self: ^Pro_Territory_Manager,
) -> [dynamic]^Pro_Territory {
	return pro_territory_manager_remove_territories_that_cant_be_conquered(
		self,
		self.player,
		pro_my_move_options_get_territory_map(self.attack_options),
		pro_my_move_options_get_unit_move_map(self.attack_options),
		pro_my_move_options_get_transport_move_map(self.attack_options),
		self.allied_attack_options,
		self.enemy_defend_options,
		false,
	)
}

