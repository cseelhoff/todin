package game

Pro_Purchase_Ai :: struct {
	calc:               ^Pro_Odds_Calculator,
	pro_data:           ^Pro_Data,
	data:               ^Game_Data,
	start_of_turn_data: ^Game_State,
	player:             ^Game_Player,
	resource_tracker:   ^Pro_Resource_Tracker,
	territory_manager:  ^Pro_Territory_Manager,
	is_bid:             bool,
}

// Synthetic static lambda from `ProPurchaseAi.bid`:
//
//     .map(t -> t.get(0))
//
// where `t` is a `List<ProPlaceTerritory>`. The lambda captures
// nothing — it just returns the first element of the list.
pro_purchase_ai_lambda_bid_0 :: proc(t: [dynamic]^Pro_Place_Territory) -> ^Pro_Place_Territory {
	return t[0]
}

// Synthetic capturing lambda from `ProPurchaseAi.populateProductionRuleMap`:
//
//     .filter(u -> !unplacedUnits.contains(u))
//
// where `unplacedUnits` is a `List<Unit>` captured from the enclosing
// scope. Returns true if `u` is not present in `unplaced_units`.
pro_purchase_ai_lambda_populate_production_rule_map_5 :: proc(
	unplaced_units: [dynamic]^Unit,
	u: ^Unit,
) -> bool {
	for existing in unplaced_units {
		if existing == u {
			return false
		}
	}
	return true
}

// Constructor for `Pro_Purchase_Ai`. Mirrors `ProPurchaseAi(AbstractProAi ai)`,
// which copies the calc and proData references from the parent AI.
pro_purchase_ai_new :: proc(ai: ^Abstract_Pro_Ai) -> ^Pro_Purchase_Ai {
	self := new(Pro_Purchase_Ai)
	self.calc = abstract_pro_ai_get_calc(ai)
	self.pro_data = abstract_pro_ai_get_pro_data(ai)
	return self
}

// Determine efficiency value for upgrading to the given purchase option.
// If the strategic value of the territory is low then favor high movement
// units as it is far from the enemy, otherwise favor high defense.
pro_purchase_ai_find_upgrade_unit_efficiency :: proc(
	ppo: ^Pro_Purchase_Option,
	strategic_value: f64,
) -> f64 {
	multiplier: f64 =
		f64(ppo.defense_efficiency) if strategic_value >= 1 else f64(ppo.movement)
	return ppo.attack_efficiency * multiplier * f64(ppo.cost) / f64(ppo.quantity)
}

// Returns every `Pro_Purchase_Territory` whose `can_place_territories` list
// contains `place_territory`.
pro_purchase_ai_get_purchase_territories :: proc(
	place_territory: ^Pro_Place_Territory,
	purchase_territories: map[^Territory]^Pro_Purchase_Territory,
) -> [dynamic]^Pro_Purchase_Territory {
	territories: [dynamic]^Pro_Purchase_Territory
	for _, t in purchase_territories {
		for candidate in t.can_place_territories {
			if candidate == place_territory {
				append(&territories, t)
				break
			}
		}
	}
	return territories
}

// Synthetic capturing lambda from `ProPurchaseAi.populateProductionRuleMap`:
//
//     .filter(u -> u.getType().equals(ppo.getUnitType()))
//
// where `ppo` is the enclosing-scope `ProPurchaseOption`.
pro_purchase_ai_lambda_populate_production_rule_map_4 :: proc(
	ppo: ^Pro_Purchase_Option,
	u: ^Unit,
) -> bool {
	return unit_get_type(u) == ppo.unit_type
}

// Synthetic non-capturing lambda from
// `ProPurchaseAi.prioritizeTerritoriesToDefend`:
//
//     needToDefendTerritories.removeIf(ppt -> ppt.getDefenseValue() <= 0);
pro_purchase_ai_lambda_prioritize_territories_to_defend_1 :: proc(
	ppt: ^Pro_Place_Territory,
) -> bool {
	return ppt.defense_value <= 0
}

// Synthetic capturing lambda from
// `ProPurchaseAi.purchaseSeaAndAmphibUnits`:
//
//     territoriesToLoadFrom.removeIf(
//         potentialTerritory ->
//             potentialTerritory.isWater()
//                 || territoryValueMap.get(potentialTerritory) > 0.25);
//
// captures `territoryValueMap` (a `Map<Territory, Double>`).
pro_purchase_ai_lambda_purchase_sea_and_amphib_units_3 :: proc(
	territory_value_map: map[^Territory]f64,
	potential_territory: ^Territory,
) -> bool {
	if territory_is_water(potential_territory) {
		return true
	}
	value, ok := territory_value_map[potential_territory]
	return ok && value > 0.25
}

