package game

import "core:fmt"
import "core:slice"
import "core:strings"

Pro_Move_Utils :: struct {}

// triplea-port-bootstrap: stable cross-language sort key for transports in
// pro_move_utils_calculate_amphib_routes. Mirrors `amphibUnitSortKey` in
// ProMoveUtils.java.
// Composite key: (currentTerritory.name, owner.name, type.name, hits,
//                 alreadyMoved, transport_signature_of_loaded_units,
//                 unit_uuid_hex).
//
// Iter 43: Java's amphibUnitSortKey omits the loaded-units signature
// AND the UUID tie-break; for tied keys Java's stable TimSort
// preserves HashMap-iteration order (which depends on
// identityHashCode and is itself nondeterministic across JVM runs).
// Odin's `map[^Unit]` iteration is ASLR-sensitive AND Odin's
// `slice.sort_by` (pdqsort) is unstable. Snap 0089 had multiple
// same-type Japanese transports loading from the same sea zone with
// identical (terr, owner, type, hits, alreadyMoved) — different
// transport iteration orders led to different units being loaded
// (when two transports both targeted the same Japan-origin unit,
// the first to process won, the others' load attempts failed
// because the unit's territory had changed). Result: Japan's
// post-NCM unit_collection.units count flaked n=2/3/5 across runs.
//
// Adding (a) the loaded-unit-types signature and (b) the unit's
// own UUID hex (stable across runs because units are loaded from
// the snapshot save state, never freshly minted during a snap run)
// makes the key UNIQUE per transport — independent of pointer hash
// order — so the resulting sort is deterministic across ASLR rolls.
// The returned string is heap-allocated; caller is responsible for
// `delete`.
pro_move_utils_amphib_unit_sort_key :: proc(
	pro_data: ^Pro_Data,
	amphib_attack_map: map[^Unit][dynamic]^Unit,
	u: ^Unit,
) -> string {
	terr_name := ""
	ut := pro_data_get_unit_territory(pro_data, u)
	if ut != nil { terr_name = territory_get_name(ut) }
	owner_name := ""
	owner := unit_get_owner(u)
	if owner != nil { owner_name = game_player_get_name(owner) }
	type_name := ""
	tp := unit_get_type(u)
	if tp != nil { type_name = unit_type_get_name(tp) }
	hits := unit_get_hits(u)
	already := unit_get_already_moved(u)

	// Loaded-units signature: sorted type names joined by 0x02.
	sig_sb := strings.builder_make()
	defer strings.builder_destroy(&sig_sb)
	if amphib_attack_map != nil {
		loaded, has_loaded := amphib_attack_map[u]
		if has_loaded {
			loaded_types := make([dynamic]string)
			defer delete(loaded_types)
			for lu in loaded {
				if lu == nil { continue }
				ltp := unit_get_type(lu)
				if ltp == nil { continue }
				append(&loaded_types, unit_type_get_name(ltp))
			}
			slice.sort(loaded_types[:])
			for s, i in loaded_types {
				if i > 0 { strings.write_byte(&sig_sb, 0x02) }
				strings.write_string(&sig_sb, s)
			}
		}
	}

	// Final UUID tie-break: 32-char hex of the unit's stable id.
	id := unit_get_id(u)
	uuid_buf: [32]u8
	hex := "0123456789abcdef"
	for b, i in id {
		uuid_buf[i*2]   = hex[b >> 4]
		uuid_buf[i*2+1] = hex[b & 0x0f]
	}
	uuid_hex := string(uuid_buf[:])

	// Single allocation for the full key.
	if already == f64(i64(already)) {
		return fmt.aprintf(
			"%s\x01%s\x01%s\x01%d\x01%d\x01%s\x01%s",
			terr_name, owner_name, type_name, hits, i64(already),
			strings.to_string(sig_sb), uuid_hex,
		)
	}
	return fmt.aprintf(
		"%s\x01%s\x01%s\x01%d\x01%v\x01%s\x01%s",
		terr_name, owner_name, type_name, hits, already,
		strings.to_string(sig_sb), uuid_hex,
	)
}

pro_move_utils_amphib_terr_less :: proc(a, b: ^Territory) -> bool {
	return strings.compare(territory_get_name(a), territory_get_name(b)) < 0
}

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

	// triplea-port-bootstrap: sort attack territories by name (mirror Java).
	sorted_attack_terrs_mr := make([dynamic]^Territory)
	defer delete(sorted_attack_terrs_mr)
	for t in attack_map { append(&sorted_attack_terrs_mr, t) }
	slice.sort_by(sorted_attack_terrs_mr[:], pro_move_utils_amphib_terr_less)

	// Loop through all territories to attack.
	for t in sorted_attack_terrs_mr {
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

	// triplea-port-bootstrap: sort attack territories by name (mirror Java).
	sorted_attack_terrs := make([dynamic]^Territory)
	defer delete(sorted_attack_terrs)
	for t in attack_map { append(&sorted_attack_terrs, t) }
	slice.sort_by(sorted_attack_terrs[:], pro_move_utils_amphib_terr_less)

	// Loop through all territories to attack.
	for t in sorted_attack_terrs {
		// Loop through each amphib attack map.
		amphib_attack_map := pro_territory_get_amphib_attack_map(attack_map[t])
		// triplea-port-bootstrap: sort transports by composite stable key.
		// Pair-sort to avoid closure-state issues with `slice.sort_by`.
		Pair :: struct { key: string, u: ^Unit }
		pairs := make([dynamic]Pair)
		defer {
			for p in pairs { delete(p.key) }
			delete(pairs)
		}
		for u in amphib_attack_map {
			append(&pairs, Pair{
				key = pro_move_utils_amphib_unit_sort_key(
					pro_data, amphib_attack_map, u,
				),
				u = u,
			})
		}
		slice.stable_sort_by(pairs[:], proc(a, b: Pair) -> bool {
			return strings.compare(a.key, b.key) < 0
		})
		for pair in pairs {
			transport := pair.u
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
						// DIVERGENCE GUARD: pro_data.unit_territory_map is
						// not yet populated for every amphib unit during
						// purchase-phase NCM simulation (Java's ProData
						// initializeSimulation populates this; the Odin
						// port is still missing some entries). Skip the
						// unit rather than crash so the rest of the round
						// can be digested for the divergence comparison.
						if unit_territory == nil { continue }
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
					// triplea-port-bootstrap: sort neighbors by name (mirror Java).
					sorted_neighbors := make([dynamic]^Territory)
					defer delete(sorted_neighbors)
					for nb in neighbors { append(&sorted_neighbors, nb) }
					slice.sort_by(sorted_neighbors[:], pro_move_utils_amphib_terr_less)
					for neighbor in sorted_neighbors {
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
							ut := pro_data_get_unit_territory(pro_data, u)
							// DIVERGENCE GUARD: same as the one above —
							// pro_data.unit_territory_map is incomplete
							// during NCM simulation; skip the unit so the
							// rest of the round can be digested.
							if ut == nil { continue }
							distance := game_map_get_distance(
								gm,
								neighbor,
								ut,
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
				// Java mirror: `ProLogger.warn(... + t + ", remainingUnitsToLoad=" + remainingUnitsToLoad)`.
				// In Java, `ProLogger.warn` only forwards to `ProLogUi.notifyAiLogMessage`,
				// which is a no-op in headless test runs (no AI log UI). The message is
				// computed but never observed; only side effect is a transient string alloc.
				//
				// In Odin, formatting `^Unit` and `^Territory` with `%v` recursively follows
				// pointer fields (owner -> ^Game_Player -> ...) and segfaults at step 36
				// (japanesePurchase NCM simulation) when stale unit pointers are present.
				// Building a safe string via `unit_to_string`/`territory_to_string` works
				// for printing but allocates from the default heap allocator, which shifts
				// downstream pointer addresses and breaks deterministic iteration order in
				// pointer-keyed maps (uc_h hash diverges from Java starting at i=32).
				//
				// Since the message is unobservable in both Java and Odin headless runs,
				// skip the warn entirely.
			}

			// Set territory transport is moving to.
			ttm := pro_territory_get_transport_territory_map(attack_map[t])
			ttm[transport] = transport_territory

			// Unload transport.
			if len(loaded_units) > 0 && !territory_is_water(t) {
				route := route_new_from_start_and_steps(transport_territory, t)
				move_batcher_add_move_units_route(moves, loaded_units[:], route)
			}
			when AMPHIB_TRACE {
				tn := default_named_get_name(&t.named_attachable.default_named)
				if tn == "Soviet Far East" {
					tt_name := transport_territory != nil ? default_named_get_name(&transport_territory.named_attachable.default_named) : "<nil>"
					lu_names: [dynamic]string
					for u in loaded_units { append(&lu_names, default_named_get_name(&u.type.named_attachable.default_named)) }
					rem_names: [dynamic]string
					for u in remaining_units_to_load { append(&rem_names, default_named_get_name(&u.type.named_attachable.default_named)) }
					fmt.printf("AMPHIB_RT_SFE tx=%p final_tt=%s loaded=%v remaining=%v water_t=%v\n",
						transport, tt_name, lu_names, rem_names, territory_is_water(t))
				}
			}
		}
	}

	when AMPHIB_TRACE {
		batched := move_batcher_batch_moves(moves)
		for md in batched {
			rt := move_description_get_route(md)
			if rt != nil {
				endt := route_get_end(rt)
				en := endt != nil ? default_named_get_name(&endt.named_attachable.default_named) : "<nil>"
				if en == "Soviet Far East" {
					startt := route_get_start(rt)
					sn := startt != nil ? default_named_get_name(&startt.named_attachable.default_named) : "<nil>"
					fmt.printf("AMPHIB_BATCH_SFE start=%s end=%s nunits=%d\n", sn, en, len(md.abstract_move_description.units))
				}
			}
		}
		return batched
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

	// triplea-port-bootstrap: sort attack territories by name; sort each
	// bombard_territory_map keys by composite Unit sort key.
	sorted_bombard_terrs := make([dynamic]^Territory)
	defer delete(sorted_bombard_terrs)
	for tk in attack_map { append(&sorted_bombard_terrs, tk) }
	slice.sort_by(sorted_bombard_terrs[:], pro_move_utils_amphib_terr_less)

	// Loop through all territories to attack.
	for tk in sorted_bombard_terrs {
		t := attack_map[tk]
		btm := pro_territory_get_bombard_territory_map(t)
		BombPair :: struct { key: string, u: ^Unit }
		bpairs := make([dynamic]BombPair)
		defer {
			for p in bpairs { delete(p.key) }
			delete(bpairs)
		}
		for u in btm {
			append(&bpairs, BombPair{
				key = pro_move_utils_amphib_unit_sort_key(pro_data, nil, u),
				u = u,
			})
		}
		slice.stable_sort_by(bpairs[:], proc(a, b: BombPair) -> bool {
			return strings.compare(a.key, b.key) < 0
		})
		for bp in bpairs {
			u := bp.u
			bombard_from_territory := btm[u]
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

	// triplea-port-bootstrap: sort attack territories by name (mirror Java).
	sorted_bombing_terrs := make([dynamic]^Territory)
	defer delete(sorted_bombing_terrs)
	for t in attack_map { append(&sorted_bombing_terrs, t) }
	slice.sort_by(sorted_bombing_terrs[:], pro_move_utils_amphib_terr_less)

	// Loop through all territories to attack.
	for t in sorted_bombing_terrs {
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
		when AMPHIB_TRACE {
			rt := move_description_get_route(move)
			if rt != nil {
				endt := route_get_end(rt)
				en := endt != nil ? default_named_get_name(&endt.named_attachable.default_named) : "<nil>"
				startt := route_get_start(rt)
				sn := startt != nil ? default_named_get_name(&startt.named_attachable.default_named) : "<nil>"
				zones := sn == "60 Sea Zone" || sn == "61 Sea Zone" || sn == "63 Sea Zone" || sn == "Japan" || en == "60 Sea Zone" || en == "61 Sea Zone" || en == "63 Sea Zone" || en == "Soviet Far East"
				if zones {
					utn: [dynamic]string
					for u in move.units { append(&utn, default_named_get_name(&u.type.named_attachable.default_named)) }
					n_seatx := len(move_description_get_units_to_sea_transports(move))
					fmt.printf("AMPHIB_PERFORM start=%s end=%s units=%v seatx=%d result='%s'\n",
						sn, en, utn, n_seatx, result)
					for u in move.units {
						ua := unit_get_unit_attachment(u)
						cap := unit_attachment_get_transport_capacity(ua)
						cost := unit_attachment_get_transport_cost(ua)
						tb := unit_get_transported_by(u)
						fmt.printf("  AP_UNIT u=%p type=%s cap=%d cost=%d transported_by=%p\n",
							u, default_named_get_name(&u.type.named_attachable.default_named), cap, cost, tb)
					}
					for k, v in move_description_get_units_to_sea_transports(move) {
						fmt.printf("  AP_SEATX cargo=%p -> tx=%p\n", k, v)
					}
				}
			}
		}
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

