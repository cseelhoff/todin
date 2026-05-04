package game

Pro_Transport_Utils :: struct {}

// Java: public static Set<Unit> getMovedUnits(
//     final List<Unit> alreadyMovedUnits,
//     final Map<Territory, ProTerritory> attackMap)
//   final Set<Unit> movedUnits = new HashSet<>(alreadyMovedUnits);
//   movedUnits.addAll(attackMap.values().stream()
//       .map(ProTerritory::getAllDefenders)
//       .flatMap(Collection::stream)
//       .collect(Collectors.toList()));
//   return movedUnits;
//
// Java's Set<Unit> maps to Odin's `map[^Unit]struct{}`. The stream
// pipeline flattens every defender of every ProTerritory in the map
// into the result set.
pro_transport_utils_get_moved_units :: proc(
	already_moved_units: [dynamic]^Unit,
	attack_map: map[^Territory]^Pro_Territory,
) -> map[^Unit]struct{} {
	moved_units := make(map[^Unit]struct{})
	for u in already_moved_units {
		moved_units[u] = {}
	}
	for _, pt in attack_map {
		defenders := pro_territory_get_all_defenders(pt)
		for u in defenders {
			moved_units[u] = {}
		}
		delete(defenders)
	}
	return moved_units
}

// Java: private static Comparator<Unit> getDecreasingAttackComparator(
//     final GamePlayer player)
//   return (o1, o2) -> {
//     final Set<UnitSupportAttachment> supportAttachments1 =
//         UnitSupportAttachment.get(o1.getType());
//     int maxSupport1 = 0;
//     for (final UnitSupportAttachment usa : supportAttachments1) {
//       if (usa.getAllied() && usa.getOffence() && usa.getBonus() > maxSupport1) {
//         maxSupport1 = usa.getBonus();
//       }
//     }
//     final int attack1 = o1.getUnitAttachment().getAttack(player) + maxSupport1;
//     ... mirror for o2 ...
//     return attack2 - attack1;
//   };
//
// The lambda captures `player`, so we use the rawptr-ctx closure-capture
// convention (see llm-instructions.md): a heap-allocated ctx struct
// holds the captured `^Game_Player`, and the returned comparator is
// the non-capturing trampoline paired with the ctx pointer. Java's
// `Comparator<Unit>` returning `attack2 - attack1` (decreasing) maps
// to a less-than predicate `attack(a) > attack(b)`.
Pro_Transport_Utils_Decreasing_Attack_Comparator_Ctx :: struct {
	player: ^Game_Player,
}

pro_transport_utils_decreasing_attack_comparator_less :: proc(
	ctx: rawptr,
	o1: ^Unit,
	o2: ^Unit,
) -> bool {
	c := cast(^Pro_Transport_Utils_Decreasing_Attack_Comparator_Ctx)ctx

	support_attachments_1 := unit_support_attachment_get(unit_get_type(o1))
	max_support_1: i32 = 0
	for usa in support_attachments_1 {
		if unit_support_attachment_get_allied(usa) &&
		   unit_support_attachment_get_offence(usa) &&
		   unit_support_attachment_get_bonus(usa) > max_support_1 {
			max_support_1 = unit_support_attachment_get_bonus(usa)
		}
	}
	attack_1 :=
		unit_attachment_get_attack(unit_get_unit_attachment(o1), c.player) + max_support_1

	support_attachments_2 := unit_support_attachment_get(unit_get_type(o2))
	max_support_2: i32 = 0
	for usa in support_attachments_2 {
		if unit_support_attachment_get_allied(usa) &&
		   unit_support_attachment_get_offence(usa) &&
		   unit_support_attachment_get_bonus(usa) > max_support_2 {
			max_support_2 = unit_support_attachment_get_bonus(usa)
		}
	}
	attack_2 :=
		unit_attachment_get_attack(unit_get_unit_attachment(o2), c.player) + max_support_2

	return attack_1 > attack_2
}

pro_transport_utils_get_decreasing_attack_comparator :: proc(
	player: ^Game_Player,
) -> (
	proc(rawptr, ^Unit, ^Unit) -> bool,
	rawptr,
) {
	ctx := new(Pro_Transport_Utils_Decreasing_Attack_Comparator_Ctx)
	ctx.player = player
	return pro_transport_utils_decreasing_attack_comparator_less, rawptr(ctx)
}

// Java: public static List<Unit> getTransports(
//     GamePlayer player,
//     Map<Territory, ProTerritory> moveMap,
//     Collection<Territory> territories)
//   Predicate<Unit> isTransport = ProMatches.unitIsOwnedTransport(player);
//   List<Unit> transports = new ArrayList<>();
//   for (Territory t : territories) {
//     ProTerritory proTerritory = moveMap.get(t);
//     if (proTerritory != null) {
//       transports.addAll(CollectionUtils.getMatches(proTerritory.getAllDefenders(), isTransport));
//     }
//   }
//   return transports;
pro_transport_utils_get_transports :: proc(
player: ^Game_Player,
move_map: map[^Territory]^Pro_Territory,
territories: [dynamic]^Territory,
) -> [dynamic]^Unit {
	is_transport_pred, is_transport_ctx := pro_matches_unit_is_owned_transport(player)
	transports: [dynamic]^Unit
	for t in territories {
		pro_territory, ok := move_map[t]
		if !ok || pro_territory == nil {
			continue
		}
		defenders := pro_territory_get_all_defenders(pro_territory)
		for u in defenders {
			if is_transport_pred(is_transport_ctx, u) {
				append(&transports, u)
			}
		}
		delete(defenders)
	}
	return transports
}

// Java: public static int findUnitsTransportCost(final List<Unit> units)
//   int transportCost = 0;
//   for (final Unit unit : units) {
//     transportCost += unit.getUnitAttachment().getTransportCost();
//   }
//   return transportCost;
pro_transport_utils_find_units_transport_cost :: proc(units: [dynamic]^Unit) -> i32 {
	transport_cost: i32 = 0
	for unit in units {
		transport_cost += unit_attachment_get_transport_cost(unit_get_unit_attachment(unit))
	}
	return transport_cost
}

// Java: u -> u.getUnitAttachment().getTransportCost()
// Comparator key extractor lambda inside `getUnitsToTransportFromTerritories`
// (the 5-arg overload), used by
// `Comparator.<Unit>comparingInt(u -> u.getUnitAttachment().getTransportCost())
//      .thenComparing(getDecreasingAttackComparator(player))`.
pro_transport_utils_lambda_get_units_to_transport_from_territories_0 :: proc(
	u: ^Unit,
) -> i32 {
	return unit_attachment_get_transport_cost(unit_get_unit_attachment(u))
}

// Java: u -> u.getUnitAttachment().getTransportCost()
// Comparator key extractor lambda inside `findBestUnitsToLandTransport`,
// the third sort key passed to `.thenComparingInt(...)` in the
// land-transport-with-capacity branch. Bytecode index 4.
pro_transport_utils_lambda_find_best_units_to_land_transport_4 :: proc(
	u: ^Unit,
) -> i32 {
	return unit_attachment_get_transport_cost(unit_get_unit_attachment(u))
}

// Java: public static List<Unit> selectUnitsToTransportFromList(
//     final Unit transport, final List<Unit> units)
//   Loads as many units as fit; if extra capacity remains, tries to swap the
//   weakest selected unit for a stronger remaining unit (sorted by movement
//   then by decreasing attack for land transports, otherwise by decreasing
//   attack only) provided capacity stays non-negative.
//
// Java mutates `units` (`units.removeAll(selectedUnits)`, `units.sort(...)`).
// We construct a local `remaining` instead so callers' lists are not
// disturbed; the returned selection is identical.
pro_transport_utils_select_units_to_transport_from_list :: proc(
	transport: ^Unit,
	units: [dynamic]^Unit,
) -> [dynamic]^Unit {
	selected_units: [dynamic]^Unit
	capacity := unit_attachment_get_transport_capacity(unit_get_unit_attachment(transport))
	capacity_count: i32 = 0

	// Load as many units as possible
	for unit in units {
		cost := unit_attachment_get_transport_cost(unit_get_unit_attachment(unit))
		if cost <= capacity - capacity_count {
			append(&selected_units, unit)
			capacity_count += cost
			if capacity_count >= capacity {
				break
			}
		}
	}

	// If extra space try to replace last unit with stronger unit
	if len(selected_units) > 0 && capacity_count < capacity {
		last_unit := selected_units[len(selected_units) - 1]
		last_unit_cost := unit_attachment_get_transport_cost(
			unit_get_unit_attachment(last_unit),
		)

		// remaining = units \ selected_units (preserve original order before sort)
		remaining: [dynamic]^Unit
		for u in units {
			in_selected := false
			for s in selected_units {
				if s == u {
					in_selected = true
					break
				}
			}
			if !in_selected {
				append(&remaining, u)
			}
		}

		is_land_transport_pred, is_land_transport_ctx := matches_unit_is_land_transport()
		use_land_transport := is_land_transport_pred(is_land_transport_ctx, transport)

		owner := unit_get_owner(transport)
		decr_attack_pred, decr_attack_ctx :=
			pro_transport_utils_get_decreasing_attack_comparator(owner)

		// Insertion sort `remaining` using the chained comparator.
		for i := 1; i < len(remaining); i += 1 {
			j := i
			for j > 0 &&
			    pro_transport_utils_select_units_less(
				    remaining[j],
				    remaining[j - 1],
				    use_land_transport,
				    decr_attack_pred,
				    decr_attack_ctx,
			    ) {
				tmp := remaining[j]
				remaining[j] = remaining[j - 1]
				remaining[j - 1] = tmp
				j -= 1
			}
		}

		for u in remaining {
			// Java: `if (comparator.compare(unit, lastUnit) >= 0) break;`
			// i.e. break unless `u` is strictly less than `last_unit`.
			if !pro_transport_utils_select_units_less(
				u,
				last_unit,
				use_land_transport,
				decr_attack_pred,
				decr_attack_ctx,
			) {
				break
			}
			cost := unit_attachment_get_transport_cost(unit_get_unit_attachment(u))
			if capacity_count - last_unit_cost + cost <= capacity {
				// Replace last_unit with u
				pop(&selected_units)
				append(&selected_units, u)
				break
			}
		}
		delete(remaining)
		free(decr_attack_ctx)
	}
	return selected_units
}

// Comparator helper used by `pro_transport_utils_select_units_to_transport_from_list`.
// Mirrors Java's
//   Comparator.<Unit>comparingInt(u -> u.getMovementLeft().intValue())
//       .thenComparing(getDecreasingAttackComparator(transport.getOwner()))
// when `use_land == true`, otherwise the decreasing-attack comparator alone.
@(private = "file")
pro_transport_utils_select_units_less :: proc(
	a, b: ^Unit,
	use_land: bool,
	decr_attack: proc(rawptr, ^Unit, ^Unit) -> bool,
	decr_attack_ctx: rawptr,
) -> bool {
	if use_land {
		ma := unit_get_movement_left(a)
		mb := unit_get_movement_left(b)
		if ma != mb {
			return ma < mb
		}
	}
	return decr_attack(decr_attack_ctx, a, b)
}

// Java: public static List<Unit> interleaveUnitsCarriersAndPlanes(
//     final List<Unit> units, final int planesThatDontNeedToLand)
//   Sorts `units` so carriers immediately follow the planes they will carry,
//   minimising losses when casualties are picked left-to-right. Returns the
//   input untouched if no carrier or no carrier-capable plane is present.
//
// The algorithm walks `result` from right to left. Whenever it hits a plane
// (carrierCost > 0) it locates the right-most carrier (skipping ones already
// "filled") and slides it adjacent to the planes it should carry, reordering
// any planes that fell on the wrong side. We keep Java's loop control flow,
// including the `i++` "re-process this unit" trick when the carrier
// overflows.
pro_transport_utils_interleave_units_carriers_and_planes :: proc(
	units: [dynamic]^Unit,
	planes_that_dont_need_to_land: i32,
) -> [dynamic]^Unit {
	is_carrier_pred, is_carrier_ctx := matches_unit_is_carrier()
	can_land_pred, can_land_ctx := matches_unit_can_land_on_carrier()
	any_carrier := false
	any_can_land := false
	for u in units {
		if is_carrier_pred(is_carrier_ctx, u) {
			any_carrier = true
		}
		if can_land_pred(can_land_ctx, u) {
			any_can_land = true
		}
	}
	if !any_carrier || !any_can_land {
		return units
	}

	// Clone the current list
	result: [dynamic]^Unit
	for u in units {
		append(&result, u)
	}

	seeked_carrier: ^Unit = nil
	index_to_place_carrier_at: i32 = -1
	space_left_on_seeked_carrier: i32 = -1
	processed_plane_count: i32 = 0
	filled_carriers: [dynamic]^Unit
	defer delete(filled_carriers)

	// Loop through all units, starting from the right, and rearrange units
	for i := i32(len(result)) - 1; i >= 0; i -= 1 {
		unit := result[i]
		ua := unit_get_unit_attachment(unit)

		if !(unit_attachment_get_carrier_cost(ua) > 0 || i == 0) {
			continue
		}

		// If we haven't ignored enough trailing planes and not last unit
		if processed_plane_count < planes_that_dont_need_to_land && i > 0 {
			processed_plane_count += 1
			continue
		}

		// If this is the first carrier seek and not last unit
		if seeked_carrier == nil && i > 0 {
			seeked_carrier_index: i32 = -1
			for k := i32(len(result)) - 1; k >= 0; k -= 1 {
				ru := result[k]
				if !is_carrier_pred(is_carrier_ctx, ru) {
					continue
				}
				already_filled := false
				for fc in filled_carriers {
					if fc == ru {
						already_filled = true
						break
					}
				}
				if !already_filled {
					seeked_carrier_index = k
					break
				}
			}
			if seeked_carrier_index == -1 {
				break
			}
			seeked_carrier = result[seeked_carrier_index]
			index_to_place_carrier_at = i + 1
			space_left_on_seeked_carrier =
				unit_attachment_get_carrier_capacity(unit_get_unit_attachment(seeked_carrier))
		}
		if unit_attachment_get_carrier_cost(ua) > 0 {
			space_left_on_seeked_carrier -= unit_attachment_get_carrier_cost(ua)
		}

		// If the carrier has been filled or overflowed or last unit
		if index_to_place_carrier_at > 0 &&
		   (space_left_on_seeked_carrier <= 0 || i == 0) {
			if space_left_on_seeked_carrier < 0 {
				// Re-process this unit on next iteration
				i += 1
			}

			// indexOf(seekedCarrier)
			seeked_index: i32 = -1
			for k in 0 ..< i32(len(result)) {
				if result[k] == seeked_carrier {
					seeked_index = k
					break
				}
			}

			if seeked_index < i {
				// Move the carrier up to the planes by: removing carrier, then reinserting it
				ordered_remove(&result, int(seeked_index))
				inject_at(&result, int(index_to_place_carrier_at - 1), seeked_carrier)
				i -= 1
				append(&filled_carriers, seeked_carrier)

				// Find the next carrier (rightmost not-yet-filled)
				seeked_carrier = nil
				for k := i32(len(result)) - 1; k >= 0; k -= 1 {
					ru := result[k]
					if !is_carrier_pred(is_carrier_ctx, ru) {
						continue
					}
					already_filled := false
					for fc in filled_carriers {
						if fc == ru {
							already_filled = true
							break
						}
					}
					if !already_filled {
						seeked_carrier = ru
						break
					}
				}
				if seeked_carrier == nil {
					break
				}

				// Place next carrier right before this plane
				index_to_place_carrier_at = i
				space_left_on_seeked_carrier = unit_attachment_get_carrier_capacity(
					unit_get_unit_attachment(seeked_carrier),
				)
			} else {
				// If it's later in the list
				old_index := seeked_index
				carrier_place_location := index_to_place_carrier_at

				// Place carrier where it's supposed to go
				ordered_remove(&result, int(old_index))
				if old_index < index_to_place_carrier_at {
					carrier_place_location -= 1
				}
				inject_at(&result, int(carrier_place_location), seeked_carrier)
				append(&filled_carriers, seeked_carrier)

				// Move the planes down to the carrier
				planes_between: [dynamic]^Unit
				for i2 := i; i2 < carrier_place_location; i2 += 1 {
					unit2 := result[i2]
					ua2 := unit_get_unit_attachment(unit2)
					if unit_attachment_get_carrier_cost(ua2) > 0 {
						append(&planes_between, unit2)
					}
				}
				// Reverse `planes_between`
				lo := 0
				hi := len(planes_between) - 1
				for lo < hi {
					tmp := planes_between[lo]
					planes_between[lo] = planes_between[hi]
					planes_between[hi] = tmp
					lo += 1
					hi -= 1
				}
				plane_move_count: i32 = 0
				for plane in planes_between {
					// remove plane (find its index)
					for k in 0 ..< i32(len(result)) {
						if result[k] == plane {
							ordered_remove(&result, int(k))
							break
						}
					}
					// Insert each plane right before carrier
					inject_at(&result, int(carrier_place_location - 1), plane)
					plane_move_count += 1
				}
				delete(planes_between)

				// Find the next carrier
				seeked_carrier = nil
				for k := i32(len(result)) - 1; k >= 0; k -= 1 {
					ru := result[k]
					if !is_carrier_pred(is_carrier_ctx, ru) {
						continue
					}
					already_filled := false
					for fc in filled_carriers {
						if fc == ru {
							already_filled = true
							break
						}
					}
					if !already_filled {
						seeked_carrier = ru
						break
					}
				}
				if seeked_carrier == nil {
					break
				}

				index_to_place_carrier_at = carrier_place_location - plane_move_count
				space_left_on_seeked_carrier = unit_attachment_get_carrier_capacity(
					unit_get_unit_attachment(seeked_carrier),
				)
			}
		}
	}
	return result
}


