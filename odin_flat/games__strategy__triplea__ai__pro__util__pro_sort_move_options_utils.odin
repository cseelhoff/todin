package game

import "core:slice"
import "core:strings"

Pro_Sort_Move_Options_Utils :: struct {}

// Java owners covered by this file:
//   - games.strategy.triplea.ai.pro.util.ProSortMoveOptionsUtils

// Java lambda$removeWinningTerritories$5 captures (attackMap, calc, player)
// from the enclosing removeWinningTerritories method. Predicate<Territory>
// test body: estimate the pending battle if not yet computed, then accept
// only the territories where the attacker is not currently winning.
@(private = "file")
Pro_Sort_Move_Options_Utils_Remove_Winning_Territories_Ctx :: struct {
	player:     ^Game_Player,
	attack_map: map[^Territory]^Pro_Territory,
	calc:       ^Pro_Odds_Calculator,
}

@(private = "file")
pro_sort_move_options_utils_lambda_remove_winning_territories_5 :: proc(
	ctx: rawptr,
	t: ^Territory,
) -> bool {
	c := cast(^Pro_Sort_Move_Options_Utils_Remove_Winning_Territories_Ctx)ctx
	patd := c.attack_map[t]
	if pro_territory_get_battle_result(patd) == nil {
		pro_territory_estimate_battle_result(patd, c.calc, c.player)
	}
	return !pro_territory_is_currently_wins(patd)
}

// Java: private static Collection<Territory> removeWinningTerritories(
//           Collection<Territory> territories, GamePlayer player,
//           Map<Territory, ProTerritory> attackMap, ProOddsCalculator calc)
//   territories.stream().filter(t -> { ... }).collect(Collectors.toList());
pro_sort_move_options_utils_remove_winning_territories :: proc(
	territories: map[^Territory]struct {},
	player: ^Game_Player,
	attack_map: map[^Territory]^Pro_Territory,
	calc: ^Pro_Odds_Calculator,
) -> [dynamic]^Territory {
	ctx := Pro_Sort_Move_Options_Utils_Remove_Winning_Territories_Ctx {
		player     = player,
		attack_map = attack_map,
		calc       = calc,
	}
	result: [dynamic]^Territory
	for t, _ in territories {
		if pro_sort_move_options_utils_lambda_remove_winning_territories_5(&ctx, t) {
			append(&result, t)
		}
	}
	return result
}

// Sort key bundle used by both `sortUnitMoveOptions` and
// `sortUnitNeededOptions`. Java's lambda comparators capture `proData`; Odin
// `proc` literals are non-capturing, so we precompute the comparison keys
// for each entry and sort the resulting slice lexicographically.
@(private = "file")
Pro_Sort_Move_Options_Entry :: struct {
	unit:        ^Unit,
	territories: map[^Territory]struct {},
	move_count:  int,
	unit_value:  i32,
	type_name:   string,
}

@(private = "file")
pro_sort_move_options_entry_less :: proc(a, b: Pro_Sort_Move_Options_Entry) -> bool {
	if a.move_count != b.move_count {
		return a.move_count < b.move_count
	}
	if a.unit_value != b.unit_value {
		return a.unit_value < b.unit_value
	}
	return a.type_name < b.type_name
}

// Java: public static Map<Unit, Set<Territory>> sortUnitMoveOptions(
//           ProData proData, Map<Unit, Set<Territory>> unitAttackOptions)
// Sort by number of move options, then unit cost, then unit type name.
pro_sort_move_options_utils_sort_unit_move_options :: proc(
	pro_data: ^Pro_Data,
	unit_attack_options: map[^Unit]map[^Territory]struct {},
) -> map[^Unit]map[^Territory]struct {} {
	list: [dynamic]Pro_Sort_Move_Options_Entry
	for u, ts in unit_attack_options {
		ut := unit_get_type(u)
		append(
			&list,
			Pro_Sort_Move_Options_Entry{
				unit = u,
				territories = ts,
				move_count = len(ts),
				unit_value = pro_data_get_unit_value(pro_data, ut),
				type_name = default_named_get_name(&ut.named_attachable.default_named),
			},
		)
	}
	slice.sort_by(list[:], pro_sort_move_options_entry_less)
	sorted: map[^Unit]map[^Territory]struct {}
	for e in list {
		sorted[e.unit] = e.territories
	}
	return sorted
}

// Java: public static Map<Unit, Set<Territory>> sortUnitNeededOptions(
//           ProData proData, GamePlayer player,
//           Map<Unit, Set<Territory>> unitAttackOptions,
//           Map<Territory, ProTerritory> attackMap, ProOddsCalculator calc)
// Same sort keys as `sortUnitMoveOptions` except the move-option count is
// the number of territories that still need additional attackers (i.e. the
// pending battles ProOddsCalculator reports as not currently winning).
pro_sort_move_options_utils_sort_unit_needed_options :: proc(
	pro_data: ^Pro_Data,
	player: ^Game_Player,
	unit_attack_options: map[^Unit]map[^Territory]struct {},
	attack_map: map[^Territory]^Pro_Territory,
	calc: ^Pro_Odds_Calculator,
) -> map[^Unit]map[^Territory]struct {} {
	list: [dynamic]Pro_Sort_Move_Options_Entry
	for u, ts in unit_attack_options {
		filtered := pro_sort_move_options_utils_remove_winning_territories(
			ts,
			player,
			attack_map,
			calc,
		)
		ut := unit_get_type(u)
		append(
			&list,
			Pro_Sort_Move_Options_Entry{
				unit = u,
				territories = ts,
				move_count = len(filtered),
				unit_value = pro_data_get_unit_value(pro_data, ut),
				type_name = default_named_get_name(&ut.named_attachable.default_named),
			},
		)
	}
	slice.sort_by(list[:], pro_sort_move_options_entry_less)
	sorted: map[^Unit]map[^Territory]struct {}
	for e in list {
		sorted[e.unit] = e.territories
	}
	return sorted
}

// Sort key bundle for sortUnitNeededOptionsThenAttack. Java's lambda
// captures `proData`, `attackMap`, the per-entry filtered territory list,
// and a HashMap-based attack-efficiency cache. Odin `proc` literals are
// non-capturing, so we precompute every comparison key (move count,
// attack efficiency, type name, total air-distance from the unit's home
// territory across the filtered targets) per entry up front and sort the
// resulting slice lexicographically. The Java tiebreak order — move-count
// asc, attack-efficiency desc, then (only when both units share a type
// and that type is air) total-distance asc, then unit-type name asc —
// collapses to the lex order
// (move_count, -attack_efficiency, type_name, total_distance) because
// the air-distance branch only fires when the type names compare equal,
// at which point distance is the next tiebreak.
@(private = "file")
Pro_Sort_Move_Options_Then_Attack_Entry :: struct {
	unit:              ^Unit,
	territories:       map[^Territory]struct {},
	move_count:        int,
	attack_efficiency: f64,
	type_name:         string,
	total_distance:    i32,
}

@(private = "file")
pro_sort_move_options_then_attack_entry_less :: proc(
	a, b: Pro_Sort_Move_Options_Then_Attack_Entry,
) -> bool {
	if a.move_count != b.move_count {
		return a.move_count < b.move_count
	}
	if a.move_count == 0 {
		return false
	}
	if a.attack_efficiency != b.attack_efficiency {
		return a.attack_efficiency > b.attack_efficiency
	}
	if a.type_name != b.type_name {
		return a.type_name < b.type_name
	}
	return a.total_distance < b.total_distance
}

// Java: public static Map<Unit, Set<Territory>> sortUnitNeededOptionsThenAttack(
//           ProData proData, GamePlayer player,
//           Map<Unit, Set<Territory>> unitAttackOptions,
//           Map<Territory, ProTerritory> attackMap, ProOddsCalculator calc)
// Sort by number of territories that still need additional units (asc),
// then by attack efficiency (desc), then — if both candidate units share
// an air unit type — by total movement distance from the unit's home
// territory across the filtered targets (asc), then by unit type name
// (asc). Attack efficiency is the unit's marginal offensive power divided
// by its proData value, with a ×10 multiplier for air units (mirroring
// the Java method's bonus for air mobility).
pro_sort_move_options_utils_sort_unit_needed_options_then_attack :: proc(
	pro_data: ^Pro_Data,
	player: ^Game_Player,
	unit_attack_options: map[^Unit]map[^Territory]struct {},
	attack_map: map[^Territory]^Pro_Territory,
	calc: ^Pro_Odds_Calculator,
) -> map[^Unit]map[^Territory]struct {} {
	data := pro_data_get_data(pro_data)
	unit_territory_map := pro_data_get_unit_territory_map(pro_data)
	air_pred, air_ctx := pro_matches_territory_can_move_air_units_and_no_aa(data, player, true)

	list: [dynamic]Pro_Sort_Move_Options_Then_Attack_Entry
	for u, ts in unit_attack_options {
		filtered := pro_sort_move_options_utils_remove_winning_territories(
			ts,
			player,
			attack_map,
			calc,
		)
		ut := unit_get_type(u)
		entry := Pro_Sort_Move_Options_Then_Attack_Entry {
			unit        = u,
			territories = ts,
			move_count  = len(filtered),
			type_name   = default_named_get_name(&ut.named_attachable.default_named),
		}
		if entry.move_count > 0 {
			entry.attack_efficiency = pro_sort_move_options_utils_calculate_attack_efficiency(
				pro_data,
				player,
				attack_map,
				filtered,
				u,
			)
			if unit_attachment_is_air(unit_get_unit_attachment(u)) {
				home := unit_territory_map[u]
				total: i32 = 0
				for t in filtered {
					total += game_map_get_distance_predicate(
						game_data_get_map(data),
						home,
						t,
						air_pred,
						air_ctx,
					)
				}
				entry.total_distance = total
			}
		}
		append(&list, entry)
	}
	slice.sort_by(list[:], pro_sort_move_options_then_attack_entry_less)
	sorted: map[^Unit]map[^Territory]struct {}
	for e in list {
		sorted[e.unit] = e.territories
	}
	return sorted
}

// Java: private static double calculateAttackEfficiency(
//           ProData proData, GamePlayer player,
//           Map<Territory, ProTerritory> attackMap,
//           Collection<Territory> territories, Unit unit)
// For each candidate target, build the offensive PowerStrengthAndRolls
// twice — once with `unit` excluded, once included — and accumulate the
// difference. The minimum per-target power difference (×10 when the unit
// is air) divided by the unit's proData value yields the attack
// efficiency. Returns 0.0 when the unit value is 0 to avoid the
// Preconditions.checkState(Double.isFinite(...)) divide-by-zero.
@(private = "file")
pro_sort_move_options_utils_calculate_attack_efficiency :: proc(
	pro_data: ^Pro_Data,
	player: ^Game_Player,
	attack_map: map[^Territory]^Pro_Territory,
	territories: [dynamic]^Territory,
	unit: ^Unit,
) -> f64 {
	data := pro_data_get_data(pro_data)
	min_power: i32 = max(i32)
	enemy_pred, enemy_ctx := matches_enemy_unit(player)
	for t in territories {
		defending_units: [dynamic]^Unit
		for u in unit_collection_get_units(territory_get_unit_collection(t)) {
			if enemy_pred(enemy_ctx, u) {
				append(&defending_units, u)
			}
		}
		attacking_units: [dynamic]^Unit
		for u in pro_territory_get_units(attack_map[t]) {
			append(&attacking_units, u)
		}
		power_difference: i32 = 0
		for include_unit in [2]bool{false, true} {
			if include_unit {
				append(&attacking_units, unit)
			}
			cv := combat_value_builder_main_builder_build(
				combat_value_builder_main_builder_territory_effects(
					combat_value_builder_main_builder_game_dice_sides(
						combat_value_builder_main_builder_lhtr_heavy_bombers(
							combat_value_builder_main_builder_support_attachments(
								combat_value_builder_main_builder_game_sequence(
									combat_value_builder_main_builder_side(
										combat_value_builder_main_builder_friendly_units(
											combat_value_builder_main_builder_enemy_units(
												combat_value_builder_main_combat_value(),
												defending_units,
											),
											attacking_units,
										),
										Battle_State_Side.OFFENSE,
									),
									game_data_get_sequence(data),
								),
								unit_type_list_get_support_rules(
									game_data_get_unit_type_list(data),
								),
							),
							properties_get_lhtr_heavy_bombers(game_data_get_properties(data)),
						),
						int(game_data_get_dice_sides(data)),
					),
					territory_effect_helper_get_effects(t),
				),
			)
			psar := power_strength_and_rolls_build(attacking_units, cv)
			sign: i32 = -1
			if include_unit {
				sign = 1
			}
			power_difference += sign * power_strength_and_rolls_calculate_total_power(psar)
		}
		if power_difference < min_power {
			min_power = power_difference
		}
	}
	if unit_attachment_is_air(unit_get_unit_attachment(unit)) {
		min_power *= 10
	}
	unit_value := f64(pro_data_get_unit_value(pro_data, unit_get_type(unit)))
	if unit_value == 0.0 {
		return 0.0
	}
	return f64(min_power) / unit_value
}

// Map.Entry<Unit, Set<Territory>> stand-in for the comparator lambdas.
// `Map_Entry` is not defined elsewhere in the package; the two lambdas
// below are the only callers, so we use a small file-local struct that
// matches what `o1.getKey()` / `o1.getValue()` produced in the Java
// source.
@(private = "file")
Pro_Sort_Move_Options_Map_Entry :: struct {
	key:   ^Unit,
	value: map[^Territory]struct {},
}

// Java: lambda$sortUnitMoveOptions$0(ProData proData,
//           Map.Entry<Unit, Set<Territory>> o1,
//           Map.Entry<Unit, Set<Territory>> o2) -> int
//   if (o1.getValue().size() != o2.getValue().size())
//     return o1.getValue().size() - o2.getValue().size();
//   else if (proData.getUnitValue(o1.getKey().getType())
//            != proData.getUnitValue(o2.getKey().getType()))
//     return proData.getUnitValue(o1.getKey().getType())
//          - proData.getUnitValue(o2.getKey().getType());
//   return o1.getKey().getType().getName()
//            .compareTo(o2.getKey().getType().getName());
pro_sort_move_options_utils_lambda_sort_unit_move_options_0 :: proc(
	pro_data: ^Pro_Data,
	o1: Pro_Sort_Move_Options_Map_Entry,
	o2: Pro_Sort_Move_Options_Map_Entry,
) -> int {
	size1 := len(o1.value)
	size2 := len(o2.value)
	if size1 != size2 {
		return size1 - size2
	}
	v1 := pro_data_get_unit_value(pro_data, unit_get_type(o1.key))
	v2 := pro_data_get_unit_value(pro_data, unit_get_type(o2.key))
	if v1 != v2 {
		return int(v1 - v2)
	}
	n1 := default_named_get_name(&unit_get_type(o1.key).named_attachable.default_named)
	n2 := default_named_get_name(&unit_get_type(o2.key).named_attachable.default_named)
	return strings.compare(n1, n2)
}

// Java: lambda$sortUnitNeededOptions$1(GamePlayer player,
//           Map<Territory, ProTerritory> attackMap,
//           ProOddsCalculator calc, ProData proData,
//           Map.Entry<Unit, Set<Territory>> o1,
//           Map.Entry<Unit, Set<Territory>> o2) -> int
//   territories1 = removeWinningTerritories(o1.getValue(), player, attackMap, calc);
//   territories2 = removeWinningTerritories(o2.getValue(), player, attackMap, calc);
//   if (territories1.size() != territories2.size())
//     return territories1.size() - territories2.size();
//   UnitType unitType1 = o1.getKey().getType();
//   UnitType unitType2 = o2.getKey().getType();
//   int value1 = proData.getUnitValue(unitType1);
//   int value2 = proData.getUnitValue(unitType2);
//   if (value1 != value2) return value1 - value2;
//   return unitType1.getName().compareTo(unitType2.getName());
pro_sort_move_options_utils_lambda_sort_unit_needed_options_1 :: proc(
	player: ^Game_Player,
	attack_map: map[^Territory]^Pro_Territory,
	calc: ^Pro_Odds_Calculator,
	pro_data: ^Pro_Data,
	o1: Pro_Sort_Move_Options_Map_Entry,
	o2: Pro_Sort_Move_Options_Map_Entry,
) -> int {
	territories1 := pro_sort_move_options_utils_remove_winning_territories(
		o1.value,
		player,
		attack_map,
		calc,
	)
	territories2 := pro_sort_move_options_utils_remove_winning_territories(
		o2.value,
		player,
		attack_map,
		calc,
	)
	size1 := len(territories1)
	size2 := len(territories2)
	if size1 != size2 {
		return size1 - size2
	}
	unit_type1 := unit_get_type(o1.key)
	unit_type2 := unit_get_type(o2.key)
	value1 := pro_data_get_unit_value(pro_data, unit_type1)
	value2 := pro_data_get_unit_value(pro_data, unit_type2)
	if value1 != value2 {
		return int(value1 - value2)
	}
	n1 := default_named_get_name(&unit_type1.named_attachable.default_named)
	n2 := default_named_get_name(&unit_type2.named_attachable.default_named)
	return strings.compare(n1, n2)
}

// Java: lambda$sortUnitNeededOptionsThenAttack$4(GamePlayer player,
//           Map<Territory, ProTerritory> attackMap,
//           ProOddsCalculator calc,
//           Map<Object, Double> attackEfficiencyCache,
//           ProData proData, GameState data,
//           Map<Unit, Territory> unitTerritoryMap,
//           Map.Entry<Unit, Set<Territory>> o1,
//           Map.Entry<Unit, Set<Territory>> o2) -> int
// Comparator body of sortUnitNeededOptionsThenAttack: order by need
// count asc, then attack efficiency desc (cached per entry via
// computeIfAbsent), then — when both unit types are equal and air —
// by total air distance from the unit's home territory across the
// filtered targets asc, then by unit type name asc. The cache is keyed
// on the entry's unit pointer (the entry identity used by Java's
// HashMap<Object,Double> in the source).
pro_sort_move_options_utils_lambda_sort_unit_needed_options_then_attack_4 :: proc(
	player: ^Game_Player,
	attack_map: map[^Territory]^Pro_Territory,
	calc: ^Pro_Odds_Calculator,
	attack_efficiency_cache: ^map[^Unit]f64,
	pro_data: ^Pro_Data,
	data: ^Game_Data,
	unit_territory_map: map[^Unit]^Territory,
	o1: Pro_Sort_Move_Options_Map_Entry,
	o2: Pro_Sort_Move_Options_Map_Entry,
) -> int {
	territories1 := pro_sort_move_options_utils_remove_winning_territories(
		o1.value,
		player,
		attack_map,
		calc,
	)
	territories2 := pro_sort_move_options_utils_remove_winning_territories(
		o2.value,
		player,
		attack_map,
		calc,
	)

	if len(territories1) != len(territories2) {
		return len(territories1) - len(territories2)
	}
	if len(territories1) == 0 {
		return 0
	}

	u1 := o1.key
	u2 := o2.key

	ae1, ok1 := attack_efficiency_cache[u1]
	if !ok1 {
		ae1 = pro_sort_move_options_utils_calculate_attack_efficiency(
			pro_data,
			player,
			attack_map,
			territories1,
			u1,
		)
		attack_efficiency_cache[u1] = ae1
	}
	ae2, ok2 := attack_efficiency_cache[u2]
	if !ok2 {
		ae2 = pro_sort_move_options_utils_calculate_attack_efficiency(
			pro_data,
			player,
			attack_map,
			territories2,
			u2,
		)
		attack_efficiency_cache[u2] = ae2
	}
	if ae1 != ae2 {
		if ae1 < ae2 {
			return 1
		}
		return -1
	}

	unit_type1 := unit_get_type(u1)
	unit_type2 := unit_get_type(u2)

	if unit_type1 == unit_type2 && unit_attachment_is_air(unit_type_get_unit_attachment(unit_type1)) {
		air_pred, air_ctx := pro_matches_territory_can_move_air_units_and_no_aa(data, player, true)
		territory1 := unit_territory_map[u1]
		territory2 := unit_territory_map[u2]
		distance1: i32 = 0
		for t in territories1 {
			distance1 += game_map_get_distance_predicate(
				game_data_get_map(data),
				territory1,
				t,
				air_pred,
				air_ctx,
			)
		}
		distance2: i32 = 0
		for t in territories2 {
			distance2 += game_map_get_distance_predicate(
				game_data_get_map(data),
				territory2,
				t,
				air_pred,
				air_ctx,
			)
		}
		if distance1 != distance2 {
			return int(distance1 - distance2)
		}
	}

	n1 := default_named_get_name(&unit_type1.named_attachable.default_named)
	n2 := default_named_get_name(&unit_type2.named_attachable.default_named)
	return strings.compare(n1, n2)
}

// Java: lambda$sortUnitNeededOptionsThenAttack$2(ProData proData,
//           GamePlayer player, Map<Territory, ProTerritory> attackMap,
//           Collection<Territory> territories1, Unit u1, Object k) -> Double
//   return calculateAttackEfficiency(proData, player, attackMap, territories1, u1);
// `computeIfAbsent` mapping function for the o1 cache lookup; the
// `Object k` parameter is the HashMap key (the Map.Entry) and is
// unused in the body.
pro_sort_move_options_utils_lambda_sort_unit_needed_options_then_attack_2 :: proc(
	pro_data: ^Pro_Data,
	player: ^Game_Player,
	attack_map: map[^Territory]^Pro_Territory,
	territories1: [dynamic]^Territory,
	u1: ^Unit,
	k: rawptr,
) -> f64 {
	_ = k
	return pro_sort_move_options_utils_calculate_attack_efficiency(
		pro_data,
		player,
		attack_map,
		territories1,
		u1,
	)
}

// Java: lambda$sortUnitNeededOptionsThenAttack$3(ProData proData,
//           GamePlayer player, Map<Territory, ProTerritory> attackMap,
//           Collection<Territory> territories2, Unit u2, Object k) -> Double
//   return calculateAttackEfficiency(proData, player, attackMap, territories2, u2);
// `computeIfAbsent` mapping function for the o2 cache lookup; same
// body as lambda$2 but emitted as a separate synthetic by javac because
// it occurs at a distinct call site.
pro_sort_move_options_utils_lambda_sort_unit_needed_options_then_attack_3 :: proc(
	pro_data: ^Pro_Data,
	player: ^Game_Player,
	attack_map: map[^Territory]^Pro_Territory,
	territories2: [dynamic]^Territory,
	u2: ^Unit,
	k: rawptr,
) -> f64 {
	_ = k
	return pro_sort_move_options_utils_calculate_attack_efficiency(
		pro_data,
		player,
		attack_map,
		territories2,
		u2,
	)
}
