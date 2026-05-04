package game

import "core:fmt"

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
