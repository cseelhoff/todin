package game

Tuv_Utils :: struct {}

// Java: lambda$getResourceCostsForTuv$0(GamePlayer)
// Source: result.computeIfAbsent(p, k -> new LinkedHashMap<>())
tuv_utils_lambda_get_resource_costs_for_tuv_0 :: proc(k: ^Game_Player) -> map[^Unit_Type]^Resource_Collection {
	return make(map[^Unit_Type]^Resource_Collection)
}

// Java: lambda$getResourceCostsForTuvForAllPlayersMergedAndAveraged$1(UnitType)
// Source: backups.computeIfAbsent(ut, k -> new ArrayList<>()) (totalProduced == 1 branch)
tuv_utils_lambda_get_resource_costs_for_tuv_for_all_players_merged_and_averaged_1 :: proc(k: ^Unit_Type) -> [dynamic]^Resource_Collection {
	return make([dynamic]^Resource_Collection)
}

// Java: lambda$getResourceCostsForTuvForAllPlayersMergedAndAveraged$2(UnitType)
// Source: backups.computeIfAbsent(ut, k -> new ArrayList<>()) (totalProduced > 1 branch)
tuv_utils_lambda_get_resource_costs_for_tuv_for_all_players_merged_and_averaged_2 :: proc(k: ^Unit_Type) -> [dynamic]^Resource_Collection {
	return make([dynamic]^Resource_Collection)
}

// Java: TuvUtils.getTuv(Collection<Unit>, IntegerMap<UnitType>) -> int
tuv_utils_get_tuv :: proc(units: [dynamic]^Unit, costs: ^Integer_Map_Unit_Type) -> i32 {
	tuv: i32 = 0
	for u in units {
		unit_value: i32 = 0
		if v, ok := costs.entries[u.type]; ok {
			unit_value = v
		}
		tuv += unit_value
	}
	return tuv
}

// Java: TuvUtils.getTuv(Collection<Unit>, GamePlayer, IntegerMap<UnitType>, GameState) -> int
//   final Collection<Unit> playerUnits =
//       CollectionUtils.getMatches(units, Matches.alliedUnit(player));
//   return getTuv(playerUnits, costs);
// `data` is unused in Java; mirror the signature.
tuv_utils_get_tuv_for_player :: proc(
	units:  [dynamic]^Unit,
	player: ^Game_Player,
	costs:  ^Integer_Map_Unit_Type,
	data:   ^Game_State,
) -> i32 {
	_ = data
	pred, pred_ctx := matches_allied_unit(player)
	player_units: [dynamic]^Unit
	defer delete(player_units)
	for u in units {
		if pred(pred_ctx, u) {
			append(&player_units, u)
		}
	}
	return tuv_utils_get_tuv(player_units, costs)
}

