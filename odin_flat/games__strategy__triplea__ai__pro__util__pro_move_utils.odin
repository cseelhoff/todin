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

