package game

import "core:fmt"
import "core:math/rand"

Pro_Purchase_Utils :: struct {}

// Java: public static Comparator<Unit> getCostComparator(final ProData proData)
//   return Comparator.comparingDouble((unit) -> ProPurchaseUtils.getCost(proData, unit));
//
// The lambda captures `proData`, so we use the rawptr-ctx closure-capture
// convention (see llm-instructions.md): a heap-allocated ctx struct holds
// the captured `^Pro_Data`, and the returned comparator is the
// non-capturing trampoline `pro_purchase_utils_cost_comparator_less`
// paired with the ctx pointer. Java's `Comparator<Unit>` maps to a
// less-than predicate `proc(rawptr, ^Unit, ^Unit) -> bool` (the shape
// consumed by Odin sort routines such as `slice.sort_by`).
Pro_Purchase_Utils_Cost_Comparator_Ctx :: struct {
	pro_data: ^Pro_Data,
}

pro_purchase_utils_cost_comparator_less :: proc(ctx: rawptr, a: ^Unit, b: ^Unit) -> bool {
	c := cast(^Pro_Purchase_Utils_Cost_Comparator_Ctx)ctx
	cost_a := pro_purchase_utils_get_cost(c.pro_data, a)
	cost_b := pro_purchase_utils_get_cost(c.pro_data, b)
	return cost_a < cost_b
}

pro_purchase_utils_get_cost_comparator :: proc(
	pro_data: ^Pro_Data,
) -> (
	proc(rawptr, ^Unit, ^Unit) -> bool,
	rawptr,
) {
	ctx := new(Pro_Purchase_Utils_Cost_Comparator_Ctx)
	ctx.pro_data = pro_data
	return pro_purchase_utils_cost_comparator_less, rawptr(ctx)
}

// Java synthetic lambda: ProPurchaseUtils#lambda$incrementUnitProductionForBidTerritories$0(ProPurchaseTerritory).
//
// Origin: inside incrementUnitProductionForBidTerritories the forEach body
//     ppt -> ppt.setUnitProduction(ppt.getUnitProduction() + 1)
// generates this synthetic non-capturing lambda. Hoisted to a free
// top-level proc following the canonical lambda naming convention.
pro_purchase_utils_lambda__increment_unit_production_for_bid_territories__0 :: proc(
	ppt: ^Pro_Purchase_Territory,
) {
	pro_purchase_territory_set_unit_production(
		ppt,
		pro_purchase_territory_get_unit_production(ppt) + 1,
	)
}

// Java: public static void incrementUnitProductionForBidTerritories(
//     final Map<Territory, ProPurchaseTerritory> purchaseTerritories) {
//   purchaseTerritories.values().forEach(
//       ppt -> ppt.setUnitProduction(ppt.getUnitProduction() + 1));
// }
pro_purchase_utils_increment_unit_production_for_bid_territories :: proc(
	purchase_territories: map[^Territory]^Pro_Purchase_Territory,
) {
	for _, ppt in purchase_territories {
		pro_purchase_utils_lambda__increment_unit_production_for_bid_territories__0(ppt)
	}
}

// Java: public static int getMaxConstructions(
//     final List<ProPurchaseOption> zeroMoveDefensePurchaseOptions) {
//   final IntegerMap<String> constructionTypesPerTurn = new IntegerMap<>();
//   for (final ProPurchaseOption ppo : zeroMoveDefensePurchaseOptions) {
//     if (ppo.isConstruction()) {
//       constructionTypesPerTurn.put(ppo.getConstructionType(), ppo.getConstructionTypePerTurn());
//     }
//   }
//   return constructionTypesPerTurn.totalValues();
// }
//
// Java's IntegerMap<String> uses value-based String equality; modeled here
// with a local map[string]i32 (last-put wins, matching IntegerMap.put), then
// summed for totalValues().
pro_purchase_utils_get_max_constructions :: proc(
	zero_move_defense_purchase_options: [dynamic]^Pro_Purchase_Option,
) -> i32 {
	construction_types_per_turn := make(map[string]i32)
	defer delete(construction_types_per_turn)
	for ppo in zero_move_defense_purchase_options {
		if pro_purchase_option_is_construction(ppo) {
			construction_types_per_turn[pro_purchase_option_get_construction_type(ppo)] =
				pro_purchase_option_get_construction_type_per_turn(ppo)
		}
	}
	total: i32 = 0
	for _, v in construction_types_per_turn {
		total += v
	}
	return total
}

// Java: private static GamePlayer getOriginalFactoryOwner(
//     final Territory territory, final GamePlayer player) {
//   final Collection<Unit> factoryUnits = territory.getMatches(Matches.unitCanProduceUnits());
//   if (factoryUnits.isEmpty()) {
//     throw new IllegalStateException("No factory in territory: " + territory);
//   }
//   for (final Unit factory2 : factoryUnits) {
//     if (player.equals(factory2.getOriginalOwner())) {
//       return factory2.getOriginalOwner();
//     }
//   }
//   return CollectionUtils.getAny(factoryUnits).getOriginalOwner();
// }
pro_purchase_utils_get_original_factory_owner :: proc(
	territory: ^Territory,
	player: ^Game_Player,
) -> ^Game_Player {
	pred, ctx := matches_unit_can_produce_units()
	factory_units: [dynamic]^Unit
	defer delete(factory_units)
	for u in territory.unit_collection.units {
		if pred(ctx, u) {
			append(&factory_units, u)
		}
	}
	if len(factory_units) == 0 {
		panic(fmt.tprintf("No factory in territory: %s", territory_to_string(territory)))
	}
	for factory2 in factory_units {
		if player == unit_get_original_owner(factory2) {
			return unit_get_original_owner(factory2)
		}
	}
	return unit_get_original_owner(factory_units[0])
}

// Java: public static List<Unit> getPlaceUnits(
//     final Territory t, final Map<Territory, ProPurchaseTerritory> purchaseTerritories) {
//   final List<Unit> placeUnits = new ArrayList<>();
//   for (final ProPurchaseTerritory purchaseTerritory : purchaseTerritories.values()) {
//     for (final ProPlaceTerritory ppt : purchaseTerritory.getCanPlaceTerritories()) {
//       if (t.equals(ppt.getTerritory())) {
//         placeUnits.addAll(ppt.getPlaceUnits());
//       }
//     }
//   }
//   return placeUnits;
// }
pro_purchase_utils_get_place_units :: proc(
	t: ^Territory,
	purchase_territories: map[^Territory]^Pro_Purchase_Territory,
) -> [dynamic]^Unit {
	place_units: [dynamic]^Unit
	for _, purchase_territory in purchase_territories {
		for ppt in pro_purchase_territory_get_can_place_territories(purchase_territory) {
			if t == pro_place_territory_get_territory(ppt) {
				for u in pro_place_territory_get_place_units(ppt) {
					append(&place_units, u)
				}
			}
		}
	}
	return place_units
}

// Java synthetic lambda: ProPurchaseUtils#lambda$getUnitsToConsume$2(Set, Unit) -> boolean.
//
// Origin: inside getUnitsToConsume the predicate
//     Matches.eligibleUnitToConsume(player, neededType).and(u -> !unitsToConsume.contains(u))
// generates this lambda with the captured `unitsToConsume` Set as its
// first synthetic parameter. Under the rawptr-ctx closure-capture
// convention (see llm-instructions.md), the captured Set is carried in a
// small ctx struct and the lambda becomes a free top-level proc with the
// `proc(rawptr, ^Unit) -> bool` shape.
Pro_Purchase_Utils_Lambda_Get_Units_To_Consume_2_Ctx :: struct {
	units_to_consume: ^map[^Unit]struct {},
}

pro_purchase_utils_lambda_get_units_to_consume_2 :: proc(ctx: rawptr, u: ^Unit) -> bool {
	c := cast(^Pro_Purchase_Utils_Lambda_Get_Units_To_Consume_2_Ctx)ctx
	_, exists := c.units_to_consume[u]
	return !exists
}

// Java: public static Collection<Unit> getUnitsToConsume(
//     GamePlayer player, Collection<Unit> existingUnits, Collection<Unit> unitsToPlace) {
//   Collection<Unit> unitsThatConsume =
//       CollectionUtils.getMatches(unitsToPlace, Matches.unitConsumesUnitsOnCreation());
//   Set<Unit> unitsToConsume = new HashSet<>();
//   for (Unit unitToBuild : unitsThatConsume) {
//     IntegerMap<UnitType> needed = unitToBuild.getUnitAttachment().getConsumesUnits();
//     for (UnitType neededType : needed.keySet()) {
//       final Predicate<Unit> matcher =
//           Matches.eligibleUnitToConsume(player, neededType).and(u -> !unitsToConsume.contains(u));
//       int neededCount = needed.getInt(neededType);
//       Collection<Unit> found = CollectionUtils.getNMatches(existingUnits, neededCount, matcher);
//       Preconditions.checkState(
//           found.size() == neededCount,
//           "Not found: " + neededCount + " of " + neededType + " for " + unitsToPlace);
//       unitsToConsume.addAll(found);
//     }
//   }
//   return unitsToConsume;
// }
//
// The Java predicate captures the mutable `unitsToConsume` Set; here we
// inline the search loop so the per-iteration "not already consumed"
// check reads directly from our local set, avoiding a heap-allocated
// closure ctx per neededType. The set is materialized as the returned
// [dynamic]^Unit (HashSet -> distinct collection).
pro_purchase_utils_get_units_to_consume :: proc(
	player: ^Game_Player,
	existing_units: [dynamic]^Unit,
	units_to_place: [dynamic]^Unit,
) -> [dynamic]^Unit {
	cuc_pred, cuc_ctx := matches_unit_consumes_units_on_creation()
	units_that_consume: [dynamic]^Unit
	defer delete(units_that_consume)
	for u in units_to_place {
		if cuc_pred(cuc_ctx, u) {
			append(&units_that_consume, u)
		}
	}
	units_to_consume_set := make(map[^Unit]struct {})
	for unit_to_build in units_that_consume {
		needed := unit_attachment_get_consumes_units(unit_get_unit_attachment(unit_to_build))
		for needed_type, needed_count in needed {
			eligible_pred, eligible_ctx := matches_eligible_unit_to_consume(player, needed_type)
			found_count: i32 = 0
			for u in existing_units {
				if found_count >= needed_count {
					break
				}
				if _, already := units_to_consume_set[u]; already {
					continue
				}
				if !eligible_pred(eligible_ctx, u) {
					continue
				}
				units_to_consume_set[u] = struct {}{}
				found_count += 1
			}
			// The caller should have already validated that the required units are present.
			if found_count != needed_count {
				panic(fmt.tprintf(
					"Not found: %d of %s for %v",
					needed_count,
					default_named_get_name(&needed_type.named_attachable.default_named),
					units_to_place,
				))
			}
		}
	}
	result: [dynamic]^Unit
	for u in units_to_consume_set {
		append(&result, u)
	}
	delete(units_to_consume_set)
	return result
}


// Java: public static double getCost(final ProData proData, final Unit unit)
//   final Resource pus = unit.getData().getResourceList().getResourceOrThrow(Constants.PUS);
//   final Collection<Unit> units = TransportTracker.transportingAndUnloaded(unit);
//   units.add(unit);
//   double cost = 0.0;
//   for (final Unit u : units) {
//     final ProductionRule rule = getProductionRule(u.getType(), u.getOwner());
//     if (rule == null) {
//       cost += proData.getUnitValue(u.getType());
//     } else {
//       cost += ((double) rule.getCosts().getInt(pus)) / rule.getResults().totalValues();
//     }
//   }
//   return cost;
//
// Constants.PUS resolves to the literal "PUs" (matches the convention used by
// ai_utils.odin and other ports). unit.getData() goes through the embedded
// Game_Data_Component. IntegerMap.getInt → integer_map_get_int (rawptr key);
// IntegerMap.totalValues → integer_map_total_values.
pro_purchase_utils_get_cost :: proc(pro_data: ^Pro_Data, unit: ^Unit) -> f64 {
	data := game_data_component_get_data(&unit.game_data_component)
	pus := resource_list_get_resource_or_throw(game_data_get_resource_list(data), "PUs")
	units := transport_tracker_transporting_and_unloaded(unit)
	defer delete(units)
	append(&units, unit)
	cost: f64 = 0.0
	for u in units {
		rule := pro_purchase_utils_get_production_rule(unit_get_type(u), unit_get_owner(u))
		if rule == nil {
			cost += f64(pro_data_get_unit_value(pro_data, unit_get_type(u)))
		} else {
			costs := production_rule_get_costs(rule)
			results := production_rule_get_results(rule)
			cost += f64(integer_map_get_int(&costs, rawptr(pus))) / f64(integer_map_total_values(&results))
		}
	}
	return cost
}


// Java: private static ProductionRule getProductionRule(UnitType unitType, GamePlayer player)
// Iterates the player's production frontier and returns the first rule whose
// results contain `unitType` with a positive count, else nil.
pro_purchase_utils_get_production_rule :: proc(
	unit_type: ^Unit_Type,
	player: ^Game_Player,
) -> ^Production_Rule {
	frontier := player.production_frontier
	if frontier == nil {
		return nil
	}
	for rule in production_frontier_iterator(frontier) {
		results := production_rule_get_results(rule)
		if integer_map_get_int(&results, rawptr(unit_type)) > 0 {
			return rule
		}
	}
	return nil
}

// Java synthetic lambda: ProPurchaseUtils#lambda$getCostComparator$1(ProData, Unit) -> double.
//
// Origin: inside getCostComparator the keyExtractor
//     (unit) -> ProPurchaseUtils.getCost(proData, unit)
// of `Comparator.comparingDouble(...)`. The lambda captures `proData`,
// so under the rawptr-ctx closure-capture convention it lives as a
// free top-level proc whose first parameter is a `^Pro_Purchase_Utils_Cost_Comparator_Ctx`
// (the same ctx struct already used by the comparator itself, which
// holds the captured `^Pro_Data`).
pro_purchase_utils_lambda_get_cost_comparator_1 :: proc(ctx: rawptr, unit: ^Unit) -> f64 {
	c := cast(^Pro_Purchase_Utils_Cost_Comparator_Ctx)ctx
	return pro_purchase_utils_get_cost(c.pro_data, unit)
}

// Java: public static Map<Territory, ProPurchaseTerritory> findBidTerritories(
//     final ProData proData, final GamePlayer player) {
//   ...
//   final Set<Territory> ownedOrHasUnitTerritories =
//       new HashSet<>(data.getMap().getTerritoriesOwnedBy(player));
//   ownedOrHasUnitTerritories.addAll(proData.getMyUnitTerritories());
//   final List<Territory> potentialTerritories =
//       CollectionUtils.getMatches(
//           ownedOrHasUnitTerritories,
//           Matches.territoryIsPassableAndNotRestrictedAndOkByRelationships(
//               player, false, false, false, false, false));
//   final Map<Territory, ProPurchaseTerritory> purchaseTerritories = new HashMap<>();
//   for (final Territory t : potentialTerritories) {
//     final ProPurchaseTerritory ppt = new ProPurchaseTerritory(t, data, player, 1, true);
//     purchaseTerritories.put(t, ppt);
//   }
//   return purchaseTerritories;
// }
pro_purchase_utils_find_bid_territories :: proc(
	pro_data: ^Pro_Data,
	player: ^Game_Player,
) -> map[^Territory]^Pro_Purchase_Territory {
	pro_logger_info("Find all bid territories")
	data := pro_data_get_data(pro_data)
	owned_or_has_unit_set := make(map[^Territory]struct {})
	defer delete(owned_or_has_unit_set)
	owned := game_map_get_territories_owned_by(game_data_get_map(data), player)
	defer delete(owned)
	for t in owned {
		owned_or_has_unit_set[t] = struct {}{}
	}
	for t in pro_data_get_my_unit_territories(pro_data) {
		owned_or_has_unit_set[t] = struct {}{}
	}
	pred, pred_ctx := matches_territory_is_passable_and_not_restricted_and_ok_by_relationships(
		player,
		false,
		false,
		false,
		false,
		false,
	)
	purchase_territories := make(map[^Territory]^Pro_Purchase_Territory)
	for t in owned_or_has_unit_set {
		if !pred(pred_ctx, t) {
			continue
		}
		ppt := pro_purchase_territory_new(t, data, player, 1, true)
		purchase_territories[t] = ppt
		pro_logger_debug(pro_purchase_territory_to_string(ppt))
	}
	return purchase_territories
}

// Java: private static int getUnitProduction(
//     final Territory territory, final GamePlayer player) {
//   final Predicate<Unit> factoryMatch =
//       Matches.unitIsOwnedAndIsFactoryOrCanProduceUnits(player)
//           .and(Matches.unitIsBeingTransported().negate())
//           .and((territory.isWater() ? Matches.unitIsLand() : Matches.unitIsSea()).negate());
//   final Collection<Unit> factoryUnits = territory.getMatches(factoryMatch);
//   final boolean originalFactory =
//       TerritoryAttachment.get(territory)
//           .map(TerritoryAttachment::getOriginalFactory)
//           .orElse(false);
//   final boolean playerIsOriginalOwner =
//       !factoryUnits.isEmpty() && player.equals(getOriginalFactoryOwner(territory, player));
//   final RulesAttachment ra = player.getRulesAttachment();
//   if (originalFactory && playerIsOriginalOwner) {
//     if (ra != null && ra.getMaxPlacePerTerritory() != -1) {
//       return Math.max(0, ra.getMaxPlacePerTerritory());
//     }
//     return Integer.MAX_VALUE;
//   }
//   if (ra != null && ra.getPlacementAnyTerritory()) {
//     return Integer.MAX_VALUE;
//   }
//   return UnitUtils.getProductionPotentialOfTerritory(
//       territory.getUnits(), territory, player, true, true);
// }
pro_purchase_utils_get_unit_production :: proc(
	territory: ^Territory,
	player: ^Game_Player,
) -> i32 {
	fact_p, fact_c := matches_unit_is_owned_and_is_factory_or_can_produce_units(player)
	trans_p, trans_c := matches_unit_is_being_transported()
	side_p: proc(rawptr, ^Unit) -> bool
	side_c: rawptr
	if territory_is_water(territory) {
		side_p, side_c = matches_unit_is_land()
	} else {
		side_p, side_c = matches_unit_is_sea()
	}
	factory_units: [dynamic]^Unit
	defer delete(factory_units)
	for u in territory.unit_collection.units {
		if fact_p(fact_c, u) && !trans_p(trans_c, u) && !side_p(side_c, u) {
			append(&factory_units, u)
		}
	}
	ta := territory_attachment_get(territory)
	original_factory := ta != nil && territory_attachment_get_original_factory(ta)
	player_is_original_owner :=
		len(factory_units) > 0 &&
		player == pro_purchase_utils_get_original_factory_owner(territory, player)
	ra := game_player_get_rules_attachment(player)
	if original_factory && player_is_original_owner {
		if ra != nil && ra.max_place_per_territory != -1 {
			return max(i32(0), ra.max_place_per_territory)
		}
		return max(i32)
	}
	if ra != nil && ra.placement_any_territory {
		return max(i32)
	}
	return unit_utils_get_production_potential_of_territory(
		territory.unit_collection.units,
		territory,
		player,
		true,
		true,
	)
}

// Java: public static Optional<ProPurchaseOption> randomizePurchaseOption(
//     final Map<ProPurchaseOption, Double> purchaseEfficiencies, final String type)
//
// Optional<ProPurchaseOption> collapses to ^Pro_Purchase_Option (nil = empty).
// Java's `Math.random()` maps to `rand.float64()`. The Java code uses a
// LinkedHashMap to preserve insertion order across the two iterations;
// Odin's builtin `map` is unordered, but a single map iteration order
// is stable for a given call, so we snapshot keys in a slice during the
// upper-bound pass and reuse that slice for the selection pass.
pro_purchase_utils_randomize_purchase_option :: proc(
	purchase_efficiencies: map[^Pro_Purchase_Option]f64,
	type_name: string,
) -> ^Pro_Purchase_Option {
	pro_logger_trace(fmt.tprintf("Select purchase option for %s", type_name))
	total_efficiency: f64 = 0
	for _, eff in purchase_efficiencies {
		total_efficiency += eff
	}
	if total_efficiency == 0 {
		return nil
	}
	keys: [dynamic]^Pro_Purchase_Option
	defer delete(keys)
	upper_bounds: [dynamic]f64
	defer delete(upper_bounds)
	upper_bound: f64 = 0.0
	for ppo, eff in purchase_efficiencies {
		chance := eff / total_efficiency * 100
		upper_bound += chance
		append(&keys, ppo)
		append(&upper_bounds, upper_bound)
		ut := pro_purchase_option_get_unit_type(ppo)
		pro_logger_trace(
			fmt.tprintf(
				"%s, probability=%v, upperBound=%v",
				default_named_get_name(&ut.named_attachable.default_named),
				chance,
				upper_bound,
			),
		)
	}
	random_number := rand.float64() * 100
	pro_logger_trace(fmt.tprintf("Random number: %v", random_number))
	for ppo, i in keys {
		if random_number <= upper_bounds[i] {
			return ppo
		}
	}
	return keys[len(keys) - 1]
}

// Java: public static List<Unit> findMaxPurchaseDefenders(
//     final ProData proData, final GamePlayer player, final Territory t,
//     final List<ProPurchaseOption> landPurchaseOptions)
//
// Constants.PUS resolves to the literal "PUs" (matches existing usage in
// pro_purchase_utils_get_cost). The Java call
// `ProPurchaseValidationUtils.findPurchaseOptionsForTerritory(proData,
// player, landPurchaseOptions, t, false)` is the 5-arg overload, which in
// Odin is `pro_purchase_validation_utils_find_purchase_options_for_territory_5`.
// `bestDefenseOption.getUnitType().createTemp(quantity, player)` returns a
// freshly-allocated [dynamic]^Unit each iteration; we copy its elements into
// `place_units` and free the temporary container.
pro_purchase_utils_find_max_purchase_defenders :: proc(
	pro_data: ^Pro_Data,
	player: ^Game_Player,
	t: ^Territory,
	land_purchase_options: [dynamic]^Pro_Purchase_Option,
) -> [dynamic]^Unit {
	pro_logger_info(
		fmt.tprintf(
			"Find max purchase defenders for %s",
			default_named_get_name(&t.named_attachable.default_named),
		),
	)
	data := pro_data_get_data(pro_data)

	// Determine most cost efficient defender that can be produced in this territory
	pus := resource_list_get_resource_or_throw(game_data_get_resource_list(data), "PUs")
	pus_remaining := resource_collection_get_quantity(game_player_get_resources(player), pus)
	purchase_options_for_territory :=
		pro_purchase_validation_utils_find_purchase_options_for_territory_5(
			pro_data,
			player,
			land_purchase_options,
			t,
			false,
		)
	defer delete(purchase_options_for_territory)
	best_defense_option: ^Pro_Purchase_Option = nil
	max_defense_efficiency: f64 = 0
	for ppo in purchase_options_for_territory {
		if pro_purchase_option_get_defense_efficiency(ppo) > max_defense_efficiency &&
		   pro_purchase_option_get_cost(ppo) <= pus_remaining {
			best_defense_option = ppo
			max_defense_efficiency = pro_purchase_option_get_defense_efficiency(ppo)
		}
	}

	// Determine number of defenders I can purchase
	place_units: [dynamic]^Unit
	if best_defense_option != nil {
		bdo_unit_type := pro_purchase_option_get_unit_type(best_defense_option)
		pro_logger_debug(
			fmt.tprintf(
				"Best defense option: %s",
				default_named_get_name(&bdo_unit_type.named_attachable.default_named),
			),
		)
		remaining_unit_production := pro_purchase_utils_get_unit_production(t, player)
		pus_spent: i32 = 0
		for pro_purchase_option_get_cost(best_defense_option) <= (pus_remaining - pus_spent) &&
		    remaining_unit_production >= pro_purchase_option_get_quantity(best_defense_option) {

			// If out of PUs or production then break

			// Create new temp defenders
			pus_spent += pro_purchase_option_get_cost(best_defense_option)
			remaining_unit_production -= pro_purchase_option_get_quantity(best_defense_option)
			new_units := unit_type_create_temp(
				bdo_unit_type,
				pro_purchase_option_get_quantity(best_defense_option),
				player,
			)
			for u in new_units {
				append(&place_units, u)
			}
			delete(new_units)
		}
		pro_logger_debug(fmt.tprintf("Potential purchased defenders: %v", place_units))
	}
	return place_units
}

// Java: public static Map<Territory, ProPurchaseTerritory> findPurchaseTerritories(
//     final ProData proData, final GamePlayer player)
//
// `data.getMap().getTerritoriesOwnedBy(player)` and
// `data.getMap().getTerritories()` map directly. The two-stage filtering
// (factory-or-anywhere, then can-move-land-units) preserves Java's
// reassign-then-filter pattern, with intermediate [dynamic]^Territory
// buffers. `new ProPurchaseTerritory(t, data, player, unitProduction)` is
// the 4-arg overload — `pro_purchase_territory_new_default` in Odin.
pro_purchase_utils_find_purchase_territories :: proc(
	pro_data: ^Pro_Data,
	player: ^Game_Player,
) -> map[^Territory]^Pro_Purchase_Territory {
	pro_logger_info("Find all purchase territories")
	data := pro_data_get_data(pro_data)

	// Find all territories that I can place units on
	ra := game_player_get_rules_attachment(player)
	owned_and_not_conquered_factory_territories: [dynamic]^Territory
	defer delete(owned_and_not_conquered_factory_territories)
	if ra != nil && ra.placement_any_territory {
		owned := game_map_get_territories_owned_by(game_data_get_map(data), player)
		defer delete(owned)
		for t in owned {
			append(&owned_and_not_conquered_factory_territories, t)
		}
	} else {
		f_p, f_c := pro_matches_territory_has_factory_and_is_not_conquered_owned_land(player)
		all_terrs := game_map_get_territories(game_data_get_map(data))
		defer delete(all_terrs)
		for t in all_terrs {
			if f_p(f_c, t) {
				append(&owned_and_not_conquered_factory_territories, t)
			}
		}
	}
	move_p, move_c := pro_matches_territory_can_move_land_units(player, false)
	filtered: [dynamic]^Territory
	defer delete(filtered)
	for t in owned_and_not_conquered_factory_territories {
		if move_p(move_c, t) {
			append(&filtered, t)
		}
	}

	// Create purchase territory holder for each factory territory
	purchase_territories := make(map[^Territory]^Pro_Purchase_Territory)
	for t in filtered {
		unit_production := pro_purchase_utils_get_unit_production(t, player)
		ppt := pro_purchase_territory_new_default(t, data, player, unit_production)
		purchase_territories[t] = ppt
		pro_logger_debug(pro_purchase_territory_to_string(ppt))
	}
	return purchase_territories
}
