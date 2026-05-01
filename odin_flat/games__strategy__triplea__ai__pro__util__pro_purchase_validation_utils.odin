package game

// Java owners covered by this file:
//   - games.strategy.triplea.ai.pro.util.ProPurchaseValidationUtils

Pro_Purchase_Validation_Utils :: struct {}

// Static helper: concatenate two unit lists into a freshly allocated
// dynamic array. Mirrors Java's
//   Stream.concat(l1.stream(), l2.stream()).collect(Collectors.toList()).
pro_purchase_validation_utils_combine_lists :: proc(
	l1: [dynamic]^Unit,
	l2: [dynamic]^Unit,
) -> [dynamic]^Unit {
	result := make([dynamic]^Unit, 0, len(l1) + len(l2))
	for u in l1 {
		append(&result, u)
	}
	for u in l2 {
		append(&result, u)
	}
	return result
}

// Mirrors Java's static
//   List<ProPurchaseOption> findPurchaseOptionsForTerritory(
//       ProData proData, GamePlayer player, List<ProPurchaseOption> purchaseOptions,
//       Territory t, Territory factoryTerritory, boolean isBid)
// which keeps every option whose temp units would actually be placeable
// in t (or buildable by factoryTerritory) under the current rules.
pro_purchase_validation_utils_find_purchase_options_for_territory :: proc(
	pro_data: ^Pro_Data,
	player: ^Game_Player,
	purchase_options: [dynamic]^Pro_Purchase_Option,
	t: ^Territory,
	factory_territory: ^Territory,
	is_bid: bool,
) -> [dynamic]^Pro_Purchase_Option {
	result := make([dynamic]^Pro_Purchase_Option, 0, len(purchase_options))
	for ppo in purchase_options {
		units := unit_type_create_temp(
			pro_purchase_option_get_unit_type(ppo),
			pro_purchase_option_get_quantity(ppo),
			player,
		)
		if pro_purchase_validation_utils_can_units_be_placed(
			pro_data,
			units,
			player,
			t,
			factory_territory,
			is_bid,
		) {
			append(&result, ppo)
		}
	}
	return result
}

// Mirrors Java's static
//   void removeInvalidPurchaseOptions(
//       ProData proData, GamePlayer player, GameState data,
//       List<ProPurchaseOption> purchaseOptions, ProResourceTracker resourceTracker,
//       int remainingUnitProduction, List<Unit> unitsToPlace,
//       Map<Territory, ProPurchaseTerritory> purchaseTerritories,
//       int remainingConstructions, Territory territory)
// which mutates purchaseOptions in place by stripping any option that
// fails any of the validation predicates.
pro_purchase_validation_utils_remove_invalid_purchase_options :: proc(
	pro_data: ^Pro_Data,
	player: ^Game_Player,
	data: ^Game_State,
	purchase_options: ^[dynamic]^Pro_Purchase_Option,
	resource_tracker: ^Pro_Resource_Tracker,
	remaining_unit_production: i32,
	units_to_place: [dynamic]^Unit,
	purchase_territories: map[^Territory]^Pro_Purchase_Territory,
	remaining_constructions: i32,
	territory: ^Territory,
) {
	for i := len(purchase_options^) - 1; i >= 0; i -= 1 {
		purchase_option := purchase_options^[i]
		combined := pro_purchase_validation_utils_combine_lists(
			units_to_place,
			pro_purchase_option_create_temp_units(purchase_option),
		)
		should_remove :=
			!pro_purchase_validation_utils_has_enough_resources_and_production(
				purchase_option,
				resource_tracker,
				remaining_unit_production,
				remaining_constructions,
			) ||
			pro_purchase_validation_utils_has_reached_max_unit_built_per_player(
				purchase_option,
				player,
				data,
				units_to_place,
				purchase_territories,
			) ||
			pro_purchase_validation_utils_has_reached_construction_limits(
				purchase_option,
				data,
				units_to_place,
				purchase_territories,
				territory,
			) ||
			!pro_purchase_validation_utils_units_to_consume_are_all_present(
				pro_data,
				player,
				territory,
				combined,
			)
		if should_remove {
			ordered_remove(purchase_options, i)
		}
	}
}

