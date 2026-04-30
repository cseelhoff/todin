package game

// Handy utility methods for the writers of an AI.
// Java: games.strategy.triplea.ai.AiUtils (utility class, no instances).
Ai_Utils :: struct {}

ai_utils_get_index_of_last_unit_matching :: proc(units: [dynamic]^Unit, match: proc(^Unit) -> bool, end_index: i32) -> i32 {
	for i := end_index; i >= 0; i -= 1 {
		unit := units[i]
		if match(unit) {
			return i
		}
	}
	return -1
}

// Java: public static Comparator<Unit> getCostComparator()
//   return Comparator.comparingInt(o -> getCost(o.getType(), o.getOwner(), o.getData()));
// Returns a comparator that sorts cheaper units before expensive ones.
// Java's Comparator<Unit> maps to Odin's `proc(a, b: ^Unit) -> bool` (less-than),
// the shape consumed by `slice.sort_by`.
ai_utils_get_cost_comparator :: proc() -> proc(a, b: ^Unit) -> bool {
	return proc(a, b: ^Unit) -> bool {
		cost_a := ai_utils_get_cost(
			unit_get_type(a),
			unit_get_owner(a),
			game_data_component_get_data(&a.game_data_component),
		)
		cost_b := ai_utils_get_cost(
			unit_get_type(b),
			unit_get_owner(b),
			game_data_component_get_data(&b.game_data_component),
		)
		return cost_a < cost_b
	}
}

// Java: static int getCost(UnitType unitType, GamePlayer player, GameState data)
//   final Resource pus = data.getResourceList().getResourceOrThrow(Constants.PUS);
//   final ProductionRule rule = getProductionRule(unitType, player);
//   return (rule == null) ? Integer.MAX_VALUE : rule.getCosts().getInt(pus);
// Private helper supporting `ai_utils_get_cost_comparator`. Constants.PUS is
// the literal "PUs" string. Integer_Map uses rawptr keys; a missing key
// yields zero-value for i32 which matches Java IntegerMap.getInt semantics.
@(private = "file")
ai_utils_get_cost :: proc(unit_type: ^Unit_Type, player: ^Game_Player, data: ^Game_Data) -> i32 {
	pus := resource_list_get_resource_or_throw(game_data_get_resource_list(data), "PUs")
	rule := ai_utils_get_production_rule(unit_type, player)
	if rule == nil {
		return max(i32)
	}
	costs := production_rule_get_costs(rule)
	return costs.map_values[rawptr(pus)]
}

// Java: private static @Nullable ProductionRule getProductionRule(UnitType, GamePlayer)
//   final ProductionFrontier frontier = player.getProductionFrontier();
//   if (frontier == null) return null;
//   for (ProductionRule rule : frontier) {
//     if (rule.getResults().getInt(unitType) == 1) return rule;
//   }
//   return null;
@(private = "file")
ai_utils_get_production_rule :: proc(unit_type: ^Unit_Type, player: ^Game_Player) -> ^Production_Rule {
	frontier := player.production_frontier
	if frontier == nil {
		return nil
	}
	for rule in production_frontier_get_rules(frontier) {
		results := production_rule_get_results(rule)
		if results.map_values[rawptr(unit_type)] == 1 {
			return rule
		}
	}
	return nil
}

