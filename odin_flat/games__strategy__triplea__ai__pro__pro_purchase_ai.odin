package game

import "core:fmt"

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

// Mark every `Pro_Place_Territory` in `purchase_territories` whose
// canPlaceTerritories list equals `place_territory` as no longer holdable.
pro_purchase_ai_set_cant_hold_place_territory :: proc(
	self: ^Pro_Purchase_Ai,
	place_territory: ^Pro_Place_Territory,
	purchase_territories: map[^Territory]^Pro_Purchase_Territory,
) {
	for _, t in purchase_territories {
		for ppt in t.can_place_territories {
			if pro_place_territory_equals(place_territory, ppt) {
				pro_place_territory_set_can_hold(ppt, false)
			}
		}
	}
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

// Static `ProPurchaseAi.doPlace(Territory, Collection<Unit>,
// IAbstractPlaceDelegate)`. Places each unit in `to_place` one at
// a time on territory `t` via the delegate; if the delegate
// returns an error message (Java `Optional<String>`), log it as a
// warning along with the territory/unit context. After all units
// are placed, pause for AI move pacing.
//
// The Java code uses `.ifPresent(message -> { ... })`; the lambda
// is inlined here as a `Maybe(string)` unwrap, mirroring the same
// effect.
pro_purchase_ai_do_place :: proc(
	t: ^Territory,
	to_place: [dynamic]^Unit,
	del: ^I_Abstract_Place_Delegate,
) {
	for unit in to_place {
		units: [dynamic]^Unit
		append(&units, unit)
		result := i_abstract_place_delegate_place_units(
			del,
			units,
			t,
			.NOT_BID,
		)
		if msg, ok := result.?; ok {
			pro_logger_warn(msg)
			pro_logger_warn(
				fmt.tprintf(
					"Attempt was at: %s with: %s",
					territory_to_string(t),
					unit_to_string(unit),
				),
			)
		}
	}
	abstract_ai_move_pause()
}

// Synthetic capturing lambda from `ProPurchaseAi.doPlace`:
//
//     placeUnits(...).ifPresent(
//         message -> {
//           ProLogger.warn(message);
//           ProLogger.warn("Attempt was at: " + t + " with: " + unit);
//         });
//
// captures the local `Territory t` and `Unit unit`. Java desugars the
// captured variables as the leading parameters of the synthetic
// `lambda$doPlace$6`. The body matches the inline expansion already
// performed by `pro_purchase_ai_do_place`.
pro_purchase_ai_lambda_do_place_6 :: proc(t: ^Territory, unit: ^Unit, message: string) {
	pro_logger_warn(message)
	pro_logger_warn(
		fmt.tprintf(
			"Attempt was at: %s with: %s",
			territory_to_string(t),
			unit_to_string(unit),
		),
	)
}

// `ProPurchaseAi.findDefendersInPlaceTerritories`. For every place
// territory the player can build into, set its defending units to
// the allied units already present.
pro_purchase_ai_find_defenders_in_place_territories :: proc(
	self: ^Pro_Purchase_Ai,
	purchase_territories: map[^Territory]^Pro_Purchase_Territory,
) {
	pro_logger_info("Find defenders in possible place territories")
	for _, ppt in purchase_territories {
		for place_territory in pro_purchase_territory_get_can_place_territories(ppt) {
			t := pro_place_territory_get_territory(place_territory)
			allied_p, allied_c := matches_is_unit_allied(self.player)
			units: [dynamic]^Unit
			for u in unit_collection_get_units(territory_get_unit_collection(t)) {
				if allied_p(allied_c, u) {
					append(&units, u)
				}
			}
			pro_place_territory_set_defending_units(place_territory, units)
			pro_logger_debug(
				fmt.tprintf(
					"%s has numDefenders=%d",
					territory_to_string(t),
					len(units),
				),
			)
		}
	}
}

// `ProPurchaseAi.addUnitsToPlace(ProPlaceTerritory, Collection<Unit>)`.
// Append `units_to_place` to the place territory's pending unit list,
// then record any units the new builds consume so subsequent purchase
// validation excludes them.
pro_purchase_ai_add_units_to_place :: proc(
	self: ^Pro_Purchase_Ai,
	ppt: ^Pro_Place_Territory,
	units_to_place: [dynamic]^Unit,
) {
	if len(units_to_place) == 0 {
		return
	}
	for u in units_to_place {
		append(&ppt.place_units, u)
	}
	pro_logger_trace(
		fmt.tprintf(
			"%s, placedUnits=%v",
			territory_to_string(pro_place_territory_get_territory(ppt)),
			units_to_place,
		),
	)
	already_consumed := pro_data_get_units_to_be_consumed(self.pro_data)
	territory_units := unit_collection_get_units(
		territory_get_unit_collection(pro_place_territory_get_territory(ppt)),
	)
	candidate_units_to_consume: [dynamic]^Unit
	defer delete(candidate_units_to_consume)
	for u in territory_units {
		if _, present := already_consumed[u]; !present {
			append(&candidate_units_to_consume, u)
		}
	}
	to_consume := pro_purchase_utils_get_units_to_consume(
		self.player,
		candidate_units_to_consume,
		units_to_place,
	)
	if len(to_consume) > 0 {
		pro_logger_trace(fmt.tprintf(" toConsume=%v", to_consume))
		for u in to_consume {
			already_consumed[u] = struct {}{}
		}
	}
}

// `ProPurchaseAi.placeUnits(List<ProPlaceTerritory>, IAbstractPlaceDelegate, Predicate<Unit>)`.
// Walk each prioritized territory and ask the place delegate for the
// units that match `unit_match`; place as many of them as remaining
// production allows.
pro_purchase_ai_place_units :: proc(
	self: ^Pro_Purchase_Ai,
	prioritized_territories: [dynamic]^Pro_Place_Territory,
	place_delegate: ^I_Abstract_Place_Delegate,
	unit_match: proc(rawptr, ^Unit) -> bool,
	unit_match_ctx: rawptr,
) {
	player_units := unit_collection_get_units(game_player_get_unit_collection(self.player))
	pro_logger_info(fmt.tprintf("Place units=%v", player_units))

	for place_territory in prioritized_territories {
		t := pro_place_territory_get_territory(place_territory)
		pro_logger_debug(fmt.tprintf("Checking place for %s", territory_to_string(t)))

		matched: [dynamic]^Unit
		defer delete(matched)
		for u in player_units {
			if unit_match(unit_match_ctx, u) {
				append(&matched, u)
			}
		}
		placeable_units := i_abstract_place_delegate_get_placeable_units(
			place_delegate,
			matched,
			t,
		)
		if placeable_units_is_error(placeable_units) {
			pro_logger_trace(
				fmt.tprintf(
					"%s can't place units with error: %s",
					territory_to_string(t),
					placeable_units_get_error_message(placeable_units),
				),
			)
			continue
		}

		remaining_unit_production := placeable_units_get_max_units(placeable_units)
		if remaining_unit_production == -1 {
			remaining_unit_production = max(i32)
		}
		pro_logger_trace(
			fmt.tprintf(
				"%s, remainingUnitProduction=%d",
				territory_to_string(t),
				remaining_unit_production,
			),
		)

		units_that_can_be_placed: [dynamic]^Unit
		defer delete(units_that_can_be_placed)
		for u in placeable_units_get_units(placeable_units) {
			append(&units_that_can_be_placed, u)
		}
		place_count := remaining_unit_production
		if i32(len(units_that_can_be_placed)) < place_count {
			place_count = i32(len(units_that_can_be_placed))
		}
		units_to_place: [dynamic]^Unit
		for i in 0 ..< int(place_count) {
			append(&units_to_place, units_that_can_be_placed[i])
		}
		pro_logger_trace(
			fmt.tprintf("%s, placedUnits=%v", territory_to_string(t), units_to_place),
		)
		pro_purchase_ai_do_place(t, units_to_place, place_delegate)
	}
}

// `ProPurchaseAi.populateProductionRuleMap`. Counts how many newly
// purchased non-sea units of each purchase option's unit type are
// queued for placement and emits a corresponding production-rule
// map keyed by `ProductionRule`.
pro_purchase_ai_populate_production_rule_map :: proc(
	self: ^Pro_Purchase_Ai,
	purchase_territories: map[^Territory]^Pro_Purchase_Territory,
	purchase_options: ^Pro_Purchase_Option_Map,
) -> ^Integer_Map {
	pro_logger_info("Populate production rule map")

	not_sea_p, not_sea_c := matches_unit_is_not_sea()
	unplaced_units: [dynamic]^Unit
	defer delete(unplaced_units)
	for u in unit_collection_get_units(game_player_get_unit_collection(self.player)) {
		if not_sea_p(not_sea_c, u) {
			append(&unplaced_units, u)
		}
	}

	// All options: union of every option-list on the map (mirrors
	// ProPurchaseOptionMap.getAllOptions, which de-duplicates via a
	// HashSet).
	all_options: [dynamic]^Pro_Purchase_Option
	defer delete(all_options)
	seen: map[^Pro_Purchase_Option]struct {}
	defer delete(seen)
	option_lists: [6][dynamic]^Pro_Purchase_Option = {
		pro_purchase_option_map_get_land_options(purchase_options),
		pro_purchase_option_map_get_land_zero_move_options(purchase_options),
		pro_purchase_option_map_get_air_options(purchase_options),
		pro_purchase_option_map_get_sea_options(purchase_options),
		pro_purchase_option_map_get_aa_options(purchase_options),
		pro_purchase_option_map_get_factory_options(purchase_options),
	}
	for options in option_lists {
		for ppo in options {
			if _, ok := seen[ppo]; !ok {
				seen[ppo] = struct {}{}
				append(&all_options, ppo)
			}
		}
	}

	purchase_map := integer_map_new()
	for ppo in all_options {
		num_units: i32 = 0
		for _, t in purchase_territories {
			for ppt in pro_purchase_territory_get_can_place_territories(t) {
				for u in pro_place_territory_get_place_units(ppt) {
					if unit_get_type(u) != pro_purchase_option_get_unit_type(ppo) {
						continue
					}
					already_unplaced := false
					for existing in unplaced_units {
						if existing == u {
							already_unplaced = true
							break
						}
					}
					if already_unplaced {
						continue
					}
					num_units += 1
				}
			}
		}
		if num_units > 0 {
			num_production_rule := num_units / pro_purchase_option_get_quantity(ppo)
			integer_map_put(
				purchase_map,
				rawptr(pro_purchase_option_get_production_rule(ppo)),
				num_production_rule,
			)
			pro_logger_info(
				fmt.tprintf(
					"%d %s",
					num_production_rule,
					production_rule_to_string(pro_purchase_option_get_production_rule(ppo)),
				),
			)
		}
	}
	return purchase_map
}

// `ProPurchaseAi.shouldSaveUpForAFleet`. Returns true when the AI
// should hold its PUs in reserve to buy a fleet next turn.
pro_purchase_ai_should_save_up_for_a_fleet :: proc(
	self: ^Pro_Purchase_Ai,
	purchase_options: ^Pro_Purchase_Option_Map,
	purchase_territories: map[^Territory]^Pro_Purchase_Territory,
) -> bool {
	if pro_resource_tracker_is_empty(self.resource_tracker) ||
	   len(pro_purchase_option_map_get_sea_defense_options(purchase_options)) == 0 ||
	   len(pro_purchase_option_map_get_sea_transport_options(purchase_options)) == 0 {
		return false
	}

	purchase_keys: [dynamic]^Territory
	defer delete(purchase_keys)
	for t, _ in purchase_territories {
		append(&purchase_keys, t)
	}

	land_can_p, land_can_c := pro_matches_territory_can_potentially_move_land_units(self.player)
	enemy_p, enemy_c := matches_is_territory_enemy(self.player)
	land_p, land_c := matches_territory_is_land()
	enemy_land_pred_ctx := new(Pro_Purchase_Ai_Enemy_Land_Ctx)
	enemy_land_pred_ctx.enemy_p = enemy_p
	enemy_land_pred_ctx.enemy_c = enemy_c
	enemy_land_pred_ctx.land_p = land_p
	enemy_land_pred_ctx.land_c = land_c

	enemy_land := pro_territory_manager_find_closest_territory(
		self.territory_manager,
		purchase_keys,
		land_can_p,
		land_can_c,
		pro_purchase_ai_pred_enemy_land,
		rawptr(enemy_land_pred_ctx),
	)
	if enemy_land != nil {
		return false
	}

	place_sea_keys: [dynamic]^Territory
	defer delete(place_sea_keys)
	place_sea_seen: map[^Territory]struct {}
	defer delete(place_sea_seen)
	max_sea_units_that_can_be_placed: i32 = 0
	for _, purchase_territory in purchase_territories {
		can_produce_sea_units := false
		for place_territory in pro_purchase_territory_get_can_place_territories(purchase_territory) {
			pt := pro_place_territory_get_territory(place_territory)
			if territory_is_water(pt) {
				if _, ok := place_sea_seen[pt]; !ok {
					place_sea_seen[pt] = struct {}{}
					append(&place_sea_keys, pt)
				}
				can_produce_sea_units = true
			}
		}
		if can_produce_sea_units {
			max_sea_units_that_can_be_placed += pro_purchase_territory_get_unit_production(
				purchase_territory,
			)
		}
	}

	sea_can_p, sea_can_c := pro_matches_territory_can_move_sea_units(self.player, true)
	enemy_land_by_sea := pro_territory_manager_find_closest_territory(
		self.territory_manager,
		place_sea_keys,
		sea_can_p,
		sea_can_c,
		pro_purchase_ai_pred_enemy_land,
		rawptr(enemy_land_pred_ctx),
	)
	if enemy_land_by_sea == nil {
		return false
	}

	max_ship_cost := new(Integer_Map_Resource)
	max_ship_cost^ = make(Integer_Map_Resource)
	defer {
		delete(max_ship_cost^)
		free(max_ship_cost)
	}
	pus := resource_list_get_resource_or_throw(
		game_data_get_resource_list(game_player_get_data(self.player)),
		"PUs",
	)
	for option in pro_purchase_option_map_get_sea_defense_options(purchase_options) {
		existing_pus, _ := max_ship_cost[pus]
		if pro_purchase_option_get_cost(option) > existing_pus {
			delete(max_ship_cost^)
			max_ship_cost^ = make(Integer_Map_Resource)
			src := pro_purchase_option_get_costs(option)
			if src != nil {
				for k, v in src^ {
					max_ship_cost[k] = v
				}
			}
		}
	}
	cost_keys: [dynamic]^Resource
	defer delete(cost_keys)
	for k in max_ship_cost^ {
		append(&cost_keys, k)
	}
	for k in cost_keys {
		max_ship_cost[k] = max_ship_cost[k] * max_sea_units_that_can_be_placed
	}	if pro_resource_tracker_has_enough_amount(self.resource_tracker, max_ship_cost) {
		return false
	}
	pro_logger_info("Saving up for a fleet, since enemy territories are only reachable by sea")
	return true
}

// Combined `Matches.isTerritoryEnemy(player).and(Matches.territoryIsLand())`
// destination predicate used by `shouldSaveUpForAFleet`.
Pro_Purchase_Ai_Enemy_Land_Ctx :: struct {
	enemy_p: proc(rawptr, ^Territory) -> bool,
	enemy_c: rawptr,
	land_p:  proc(rawptr, ^Territory) -> bool,
	land_c:  rawptr,
}

pro_purchase_ai_pred_enemy_land :: proc(ctx_ptr: rawptr, t: ^Territory) -> bool {
	c := cast(^Pro_Purchase_Ai_Enemy_Land_Ctx)ctx_ptr
	return c.enemy_p(c.enemy_c, t) && c.land_p(c.land_c, t)
}

// `ProPurchaseAi.repair`. Locate damaged factories and submit a
// repair-purchase to the delegate. Mirrors the Java logic line-for-line:
// only enters the repair branch when the player has a repair frontier
// and the rule "damage from bombing applies to units (not territories)"
// is set.
pro_purchase_ai_repair :: proc(
	self: ^Pro_Purchase_Ai,
	initial_pus_remaining: i32,
	purchase_delegate: ^I_Purchase_Delegate,
	data: ^Game_Data,
	player: ^Game_Player,
) {
	pus_remaining := initial_pus_remaining
	pro_logger_info(fmt.tprintf("Repairing factories with PUsRemaining=%d", pus_remaining))

	self.data = data
	self.player = player

	owned_p, owned_c := matches_unit_is_owned_by(player)
	can_prod_p, can_prod_c := matches_unit_can_produce_units()
	infra_p, infra_c := matches_unit_is_infrastructure()

	rfact_p, rfact_c := pro_matches_territory_has_factory_and_is_not_conquered_owned_land(player)
	rfactories: [dynamic]^Territory
	defer delete(rfactories)
	for t in game_map_get_territories(game_data_get_map(data)) {
		if rfact_p(rfact_c, t) {
			append(&rfactories, t)
		}
	}

	if game_player_get_repair_frontier(player) != nil &&
	   properties_get_damage_from_bombing_done_to_units_instead_of_territories(
		   game_data_get_properties(data),
	   ) {
		pro_logger_debug("Factories can be damaged")
		can_prod_dmg_p, can_prod_dmg_c := matches_unit_can_produce_units_and_can_be_damaged()
		owned_match_p, owned_match_c := matches_territory_is_owned_and_has_owned_unit_matching(
			player,
			can_prod_dmg_p,
			can_prod_dmg_c,
		)
		dmg_p, dmg_c := matches_unit_has_taken_some_bombing_unit_damage()

		units_that_can_produce_needing_repair: map[^Unit]^Territory
		defer delete(units_that_can_produce_needing_repair)
		for fix_terr in rfactories {
			if !owned_match_p(owned_match_c, fix_terr) {
				continue
			}
			our_factories: [dynamic]^Unit
			defer delete(our_factories)
			for u in unit_collection_get_units(territory_get_unit_collection(fix_terr)) {
				if owned_p(owned_c, u) &&
				   can_prod_p(can_prod_c, u) &&
				   infra_p(infra_c, u) {
					append(&our_factories, u)
				}
			}
			optional_factory_needing_repair := unit_utils_get_biggest_producer(
				our_factories,
				fix_terr,
				player,
				false,
			)
			if optional_factory_needing_repair != nil &&
			   dmg_p(dmg_c, optional_factory_needing_repair) {
				units_that_can_produce_needing_repair[optional_factory_needing_repair] = fix_terr
			}
		}
		pro_logger_debug(
			fmt.tprintf(
				"Factories that need repaired: %v",
				units_that_can_produce_needing_repair,
			),
		)
		for repair_rule in repair_frontier_get_rules(game_player_get_repair_frontier(player)) {
			// RepairRule.getAnyResultKey() — RepairRule.results stores
			// UnitType keys; pull any one. results is ^Integer_Map keyed by
			// rawptr in the Odin port (mirrors purchase_delegate_lambda_static_0).
			any_result_key: ^Unit_Type = nil
			if repair_rule.results != nil {
				for k, _ in repair_rule.results.map_values {
					any_result_key = cast(^Unit_Type)k
					break
				}
			}
			for fix_unit, fix_terr in units_that_can_produce_needing_repair {
				if fix_unit == nil || unit_get_type(fix_unit) != any_result_key {
					continue
				}
				if !owned_match_p(owned_match_c, fix_terr) {
					continue
				}
				diff := unit_get_unit_damage(fix_unit)
				if diff > 0 {
					repair_imap := integer_map_new()
					integer_map_add(repair_imap, rawptr(repair_rule), diff)
					repair_map: map[^Unit]^Integer_Map
					defer delete(repair_map)
					repair_map[fix_unit] = repair_imap
					pus_remaining -= diff
					pro_logger_debug(
						fmt.tprintf(
							"Repairing factory=%s, damage=%d, repairRule=%s",
							unit_to_string(fix_unit),
							diff,
							repair_rule_to_string(repair_rule),
						),
					)
					i_purchase_delegate_purchase_repair(purchase_delegate, repair_map)
				}
			}
		}
	}
}

