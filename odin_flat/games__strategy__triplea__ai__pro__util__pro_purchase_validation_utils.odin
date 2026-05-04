package game

import "core:strings"

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

// Mirrors Java's 5-arg overload
//   List<ProPurchaseOption> findPurchaseOptionsForTerritory(
//       ProData proData, GamePlayer player,
//       List<ProPurchaseOption> purchaseOptions, Territory t, boolean isBid)
// which simply delegates to the 6-arg form using t as the factory
// territory. Suffix _5 mirrors the project's unit_type_create_5
// convention for distinguishing Odin overloads by parameter count.
pro_purchase_validation_utils_find_purchase_options_for_territory_5 :: proc(
	pro_data: ^Pro_Data,
	player: ^Game_Player,
	purchase_options: [dynamic]^Pro_Purchase_Option,
	t: ^Territory,
	is_bid: bool,
) -> [dynamic]^Pro_Purchase_Option {
	return pro_purchase_validation_utils_find_purchase_options_for_territory(
		pro_data,
		player,
		purchase_options,
		t,
		t,
		is_bid,
	)
}

// Mirrors Java's private static
//   int findNumberOfConstructionTypeToPlace(
//       ProPurchaseOption purchaseOption, List<Unit> unitsToPlace,
//       Map<Territory, ProPurchaseTerritory> purchaseTerritories,
//       Territory territory)
// which counts how many units of the option's UnitType are already
// queued for placement in the given territory — both in unitsToPlace
// and across every ProPlaceTerritory belonging to the supplied
// purchaseTerritories map whose territory equals `territory`.
pro_purchase_validation_utils_find_number_of_construction_type_to_place :: proc(
	purchase_option: ^Pro_Purchase_Option,
	units_to_place: [dynamic]^Unit,
	purchase_territories: map[^Territory]^Pro_Purchase_Territory,
	territory: ^Territory,
) -> i32 {
	target_type := pro_purchase_option_get_unit_type(purchase_option)
	num_construction_type_to_place: i32 = 0
	for u in units_to_place {
		if unit_get_type(u) == target_type {
			num_construction_type_to_place += 1
		}
	}
	for _, t in purchase_territories {
		for place_territory in pro_purchase_territory_get_can_place_territories(t) {
			if pro_place_territory_get_territory(place_territory) == territory {
				for u in pro_place_territory_get_place_units(place_territory) {
					if unit_get_type(u) == target_type {
						num_construction_type_to_place += 1
					}
				}
			}
		}
	}
	return num_construction_type_to_place
}

// Mirrors Java's private static
//   boolean hasReachedMaxUnitBuiltPerPlayer(
//       ProPurchaseOption purchaseOption, GamePlayer player, GameState data,
//       List<Unit> unitsToPlace,
//       Map<Territory, ProPurchaseTerritory> purchaseTerritories)
// which returns true when buying purchaseOption.getQuantity() more
// units of purchaseOption.getUnitType() owned by `player` would push
// the total already-built + queued count past the unit type's
// per-player cap. maxBuiltPerPlayer == -1 means unlimited; 0 means
// the type is forbidden.
pro_purchase_validation_utils_has_reached_max_unit_built_per_player :: proc(
	purchase_option: ^Pro_Purchase_Option,
	player: ^Game_Player,
	data: ^Game_State,
	units_to_place: [dynamic]^Unit,
	purchase_territories: map[^Territory]^Pro_Purchase_Territory,
) -> bool {
	max_built := pro_purchase_option_get_max_built_per_player(purchase_option)
	type := pro_purchase_option_get_unit_type(purchase_option)
	if max_built == 0 {
		return true
	} else if max_built > 0 {
		// Predicate: unit.getType() == type && unit.getOwner() == player.
		currently_built: i32 = 0
		for u in units_to_place {
			if unit_get_type(u) == type && unit_get_owner(u) == player {
				currently_built += 1
			}
		}
		all_territories := game_map_get_territories(game_state_get_map(data))
		for t in all_territories {
			// Inline count avoids needing a rawptr-aware overload of
			// unit_collection_count_matches (whose pred is a bare
			// proc(^Unit) -> bool with no closure).
			for u in unit_collection_get_units(territory_get_unit_collection(t)) {
				if unit_get_type(u) == type && unit_get_owner(u) == player {
					currently_built += 1
				}
			}
		}
		for _, t in purchase_territories {
			for place_territory in pro_purchase_territory_get_can_place_territories(t) {
				for u in pro_place_territory_get_place_units(place_territory) {
					if unit_get_type(u) == type && unit_get_owner(u) == player {
						currently_built += 1
					}
				}
			}
		}
		allowed_build := max_built - currently_built
		return allowed_build - pro_purchase_option_get_quantity(purchase_option) < 0
	}
	return false
}

// Mirrors Java's private static
//   boolean unitsToConsumeAreAllPresent(
//       ProData proData, GamePlayer player, Territory t,
//       Collection<Unit> unitsToBuild)
// Returns true when every UnitType the buildables would consume is
// already present in territory `t` in sufficient quantity, ignoring
// units already earmarked for consumption via proData.unitsToBeConsumed.
pro_purchase_validation_utils_units_to_consume_are_all_present :: proc(
	pro_data: ^Pro_Data,
	player: ^Game_Player,
	t: ^Territory,
	units_to_build: [dynamic]^Unit,
) -> bool {
	required_units := integer_map_new()
	for unit_to_build in units_to_build {
		consumes := unit_attachment_get_consumes_units(unit_get_unit_attachment(unit_to_build))
		for ut, qty in consumes {
			integer_map_add(required_units, rawptr(ut), qty)
		}
	}
	if integer_map_is_empty(required_units) {
		return true
	}
	eligible_territory_units := integer_map_new()
	// TODO: This will need to change if consumed units may come from other territories.
	consumed := pro_data_get_units_to_be_consumed(pro_data)
	for u in unit_collection_get_units(territory_get_unit_collection(t)) {
		if _, already_consumed := consumed[u]; already_consumed {
			continue
		}
		pred, ctx := matches_eligible_unit_to_consume(player, unit_get_type(u))
		if pred(ctx, u) {
			integer_map_add(eligible_territory_units, rawptr(unit_get_type(u)), 1)
		}
	}
	return integer_map_greater_than_or_equal_to(eligible_territory_units, required_units)
}


// Mirrors Java's private static
//   int findMaxConstructionTypeAllowed(
//       ProPurchaseOption purchaseOption, GameState data, Territory territory)
// which returns the cap on how many construction-type buildings of
// purchaseOption.getUnitType() may be placed in `territory`. The
// factory and structure construction types use the option's own
// configured maximum verbatim. Other construction types may be
// expanded by the unlimitedConstructions / moreConstructionsWithFactory
// game properties.
//
// Constants.CONSTRUCTION_TYPE_FACTORY is the literal string "factory"
// and Constants.CONSTRUCTION_TYPE_STRUCTURE is the literal string
// "structure" (see triplea Constants.java); inlined here since the
// Odin Constants file does not yet export these tokens.
pro_purchase_validation_utils_find_max_construction_type_allowed :: proc(
	purchase_option: ^Pro_Purchase_Option,
	data: ^Game_State,
	territory: ^Territory,
) -> i32 {
	max_construction_type := pro_purchase_option_get_max_construction_type(purchase_option)
	construction_type := pro_purchase_option_get_construction_type(purchase_option)
	if construction_type != "factory" &&
	   !strings.has_suffix(construction_type, "structure") {
		props := game_state_get_properties(data)
		if properties_get_unlimited_constructions(props) {
			max_construction_type = max(i32)
		} else if properties_get_more_constructions_with_factory(props) {
			// Java: TerritoryAttachment.get(territory)
			//         .map(TerritoryAttachment::getProduction).orElse(0)
			production: i32 = 0
			att := territory_attachment_get(territory)
			if att != nil {
				production = territory_attachment_get_production(att)
			}
			if production > max_construction_type {
				max_construction_type = production
			}
		}
	}
	return max_construction_type
}

// Mirrors Java's private static
//   boolean isPlacingFightersOnNewCarriers(Territory t, List<Unit> units)
// which is true iff `t` is a sea zone, the produceFightersOnCarriers
// game property is enabled, and `units` contains at least one air
// unit and at least one carrier.
pro_purchase_validation_utils_is_placing_fighters_on_new_carriers :: proc(
	t: ^Territory,
	units: [dynamic]^Unit,
) -> bool {
	if !territory_is_water(t) {
		return false
	}
	data := game_data_component_get_data(
		&t.named_attachable.default_named.game_data_component,
	)
	if !properties_get_produce_fighters_on_carriers(game_data_get_properties(data)) {
		return false
	}
	air_pred, air_ctx := matches_unit_is_air()
	any_air := false
	for u in units {
		if air_pred(air_ctx, u) {
			any_air = true
			break
		}
	}
	if !any_air {
		return false
	}
	carrier_pred, carrier_ctx := matches_unit_is_carrier()
	for u in units {
		if carrier_pred(carrier_ctx, u) {
			return true
		}
	}
	return false
}

// Mirrors Java's private static
//   boolean hasReachedConstructionLimits(
//       ProPurchaseOption purchaseOption, GameState data,
//       List<Unit> unitsToPlace,
//       Map<Territory, ProPurchaseTerritory> purchaseTerritories,
//       Territory territory)
// which returns true when the option is a construction and either
// already has its per-turn quota of constructions of this type queued
// for `territory`, or together with units already in `territory` would
// exceed the territory's allowed maximum of this construction type.
pro_purchase_validation_utils_has_reached_construction_limits :: proc(
	purchase_option: ^Pro_Purchase_Option,
	data: ^Game_State,
	units_to_place: [dynamic]^Unit,
	purchase_territories: map[^Territory]^Pro_Purchase_Territory,
	territory: ^Territory,
) -> bool {
	if pro_purchase_option_is_construction(purchase_option) && territory != nil {
		num_construction_type_to_place :=
			pro_purchase_validation_utils_find_number_of_construction_type_to_place(
				purchase_option,
				units_to_place,
				purchase_territories,
				territory,
			)
		if num_construction_type_to_place >=
		   pro_purchase_option_get_construction_type_per_turn(purchase_option) {
			return true
		}

		max_construction_type :=
			pro_purchase_validation_utils_find_max_construction_type_allowed(
				purchase_option,
				data,
				territory,
			)
		target_type := pro_purchase_option_get_unit_type(purchase_option)
		num_existing_construction_type: i32 = 0
		for u in unit_collection_get_units(territory_get_unit_collection(territory)) {
			if unit_get_type(u) == target_type {
				num_existing_construction_type += 1
			}
		}
		return (num_construction_type_to_place + num_existing_construction_type) >=
		       max_construction_type
	}
	return false
}
