package game

import "core:slice"

Pro_Sort_Move_Options_Utils :: struct {}

// Java owners covered by this file:
//   - games.strategy.triplea.ai.pro.util.ProSortMoveOptionsUtils

// Java: private static Collection<Territory> removeWinningTerritories(
//           Collection<Territory> territories, GamePlayer player,
//           Map<Territory, ProTerritory> attackMap, ProOddsCalculator calc)
//   territories.stream().filter(t -> {
//     ProTerritory patd = attackMap.get(t);
//     if (patd.getBattleResult() == null) patd.estimateBattleResult(calc, player);
//     return !patd.isCurrentlyWins();
//   }).collect(Collectors.toList());
pro_sort_move_options_utils_remove_winning_territories :: proc(
	territories: map[^Territory]struct {},
	player: ^Game_Player,
	attack_map: map[^Territory]^Pro_Territory,
	calc: ^Pro_Odds_Calculator,
) -> [dynamic]^Territory {
	result: [dynamic]^Territory
	for t, _ in territories {
		patd := attack_map[t]
		if pro_territory_get_battle_result(patd) == nil {
			pro_territory_estimate_battle_result(patd, calc, player)
		}
		if !pro_territory_is_currently_wins(patd) {
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
