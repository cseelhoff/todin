package game

import "core:fmt"

Pro_Move_Utils :: struct {}

// Synthetic lambda `e -> Stream.concat(Stream.of(e.getKey()), e.getValue().stream())`
// from `ProMoveUtils.calculateMoveRoutes`, applied as the `flatMap` over
// `attackMap.values().map(ProTerritory::getAmphibAttackMap).map(Map::entrySet).flatMap(Collection::stream)`.
// The `Map.Entry<Unit, Collection<Unit>>` is unpacked into separate key/value
// parameters; the result is a flat list of the entry's key followed by every
// element of its value collection.
pro_move_utils_lambda_calculate_move_routes_0 :: proc(key: ^Unit, value: [dynamic]^Unit) -> [dynamic]^Unit {
	result := make([dynamic]^Unit)
	append(&result, key)
	for u in value {
		append(&result, u)
	}
	return result
}

// Synthetic lambda `move -> move.getUnitsToSeaTransports().isEmpty()`
// from `ProMoveUtils.doMove`, used as the `allMatch` predicate that
// determines whether none of the queued moves carry sea-transport loads.
pro_move_utils_lambda__do_move__3 :: proc(move: ^Move_Description) -> bool {
	return len(move_description_get_units_to_sea_transports(move)) == 0
}

// Synthetic lambda `route -> moves.add(new MoveDescription(unitList, route))`
// from `ProMoveUtils.calculateBombardMoveRoutes`, applied as the
// `Optional<Route>::ifPresent` consumer when the naval route to the
// bombard-from territory exists. Captures the enclosing `moves` and
// `unitList` ArrayLists; appends a freshly-constructed MoveDescription
// (via the 2-arg Collection<Unit>+Route constructor) to `moves`.
pro_move_utils_lambda__calculate_bombard_move_routes__1 :: proc(
	moves: ^[dynamic]^Move_Description,
	unit_list: [dynamic]^Unit,
	route: ^Route,
) {
	append(moves, move_description_new_units_route(unit_list[:], route))
}

// Synthetic lambda `route -> moves.add(new MoveDescription(unitList, route))`
// from `ProMoveUtils.calculateBombingRoutes`, applied as the
// `Optional<Route>::ifPresent` consumer when the air route to the
// strategic-bombing target territory exists. Captures the enclosing
// `moves` and `unitList` ArrayLists; appends a freshly-constructed
// MoveDescription (via the 2-arg Collection<Unit>+Route constructor)
// to `moves`.
pro_move_utils_lambda__calculate_bombing_routes__2 :: proc(
	moves: ^[dynamic]^Move_Description,
	unit_list: [dynamic]^Unit,
	route: ^Route,
) {
	append(moves, move_description_new_units_route(unit_list[:], route))
}

// File-scope holders bridging a ctx-form Predicate<Territory> (the
// closures returned by ProMatches.territoryCanMove*UnitsThrough and
// territoryCanMoveAirUnitsAndNoAa) into the bare
// `proc(^Territory) -> bool` cond consumed by
// `game_map_get_route_for_unit`. Each route lookup runs synchronously
// inside the for-loop bodies below, so a single pair of holders is
// sufficient — set the holders, call game_map_get_route_for_unit,
// inspect the returned ^Route, repeat. Same pattern used by
// pro_non_combat_move_ai.odin.
@(private = "file")
pro_move_utils_active_cond: proc(rawptr, ^Territory) -> bool

@(private = "file")
pro_move_utils_active_cond_ctx: rawptr

@(private = "file")
pro_move_utils_cond_trampoline :: proc(t: ^Territory) -> bool {
	return pro_move_utils_active_cond(pro_move_utils_active_cond_ctx, t)
}

// games.strategy.triplea.ai.pro.util.ProMoveUtils#calculateMoveRoutes(
//     ProData, GamePlayer, Map<Territory, ProTerritory>, boolean)
//
// Calculates normal movement routes (land, air, sea attack routes; not
// amphibious, bombardment, or strategic bombing). Mirrors the Java:
//
//   1. Collect every amphib-attack participant (transport keys and the
//      attacking units in their value collections) into a set so they
//      can be skipped in the main loop — they are handled separately
//      by calculateAmphibRoutes.
//   2. For each (territory, ProTerritory) entry: walk every unit
//      attacking the territory, skip amphib units and units already at
//      `t`, build a singleton unit list, optionally extend it with
//      `MoveValidator.carrierMustMoveWith(start, player).get(u)` when
//      `u` is a carrier, then pick the route predicate based on the
//      unit-list composition (any-sea → sea, all-land → land with a
//      land-transport retry when the previous unit in this iteration
//      was a land transport originating from the same start, all-air
//      → air-no-AA). The land-transport retry mirrors the Java's
//      `lastLandTransport` Tuple<Territory, Unit> threaded across
//      iterations of the inner loop.
//   3. Record an empty Optional → ProLogger.warn at WARN; record a
//      present route → append `new MoveDescription(unitList, route)`.
//
// `route_for_unit` is the Odin equivalent of `getRouteForUnit`,
// returning `^Route` (nil = empty Optional). Predicate values returned
// by ProMatches/Matches are (proc, rawptr) pairs; this proc bridges
// them into the bare-proc form via the file-scope cond holder.
pro_move_utils_calculate_move_routes :: proc(
	pro_data: ^Pro_Data,
	player: ^Game_Player,
	attack_map: map[^Territory]^Pro_Territory,
	is_combat_move: bool,
) -> [dynamic]^Move_Description {
	data := pro_data_get_data(pro_data)
	gm := game_data_get_map(data)

	// Find all amphib units (transport keys + attacking-unit values).
	amphib_units := make(map[^Unit]struct{})
	defer delete(amphib_units)
	for _, pt in attack_map {
		aam := pro_territory_get_amphib_attack_map(pt)
		for k, v in aam {
			amphib_units[k] = {}
			for u in v {
				amphib_units[u] = {}
			}
		}
	}

	moves := make([dynamic]^Move_Description)

	is_sea_p, is_sea_c := matches_unit_is_sea()
	is_land_p, is_land_c := matches_unit_is_land()
	is_air_p, is_air_c := matches_unit_is_air()
	is_carrier_p, is_carrier_c := matches_unit_is_carrier()
	is_land_transport_p, is_land_transport_c := matches_unit_is_land_transport()

	// Loop through all territories to attack.
	for t in attack_map {
		// Java: Tuple<Territory, Unit> lastLandTransport = Tuple.of(null, null);
		llt_first: ^Territory = nil
		llt_second: ^Unit = nil

		units := pro_territory_get_units(attack_map[t])
		for u in units {
			// Skip amphib units.
			if _, is_amphib := amphib_units[u]; is_amphib {
				continue
			}

			// Skip if unit is already in move-to territory.
			start_territory := pro_data_get_unit_territory(pro_data, u)
			if start_territory == nil || start_territory == t {
				continue
			}

			// Add unit to move list.
			unit_list := make([dynamic]^Unit)
			append(&unit_list, u)
			if is_land_transport_p(is_land_transport_c, u) {
				llt_first = start_territory
				llt_second = u
			}

			// If carrier has dependent allied fighters then move them too.
			if is_carrier_p(is_carrier_c, u) {
				cmw := move_validator_carrier_must_move_with_territory(
					start_territory,
					player,
				)
				if extras, ok := cmw[u]; ok {
					for x in extras {
						append(&unit_list, x)
					}
				}
			}

			// Determine route and add to move list.
			route: ^Route = nil

			any_sea := false
			for v in unit_list {
				if is_sea_p(is_sea_c, v) {
					any_sea = true
					break
				}
			}
			if any_sea {
				// Sea unit (including carriers with planes).
				cp, cc := pro_matches_territory_can_move_sea_units_through(
					player,
					is_combat_move,
				)
				pro_move_utils_active_cond = cp
				pro_move_utils_active_cond_ctx = cc
				route = game_map_get_route_for_unit(
					gm,
					start_territory,
					t,
					pro_move_utils_cond_trampoline,
					u,
					player,
				)
			} else {
				all_land := true
				for v in unit_list {
					if !is_land_p(is_land_c, v) {
						all_land = false
						break
					}
				}
				if all_land {
					// Land unit.
					empty_enemies: [dynamic]^Territory
					cp, cc := pro_matches_territory_can_move_land_units_through(
						player,
						u,
						start_territory,
						is_combat_move,
						empty_enemies,
					)
					pro_move_utils_active_cond = cp
					pro_move_utils_active_cond_ctx = cc
					route = game_map_get_route_for_unit(
						gm,
						start_territory,
						t,
						pro_move_utils_cond_trampoline,
						u,
						player,
					)
					if route == nil && start_territory == llt_first {
						empty_enemies2: [dynamic]^Territory
						cp2, cc2 := pro_matches_territory_can_move_land_units_through(
							player,
							llt_second,
							start_territory,
							is_combat_move,
							empty_enemies2,
						)
						pro_move_utils_active_cond = cp2
						pro_move_utils_active_cond_ctx = cc2
						route = game_map_get_route_for_unit(
							gm,
							start_territory,
							t,
							pro_move_utils_cond_trampoline,
							u,
							player,
						)
					}
				} else {
					all_air := true
					for v in unit_list {
						if !is_air_p(is_air_c, v) {
							all_air = false
							break
						}
					}
					if all_air {
						// Air unit.
						cp, cc := pro_matches_territory_can_move_air_units_and_no_aa(
							data,
							player,
							is_combat_move,
						)
						pro_move_utils_active_cond = cp
						pro_move_utils_active_cond_ctx = cc
						route = game_map_get_route_for_unit(
							gm,
							start_territory,
							t,
							pro_move_utils_cond_trampoline,
							u,
							player,
						)
					}
				}
			}

			if route == nil {
				pro_logger_warn(
					fmt.tprintf(
						"%d-%s: route is null (could not calculate route)%v to %v, units=%v",
						game_sequence_get_round(game_data_get_sequence(data)),
						game_step_get_name(
							game_sequence_get_step(game_data_get_sequence(data)),
						),
						start_territory,
						t,
						unit_list[:],
					),
				)
			} else {
				append(&moves, move_description_new_units_route(unit_list[:], route))
			}
		}
	}
	return moves
}

// games.strategy.triplea.ai.pro.util.ProMoveUtils#calculateAmphibRoutes(
//     ProData, GamePlayer, Map<Territory, ProTerritory>, boolean)
//
// Calculates amphibious movement routes. Mirrors the Java:
//
//   For each (territory, ProTerritory) entry, walk the
//   amphibAttackMap (Transport -> List<Unit>) and, per transport,
//   start a fresh sequence on a MoveBatcher. Loaded units come from
//   transport.isTransporting(transportTerritory); otherwise the
//   value collection is the remainingUnitsToLoad pile. Then loop
//   while movesLeft >= 0:
//
//     1. If transportTerritory has no enemy units, look at every
//        remaining unit; if it is one square away on the GameMap,
//        emit a transport-load sequence (load route + transport)
//        and move it from remainingUnitsToLoad to loadedUnits.
//     2. If movesLeft > 0 and we still have somewhere to go (more
//        than one square from t, or units left to pick up, or an
//        explicit unloadTerritory we're not yet on), pick the best
//        next sea neighbor: filter by ProMatches.canMoveSeaThrough,
//        skip those that fail MoveValidator.validateCanal, and
//        score by (a) the max distance from neighbor to remaining
//        loaders and (b) the distance-ignore-end from neighbor to
//        t / unloadTerritory under the same sea predicate. The
//        Java's tri-condition tie-breaker is reproduced verbatim.
//        On success, queue an addMove(transport+loadedUnits, route)
//        on the MoveBatcher and advance transportTerritory.
//     3. After the load/move loop, warn if any remainingUnitsToLoad
//        survive, then publish the final transportTerritory back
//        into the ProTerritory's transportTerritoryMap. If we have
//        loaded units and t is land, queue the final unload move.
//
//   The MoveBatcher's batchMoves() handles cross-sequence merging
//   (see move_batcher_batch_moves) and yields the final list of
//   MoveDescriptions.
pro_move_utils_calculate_amphib_routes :: proc(
	pro_data: ^Pro_Data,
	player: ^Game_Player,
	attack_map: map[^Territory]^Pro_Territory,
	is_combat_move: bool,
) -> [dynamic]^Move_Description {
	data := pro_data_get_data(pro_data)
	gm := game_data_get_map(data)

	moves := move_batcher_new()

	// Loop through all territories to attack.
	for t in attack_map {
		// Loop through each amphib attack map.
		amphib_attack_map := pro_territory_get_amphib_attack_map(attack_map[t])
		for transport in amphib_attack_map {
			moves_left := int(unit_get_movement_left(transport))
			transport_territory := pro_data_get_unit_territory(pro_data, transport)
			move_batcher_new_sequence(moves)

			// Check if units are already loaded or not.
			loaded_units := make([dynamic]^Unit)
			remaining_units_to_load := make([dynamic]^Unit)

			if unit_is_transporting_in_territory_arg(transport, transport_territory) {
				for u in amphib_attack_map[transport] {
					append(&loaded_units, u)
				}
			} else {
				for u in amphib_attack_map[transport] {
					append(&remaining_units_to_load, u)
				}
			}

			// Load units and move transport.
			for moves_left >= 0 {
				// Load adjacent units if no enemies present in transport territory.
				heu_p, heu_c := matches_territory_has_enemy_units(player)
				if !heu_p(heu_c, transport_territory) {
					units_to_remove := make([dynamic]^Unit)
					for amphib_unit in remaining_units_to_load {
						unit_territory := pro_data_get_unit_territory(pro_data, amphib_unit)
						if game_map_get_distance(gm, transport_territory, unit_territory) == 1 {
							route := route_new_from_start_and_steps(
								unit_territory,
								transport_territory,
							)
							move_batcher_add_transport_load(
								moves,
								amphib_unit,
								route,
								transport,
							)
							append(&units_to_remove, amphib_unit)
							append(&loaded_units, amphib_unit)
						}
					}
					for u in units_to_remove {
						for i := 0; i < len(remaining_units_to_load); i += 1 {
							if remaining_units_to_load[i] == u {
								ordered_remove(&remaining_units_to_load, i)
								break
							}
						}
					}
				}

				// Move transport if I'm not already at the end or out of moves.
				transport_territory_map := pro_territory_get_transport_territory_map(
					attack_map[t],
				)
				unload_territory: ^Territory = nil
				if v, ok := transport_territory_map[transport]; ok {
					unload_territory = v
				}
				distance_from_end := game_map_get_distance(gm, transport_territory, t)
				if territory_is_water(t) {
					distance_from_end += 1
				}
				if moves_left > 0 &&
				   (distance_from_end > 1 ||
						   len(remaining_units_to_load) > 0 ||
						   (unload_territory != nil &&
									   unload_territory != transport_territory)) {
					nb_p, nb_c := pro_matches_territory_can_move_sea_units_through(
						player,
						is_combat_move,
					)
					neighbors := game_map_get_neighbors_predicate(
						gm,
						transport_territory,
						nb_p,
						nb_c,
					)
					defer delete(neighbors)
					territory_to_move_to: ^Territory = nil
					min_unit_distance := i32(max(i32))
					// Used to move to farthest away loading territory first.
					max_distance_from_end := i32(min(i32))
					move_validator := move_validator_new(data, !is_combat_move)
					transport_singleton := make([dynamic]^Unit)
					append(&transport_singleton, transport)
					for neighbor in neighbors {
						route := route_new_from_start_and_steps(
							transport_territory,
							neighbor,
						)
						if move_validator_validate_canal(
							   move_validator,
							   route,
							   transport_singleton,
							   false,
							   player,
						   ) !=
						   nil {
							continue
						}
						distance_from_unload_territory: i32 = 0
						if unload_territory != nil {
							cp, cc := pro_matches_territory_can_move_sea_units_through(
								player,
								is_combat_move,
							)
							pro_move_utils_active_cond = cp
							pro_move_utils_active_cond_ctx = cc
							distance_from_unload_territory =
								game_map_get_distance_ignore_end_for_condition(
									gm,
									neighbor,
									unload_territory,
									pro_move_utils_cond_trampoline,
								)
						}
						cp2, cc2 := pro_matches_territory_can_move_sea_units_through(
							player,
							is_combat_move,
						)
						pro_move_utils_active_cond = cp2
						pro_move_utils_active_cond_ctx = cc2
						neighbor_distance_from_end :=
							game_map_get_distance_ignore_end_for_condition(
								gm,
								neighbor,
								t,
								pro_move_utils_cond_trampoline,
							)
						if territory_is_water(t) {
							neighbor_distance_from_end += 1
						}
						max_unit_distance: i32 = 0
						for u in remaining_units_to_load {
							distance := game_map_get_distance(
								gm,
								neighbor,
								pro_data_get_unit_territory(pro_data, u),
							)
							if distance > max_unit_distance {
								max_unit_distance = distance
							}
						}
						if neighbor_distance_from_end <= i32(moves_left) &&
						   max_unit_distance <= min_unit_distance &&
						   distance_from_unload_territory < i32(moves_left) &&
						   (max_unit_distance < min_unit_distance ||
								   (max_unit_distance > 1 &&
										   neighbor_distance_from_end >
											   max_distance_from_end) ||
								   (max_unit_distance <= 1 &&
										   neighbor_distance_from_end <
											   max_distance_from_end)) {
							territory_to_move_to = neighbor
							min_unit_distance = max_unit_distance
							if neighbor_distance_from_end > max_distance_from_end {
								max_distance_from_end = neighbor_distance_from_end
							}
						}
					}
					if territory_to_move_to != nil {
						units_to_move := make([dynamic]^Unit)
						append(&units_to_move, transport)
						for u in loaded_units {
							append(&units_to_move, u)
						}
						route := route_new_from_start_and_steps(
							transport_territory,
							territory_to_move_to,
						)
						move_batcher_add_move_units_route(moves, units_to_move[:], route)
						transport_territory = territory_to_move_to
					}
				}
				moves_left -= 1
			}
			if len(remaining_units_to_load) > 0 {
				pro_logger_warn(
					fmt.tprintf(
						"%d-%s: %v, remainingUnitsToLoad=%v",
						game_sequence_get_round(game_data_get_sequence(data)),
						game_step_get_name(
							game_sequence_get_step(game_data_get_sequence(data)),
						),
						t,
						remaining_units_to_load[:],
					),
				)
			}

			// Set territory transport is moving to.
			ttm := pro_territory_get_transport_territory_map(attack_map[t])
			ttm[transport] = transport_territory

			// Unload transport.
			if len(loaded_units) > 0 && !territory_is_water(t) {
				route := route_new_from_start_and_steps(transport_territory, t)
				move_batcher_add_move_units_route(moves, loaded_units[:], route)
			}
		}
	}

	return move_batcher_batch_moves(moves)
}

// games.strategy.triplea.ai.pro.util.ProMoveUtils#calculateBombardMoveRoutes(
//     ProData, GamePlayer, Map<Territory, ProTerritory>)
//
// Calculates bombardment movement routes. Mirrors the Java:
//
//   For each ProTerritory in attackMap.values(), iterate the
//   bombardTerritoryMap (Unit -> Territory) entries; skip units
//   already at their bombard-from territory; for each surviving unit,
//   if it is owned, sea, and can be moved, route it from its start
//   territory to the bombard-from territory using the sea predicate
//   (combat move = true), and append a MoveDescription on success.
//
// Java's `Optional<Route>::ifPresent` consumer is the existing
// pro_move_utils_lambda__calculate_bombard_move_routes__1 helper.
pro_move_utils_calculate_bombard_move_routes :: proc(
	pro_data: ^Pro_Data,
	player: ^Game_Player,
	attack_map: map[^Territory]^Pro_Territory,
) -> [dynamic]^Move_Description {
	data := pro_data_get_data(pro_data)
	gm := game_data_get_map(data)

	moves := make([dynamic]^Move_Description)

	// Loop through all territories to attack.
	for _, t in attack_map {
		btm := pro_territory_get_bombard_territory_map(t)
		for u, bombard_from_territory in btm {
			// Skip if unit is already in move-to territory.
			start_territory := pro_data_get_unit_territory(pro_data, u)
			if start_territory == nil || start_territory == bombard_from_territory {
				continue
			}

			// Add unit to move list.
			unit_list := make([dynamic]^Unit)
			append(&unit_list, u)

			// Determine route and add to move list.
			owned_sea_p, owned_sea_c := pro_matches_unit_can_be_moved_and_is_owned_sea(
				player,
				true,
			)
			all_owned_sea := true
			for v in unit_list {
				if !owned_sea_p(owned_sea_c, v) {
					all_owned_sea = false
					break
				}
			}
			if all_owned_sea {
				cp, cc := pro_matches_territory_can_move_sea_units_through(player, true)
				pro_move_utils_active_cond = cp
				pro_move_utils_active_cond_ctx = cc
				route := game_map_get_route_for_unit(
					gm,
					start_territory,
					bombard_from_territory,
					pro_move_utils_cond_trampoline,
					u,
					player,
				)
				if route != nil {
					pro_move_utils_lambda__calculate_bombard_move_routes__1(
						&moves,
						unit_list,
						route,
					)
				}
			}
		}
	}

	return moves
}

// games.strategy.triplea.ai.pro.util.ProMoveUtils#calculateBombingRoutes(
//     ProData, GamePlayer, Map<Territory, ProTerritory>)
//
// Calculates strategic bombing raid movement routes. Mirrors the Java:
//
//   For each (territory, ProTerritory) entry, iterate the bombers
//   list; skip units already at the target territory; if the unit is
//   air, route it from its start territory to `t` using the
//   air-no-AA predicate (combat move = true), and append a
//   MoveDescription on success.
pro_move_utils_calculate_bombing_routes :: proc(
	pro_data: ^Pro_Data,
	player: ^Game_Player,
	attack_map: map[^Territory]^Pro_Territory,
) -> [dynamic]^Move_Description {
	data := pro_data_get_data(pro_data)
	gm := game_data_get_map(data)

	moves := make([dynamic]^Move_Description)

	is_air_p, is_air_c := matches_unit_is_air()

	// Loop through all territories to attack.
	for t in attack_map {
		bombers := pro_territory_get_bombers(attack_map[t])
		for u in bombers {
			// Skip if unit is already in move-to territory.
			start_territory := pro_data_get_unit_territory(pro_data, u)
			if start_territory == nil || start_territory == t {
				continue
			}

			// Add unit to move list.
			unit_list := make([dynamic]^Unit)
			append(&unit_list, u)

			// Determine route and add to move list.
			all_air := true
			for v in unit_list {
				if !is_air_p(is_air_c, v) {
					all_air = false
					break
				}
			}
			if all_air {
				cp, cc := pro_matches_territory_can_move_air_units_and_no_aa(
					data,
					player,
					true,
				)
				pro_move_utils_active_cond = cp
				pro_move_utils_active_cond_ctx = cc
				route := game_map_get_route_for_unit(
					gm,
					start_territory,
					t,
					pro_move_utils_cond_trampoline,
					u,
					player,
				)
				if route != nil {
					pro_move_utils_lambda__calculate_bombing_routes__2(
						&moves,
						unit_list,
						route,
					)
				}
			}
		}
	}
	return moves
}

// games.strategy.triplea.ai.pro.util.ProMoveUtils#doMove(
//     ProData, List<MoveDescription>, IMoveDelegate)
//
// Moves the specified groups of units along the specified routes,
// possibly using the specified transports. Mirrors the Java doMove:
//
//   1. If no move in the list carries a sea-transport load, fold any
//      pair of moves that share the same route into a single
//      MoveDescription whose unit list concatenates the later move's
//      units in front of the earlier move's units (this matches the
//      Java order: addAll(j) then addAll(i)).
//   2. Submit each (possibly merged) move to the IMoveDelegate. The
//      Java performMove returns Optional<String>; the Odin
//      Move_Delegate#perform_move returns "" on success or an error
//      message; warn via ProLogger when non-empty.
//   3. Between moves, call AbstractAi.movePause() unless the run is a
//      simulation.
//
// `moves` is taken by pointer because the Java code mutates the list
// in-place (set + remove) during the merge pass.
pro_move_utils_do_move :: proc(
	pro_data: ^Pro_Data,
	moves: ^[dynamic]^Move_Description,
	move_del: ^I_Move_Delegate,
) {
	data := pro_data_get_data(pro_data)

	// Group non-amphib units of the same type moving on the same route.
	no_transport_loads := true
	for m in moves^ {
		if !pro_move_utils_lambda__do_move__3(m) {
			no_transport_loads = false
			break
		}
	}
	if no_transport_loads {
		for i := 0; i < len(moves^); i += 1 {
			r := move_description_get_route(moves^[i])
			for j := i + 1; j < len(moves^); j += 1 {
				r2 := move_description_get_route(moves^[j])
				if route_equals(r, r2) {
					merged_units := make([dynamic]^Unit)
					for u in moves^[j].units {
						append(&merged_units, u)
					}
					for u in moves^[i].units {
						append(&merged_units, u)
					}
					moves^[j] = move_description_new_units_route(merged_units[:], r)
					ordered_remove(moves, i)
					i -= 1
					break
				}
			}
		}
	}

	// Move units.
	for move in moves^ {
		// Move_Delegate is the concrete remote delegate behind
		// IMoveDelegate; cast through the marker interface to invoke it.
		md := cast(^Move_Delegate)move_del
		result := move_delegate_perform_move(md, move)
		if result != "" {
			pro_logger_warn(
				fmt.tprintf(
					"%d-%s: could not move %v over %v because: %s",
					game_sequence_get_round(game_data_get_sequence(data)),
					game_step_get_name(game_sequence_get_step(game_data_get_sequence(data))),
					move.units[:],
					move_description_get_route(move),
					result,
				),
			)
		}
		if !pro_data_is_simulation(pro_data) {
			abstract_ai_move_pause()
		}
	}
}

// Synthetic lambda `result -> ProLogger.warn(<round>-<step>: could not move ... because: result)`
// from `ProMoveUtils.doMove`, applied as the `Optional<String>::ifPresent`
// consumer on the result of `IMoveDelegate.performMove(move)`. Captures
// the enclosing `data` (GameState) and `move` (MoveDescription); logs the
// round/step header along with the move's units, route, and the failure
// reason returned by the delegate.
pro_move_utils_lambda__do_move__4 :: proc(data: ^Game_Data, move: ^Move_Description, result: string) {
	pro_logger_warn(
		fmt.tprintf(
			"%d-%s: could not move %v over %v because: %s",
			game_sequence_get_round(game_data_get_sequence(data)),
			game_step_get_name(game_sequence_get_step(game_data_get_sequence(data))),
			move.units[:],
			move_description_get_route(move),
			result,
		),
	)
}

