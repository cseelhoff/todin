package game

import "core:fmt"
import "core:slice"

Casualty_Order_Of_Losses :: struct {}

@(private="file")
casualty_order_of_losses_ool_cache: map[string][dynamic]^Casualty_Order_Of_Losses_Amphib_Type

casualty_order_of_losses_clear_ool_cache :: proc() {
	clear(&casualty_order_of_losses_ool_cache)
}

// Java: CasualtyOrderOfLosses#computeOolCacheKey(Parameters, List<AmphibType>)
//
// Mirrors Java's
//   parameters.player.getName()
//     + "|" + parameters.battlesite.getName()
//     + "|" + parameters.combatValue.getBattleSide()
//     + "|" + Objects.hashCode(targetTypes)
//
// `Combat_Value` is the empty interface stub in odin_flat/, so there is
// no virtual dispatch for `getBattleSide()`. Each `^Combat_Value` instance
// represents exactly one battle side, so its pointer identity is a strict
// refinement of the side enum and yields the same cache-discrimination
// behavior the Java key relies on.
//
// `Objects.hashCode(List)` in Java is the List.hashCode contract:
//     int h = 1; for (T e : list) h = 31*h + Objects.hashCode(e);
// AmphibType is a Lombok @Value, so its hashCode combines its two fields
// (`type` identity hash, `isAmphibious` bool hash) the same way.
casualty_order_of_losses_compute_ool_cache_key :: proc(
	parameters: ^Casualty_Order_Of_Losses_Parameters,
	target_types: [dynamic]^Casualty_Order_Of_Losses_Amphib_Type,
) -> string {
	player_name := default_named_get_name(&parameters.player.named_attachable.default_named)
	battlesite_name := default_named_get_name(&parameters.battlesite.named_attachable.default_named)

	// List.hashCode contract.
	list_hash: i32 = 1
	for amphib in target_types {
		// AmphibType.hashCode (@Value): 31 * (31 + type-hash) + bool-hash,
		// which equals 31 * type-hash + bool-hash + 31 (Lombok's
		// PRIME=59 in newer versions, but the JDK default for List uses 31;
		// we follow List.hashCode here and treat AmphibType.hashCode as
		// `31 * Objects.hashCode(type) + Boolean.hashCode(isAmphibious)`,
		// i.e. an order-stable mix of its fields).
		type_hash: i32
		if amphib != nil {
			type_hash = i32(uintptr(rawptr(amphib.type)) & 0x7fffffff)
			bool_hash: i32 = 1237
			if amphib.is_amphibious {
				bool_hash = 1231
			}
			elem_hash := 31 * type_hash + bool_hash
			list_hash = 31 * list_hash + elem_hash
		} else {
			list_hash = 31 * list_hash
		}
	}

	return fmt.tprintf(
		"%s|%s|%p|%d",
		player_name,
		battlesite_name,
		rawptr(parameters.combat_value),
		list_hash,
	)
}

// Java: CasualtyOrderOfLosses#sortUnitsForCasualtiesWithSupportImpl(Parameters)
//
// Sorts a copy of `parameters.targetsToPickFrom` ascending by combat value
// (after a descending sort + reverse), then iteratively pulls the unit
// whose loss costs the battle the least power — accounting for support
// power and support-rolls that the unit grants to others — into the
// result list. After roughly half of the input has been picked, any
// remaining units are appended in their (ascending) order.
//
// Java's `new UnitBattleComparator(...).reversed()` is realized with a
// file-private comparator slot and a less-than predicate that flips the
// sign. Java's `Map<Unit, IntegerMap<Unit>>` getters return the
// PowerStrengthAndRolls's underlying maps; Odin maps share backing
// storage on assignment, so mutations done through these locals are
// observed by the source struct (matching Java reference semantics).
// Java's `Map.put(supportedUnit, strengthAndRollsWithoutSupport)` reads
// as a value-overwrite in Odin: we deref the new heap-allocated
// `^Unit_Power_Strength_And_Rolls` and store the value back into the
// map.
@(private="file")
casualty_order_of_losses_sort_impl_cmp_: ^Unit_Battle_Comparator

@(private="file")
casualty_order_of_losses_sort_impl_reversed_less_ :: proc(a: ^Unit, b: ^Unit) -> bool {
	// reversed comparator: a < b iff cmp(a, b) > 0.
	return unit_battle_comparator_compare(casualty_order_of_losses_sort_impl_cmp_, a, b) > 0
}

@(private="file")
casualty_order_of_losses_remove_first_match_ :: proc(list: ^[dynamic]^Unit, target: ^Unit) -> bool {
	for j := 0; j < len(list^); j += 1 {
		if list^[j] == target {
			ordered_remove(list, j)
			return true
		}
	}
	return false
}

casualty_order_of_losses_sort_units_for_casualties_with_support_impl :: proc(
	parameters: ^Casualty_Order_Of_Losses_Parameters,
) -> [dynamic]^Unit {
	// Sort enough units to kill off (descending by combat value).
	sorted_units_list := make([dynamic]^Unit, 0, len(parameters.targets_to_pick_from))
	for u in parameters.targets_to_pick_from {
		append(&sorted_units_list, u)
	}

	data := cast(^Game_Data)parameters.data

	cmp1 := unit_battle_comparator_new(
		parameters.costs,
		data,
		combat_value_build_with_no_unit_supports(parameters.combat_value),
		true,
		false,
	)
	casualty_order_of_losses_sort_impl_cmp_ = cmp1
	slice.sort_by(sorted_units_list[:], casualty_order_of_losses_sort_impl_reversed_less_)

	// Sort units starting with the strongest so that support gets added to them first.
	unit_comparator_without_primary_power := unit_battle_comparator_new(
		parameters.costs,
		data,
		combat_value_build_with_no_unit_supports(parameters.combat_value),
		true,
		true,
	)

	unit_power_and_rolls := power_strength_and_rolls_build_with_pre_sorted_units(
		sorted_units_list,
		parameters.combat_value,
	)

	unit_support_power_map := power_strength_and_rolls_get_unit_support_power_map(unit_power_and_rolls)
	unit_support_rolls_map := power_strength_and_rolls_get_unit_support_rolls_map(unit_power_and_rolls)
	unit_power_and_rolls_map := power_strength_and_rolls_get_total_strength_and_total_rolls_by_unit(unit_power_and_rolls)

	// Sort units starting with weakest for finding the worst units.
	slice.reverse(sorted_units_list[:])

	sorted_well_enough_units_list := make([dynamic]^Unit)

	original_unit_power_and_rolls_map := make(map[^Unit]Unit_Power_Strength_And_Rolls)
	for k, v in unit_power_and_rolls_map {
		original_unit_power_and_rolls_map[k] = v
	}

	for i := 0; i < len(sorted_units_list); i += 1 {
		// Loop through all target units to find the best unit to take as casualty.
		worst_unit: ^Unit = nil
		min_power: i32 = max(i32)
		unit_types := make(map[^Unit_Type]struct{})
		for u in sorted_units_list {
			ut := unit_get_type(u)
			if ut in unit_types {
				continue
			}
			unit_types[ut] = {}
			// Find unit power.
			orig_entry := original_unit_power_and_rolls_map[u]
			power := unit_power_strength_and_rolls_get_power(&orig_entry)
			// Add any support power that it provides to other units.
			if u in unit_support_power_map {
				support_power_for_unit := unit_support_power_map[u]
				keys := integer_map_key_set(&support_power_for_unit)
				for sk in keys {
					supported_unit := cast(^Unit)sk
					strength_and_rolls, ok := unit_power_and_rolls_map[supported_unit]
					if !ok {
						continue
					}
					// Remove any rolls provided by this support, so they aren't counted twice.
					if u in unit_support_rolls_map {
						support_rolls_for_unit := unit_support_rolls_map[u]
						rolls := integer_map_get_int(&support_rolls_for_unit, rawptr(supported_unit))
						adjusted := unit_power_strength_and_rolls_subtract_rolls(&strength_and_rolls, rolls)
						strength_and_rolls = adjusted^
					}
					// If one roll then just add the power.
					if unit_power_strength_and_rolls_get_rolls(&strength_and_rolls) == 1 {
						power += integer_map_get_int(&support_power_for_unit, rawptr(supported_unit))
						continue
					}
					// Find supported unit power with support.
					power_with_support := unit_power_strength_and_rolls_get_power(&strength_and_rolls)
					// Find supported unit power without support.
					strength := integer_map_get_int(&support_power_for_unit, rawptr(supported_unit))
					adjusted_no_support := unit_power_strength_and_rolls_subtract_strength(
						&strength_and_rolls,
						strength,
					)
					power_without_support := unit_power_strength_and_rolls_get_power(adjusted_no_support)
					// Add the actual power provided by the support.
					added_power := power_with_support - power_without_support
					power += added_power
				}
				delete(keys)
			}
			// Add any power from support rolls that it provides to other units.
			if u in unit_support_rolls_map {
				support_rolls_for_unit := unit_support_rolls_map[u]
				keys := integer_map_key_set(&support_rolls_for_unit)
				for sk in keys {
					supported_unit := cast(^Unit)sk
					strength_and_rolls, ok := unit_power_and_rolls_map[supported_unit]
					if !ok {
						continue
					}
					// Find supported unit power with support.
					power_with_support := unit_power_strength_and_rolls_get_power(&strength_and_rolls)
					// Find supported unit power without support.
					rolls := integer_map_get_int(&support_rolls_for_unit, rawptr(supported_unit))
					adjusted_no_support := unit_power_strength_and_rolls_subtract_rolls(
						&strength_and_rolls,
						rolls,
					)
					power_without_support := unit_power_strength_and_rolls_get_power(adjusted_no_support)
					// Add the actual power provided by the support.
					added_power := power_with_support - power_without_support
					power += added_power
				}
				delete(keys)
			}
			// Check if unit has lower power.
			if power < min_power ||
			   (power == min_power &&
					   unit_battle_comparator_compare(unit_comparator_without_primary_power, u, worst_unit) < 0) {
				worst_unit = u
				min_power = power
			}
		}
		delete(unit_types)

		// Add the worst unit to sorted list, update any units it supported, and remove from
		// other collections.
		if worst_unit in unit_support_power_map {
			support_power_for_unit := unit_support_power_map[worst_unit]
			keys := integer_map_key_set(&support_power_for_unit)
			for sk in keys {
				supported_unit := cast(^Unit)sk
				strength_and_rolls, ok := unit_power_and_rolls_map[supported_unit]
				if !ok {
					continue
				}
				strength := integer_map_get_int(&support_power_for_unit, rawptr(supported_unit))
				without_support := unit_power_strength_and_rolls_subtract_strength(
					&strength_and_rolls,
					strength,
				)
				unit_power_and_rolls_map[supported_unit] = without_support^
				casualty_order_of_losses_remove_first_match_(&sorted_units_list, supported_unit)
				inject_at(&sorted_units_list, 0, supported_unit)
			}
			delete(keys)
		}
		if worst_unit in unit_support_rolls_map {
			support_rolls_for_unit := unit_support_rolls_map[worst_unit]
			keys := integer_map_key_set(&support_rolls_for_unit)
			for sk in keys {
				supported_unit := cast(^Unit)sk
				strength_and_rolls, ok := unit_power_and_rolls_map[supported_unit]
				if !ok {
					continue
				}
				rolls := integer_map_get_int(&support_rolls_for_unit, rawptr(supported_unit))
				without_support := unit_power_strength_and_rolls_subtract_rolls(
					&strength_and_rolls,
					rolls,
				)
				unit_power_and_rolls_map[supported_unit] = without_support^
				casualty_order_of_losses_remove_first_match_(&sorted_units_list, supported_unit)
				inject_at(&sorted_units_list, 0, supported_unit)
			}
			delete(keys)
		}
		append(&sorted_well_enough_units_list, worst_unit)
		casualty_order_of_losses_remove_first_match_(&sorted_units_list, worst_unit)
		delete_key(&unit_power_and_rolls_map, worst_unit)
		delete_key(&unit_support_power_map, worst_unit)
		delete_key(&unit_support_rolls_map, worst_unit)
	}
	for u in sorted_units_list {
		append(&sorted_well_enough_units_list, u)
	}
	return sorted_well_enough_units_list
}

// Java: CasualtyOrderOfLosses#sortUnitsForCasualtiesWithSupport(Parameters)
//
// Returns the perfect casualty-pick order for `parameters.targetsToPickFrom`,
// using the OOL cache when possible. The cache key is a string derived
// from the player, battlesite, combat side, and the (ordered) list of
// AmphibTypes for the targets. On a miss we delegate to the impl proc,
// then store the result and every prefix-shrinking subset under the
// matching key (as Java does), so future calls with smaller target lists
// hit the cache.
casualty_order_of_losses_sort_units_for_casualties_with_support :: proc(
	parameters: ^Casualty_Order_Of_Losses_Parameters,
) -> [dynamic]^Unit {
	// Convert unit lists to unit type lists.
	target_types := make([dynamic]^Casualty_Order_Of_Losses_Amphib_Type, 0, len(parameters.targets_to_pick_from))
	for u in parameters.targets_to_pick_from {
		append(&target_types, casualty_order_of_losses_amphib_type_of(u))
	}

	// Calculate hashes and cache key.
	key := casualty_order_of_losses_compute_ool_cache_key(parameters, target_types)

	// Check OOL cache.
	if stored, ok := casualty_order_of_losses_ool_cache[key]; ok {
		result := make([dynamic]^Unit)
		select_from := make([dynamic]^Unit, 0, len(parameters.targets_to_pick_from))
		for u in parameters.targets_to_pick_from {
			append(&select_from, u)
		}
		for amphib_type in stored {
			j := 0
			for j < len(select_from) {
				unit := select_from[j]
				if casualty_order_of_losses_amphib_type_matches(amphib_type, unit) {
					append(&result, unit)
					ordered_remove(&select_from, j)
				} else {
					j += 1
				}
			}
		}
		delete(select_from)
		delete(target_types)
		return result
	}

	sorted_well_enough_units_list := casualty_order_of_losses_sort_units_for_casualties_with_support_impl(parameters)

	// Cache result and all subsets of the result.
	unit_types := make([dynamic]^Casualty_Order_Of_Losses_Amphib_Type, 0, len(sorted_well_enough_units_list))
	for u in sorted_well_enough_units_list {
		append(&unit_types, casualty_order_of_losses_amphib_type_of(u))
	}
	cur_key := key
	for len(unit_types) > 0 {
		// Cache the current snapshot of unit_types under cur_key.
		snapshot := make([dynamic]^Casualty_Order_Of_Losses_Amphib_Type, 0, len(unit_types))
		for t in unit_types {
			append(&snapshot, t)
		}
		casualty_order_of_losses_ool_cache[cur_key] = snapshot

		// Java: it.next() then targetTypes.remove(unitTypeToRemove); it.remove();
		unit_type_to_remove := unit_types[0]
		ordered_remove(&unit_types, 0)
		// Remove first matching element from target_types. Java's
		// List.remove(Object) uses .equals(); AmphibType is @Value so it
		// compares by (type, isAmphibious).
		for j := 0; j < len(target_types); j += 1 {
			t := target_types[j]
			if t.type == unit_type_to_remove.type &&
			   t.is_amphibious == unit_type_to_remove.is_amphibious {
				ordered_remove(&target_types, j)
				break
			}
		}
		cur_key = casualty_order_of_losses_compute_ool_cache_key(parameters, target_types)
	}
	delete(unit_types)
	delete(target_types)

	return sorted_well_enough_units_list
}
