package game

import "core:fmt"
import "core:slice"

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


// `ProPurchaseAi.purchaseAaUnits(Map<Territory, ProPurchaseTerritory>,
// List<ProPlaceTerritory>, List<ProPurchaseOption>)`. For every prioritized
// land territory under threat of strategic bombing, pick the cheapest
// AA-for-bombing unit that fits in the territory's remaining production
// budget and queue one for placement.
pro_purchase_ai_purchase_aa_units :: proc(
	self: ^Pro_Purchase_Ai,
	purchase_territories: map[^Territory]^Pro_Purchase_Territory,
	prioritized_land_territories: [dynamic]^Pro_Place_Territory,
	special_purchase_options: [dynamic]^Pro_Purchase_Option,
) {
	if pro_resource_tracker_is_empty(self.resource_tracker) {
		return
	}
	pro_logger_info(
		fmt.tprintf("Purchase AA units with resources: %v", self.resource_tracker),
	)

	enemy_attack_options := pro_territory_manager_get_enemy_attack_options(
		self.territory_manager,
	)

	for place_territory in prioritized_land_territories {
		t := pro_place_territory_get_territory(place_territory)
		pro_logger_debug(fmt.tprintf("Checking AA place for %s", territory_to_string(t)))

		max_terr := pro_other_move_options_get_max(enemy_attack_options, t)
		if max_terr == nil {
			continue
		}

		remaining_unit_production := pro_purchase_territory_get_remaining_unit_production(
			purchase_territories[t],
		)
		pro_logger_debug(
			fmt.tprintf(
				"%s, remainingUnitProduction=%d",
				territory_to_string(t),
				remaining_unit_production,
			),
		)
		if remaining_unit_production <= 0 {
			continue
		}

		// Check if the territory needs AA: an enemy strategic bomber can
		// reach it, the territory hosts a damageable producer, and there
		// is no AA-for-bombing defender already.
		bomber_p, bomber_c := matches_unit_is_strategic_bomber()
		enemy_can_bomb := false
		for u in pro_territory_get_max_units(max_terr) {
			if bomber_p(bomber_c, u) {
				enemy_can_bomb = true
				break
			}
		}
		can_prod_dmg_p, can_prod_dmg_c := matches_unit_can_produce_units_and_can_be_damaged()
		territory_can_be_bombed := false
		for u in unit_collection_get_units(territory_get_unit_collection(t)) {
			if can_prod_dmg_p(can_prod_dmg_c, u) {
				territory_can_be_bombed = true
				break
			}
		}
		aa_unit_p, aa_unit_c := matches_unit_is_aa_for_bombing_this_unit_only()
		has_aa_bombing_defense := false
		for u in unit_collection_get_units(territory_get_unit_collection(t)) {
			if aa_unit_p(aa_unit_c, u) {
				has_aa_bombing_defense = true
				break
			}
		}
		pro_logger_debug(
			fmt.tprintf(
				"%s, enemyCanBomb=%v, territoryCanBeBombed=%v, hasAABombingDefense=%v",
				territory_to_string(t),
				enemy_can_bomb,
				territory_can_be_bombed,
				has_aa_bombing_defense,
			),
		)
		if !enemy_can_bomb || !territory_can_be_bombed || has_aa_bombing_defense {
			continue
		}

		// Strip options that cost too much PUs or production for this
		// territory's remaining capacity.
		purchase_options_for_territory :=
			pro_purchase_validation_utils_find_purchase_options_for_territory_5(
				self.pro_data,
				self.player,
				special_purchase_options,
				t,
				self.is_bid,
			)
		empty_units: [dynamic]^Unit
		pro_purchase_validation_utils_remove_invalid_purchase_options(
			self.pro_data,
			self.player,
			self.start_of_turn_data,
			&purchase_options_for_territory,
			self.resource_tracker,
			remaining_unit_production,
			empty_units,
			purchase_territories,
			0,
			t,
		)
		delete(empty_units)
		if len(purchase_options_for_territory) == 0 {
			delete(purchase_options_for_territory)
			continue
		}

		// Pick the cheapest AA-for-bombing unit type that does not
		// require consuming other units to build.
		best_aa_option: ^Pro_Purchase_Option = nil
		min_cost: i32 = max(i32)
		aa_type_p, aa_type_c := matches_unit_type_is_aa_for_bombing_this_unit_only()
		consumes_p, consumes_c := matches_unit_type_consumes_units_on_creation()
		for ppo in purchase_options_for_territory {
			ut := pro_purchase_option_get_unit_type(ppo)
			if aa_type_p(aa_type_c, ut) &&
			   pro_purchase_option_get_cost(ppo) < min_cost &&
			   !consumes_p(consumes_c, ut) {
				best_aa_option = ppo
				min_cost = pro_purchase_option_get_cost(ppo)
			}
		}
		delete(purchase_options_for_territory)

		if best_aa_option == nil {
			continue
		}
		pro_logger_trace(
			fmt.tprintf(
				"Best AA unit: %s",
				default_named_get_name(
					&pro_purchase_option_get_unit_type(best_aa_option).named_attachable.default_named,
				),
			),
		)

		pro_resource_tracker_purchase(self.resource_tracker, best_aa_option)
		pro_purchase_ai_add_units_to_place(
			self,
			place_territory,
			pro_purchase_option_create_temp_units(best_aa_option),
		)
	}
}

// Synthetic less-comparator for `prioritizedLandTerritories.sort(
// Comparator.comparingDouble(ProPlaceTerritory::getStrategicValue))`
// in `ProPurchaseAi.upgradeUnitsWithRemainingPUs`.
pro_purchase_ai_lambda_upgrade_units_with_remaining_pus_strategic_less :: proc(
	a: ^Pro_Place_Territory,
	b: ^Pro_Place_Territory,
) -> bool {
	return pro_place_territory_get_strategic_value(a) <
		pro_place_territory_get_strategic_value(b)
}

// `ProPurchaseAi.upgradeUnitsWithRemainingPUs(Map<Territory, ProPurchaseTerritory>,
// ProPurchaseOptionMap)`. With any leftover PUs after all higher-priority
// purchases, walk safe land territories from least-strategic to most and
// swap each cheap previously-queued unit for the most efficient air or
// land replacement that fits the remaining budget.
pro_purchase_ai_upgrade_units_with_remaining_pus :: proc(
	self: ^Pro_Purchase_Ai,
	purchase_territories: map[^Territory]^Pro_Purchase_Territory,
	purchase_options: ^Pro_Purchase_Option_Map,
) {
	if pro_resource_tracker_is_empty(self.resource_tracker) {
		return
	}
	pro_logger_info(
		fmt.tprintf("Upgrade units with resources: %v", self.resource_tracker),
	)

	// Gather every safe (non-water, can-hold) place territory.
	prioritized_land_territories: [dynamic]^Pro_Place_Territory
	defer delete(prioritized_land_territories)
	for _, ppt in purchase_territories {
		for place_territory in pro_purchase_territory_get_can_place_territories(ppt) {
			t := pro_place_territory_get_territory(place_territory)
			if !territory_is_water(t) && pro_place_territory_is_can_hold(place_territory) {
				append(&prioritized_land_territories, place_territory)
			}
		}
	}

	// Sort by ascending strategic value (try far-away territories first).
	slice.sort_by(
		prioritized_land_territories[:],
		pro_purchase_ai_lambda_upgrade_units_with_remaining_pus_strategic_less,
	)
	pro_logger_debug(
		fmt.tprintf("Sorted land territories: %v", prioritized_land_territories),
	)

	for place_territory in prioritized_land_territories {
		t := pro_place_territory_get_territory(place_territory)
		pro_logger_debug(fmt.tprintf("Checking territory: %s", territory_to_string(t)))

		// Build the air+land candidate list for this territory.
		air_and_land_purchase_options: [dynamic]^Pro_Purchase_Option
		defer delete(air_and_land_purchase_options)
		for ppo in pro_purchase_option_map_get_air_options(purchase_options) {
			append(&air_and_land_purchase_options, ppo)
		}
		for ppo in pro_purchase_option_map_get_land_options(purchase_options) {
			append(&air_and_land_purchase_options, ppo)
		}
		purchase_options_for_territory :=
			pro_purchase_validation_utils_find_purchase_options_for_territory_5(
				self.pro_data,
				self.player,
				air_and_land_purchase_options,
				t,
				self.is_bid,
			)
		defer delete(purchase_options_for_territory)

		remaining_upgrade_units :=
			pro_purchase_territory_get_unit_production(purchase_territories[t]) / 3
		for {
			if remaining_upgrade_units <= 0 {
				break
			}

			// Find the cheapest already-placed purchase option in this
			// territory.
			min_purchase_option: ^Pro_Purchase_Option = nil
			for u in pro_place_territory_get_place_units(place_territory) {
				for ppo in air_and_land_purchase_options {
					if unit_type_equals(
						   unit_get_type(u),
						   pro_purchase_option_get_unit_type(ppo),
					   ) &&
					   (min_purchase_option == nil ||
							   pro_purchase_option_get_cost(ppo) <
								   pro_purchase_option_get_cost(min_purchase_option)) {
						min_purchase_option = ppo
					}
				}
			}
			if min_purchase_option == nil {
				break
			}

			// Re-validate the upgrade option list against a one-unit
			// budget while temporarily reserving the cheap option's cost.
			pro_resource_tracker_remove_temp_purchase(
				self.resource_tracker,
				min_purchase_option,
			)
			empty_units: [dynamic]^Unit
			pro_purchase_validation_utils_remove_invalid_purchase_options(
				self.pro_data,
				self.player,
				self.start_of_turn_data,
				&purchase_options_for_territory,
				self.resource_tracker,
				1,
				empty_units,
				purchase_territories,
				0,
				t,
			)
			delete(empty_units)
			pro_resource_tracker_clear_temp_purchases(self.resource_tracker)
			if len(purchase_options_for_territory) == 0 {
				break
			}

			// Choose the most efficient upgrade option, preferring air.
			best_upgrade_option: ^Pro_Purchase_Option = nil
			max_efficiency := pro_purchase_ai_find_upgrade_unit_efficiency(
				min_purchase_option,
				pro_place_territory_get_strategic_value(place_territory),
			)
			for ppo in purchase_options_for_territory {
				if !pro_purchase_option_is_consumes_units(ppo) &&
				   pro_purchase_option_get_cost(ppo) >
					   pro_purchase_option_get_cost(min_purchase_option) &&
				   (pro_purchase_option_is_air(ppo) ||
						   pro_place_territory_get_strategic_value(place_territory) >= 0.25 ||
						   pro_purchase_option_get_transport_cost(ppo) <=
							   pro_purchase_option_get_transport_cost(min_purchase_option)) {
					efficiency := pro_purchase_ai_find_upgrade_unit_efficiency(
						ppo,
						pro_place_territory_get_strategic_value(place_territory),
					)
					if pro_purchase_option_is_air(ppo) {
						efficiency *= 10
					}
					if pro_purchase_option_get_carrier_cost(ppo) > 0 {
						unused_local_carrier_capacity :=
							pro_transport_utils_get_unused_local_carrier_capacity(
								self.player,
								t,
								pro_place_territory_get_place_units(place_territory),
							)
						needed_fighters :=
							unused_local_carrier_capacity /
							pro_purchase_option_get_carrier_cost(ppo)
						efficiency *= f64(1 + needed_fighters)
					}
					if efficiency > max_efficiency {
						best_upgrade_option = ppo
						max_efficiency = efficiency
					}
				}
			}
			if best_upgrade_option == nil {
				for i := 0; i < len(air_and_land_purchase_options); i += 1 {
					if air_and_land_purchase_options[i] == min_purchase_option {
						ordered_remove(&air_and_land_purchase_options, i)
						break
					}
				}
				continue
			}

			// Pick the units that will actually be replaced.
			units_to_remove: [dynamic]^Unit
			num_units_to_remove := pro_purchase_option_get_quantity(min_purchase_option)
			for u in pro_place_territory_get_place_units(place_territory) {
				if num_units_to_remove <= 0 {
					break
				}
				if unit_type_equals(
					unit_get_type(u),
					pro_purchase_option_get_unit_type(min_purchase_option),
				) {
					append(&units_to_remove, u)
					num_units_to_remove -= 1
				}
			}
			if num_units_to_remove > 0 {
				delete(units_to_remove)
				for i := 0; i < len(air_and_land_purchase_options); i += 1 {
					if air_and_land_purchase_options[i] == min_purchase_option {
						ordered_remove(&air_and_land_purchase_options, i)
						break
					}
				}
				continue
			}

			// Apply the upgrade: refund the cheap option, drop the
			// removed units from the place list, and queue equivalent
			// upgraded units while the budget still covers them.
			pro_resource_tracker_remove_purchase(self.resource_tracker, min_purchase_option)
			remaining_upgrade_units -= pro_purchase_option_get_quantity(min_purchase_option)

			new_place_units: [dynamic]^Unit
			for u in place_territory.place_units {
				keep := true
				for r in units_to_remove {
					if u == r {
						keep = false
						break
					}
				}
				if keep {
					append(&new_place_units, u)
				}
			}
			delete(place_territory.place_units)
			place_territory.place_units = new_place_units

			pro_logger_trace(
				fmt.tprintf(
					"%s, removedUnits=%v",
					territory_to_string(t),
					units_to_remove,
				),
			)
			for _ in 0 ..< len(units_to_remove) {
				if pro_resource_tracker_has_enough(self.resource_tracker, best_upgrade_option) {
					pro_resource_tracker_purchase(self.resource_tracker, best_upgrade_option)
					pro_purchase_ai_add_units_to_place(
						self,
						place_territory,
						pro_purchase_option_create_temp_units(best_upgrade_option),
					)
				}
			}
			delete(units_to_remove)
		}
	}
}

// Synthetic less-comparator for `Comparator.comparingDouble(
// ProPlaceTerritory::getDefenseValue).reversed()` in
// `ProPurchaseAi.prioritizeTerritoriesToDefend`. Reversed order =
// descending → `less(a,b)` is `a > b`.
pro_purchase_ai_lambda_prioritize_territories_to_defend_defense_desc :: proc(
	a: ^Pro_Place_Territory,
	b: ^Pro_Place_Territory,
) -> bool {
	return pro_place_territory_get_defense_value(a) >
		pro_place_territory_get_defense_value(b)
}

// `ProPurchaseAi.prioritizeTerritoriesToDefend(Map<Territory, ProPurchaseTerritory>, boolean)`.
// Walks every `ProPlaceTerritory` reachable from the player's purchase
// territories, filters down to those that genuinely need defending
// (capital rule, TUV swing, leftover land units), assigns each a
// defense value from production / factory presence / capital weight /
// existing defender TUV, drops anything with a non-positive value,
// and returns the survivors sorted by defense value descending.
pro_purchase_ai_prioritize_territories_to_defend :: proc(
	self: ^Pro_Purchase_Ai,
	purchase_territories: map[^Territory]^Pro_Purchase_Territory,
	is_land: bool,
) -> [dynamic]^Pro_Place_Territory {
	pro_logger_info(
		fmt.tprintf("Prioritize territories to defend with isLand=%v", is_land),
	)

	enemy_attack_options := pro_territory_manager_get_enemy_attack_options(
		self.territory_manager,
	)

	air_p, air_c := matches_unit_is_air()
	owned_p, owned_c := matches_unit_is_owned_by(self.player)

	// Determine which territories need defended.
	need_to_defend: [dynamic]^Pro_Place_Territory
	defer delete(need_to_defend)
	need_to_defend_seen: map[^Pro_Place_Territory]struct {}
	defer delete(need_to_defend_seen)

	for _, ppt in purchase_territories {
		for place_territory in pro_purchase_territory_get_can_place_territories(ppt) {
			t := pro_place_territory_get_territory(place_territory)
			max_terr := pro_other_move_options_get_max(enemy_attack_options, t)
			if max_terr == nil ||
			   (territory_is_water(t) &&
					   len(pro_place_territory_get_defending_units(place_territory)) == 0) ||
			   (is_land && territory_is_water(t)) ||
			   (!is_land && !territory_is_water(t)) {
				continue
			}

			// Build the deduped enemy-attacker list (Java HashSet of
			// max units + amphib units).
			enemy_attacking_units: [dynamic]^Unit
			defer delete(enemy_attacking_units)
			enemy_seen: map[^Unit]struct {}
			defer delete(enemy_seen)
			for u in pro_territory_get_max_units(max_terr) {
				if _, ok := enemy_seen[u]; !ok {
					enemy_seen[u] = struct {}{}
					append(&enemy_attacking_units, u)
				}
			}
			for u in pro_territory_get_max_amphib_units(max_terr) {
				if _, ok := enemy_seen[u]; !ok {
					enemy_seen[u] = struct {}{}
					append(&enemy_attacking_units, u)
				}
			}

			bombard_units: [dynamic]^Unit
			defer delete(bombard_units)
			for u in pro_territory_get_max_bombard_units(max_terr) {
				append(&bombard_units, u)
			}

			result := pro_odds_calculator_calculate_battle_results(
				self.calc,
				self.pro_data,
				t,
				enemy_attacking_units,
				pro_place_territory_get_defending_units(place_territory),
				bombard_units,
			)
			pro_place_territory_set_min_battle_result(place_territory, result)

			hold_value: f64 = 0
			if territory_is_water(t) {
				owned_defenders: [dynamic]^Unit
				defer delete(owned_defenders)
				for u in pro_place_territory_get_defending_units(place_territory) {
					if owned_p(owned_c, u) {
						append(&owned_defenders, u)
					}
				}
				costs := new(Integer_Map_Unit_Type)
				costs.entries = pro_data_get_unit_value_map(self.pro_data)
				unit_value := tuv_utils_get_tuv(owned_defenders, costs)
				free(costs)
				hold_value = f64(unit_value) / 8.0
			}

			pro_logger_trace(
				fmt.tprintf(
					"%s TUVSwing=%v, win%%=%v, hasLandUnitRemaining=%v, holdValue=%v, enemyAttackers=%s, defenders=%s",
					territory_to_string(t),
					pro_battle_result_get_tuv_swing(result),
					pro_battle_result_get_win_percentage(result),
					pro_battle_result_is_has_land_unit_remaining(result),
					hold_value,
					pro_utils_summarize_units(enemy_attacking_units),
					pro_utils_summarize_units(
						pro_place_territory_get_defending_units(place_territory),
					),
				),
			)

			// Decide if it can't currently be held.
			is_land_and_can_only_be_attacked_by_air :=
				!territory_is_water(t) && len(enemy_attacking_units) > 0
			if is_land_and_can_only_be_attacked_by_air {
				for u in enemy_attacking_units {
					if !air_p(air_c, u) {
						is_land_and_can_only_be_attacked_by_air = false
						break
					}
				}
			}
			should_add :=
				(!territory_is_water(t) &&
					   pro_battle_result_is_has_land_unit_remaining(result)) ||
				pro_battle_result_get_tuv_swing(result) > hold_value ||
				(t == pro_data_get_my_capital(self.pro_data) &&
						!is_land_and_can_only_be_attacked_by_air &&
						pro_battle_result_get_win_percentage(result) >
							(100.0 - pro_data_get_win_percentage(self.pro_data)))
			if should_add {
				if _, present := need_to_defend_seen[place_territory]; !present {
					need_to_defend_seen[place_territory] = struct {}{}
					append(&need_to_defend, place_territory)
				}
			}
		}
	}

	// Calculate value of defending each territory.
	has_factory_p, has_factory_c :=
		pro_matches_territory_has_infra_factory_and_is_owned_land(self.player)
	for place_territory in need_to_defend {
		t := pro_place_territory_get_territory(place_territory)

		is_my_capital: i32 = 0
		if t == pro_data_get_my_capital(self.pro_data) {
			is_my_capital = 1
		}

		is_factory: i32 = 0
		if has_factory_p(has_factory_c, t) {
			is_factory = 1
		}

		production: i32 = 0
		ta := territory_attachment_get(t)
		if ta != nil {
			production = territory_attachment_get_production(ta)
		}

		costs := new(Integer_Map_Unit_Type)
		costs.entries = pro_data_get_unit_value_map(self.pro_data)
		defending_unit_value := f64(
			tuv_utils_get_tuv(
				pro_place_territory_get_defending_units(place_territory),
				costs,
			),
		)
		free(costs)
		if territory_is_water(t) {
			any_owned := false
			for u in pro_place_territory_get_defending_units(place_territory) {
				if owned_p(owned_c, u) {
					any_owned = true
					break
				}
			}
			if !any_owned {
				defending_unit_value = 0
			}
		}

		territory_value :=
			(2.0 * f64(production) + 4.0 * f64(is_factory) + 0.5 * defending_unit_value) *
			(1.0 + f64(is_factory)) *
			(1.0 + 10.0 * f64(is_my_capital))
		pro_place_territory_set_defense_value(place_territory, territory_value)
	}

	// Drop territories with non-positive defense value, then sort
	// the survivors by defense value descending.
	sorted_territories: [dynamic]^Pro_Place_Territory
	for ppt in need_to_defend {
		if !pro_purchase_ai_lambda_prioritize_territories_to_defend_1(ppt) {
			append(&sorted_territories, ppt)
		}
	}
	slice.sort_by(
		sorted_territories[:],
		pro_purchase_ai_lambda_prioritize_territories_to_defend_defense_desc,
	)
	for place_territory in sorted_territories {
		pro_logger_debug(
			fmt.tprintf(
				"%v defenseValue=%v",
				place_territory,
				pro_place_territory_get_defense_value(place_territory),
			),
		)
	}
	return sorted_territories
}

// Synthetic less-comparator for `Comparator.comparingDouble(
// ProPlaceTerritory::getStrategicValue).reversed()` in the first
// loop of `ProPurchaseAi.purchaseUnitsWithRemainingProduction`.
pro_purchase_ai_lambda_purchase_units_with_remaining_production_strategic_desc :: proc(
	a: ^Pro_Place_Territory,
	b: ^Pro_Place_Territory,
) -> bool {
	return pro_place_territory_get_strategic_value(a) >
		pro_place_territory_get_strategic_value(b)
}

// Synthetic less-comparator for `Comparator.comparingDouble(
// ProPlaceTerritory::getDefenseValue).reversed()` in the second
// loop of `ProPurchaseAi.purchaseUnitsWithRemainingProduction`.
pro_purchase_ai_lambda_purchase_units_with_remaining_production_defense_desc :: proc(
	a: ^Pro_Place_Territory,
	b: ^Pro_Place_Territory,
) -> bool {
	return pro_place_territory_get_defense_value(a) >
		pro_place_territory_get_defense_value(b)
}

// `ProPurchaseAi.purchaseUnitsWithRemainingProduction(
//     Map<Territory, ProPurchaseTerritory>, List<ProPurchaseOption>,
//     List<ProPurchaseOption>)`.
// Two passes: (1) for safe (can-hold) land territories with leftover
// production, queue the most efficient long-range attack unit
// (preferring air) until the budget or the option list is exhausted;
// (2) for unsafe (can't-hold) land territories, sample defense units
// weighted by `cost^2 * defenseEfficiency` until exhausted.
pro_purchase_ai_purchase_units_with_remaining_production :: proc(
	self: ^Pro_Purchase_Ai,
	purchase_territories: map[^Territory]^Pro_Purchase_Territory,
	land_purchase_options: [dynamic]^Pro_Purchase_Option,
	air_purchase_options: [dynamic]^Pro_Purchase_Option,
) {
	if pro_resource_tracker_is_empty(self.resource_tracker) {
		return
	}
	pro_logger_info(
		fmt.tprintf(
			"Purchase units in territories with remaining production with resources: %v",
			self.resource_tracker,
		),
	)

	// Split safe vs. can't-hold land place territories that still
	// have unit production budget.
	prioritized_land_territories: [dynamic]^Pro_Place_Territory
	defer delete(prioritized_land_territories)
	prioritized_cant_hold_land_territories: [dynamic]^Pro_Place_Territory
	defer delete(prioritized_cant_hold_land_territories)
	for _, ppt in purchase_territories {
		for place_territory in pro_purchase_territory_get_can_place_territories(ppt) {
			t := pro_place_territory_get_territory(place_territory)
			pt_for_t, has_pt := purchase_territories[t]
			if !has_pt {
				continue
			}
			if !territory_is_water(t) &&
			   pro_place_territory_is_can_hold(place_territory) &&
			   pro_purchase_territory_get_remaining_unit_production(pt_for_t) > 0 {
				append(&prioritized_land_territories, place_territory)
			} else if !territory_is_water(t) &&
			   pro_purchase_territory_get_remaining_unit_production(pt_for_t) > 0 {
				append(&prioritized_cant_hold_land_territories, place_territory)
			}
		}
	}

	slice.sort_by(
		prioritized_land_territories[:],
		pro_purchase_ai_lambda_purchase_units_with_remaining_production_strategic_desc,
	)
	pro_logger_debug(
		fmt.tprintf(
			"Sorted land territories with remaining production: %v",
			prioritized_land_territories,
		),
	)

	// Pass 1: long-range attack units in safe territories.
	for place_territory in prioritized_land_territories {
		t := pro_place_territory_get_territory(place_territory)
		pro_logger_debug(fmt.tprintf("Checking territory: %v", t))

		air_and_land_purchase_options: [dynamic]^Pro_Purchase_Option
		defer delete(air_and_land_purchase_options)
		for ppo in air_purchase_options {
			append(&air_and_land_purchase_options, ppo)
		}
		for ppo in land_purchase_options {
			append(&air_and_land_purchase_options, ppo)
		}
		purchase_options_for_territory :=
			pro_purchase_validation_utils_find_purchase_options_for_territory_5(
				self.pro_data,
				self.player,
				air_and_land_purchase_options,
				t,
				self.is_bid,
			)
		defer delete(purchase_options_for_territory)

		remaining_unit_production :=
			pro_purchase_territory_get_remaining_unit_production(purchase_territories[t])
		for {
			empty_units: [dynamic]^Unit
			pro_purchase_validation_utils_remove_invalid_purchase_options(
				self.pro_data,
				self.player,
				self.start_of_turn_data,
				&purchase_options_for_territory,
				self.resource_tracker,
				remaining_unit_production,
				empty_units,
				purchase_territories,
				0,
				t,
			)
			delete(empty_units)
			if len(purchase_options_for_territory) == 0 {
				break
			}

			// Pick the option with the highest
			// attackEfficiency * movement / quantity, with air x10.
			best_attack_option: ^Pro_Purchase_Option = nil
			max_attack_efficiency: f64 = 0
			for ppo in purchase_options_for_territory {
				attack_efficiency :=
					pro_purchase_option_get_attack_efficiency(ppo) *
					f64(pro_purchase_option_get_movement(ppo)) /
					f64(pro_purchase_option_get_quantity(ppo))
				if pro_purchase_option_is_air(ppo) {
					attack_efficiency *= 10
				}
				if attack_efficiency > max_attack_efficiency {
					best_attack_option = ppo
					max_attack_efficiency = attack_efficiency
				}
			}
			if best_attack_option == nil {
				break
			}

			pro_resource_tracker_purchase(self.resource_tracker, best_attack_option)
			remaining_unit_production -=
				pro_purchase_option_get_quantity(best_attack_option)
			pro_purchase_ai_add_units_to_place(
				self,
				place_territory,
				pro_purchase_option_create_temp_units(best_attack_option),
			)
		}
	}

	slice.sort_by(
		prioritized_cant_hold_land_territories[:],
		pro_purchase_ai_lambda_purchase_units_with_remaining_production_defense_desc,
	)
	pro_logger_debug(
		fmt.tprintf(
			"Sorted can't hold land territories with remaining production: %v",
			prioritized_cant_hold_land_territories,
		),
	)

	// Pass 2: defense units in can't-hold territories.
	owned_p, owned_c := matches_unit_is_owned_by(self.player)
	for place_territory in prioritized_cant_hold_land_territories {
		t := pro_place_territory_get_territory(place_territory)
		pro_logger_debug(fmt.tprintf("Checking territory: %v", t))

		owned_local_units: [dynamic]^Unit
		defer delete(owned_local_units)
		for u in unit_collection_get_units(territory_get_unit_collection(t)) {
			if owned_p(owned_c, u) {
				append(&owned_local_units, u)
			}
		}

		air_and_land_purchase_options: [dynamic]^Pro_Purchase_Option
		defer delete(air_and_land_purchase_options)
		for ppo in air_purchase_options {
			append(&air_and_land_purchase_options, ppo)
		}
		for ppo in land_purchase_options {
			append(&air_and_land_purchase_options, ppo)
		}
		purchase_options_for_territory :=
			pro_purchase_validation_utils_find_purchase_options_for_territory_5(
				self.pro_data,
				self.player,
				air_and_land_purchase_options,
				t,
				self.is_bid,
			)
		defer delete(purchase_options_for_territory)

		remaining_unit_production :=
			pro_purchase_territory_get_remaining_unit_production(purchase_territories[t])
		for {
			empty_units: [dynamic]^Unit
			pro_purchase_validation_utils_remove_invalid_purchase_options(
				self.pro_data,
				self.player,
				self.start_of_turn_data,
				&purchase_options_for_territory,
				self.resource_tracker,
				remaining_unit_production,
				empty_units,
				purchase_territories,
				0,
				t,
			)
			delete(empty_units)

			defense_efficiencies: map[^Pro_Purchase_Option]f64
			defer delete(defense_efficiencies)
			for ppo in purchase_options_for_territory {
				cost := f64(pro_purchase_option_get_cost(ppo))
				defense_efficiencies[ppo] =
					cost * cost *
					pro_purchase_option_get_defense_efficiency_with_args(
						ppo,
						1,
						self.data,
						owned_local_units,
						pro_place_territory_get_place_units(place_territory),
					)
			}

			selected_option := pro_purchase_utils_randomize_purchase_option(
				defense_efficiencies,
				"Defense",
			)
			if selected_option == nil {
				break
			}

			pro_resource_tracker_purchase(self.resource_tracker, selected_option)
			remaining_unit_production -= pro_purchase_option_get_quantity(selected_option)
			pro_purchase_ai_add_units_to_place(
				self,
				place_territory,
				pro_purchase_option_create_temp_units(selected_option),
			)
		}
	}
}

// `ProPurchaseAi.placeDefenders(Map<Territory, ProPurchaseTerritory>,
// List<ProPlaceTerritory>, IAbstractPlaceDelegate)`. For every
// prioritized territory, asks the place delegate for the
// non-construction units that can be placed there, then commits
// units one-by-one until the battle result is acceptable. If the
// final result still doesn't justify the defense, the territory is
// flagged as unable to hold via `setCantHoldPlaceTerritory`.
pro_purchase_ai_place_defenders :: proc(
	self: ^Pro_Purchase_Ai,
	place_non_construction_territories: map[^Territory]^Pro_Purchase_Territory,
	need_to_defend_territories: [dynamic]^Pro_Place_Territory,
	place_delegate: ^I_Abstract_Place_Delegate,
) {
	player_units := unit_collection_get_units(
		game_player_get_unit_collection(self.player),
	)
	pro_logger_info(fmt.tprintf("Place defenders with units=%v", player_units))

	enemy_attack_options := pro_territory_manager_get_enemy_attack_options(
		self.territory_manager,
	)

	not_construction_p, not_construction_c := matches_unit_is_not_construction()

	for place_territory in need_to_defend_territories {
		t := pro_place_territory_get_territory(place_territory)
		max_terr := pro_other_move_options_get_max(enemy_attack_options, t)
		max_units_summary, max_amphib_summary: string
		if max_terr != nil {
			max_units_list: [dynamic]^Unit
			defer delete(max_units_list)
			for u in pro_territory_get_max_units(max_terr) {
				append(&max_units_list, u)
			}
			max_units_summary = pro_utils_summarize_units(max_units_list)
			max_amphib_summary = pro_utils_summarize_units(
				pro_territory_get_max_amphib_units(max_terr),
			)
		}
		pro_logger_debug(
			fmt.tprintf(
				"Placing defenders for %s, enemyAttackers=%s, amphibEnemyAttackers=%s, defenders=%s",
				territory_to_string(t),
				max_units_summary,
				max_amphib_summary,
				pro_utils_summarize_units(
					pro_place_territory_get_defending_units(place_territory),
				),
			),
		)

		// player.getMatches(Matches.unitIsNotConstruction()).
		non_construction_player_units: [dynamic]^Unit
		defer delete(non_construction_player_units)
		for u in player_units {
			if not_construction_p(not_construction_c, u) {
				append(&non_construction_player_units, u)
			}
		}

		placeable_units := i_abstract_place_delegate_get_placeable_units(
			place_delegate,
			non_construction_player_units,
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

		// Place defenders one-at-a-time until the territory can be
		// held (or we run out of units).
		units_that_can_be_placed: [dynamic]^Unit
		defer delete(units_that_can_be_placed)
		for u in placeable_units_get_units(placeable_units) {
			append(&units_that_can_be_placed, u)
		}
		land_place_count := remaining_unit_production
		if i32(len(units_that_can_be_placed)) < land_place_count {
			land_place_count = i32(len(units_that_can_be_placed))
		}
		units_to_place: [dynamic]^Unit
		final_result := pro_battle_result_new_empty()
		for i in 0 ..< int(land_place_count) {
			append(&units_to_place, units_that_can_be_placed[i])

			// Build deduped enemy-attacker list (max units + amphib).
			enemy_attacking_units: [dynamic]^Unit
			defer delete(enemy_attacking_units)
			enemy_seen: map[^Unit]struct {}
			defer delete(enemy_seen)
			if max_terr != nil {
				for u in pro_territory_get_max_units(max_terr) {
					if _, ok := enemy_seen[u]; !ok {
						enemy_seen[u] = struct {}{}
						append(&enemy_attacking_units, u)
					}
				}
				for u in pro_territory_get_max_amphib_units(max_terr) {
					if _, ok := enemy_seen[u]; !ok {
						enemy_seen[u] = struct {}{}
						append(&enemy_attacking_units, u)
					}
				}
			}

			defenders: [dynamic]^Unit
			defer delete(defenders)
			for u in pro_place_territory_get_defending_units(place_territory) {
				append(&defenders, u)
			}
			for u in units_to_place {
				append(&defenders, u)
			}

			bombard_units: [dynamic]^Unit
			defer delete(bombard_units)
			if max_terr != nil {
				for u in pro_territory_get_max_bombard_units(max_terr) {
					append(&bombard_units, u)
				}
			}

			final_result = pro_odds_calculator_calculate_battle_results(
				self.calc,
				self.pro_data,
				t,
				enemy_attacking_units,
				defenders,
				bombard_units,
			)

			my_capital := pro_data_get_my_capital(self.pro_data)
			if (t != my_capital &&
				   !pro_battle_result_is_has_land_unit_remaining(final_result) &&
				   pro_battle_result_get_tuv_swing(final_result) <= 0) ||
			   (t == my_capital &&
					   pro_battle_result_get_win_percentage(final_result) <
						   (100.0 - pro_data_get_win_percentage(self.pro_data)) &&
					   pro_battle_result_get_tuv_swing(final_result) <= 0) {
				break
			}
		}

		// Decide whether to commit the placement or flag as unholdable.
		min_battle_result := pro_place_territory_get_min_battle_result(place_territory)
		min_tuv_swing: f64 = 0
		if min_battle_result != nil {
			min_tuv_swing = pro_battle_result_get_tuv_swing(min_battle_result)
		}
		my_capital := pro_data_get_my_capital(self.pro_data)
		if !pro_battle_result_is_has_land_unit_remaining(final_result) ||
		   pro_battle_result_get_tuv_swing(final_result) < min_tuv_swing ||
		   t == my_capital {
			pro_logger_trace(
				fmt.tprintf(
					"%s, placedUnits=%v, TUVSwing=%v",
					territory_to_string(t),
					units_to_place,
					pro_battle_result_get_tuv_swing(final_result),
				),
			)
			pro_purchase_ai_do_place(t, units_to_place, place_delegate)
		} else {
			pro_purchase_ai_set_cant_hold_place_territory(
				self,
				place_territory,
				place_non_construction_territories,
			)
			pro_logger_trace(
				fmt.tprintf(
					"%s, unable to defend with placedUnits=%v, TUVSwing=%v, minTUVSwing=%v",
					territory_to_string(t),
					units_to_place,
					pro_battle_result_get_tuv_swing(final_result),
					min_tuv_swing,
				),
			)
		}
		delete(units_to_place)
	}
}

// Synthetic capturing lambda from `ProPurchaseAi.purchaseFactory`:
//
//     purchaseFactoryTerritories.removeIf(
//         t -> !ProBattleUtils.territoryHasLocalLandSuperiority(
//             proData, t, ProBattleUtils.MEDIUM_RANGE, player, purchaseTerritories));
//
// The Java lambda captures the enclosing `purchaseTerritories` map; `proData`
// and `player` are fields of `ProPurchaseAi`, so they are accessed through the
// owner pointer here.
pro_purchase_ai_lambda_purchase_factory_2 :: proc(
	this:                 ^Pro_Purchase_Ai,
	purchase_territories: map[^Territory]^Pro_Purchase_Territory,
	t:                    ^Territory,
) -> bool {
	return !pro_battle_utils_territory_has_local_land_superiority(
		this.pro_data, t, 3, this.player, purchase_territories,
	)
}

// `ProPurchaseAi.prioritizeLandTerritories(Map<Territory, ProPurchaseTerritory>)`.
// Build the ordered list of `Pro_Place_Territory`s where land units should be
// purchased: keep only land place territories with strategic value >= 1 that
// can be held, then prefer those that have an enemy neighbor, are surrounded
// by 3+ potential-enemy-owned land tiles within range 9, or fail the
// short-range local land superiority check. Sort the survivors by descending
// strategic value (matching Java's
// `Comparator.comparingDouble(ProPlaceTerritory::getStrategicValue).reversed()`).
pro_purchase_ai_prioritize_land_territories :: proc(
	self:                 ^Pro_Purchase_Ai,
	purchase_territories: map[^Territory]^Pro_Purchase_Territory,
) -> [dynamic]^Pro_Place_Territory {
	pro_logger_info("Prioritize land territories to place")

	prioritized_land_territories: [dynamic]^Pro_Place_Territory
	for _, ppt in purchase_territories {
		for place_territory in ppt.can_place_territories {
			t := pro_place_territory_get_territory(place_territory)
			if territory_is_water(t) {
				continue
			}
			if pro_place_territory_get_strategic_value(place_territory) < 1 {
				continue
			}
			if !pro_place_territory_is_can_hold(place_territory) {
				continue
			}

			gm := game_data_get_map(self.data)

			enemy_pred, enemy_ctx := pro_matches_territory_is_enemy_land(self.player)
			enemy_neighbors := game_map_get_neighbors_predicate(
				gm, t, enemy_pred, enemy_ctx,
			)
			has_enemy_neighbors := len(enemy_neighbors) > 0
			delete(enemy_neighbors)

			land_pred, land_ctx :=
				pro_matches_territory_can_potentially_move_land_units(self.player)
			nearby_land_territories := game_map_get_neighbors_distance_predicate(
				gm, t, 9, land_pred, land_ctx,
			)
			potential_enemies := pro_utils_get_potential_enemy_players(self.player)
			owned_pred, owned_ctx := matches_is_territory_owned_by_any_of(potential_enemies)
			num_nearby_enemy_territories: i32 = 0
			for n in nearby_land_territories {
				if owned_pred(owned_ctx, n) {
					num_nearby_enemy_territories += 1
				}
			}
			delete(nearby_land_territories)

			has_local_land_superiority :=
				pro_battle_utils_territory_has_local_land_superiority_4(
					self.pro_data, t, 2, self.player,
				)

			if has_enemy_neighbors ||
			   num_nearby_enemy_territories >= 3 ||
			   !has_local_land_superiority {
				append(&prioritized_land_territories, place_territory)
			}
		}
	}

	slice.sort_by(
		prioritized_land_territories[:],
		pro_purchase_ai_lambda_purchase_units_with_remaining_production_strategic_desc,
	)
	for place_territory in prioritized_land_territories {
		pro_logger_debug(
			fmt.tprintf(
				"%s strategicValue=%v",
				pro_place_territory_to_string(place_territory),
				pro_place_territory_get_strategic_value(place_territory),
			),
		)
	}
	return prioritized_land_territories
}

// `ProPurchaseAi.prioritizeSeaTerritories(Map<Territory, ProPurchaseTerritory>)`.
// Collect every water `Pro_Place_Territory` with positive strategic value
// that can be held, score each by combining transport count, defender count,
// and the need for additional defenders (driven by the enemy attack
// estimate and the territory-local naval superiority check), overwrite the
// place territory's strategic value with that score, then return the list
// sorted by descending strategic value.
pro_purchase_ai_prioritize_sea_territories :: proc(
	self:                 ^Pro_Purchase_Ai,
	purchase_territories: map[^Territory]^Pro_Purchase_Territory,
) -> [dynamic]^Pro_Place_Territory {
	pro_logger_info("Prioritize sea territories")

	enemy_attack_options := pro_territory_manager_get_enemy_attack_options(
		self.territory_manager,
	)

	sea_place_territories := make(map[^Pro_Place_Territory]struct{})
	defer delete(sea_place_territories)
	for _, ppt in purchase_territories {
		for place_territory in ppt.can_place_territories {
			t := pro_place_territory_get_territory(place_territory)
			if territory_is_water(t) &&
			   pro_place_territory_get_strategic_value(place_territory) > 0 &&
			   pro_place_territory_is_can_hold(place_territory) {
				sea_place_territories[place_territory] = struct{}{}
			}
		}
	}

	pro_logger_debug("Determine sea place value:")
	owned_pred, owned_ctx := matches_unit_is_owned_by(self.player)
	transport_pred, transport_ctx := matches_unit_is_sea_transport()
	not_transport_pred, not_transport_ctx := matches_unit_is_not_sea_transport()
	for place_territory in sea_place_territories {
		t := pro_place_territory_get_territory(place_territory)

		// Find number of local naval units.
		units: [dynamic]^Unit
		for u in pro_place_territory_get_defending_units(place_territory) {
			append(&units, u)
		}
		place_units := pro_purchase_utils_get_place_units(t, purchase_territories)
		for u in place_units {
			append(&units, u)
		}
		delete(place_units)

		num_my_transports: i32 = 0
		for u in units {
			if owned_pred(owned_ctx, u) && transport_pred(transport_ctx, u) {
				num_my_transports += 1
			}
		}
		num_sea_defenders: i32 = 0
		for u in units {
			if not_transport_pred(not_transport_ctx, u) {
				num_sea_defenders += 1
			}
		}

		// Determine needed defense strength.
		need_defenders: i32 = 0
		max_attack := pro_other_move_options_get_max(enemy_attack_options, t)
		if max_attack != nil {
			max_units_list: [dynamic]^Unit
			for u, _ in pro_territory_get_max_units(max_attack) {
				append(&max_units_list, u)
			}
			strength_difference := pro_battle_utils_estimate_strength_difference(
				t, max_units_list, units,
			)
			delete(max_units_list)
			if strength_difference > 50 {
				need_defenders = 1
			}
		}
		empty_purchase := make(map[^Territory]^Pro_Purchase_Territory)
		empty_units: [dynamic]^Unit
		has_local_naval_superiority :=
			pro_battle_utils_territory_has_local_naval_superiority(
				self.pro_data,
				self.calc,
				t,
				self.player,
				empty_purchase,
				empty_units,
			)
		delete(empty_purchase)
		delete(empty_units)
		if !has_local_naval_superiority {
			need_defenders = 1
		}

		// Calculate sea value for prioritization.
		territory_value :=
			pro_place_territory_get_strategic_value(place_territory) *
			(1.0 + f64(num_my_transports) + 0.1 * f64(num_sea_defenders)) /
			(1.0 + 3.0 * f64(need_defenders))
		pro_logger_debug(
			fmt.tprintf(
				"%s, value=%v, strategicValue=%v, numMyTransports=%v, numSeaDefenders=%v, needDefenders=%v",
				territory_to_string(t),
				territory_value,
				pro_place_territory_get_strategic_value(place_territory),
				num_my_transports,
				num_sea_defenders,
				need_defenders,
			),
		)
		pro_place_territory_set_strategic_value(place_territory, territory_value)

		delete(units)
	}

	// Sort territories by value (descending).
	sorted_territories: [dynamic]^Pro_Place_Territory
	for k in sea_place_territories {
		append(&sorted_territories, k)
	}
	slice.sort_by(
		sorted_territories[:],
		pro_purchase_ai_lambda_purchase_units_with_remaining_production_strategic_desc,
	)
	pro_logger_debug("Sorted sea territories:")
	for place_territory in sorted_territories {
		pro_logger_debug(
			fmt.tprintf(
				"%s value=%v",
				pro_place_territory_to_string(place_territory),
				pro_place_territory_get_strategic_value(place_territory),
			),
		)
	}
	return sorted_territories
}

// `ProPurchaseAi.addUnitsToPlaceTerritory(ProPlaceTerritory, List<Unit>,
// Map<Territory, ProPurchaseTerritory>)`. For each purchase territory whose
// `can_place_territories` contains `place_territory` and that still has
// remaining unit production, place every construction unit (which does not
// consume production) and then up to `remaining_unit_production` of the
// non-construction units. Mirrors Java's mutation of `units_to_place`: the
// caller's list shrinks as units are placed. The pointer parameter mirrors
// Java's pass-by-reference semantics on a `final List<Unit>`.
pro_purchase_ai_add_units_to_place_territory :: proc(
	self:                 ^Pro_Purchase_Ai,
	place_territory:      ^Pro_Place_Territory,
	units_to_place:       ^[dynamic]^Unit,
	purchase_territories: map[^Territory]^Pro_Purchase_Territory,
) {
	for _, purchase_territory in purchase_territories {
		for ppt in purchase_territory.can_place_territories {
			if !pro_place_territory_equals(place_territory, ppt) {
				continue
			}
			if pro_purchase_territory_get_remaining_unit_production(purchase_territory) <= 0 {
				continue
			}
			if !pro_purchase_validation_utils_can_units_be_placed(
				self.pro_data,
				units_to_place^,
				self.player,
				pro_place_territory_get_territory(ppt),
				pro_purchase_territory_get_territory(purchase_territory),
				self.is_bid,
			) {
				continue
			}

			// Split into constructions vs the rest, dropping constructions
			// from `units_to_place` (Java: unitsToPlace.removeAll(constructions)).
			construction_pred, construction_ctx := matches_unit_is_construction()
			constructions: [dynamic]^Unit
			remaining: [dynamic]^Unit
			for u in units_to_place^ {
				if construction_pred(construction_ctx, u) {
					append(&constructions, u)
				} else {
					append(&remaining, u)
				}
			}
			delete(units_to_place^)
			units_to_place^ = remaining
			pro_purchase_ai_add_units_to_place(self, ppt, constructions)
			delete(constructions)

			// Place at most `remaining_unit_production` of the non-construction
			// units, then drop them from `units_to_place` (Java: subList +
			// units.clear()).
			rem_prod := pro_purchase_territory_get_remaining_unit_production(
				purchase_territory,
			)
			num_units := rem_prod
			if i32(len(units_to_place^)) < num_units {
				num_units = i32(len(units_to_place^))
			}
			placed: [dynamic]^Unit
			for i in 0 ..< int(num_units) {
				append(&placed, units_to_place[i])
			}
			pro_purchase_ai_add_units_to_place(self, ppt, placed)
			delete(placed)

			leftover: [dynamic]^Unit
			for i in int(num_units) ..< len(units_to_place^) {
				append(&leftover, units_to_place[i])
			}
			delete(units_to_place^)
			units_to_place^ = leftover
		}
	}
}

// `ProPurchaseAi.place(Map<Territory, ProPurchaseTerritory>, IAbstractPlaceDelegate)`.
// Drives the entire placement phase: place every unit recorded by the
// purchase phase (land first, then sea), then if the player still has
// units in hand (e.g. WW2v3 China), prioritize-then-place them.
pro_purchase_ai_place :: proc(
	self:                 ^Pro_Purchase_Ai,
	purchase_territories: map[^Territory]^Pro_Purchase_Territory,
	place_delegate:       ^I_Abstract_Place_Delegate,
) {
	pro_logger_info("Starting place phase")

	self.data = pro_data_get_data(self.pro_data)
	self.player = pro_data_get_player(self.pro_data)
	self.territory_manager = pro_territory_manager_new(self.calc, self.pro_data)

	// Clear list of units to be consumed, since we only used for movement
	// phase. Additionally, we omit units in this list when checking for
	// eligible units to consume, so we need to clear it before we actually
	// do placement.
	clear(&self.pro_data.units_to_be_consumed)

	// Place all units calculated during purchase phase (land then sea to
	// reduce failed placements). The `purchase_territories` map may be
	// empty, but the iteration handles that naturally.
	for pass in 0 ..< 2 {
		want_water := pass == 1
		for _, t in purchase_territories {
			for ppt in pro_purchase_territory_get_can_place_territories(t) {
				ppt_terr := pro_place_territory_get_territory(ppt)
				if territory_is_water(ppt_terr) != want_water {
					continue
				}
				units_to_place: [dynamic]^Unit
				for place_unit in pro_place_territory_get_place_units(ppt) {
					placed_type := unit_get_type(place_unit)
					for my_unit in unit_collection_get_units(
						game_player_get_unit_collection(self.player),
					) {
						if unit_get_type(my_unit) != placed_type {
							continue
						}
						already := false
						for u in units_to_place {
							if u == my_unit {
								already = true
								break
							}
						}
						if !already {
							append(&units_to_place, my_unit)
							break
						}
					}
				}
				target := game_map_get_territory_or_null(
					game_data_get_map(self.data),
					territory_get_name(ppt_terr),
				)
				pro_purchase_ai_do_place(target, units_to_place, place_delegate)
				pro_logger_debug(
					fmt.tprintf(
						"%s placed units: %v",
						territory_to_string(ppt_terr),
						units_to_place,
					),
				)
			}
		}
	}

	// Place remaining units (currently only implemented to handle land
	// units, ex. WW2v3 China)
	if unit_collection_is_empty(game_player_get_unit_collection(self.player)) {
		return
	}

	pro_logger_debug(
		fmt.tprintf(
			"Remaining units to place: %v",
			unit_collection_get_units(game_player_get_unit_collection(self.player)),
		),
	)

	// Find all place territories
	place_non_construction_territories :=
		pro_purchase_utils_find_purchase_territories(self.pro_data, self.player)
	place_territories: map[^Territory]struct {}
	for _, t in place_non_construction_territories {
		for ppt in pro_purchase_territory_get_can_place_territories(t) {
			place_territories[pro_place_territory_get_territory(ppt)] = {}
		}
	}

	// Determine max enemy attack units and current allied defenders
	empty_cleared: [dynamic]^Territory
	pt_list: [dynamic]^Territory
	for pt, _ in place_territories {
		append(&pt_list, pt)
	}
	pro_territory_manager_populate_enemy_attack_options(
		self.territory_manager,
		empty_cleared,
		pt_list,
	)
	delete(empty_cleared)
	delete(pt_list)
	pro_purchase_ai_find_defenders_in_place_territories(
		self,
		place_non_construction_territories,
	)

	// Prioritize land territories that need defended and place additional
	// defenders.
	need_to_defend_land_territories :=
		pro_purchase_ai_prioritize_territories_to_defend(
			self,
			place_non_construction_territories,
			true,
		)
	pro_purchase_ai_place_defenders(
		self,
		place_non_construction_territories,
		need_to_defend_land_territories,
		place_delegate,
	)

	// Prioritize sea territories that need defended and place additional
	// defenders.
	need_to_defend_sea_territories :=
		pro_purchase_ai_prioritize_territories_to_defend(
			self,
			place_non_construction_territories,
			false,
		)
	pro_purchase_ai_place_defenders(
		self,
		place_non_construction_territories,
		need_to_defend_sea_territories,
		place_delegate,
	)

	// Find strategic value for each territory
	pro_logger_info("Find strategic value for place territories")
	territories_to_check: map[^Territory]struct {}
	for _, t in place_non_construction_territories {
		for ppt in pro_purchase_territory_get_can_place_territories(t) {
			territories_to_check[pro_place_territory_get_territory(ppt)] = {}
		}
	}
	empty_tt: [dynamic]^Territory
	empty_ta: [dynamic]^Territory
	territory_value_map := pro_territory_value_utils_find_territory_values(
		self.pro_data,
		self.player,
		empty_tt,
		empty_ta,
		territories_to_check,
	)
	delete(empty_tt)
	delete(empty_ta)
	delete(territories_to_check)
	for _, t in place_non_construction_territories {
		for ppt in pro_purchase_territory_get_can_place_territories(t) {
			val := territory_value_map[pro_place_territory_get_territory(ppt)]
			pro_place_territory_set_strategic_value(ppt, val)
			pro_logger_debug(
				fmt.tprintf(
					"%s, strategicValue=%v",
					territory_to_string(pro_place_territory_get_territory(ppt)),
					val,
				),
			)
		}
	}
	delete(territory_value_map)

	// Prioritize place territories
	prioritized_territories := pro_purchase_ai_prioritize_land_territories(
		self,
		place_non_construction_territories,
	)
	for _, ppt in place_non_construction_territories {
		for place_territory in pro_purchase_territory_get_can_place_territories(ppt) {
			already := false
			for existing in prioritized_territories {
				if existing == place_territory {
					already = true
					break
				}
			}
			if !already {
				append(&prioritized_territories, place_territory)
			}
		}
	}

	// Place regular then isConstruction units (placeDelegate.getPlaceableUnits
	// doesn't handle combined).
	not_construction_p, not_construction_c := matches_unit_is_not_construction()
	pro_purchase_ai_place_units(
		self,
		prioritized_territories,
		place_delegate,
		not_construction_p,
		not_construction_c,
	)
	construction_p, construction_c := matches_unit_is_construction()
	pro_purchase_ai_place_units(
		self,
		prioritized_territories,
		place_delegate,
		construction_p,
		construction_c,
	)

	self.territory_manager = nil
}

// `ProPurchaseAi.purchaseDefenders(Map, List, List, List, List, boolean)`.
// For each prioritized place territory under threat, queue defenders
// from the territory's purchase territories until either the territory
// is safely held or no more options exist; commit the temp purchases
// only if the result was acceptable.
pro_purchase_ai_purchase_defenders :: proc(
	self:                            ^Pro_Purchase_Ai,
	purchase_territories:            map[^Territory]^Pro_Purchase_Territory,
	need_to_defend_territories:      [dynamic]^Pro_Place_Territory,
	defense_purchase_options:        [dynamic]^Pro_Purchase_Option,
	zero_move_defense_purchase_options: [dynamic]^Pro_Purchase_Option,
	air_purchase_options:            [dynamic]^Pro_Purchase_Option,
	is_land:                         bool,
) {
	if pro_resource_tracker_is_empty(self.resource_tracker) {
		return
	}
	pro_logger_info(
		fmt.tprintf(
			"Purchase defenders with resources: %v, isLand=%v",
			self.resource_tracker,
			is_land,
		),
	)

	enemy_attack_options := pro_territory_manager_get_enemy_attack_options(
		self.territory_manager,
	)

	for place_territory in need_to_defend_territories {
		t := pro_place_territory_get_territory(place_territory)
		max_terr := pro_other_move_options_get_max(enemy_attack_options, t)
		max_units_set := pro_territory_get_max_units(max_terr)
		max_units_list: [dynamic]^Unit
		for u, _ in max_units_set {
			append(&max_units_list, u)
		}
		max_amphib_list := pro_territory_get_max_amphib_units(max_terr)
		pro_logger_debug(
			fmt.tprintf(
				"Purchasing defenders for %s, enemyAttackers=%s, amphibEnemyAttackers=%s, defenders=%s",
				territory_get_name(t),
				pro_utils_summarize_units(max_units_list),
				pro_utils_summarize_units(max_amphib_list),
				pro_utils_summarize_units(pro_place_territory_get_defending_units(place_territory)),
			),
		)

		// Find local owned units
		owned_p, owned_c := matches_unit_is_owned_by(self.player)
		owned_local_units := territory_get_matches(t, owned_p, owned_c)
		empty_units: [dynamic]^Unit
		unused_carrier_capacity := min(
			i32(0),
			pro_transport_utils_get_unused_carrier_capacity(self.player, t, empty_units),
		)
		unused_local_carrier_capacity :=
			pro_transport_utils_get_unused_local_carrier_capacity(
				self.player, t, empty_units,
			)
		delete(empty_units)
		pro_logger_trace(
			fmt.tprintf(
				"%s, unusedCarrierCapacity=%v, unusedLocalCarrierCapacity=%v",
				territory_to_string(t),
				unused_carrier_capacity,
				unused_local_carrier_capacity,
			),
		)

		// Determine if need destroyer
		sub_p, sub_c := matches_unit_has_sub_battle_abilities()
		dest_p, dest_c := matches_unit_is_destroyer()
		any_sub := false
		for u in max_units_list {
			if sub_p(sub_c, u) {
				any_sub = true
				break
			}
		}
		any_owned_destroyer := false
		for u in owned_local_units {
			if dest_p(dest_c, u) {
				any_owned_destroyer = true
				break
			}
		}
		need_destroyer := any_sub && !any_owned_destroyer

		// Find all purchase territories for place territory
		units_to_place: [dynamic]^Unit
		final_result := pro_battle_result_new_empty()
		selected_purchase_territories := pro_purchase_ai_get_purchase_territories(
			place_territory,
			purchase_territories,
		)
		for purchase_territory in selected_purchase_territories {
			remaining_unit_production :=
				pro_purchase_territory_get_remaining_unit_production(purchase_territory)
			remaining_constructions := pro_purchase_utils_get_max_constructions(
				zero_move_defense_purchase_options,
			)
			pro_logger_debug(
				fmt.tprintf(
					"%s, remainingUnitProduction=%v, remainingConstructions=%v",
					territory_to_string(pro_purchase_territory_get_territory(purchase_territory)),
					remaining_unit_production,
					remaining_constructions,
				),
			)
			if remaining_unit_production <= 0 && remaining_constructions <= 0 {
				continue
			}

			// Find defenders that can be produced in this territory
			all_defense_purchase_options: [dynamic]^Pro_Purchase_Option
			for ppo in defense_purchase_options {
				append(&all_defense_purchase_options, ppo)
			}
			for ppo in zero_move_defense_purchase_options {
				append(&all_defense_purchase_options, ppo)
			}
			purchase_options_for_territory :=
				pro_purchase_validation_utils_find_purchase_options_for_territory(
					self.pro_data,
					self.player,
					all_defense_purchase_options,
					t,
					pro_purchase_territory_get_territory(purchase_territory),
					self.is_bid,
				)
			delete(all_defense_purchase_options)
			for ppo in air_purchase_options {
				append(&purchase_options_for_territory, ppo)
			}

			// Purchase necessary defenders
			for {
				pro_purchase_validation_utils_remove_invalid_purchase_options(
					self.pro_data,
					self.player,
					self.start_of_turn_data,
					&purchase_options_for_territory,
					self.resource_tracker,
					remaining_unit_production,
					units_to_place,
					purchase_territories,
					remaining_constructions,
					t,
				)
				defense_efficiencies := make(map[^Pro_Purchase_Option]f64)
				for ppo in purchase_options_for_territory {
					if is_land {
						defense_efficiencies[ppo] =
							pro_purchase_option_get_defense_efficiency_with_args(
								ppo, 1, self.data, owned_local_units, units_to_place,
							)
					} else {
						defense_efficiencies[ppo] =
							pro_purchase_option_get_sea_defense_efficiency(
								ppo,
								self.data,
								owned_local_units,
								units_to_place,
								need_destroyer,
								unused_carrier_capacity,
								unused_local_carrier_capacity,
							)
					}
				}
				selected_option := pro_purchase_utils_randomize_purchase_option(
					defense_efficiencies, "Defense",
				)
				delete(defense_efficiencies)
				if selected_option == nil {
					break
				}
				if pro_purchase_option_is_destroyer(selected_option) {
					need_destroyer = false
				}

				// Create new temp units
				pro_resource_tracker_temp_purchase(self.resource_tracker, selected_option)
				if pro_purchase_option_is_construction(selected_option) {
					remaining_constructions -=
						pro_purchase_option_get_quantity(selected_option)
				} else {
					remaining_unit_production -=
						pro_purchase_option_get_quantity(selected_option)
				}
				temp_units := pro_purchase_option_create_temp_units(selected_option)
				for u in temp_units {
					append(&units_to_place, u)
				}
				delete(temp_units)
				if pro_purchase_option_is_carrier(selected_option) ||
				   pro_purchase_option_is_air(selected_option) {
					unused_carrier_capacity =
						pro_transport_utils_get_unused_carrier_capacity(
							self.player, t, units_to_place,
						)
					unused_local_carrier_capacity =
						pro_transport_utils_get_unused_local_carrier_capacity(
							self.player, t, units_to_place,
						)
				}
				pro_logger_trace(
					fmt.tprintf(
						"Selected unit=%s, unusedCarrierCapacity=%v, unusedLocalCarrierCapacity=%v",
						unit_type_get_name(
							pro_purchase_option_get_unit_type(selected_option),
						),
						unused_carrier_capacity,
						unused_local_carrier_capacity,
					),
				)

				// Find current battle result
				enemy_attacking_units: [dynamic]^Unit
				seen: map[^Unit]struct{}
				for u in max_units_list {
					if _, ok := seen[u]; !ok {
						seen[u] = {}
						append(&enemy_attacking_units, u)
					}
				}
				for u in max_amphib_list {
					if _, ok := seen[u]; !ok {
						seen[u] = {}
						append(&enemy_attacking_units, u)
					}
				}
				delete(seen)
				defenders: [dynamic]^Unit
				for u in pro_place_territory_get_defending_units(place_territory) {
					append(&defenders, u)
				}
				for u in units_to_place {
					append(&defenders, u)
				}
				bombard_set := pro_territory_get_max_bombard_units(max_terr)
				bombard_list: [dynamic]^Unit
				for u, _ in bombard_set {
					append(&bombard_list, u)
				}
				final_result = pro_odds_calculator_calculate_battle_results(
					self.calc,
					self.pro_data,
					t,
					enemy_attacking_units,
					defenders,
					bombard_list,
				)

				// Break if it can be held
				is_capital := t == pro_data_get_my_capital(self.pro_data)
				if (!is_capital &&
					   !pro_battle_result_is_has_land_unit_remaining(final_result) &&
					   pro_battle_result_get_tuv_swing(final_result) <= 0) ||
				   (is_capital &&
						   pro_battle_result_get_win_percentage(final_result) <
							   (100 - pro_data_get_win_percentage(self.pro_data)) &&
						   pro_battle_result_get_tuv_swing(final_result) <= 0) {
					break
				}
			}
			delete(purchase_options_for_territory)
		}
		delete(selected_purchase_territories)

		// Check to see if its worth trying to defend the territory
		has_local_superiority := pro_battle_utils_territory_has_local_land_superiority(
			self.pro_data, t, 2, self.player, purchase_territories,
		)
		min_battle := pro_place_territory_get_min_battle_result(place_territory)
		if !pro_battle_result_is_has_land_unit_remaining(final_result) ||
		   (pro_battle_result_get_tuv_swing(final_result) -
			   f64(pro_resource_tracker_get_temp_pus(
				   self.resource_tracker, self.start_of_turn_data,
			   )) /
				   2.0) <
			   pro_battle_result_get_tuv_swing(min_battle) ||
		   t == pro_data_get_my_capital(self.pro_data) ||
		   (!territory_is_water(t) && has_local_superiority) {
			pro_resource_tracker_confirm_temp_purchases(self.resource_tracker)
			pro_logger_trace(
				fmt.tprintf(
					"%s, placedUnits=%v, TUVSwing=%v, hasLandUnitRemaining=%v, hasLocalSuperiority=%v",
					territory_to_string(t),
					units_to_place,
					pro_battle_result_get_tuv_swing(final_result),
					pro_battle_result_is_has_land_unit_remaining(final_result),
					has_local_superiority,
				),
			)
			pro_purchase_ai_add_units_to_place_territory(
				self, place_territory, &units_to_place, purchase_territories,
			)
		} else {
			pro_resource_tracker_clear_temp_purchases(self.resource_tracker)
			pro_purchase_ai_set_cant_hold_place_territory(
				self, place_territory, purchase_territories,
			)
			pro_logger_trace(
				fmt.tprintf(
					"%s, unable to defend with placedUnits=%v, TUVSwing=%v, minTUVSwing=%v",
					territory_to_string(t),
					units_to_place,
					pro_battle_result_get_tuv_swing(final_result),
					pro_battle_result_get_tuv_swing(min_battle),
				),
			)
		}
		delete(units_to_place)
		delete(owned_local_units)
		delete(max_units_list)
	}
}

// `ProPurchaseAi.purchaseLandUnits(Map, List, ProPurchaseOptionMap)`.
// For every prioritized land territory, optionally consume any unplaced
// units that fit, then iteratively buy fodder/attack/defense units until
// the territory's remaining production is exhausted.
pro_purchase_ai_purchase_land_units :: proc(
	self:                         ^Pro_Purchase_Ai,
	purchase_territories:         map[^Territory]^Pro_Purchase_Territory,
	prioritized_land_territories: [dynamic]^Pro_Place_Territory,
	purchase_options:             ^Pro_Purchase_Option_Map,
) {
	// player.getMatches(Matches.unitIsNotSea())
	not_sea_p, not_sea_c := matches_unit_is_not_sea()
	unplaced_units: [dynamic]^Unit
	for u in unit_collection_get_units(game_player_get_unit_collection(self.player)) {
		if not_sea_p(not_sea_c, u) {
			append(&unplaced_units, u)
		}
	}
	if pro_resource_tracker_is_empty(self.resource_tracker) && len(unplaced_units) == 0 {
		delete(unplaced_units)
		return
	}
	pro_logger_info(
		fmt.tprintf("Purchase land units with resources: %v", self.resource_tracker),
	)
	if len(unplaced_units) > 0 {
		pro_logger_info(
			fmt.tprintf("Purchase land units with unplaced units=%v", unplaced_units),
		)
	}

	// Loop through prioritized territories and purchase land units
	territories_to_check: map[^Territory]struct {}
	can_move_land_p, can_move_land_c :=
		pro_matches_territory_can_potentially_move_land_units(self.player)
	enemy_players := pro_utils_get_enemy_players(self.player)
	is_enemy_p, is_enemy_c := matches_is_territory_owned_by_any_of(enemy_players)
	gm := game_data_get_map(self.data)
	for place_territory in prioritized_land_territories {
		land_territories := game_map_get_neighbors_distance_predicate(
			gm,
			pro_place_territory_get_territory(place_territory),
			9,
			can_move_land_p,
			can_move_land_c,
		)
		for nb, _ in land_territories {
			if is_enemy_p(is_enemy_c, nb) {
				territories_to_check[nb] = {}
			}
		}
		delete(land_territories)
	}
	delete(enemy_players)
	empty_tt: [dynamic]^Territory
	empty_ta: [dynamic]^Territory
	territory_value_map := pro_territory_value_utils_find_territory_values(
		self.pro_data, self.player, empty_tt, empty_ta, territories_to_check,
	)
	delete(empty_tt)
	delete(empty_ta)
	delete(territories_to_check)

	for place_territory in prioritized_land_territories {
		t := pro_place_territory_get_territory(place_territory)
		pro_logger_debug(fmt.tprintf("Checking land place for %s", territory_get_name(t)))

		// Check remaining production
		pt_for_t := purchase_territories[t]
		remaining_unit_production :=
			pro_purchase_territory_get_remaining_unit_production(pt_for_t)
		pro_logger_debug(
			fmt.tprintf(
				"%s, remainingUnitProduction=%v",
				territory_to_string(t),
				remaining_unit_production,
			),
		)
		if remaining_unit_production <= 0 {
			continue
		}

		// Determine most cost efficient units that can be produced in this
		// territory.
		land_fodder_options :=
			pro_purchase_validation_utils_find_purchase_options_for_territory_5(
				self.pro_data,
				self.player,
				pro_purchase_option_map_get_land_fodder_options(purchase_options),
				t,
				self.is_bid,
			)
		land_attack_options :=
			pro_purchase_validation_utils_find_purchase_options_for_territory_5(
				self.pro_data,
				self.player,
				pro_purchase_option_map_get_land_attack_options(purchase_options),
				t,
				self.is_bid,
			)
		land_defense_options :=
			pro_purchase_validation_utils_find_purchase_options_for_territory_5(
				self.pro_data,
				self.player,
				pro_purchase_option_map_get_land_defense_options(purchase_options),
				t,
				self.is_bid,
			)

		// Determine enemy distance and locally owned units
		enemy_distance :=
			pro_utils_get_closest_enemy_or_neutral_land_territory_distance(
				&self.data.game_state, self.player, t, territory_value_map,
			)
		if enemy_distance <= 0 {
			enemy_distance = 10
		}
		fodder_percent := 80 - enemy_distance * 5
		pro_logger_debug(
			fmt.tprintf(
				"%s, enemyDistance=%v, fodderPercent=%v",
				territory_to_string(t),
				enemy_distance,
				fodder_percent,
			),
		)
		neighbor_p, neighbor_c := pro_matches_territory_can_move_land_units(
			self.player, false,
		)
		neighbors := game_map_get_neighbors_distance_predicate(
			gm, t, 2, neighbor_p, neighbor_c,
		)
		neighbors[t] = {}
		owned_p, owned_c := matches_unit_is_owned_by(self.player)
		owned_local_units: [dynamic]^Unit
		for nb, _ in neighbors {
			matched := territory_get_matches(nb, owned_p, owned_c)
			for u in matched {
				append(&owned_local_units, u)
			}
			delete(matched)
		}
		delete(neighbors)

		// Check for unplaced units
		units_to_place: [dynamic]^Unit
		i := 0
		for i < len(unplaced_units) && remaining_unit_production > 0 {
			u := unplaced_units[i]
			append(&units_to_place, u)
			if pro_purchase_validation_utils_can_units_be_placed(
				self.pro_data, units_to_place, self.player, t, t, self.is_bid,
			) {
				remaining_unit_production -= 1
				ordered_remove(&unplaced_units, i)
				pro_logger_trace(fmt.tprintf("Selected unplaced unit=%v", u))
			} else {
				pop(&units_to_place)
				i += 1
			}
		}

		// Purchase as many units as possible
		added_fodder_units: i32 = 0
		attack_and_defense_difference: f64 = 0
		select_fodder_unit := true
		for {
			pro_purchase_validation_utils_remove_invalid_purchase_options(
				self.pro_data, self.player, self.start_of_turn_data,
				&land_fodder_options, self.resource_tracker,
				remaining_unit_production, units_to_place, purchase_territories,
				0, t,
			)
			pro_purchase_validation_utils_remove_invalid_purchase_options(
				self.pro_data, self.player, self.start_of_turn_data,
				&land_attack_options, self.resource_tracker,
				remaining_unit_production, units_to_place, purchase_territories,
				0, t,
			)
			pro_purchase_validation_utils_remove_invalid_purchase_options(
				self.pro_data, self.player, self.start_of_turn_data,
				&land_defense_options, self.resource_tracker,
				remaining_unit_production, units_to_place, purchase_territories,
				0, t,
			)

			selected_option: ^Pro_Purchase_Option = nil
			if !select_fodder_unit && attack_and_defense_difference > 0 &&
			   len(land_defense_options) > 0 {
				defense_efficiencies := make(map[^Pro_Purchase_Option]f64)
				for ppo in land_defense_options {
					defense_efficiencies[ppo] =
						pro_purchase_option_get_defense_efficiency_with_args(
							ppo, enemy_distance, self.data, owned_local_units, units_to_place,
						)
				}
				selected_option = pro_purchase_utils_randomize_purchase_option(
					defense_efficiencies, "Land Defense",
				)
				delete(defense_efficiencies)
			} else if !select_fodder_unit && len(land_attack_options) > 0 {
				attack_efficiencies := make(map[^Pro_Purchase_Option]f64)
				for ppo in land_attack_options {
					attack_efficiencies[ppo] =
						pro_purchase_option_get_attack_efficiency_with_args(
							ppo, enemy_distance, self.data, owned_local_units, units_to_place,
						)
				}
				selected_option = pro_purchase_utils_randomize_purchase_option(
					attack_efficiencies, "Land Attack",
				)
				delete(attack_efficiencies)
			} else if len(land_fodder_options) > 0 {
				fodder_efficiencies := make(map[^Pro_Purchase_Option]f64)
				for ppo in land_fodder_options {
					fodder_efficiencies[ppo] = pro_purchase_option_get_fodder_efficiency(
						ppo, enemy_distance, self.data, owned_local_units, units_to_place,
					)
				}
				selected_option = pro_purchase_utils_randomize_purchase_option(
					fodder_efficiencies, "Land Fodder",
				)
				delete(fodder_efficiencies)
				if selected_option != nil {
					added_fodder_units += pro_purchase_option_get_quantity(selected_option)
				}
			}
			if selected_option == nil {
				break
			}

			pro_resource_tracker_purchase(self.resource_tracker, selected_option)
			remaining_unit_production -= pro_purchase_option_get_quantity(selected_option)
			temp_units := pro_purchase_option_create_temp_units(selected_option)
			for u in temp_units {
				append(&units_to_place, u)
			}
			delete(temp_units)
			attack_and_defense_difference +=
				pro_purchase_option_get_attack(selected_option) -
				pro_purchase_option_get_defense(selected_option)
			if len(units_to_place) > 0 {
				select_fodder_unit =
					f64(added_fodder_units) / f64(len(units_to_place)) * 100.0 <=
					f64(fodder_percent)
			}
			pro_logger_trace(
				fmt.tprintf(
					"Selected unit=%s",
					unit_type_get_name(pro_purchase_option_get_unit_type(selected_option)),
				),
			)
		}

		pro_purchase_ai_add_units_to_place(self, place_territory, units_to_place)
		delete(land_fodder_options)
		delete(land_attack_options)
		delete(land_defense_options)
		delete(owned_local_units)
		delete(units_to_place)
	}
	delete(territory_value_map)
	delete(unplaced_units)
}

// `ProPurchaseAi.purchaseFactory(Map, Map, List, ProPurchaseOptionMap, boolean)`.
// If every prioritized land territory has used up its production, scan
// owned land for a viable factory site (production >= 3, holdable, and
// — unless we have extra PUs — with local land superiority), pick the
// best one by territory-value, and queue a factory.
pro_purchase_ai_purchase_factory :: proc(
	self:                          ^Pro_Purchase_Ai,
	factory_purchase_territories:  map[^Territory]^Pro_Purchase_Territory,
	purchase_territories:          map[^Territory]^Pro_Purchase_Territory,
	prioritized_land_territories:  [dynamic]^Pro_Place_Territory,
	purchase_options:              ^Pro_Purchase_Option_Map,
	has_extra_pus:                 bool,
) {
	factory_purchase_territories := factory_purchase_territories

	if pro_resource_tracker_is_empty(self.resource_tracker) {
		return
	}
	pro_logger_info(
		fmt.tprintf(
			"Purchase factory with resources: %v, hasExtraPUs=%v",
			self.resource_tracker,
			has_extra_pus,
		),
	)

	enemy_attack_options := pro_territory_manager_get_enemy_attack_options(
		self.territory_manager,
	)

	// Only try to purchase a factory if all production was used in
	// prioritized land territories.
	for place_territory in prioritized_land_territories {
		for t, _ in purchase_territories {
			if pro_place_territory_get_territory(place_territory) == t &&
			   pro_purchase_territory_get_remaining_unit_production(
				   purchase_territories[t],
			   ) >
				   0 {
				pro_logger_debug(
					fmt.tprintf(
						"Not purchasing a factory since remaining land production in %s",
						territory_to_string(t),
					),
				)
				return
			}
		}
	}

	// Find all owned land territories that weren't conquered and don't
	// already have a factory.
	gm := game_data_get_map(self.data)
	no_factory_p, no_factory_c :=
		pro_matches_territory_has_no_infra_factory_and_is_not_conquered_owned_land(
			self.player,
		)
	possible_factory_territories: [dynamic]^Territory
	for t in game_map_get_territories(gm) {
		if no_factory_p(no_factory_c, t) {
			append(&possible_factory_territories, t)
		}
	}
	// possibleFactoryTerritories.removeAll(factoryPurchaseTerritories.keySet())
	for i := len(possible_factory_territories) - 1; i >= 0; i -= 1 {
		if _, ok := factory_purchase_territories[possible_factory_territories[i]]; ok {
			ordered_remove(&possible_factory_territories, i)
		}
	}
	purchase_factory_territories: map[^Territory]struct {}
	territories_that_cant_be_held: [dynamic]^Territory
	for t in possible_factory_territories {
		// Only consider territories with production of at least 3 unless
		// there are still remaining PUs.
		production: i32 = 0
		att := territory_attachment_get(t)
		if att != nil {
			production = territory_attachment_get_production(att)
		}
		if (production < 3 && !has_extra_pus) || production < 2 {
			continue
		}

		max_terr := pro_other_move_options_get_max(enemy_attack_options, t)
		if max_terr == nil {
			purchase_factory_territories[t] = {}
			pro_logger_trace(
				fmt.tprintf(
					"Possible factory since no enemy attackers: %s",
					territory_get_name(t),
				),
			)
		} else {
			// Find current battle result
			allied_p, allied_c := matches_is_unit_allied(self.player)
			defenders := territory_get_matches(t, allied_p, allied_c)
			max_units_set := pro_territory_get_max_units(max_terr)
			enemy_attacking_units: [dynamic]^Unit
			seen: map[^Unit]struct{}
			for u, _ in max_units_set {
				if _, ok := seen[u]; !ok {
					seen[u] = {}
					append(&enemy_attacking_units, u)
				}
			}
			for u in pro_territory_get_max_amphib_units(max_terr) {
				if _, ok := seen[u]; !ok {
					seen[u] = {}
					append(&enemy_attacking_units, u)
				}
			}
			delete(seen)
			bombard_set := pro_territory_get_max_bombard_units(max_terr)
			bombard_list: [dynamic]^Unit
			for u, _ in bombard_set {
				append(&bombard_list, u)
			}
			result := pro_odds_calculator_estimate_defend_battle_results(
				self.calc, self.pro_data, t, enemy_attacking_units, defenders, bombard_list,
			)
			if pro_battle_result_is_has_land_unit_remaining(result) ||
			   pro_battle_result_get_tuv_swing(result) > 0 {
				append(&territories_that_cant_be_held, t)
				pro_logger_trace(
					fmt.tprintf(
						"Can't hold territory: %s, hasLandUnitRemaining=%v, TUVSwing=%v, enemyAttackers=%v, myDefenders=%v",
						territory_get_name(t),
						pro_battle_result_is_has_land_unit_remaining(result),
						pro_battle_result_get_tuv_swing(result),
						len(enemy_attacking_units),
						len(defenders),
					),
				)
			} else {
				purchase_factory_territories[t] = {}
				pro_logger_trace(
					fmt.tprintf(
						"Possible factory: %s, hasLandUnitRemaining=%v, TUVSwing=%v, enemyAttackers=%v, myDefenders=%v",
						territory_get_name(t),
						pro_battle_result_is_has_land_unit_remaining(result),
						pro_battle_result_get_tuv_swing(result),
						len(enemy_attacking_units),
						len(defenders),
					),
				)
			}
			delete(defenders)
			delete(enemy_attacking_units)
			delete(bombard_list)
		}
	}
	delete(possible_factory_territories)
	pro_logger_debug(
		fmt.tprintf("Possible factory territories: %v", purchase_factory_territories),
	)

	// Remove any territories that don't have local land superiority
	if !has_extra_pus {
		to_remove: [dynamic]^Territory
		for t, _ in purchase_factory_territories {
			if !pro_battle_utils_territory_has_local_land_superiority(
				self.pro_data, t, 3, self.player, purchase_territories,
			) {
				append(&to_remove, t)
			}
		}
		for t in to_remove {
			delete_key(&purchase_factory_territories, t)
		}
		delete(to_remove)
		pro_logger_debug(
			fmt.tprintf(
				"Possible factory territories that have land superiority: %v",
				purchase_factory_territories,
			),
		)
	}

	// Find strategic value for each territory
	empty_ta: [dynamic]^Territory
	territory_value_map := pro_territory_value_utils_find_territory_values(
		self.pro_data, self.player, territories_that_cant_be_held, empty_ta,
		purchase_factory_territories,
	)
	delete(empty_ta)
	max_value: f64 = 0.0
	max_territory: ^Territory = nil
	water_p, water_c := matches_territory_has_neighbor_matching_water(self.player)
	can_move_land_p, can_move_land_c := pro_matches_territory_can_move_land_units(
		self.player, false,
	)
	enemy_match_p, enemy_match_c := matches_is_territory_enemy(self.player)
	for t, _ in purchase_factory_territories {
		production: i32 = 0
		att := territory_attachment_get(t)
		if att != nil {
			production = territory_attachment_get_production(att)
		}
		val := territory_value_map[t] * f64(production) + 0.1 * f64(production)
		is_adjacent_to_sea := water_p(water_c, t)
		nearby_land_territories := game_map_get_neighbors_distance_predicate(
			gm, t, 9, can_move_land_p, can_move_land_c,
		)
		num_nearby_enemy_territories: i32 = 0
		for n, _ in nearby_land_territories {
			if enemy_match_p(enemy_match_c, n) {
				num_nearby_enemy_territories += 1
			}
		}
		delete(nearby_land_territories)
		pro_logger_trace(
			fmt.tprintf(
				"%s, strategic value=%v, value=%v, numNearbyEnemyTerritories=%v",
				territory_to_string(t),
				territory_value_map[t],
				val,
				num_nearby_enemy_territories,
			),
		)
		if val > max_value &&
		   ((num_nearby_enemy_territories >= 4 && territory_value_map[t] >= 1) ||
				   (is_adjacent_to_sea && has_extra_pus)) {
			max_value = val
			max_territory = t
		}
	}
	delete(territories_that_cant_be_held)
	delete(territory_value_map)
	delete(purchase_factory_territories)
	pro_logger_debug(
		fmt.tprintf("Try to purchase factory for territory: %v", max_territory),
	)

	if max_territory != nil {
		// Find most expensive placed land unit to consider removing for a
		// factory.
		max_placed_option: ^Pro_Purchase_Option = nil
		max_placed_territory: ^Pro_Place_Territory = nil
		max_placed_unit: ^Unit = nil
		for place_territory in prioritized_land_territories {
			for u in pro_place_territory_get_place_units(place_territory) {
				for ppo in pro_purchase_option_map_get_land_options(purchase_options) {
					if unit_get_type(u) == pro_purchase_option_get_unit_type(ppo) &&
					   pro_purchase_option_get_quantity(ppo) == 1 &&
					   (max_placed_option == nil ||
							   pro_purchase_option_get_cost(ppo) >=
								   pro_purchase_option_get_cost(max_placed_option)) {
						max_placed_option = ppo
						max_placed_territory = place_territory
						max_placed_unit = u
					}
				}
			}
		}

		// Determine units that can be produced in this territory
		purchase_options_for_territory :=
			pro_purchase_validation_utils_find_purchase_options_for_territory_5(
				self.pro_data,
				self.player,
				pro_purchase_option_map_get_factory_options(purchase_options),
				max_territory,
				self.is_bid,
			)
		pro_resource_tracker_remove_temp_purchase(self.resource_tracker, max_placed_option)
		empty_units: [dynamic]^Unit
		pro_purchase_validation_utils_remove_invalid_purchase_options(
			self.pro_data, self.player, self.start_of_turn_data,
			&purchase_options_for_territory, self.resource_tracker, 0,
			empty_units, purchase_territories, 1, max_territory,
		)
		delete(empty_units)
		pro_resource_tracker_clear_temp_purchases(self.resource_tracker)

		// Determine most expensive factory option (currently doesn't buy
		// mobile factories).
		best_factory_option: ^Pro_Purchase_Option = nil
		max_factory_efficiency: f64 = 0
		for ppo in purchase_options_for_territory {
			if pro_purchase_option_get_movement(ppo) == 0 &&
			   f64(pro_purchase_option_get_cost(ppo)) > max_factory_efficiency {
				best_factory_option = ppo
				max_factory_efficiency = f64(pro_purchase_option_get_cost(ppo))
			}
		}
		delete(purchase_options_for_territory)

		if best_factory_option != nil {
			pro_logger_debug(
				fmt.tprintf(
					"Best factory unit: %s",
					unit_type_get_name(pro_purchase_option_get_unit_type(best_factory_option)),
				),
			)
			factory_purchase_territory := pro_purchase_territory_new_default(
				max_territory, self.data, self.player, 0,
			)
			factory_purchase_territories[max_territory] = factory_purchase_territory
			for ppt in pro_purchase_territory_get_can_place_territories(
				factory_purchase_territory,
			) {
				if pro_place_territory_get_territory(ppt) == max_territory {
					factory := pro_purchase_option_create_temp_units(best_factory_option)
					pro_purchase_ai_add_units_to_place(self, ppt, factory)
					if pro_resource_tracker_has_enough(
						self.resource_tracker, best_factory_option,
					) {
						pro_resource_tracker_purchase(
							self.resource_tracker, best_factory_option,
						)
						pro_logger_debug(
							fmt.tprintf(
								"%s, placedFactory=%v",
								territory_to_string(max_territory),
								factory,
							),
						)
					} else {
						pro_resource_tracker_purchase(
							self.resource_tracker, best_factory_option,
						)
						pro_resource_tracker_remove_purchase(
							self.resource_tracker, max_placed_option,
						)
						if max_placed_territory != nil {
							place_units := pro_place_territory_get_place_units(
								max_placed_territory,
							)
							for i := len(place_units) - 1; i >= 0; i -= 1 {
								if place_units[i] == max_placed_unit {
									ordered_remove(&place_units, i)
									break
								}
							}
						}
						pro_logger_debug(
							fmt.tprintf(
								"%s, placedFactory=%v, removedUnit=%v",
								territory_to_string(max_territory),
								factory,
								max_placed_unit,
							),
						)
					}
					delete(factory)
				}
			}
		}
	}
}

// `ProPurchaseAi.purchaseSeaAndAmphibUnits(Map, List, ProPurchaseOptionMap)`.
// Buy sea defenders for each prioritized sea territory until it can be
// held, then buy local naval superiority and finally transports +
// amphib units. Returns true if the AI wanted to buy a fleet but
// couldn't defend it and should consider saving up.
pro_purchase_ai_purchase_sea_and_amphib_units :: proc(
	self:                        ^Pro_Purchase_Ai,
	purchase_territories:        map[^Territory]^Pro_Purchase_Territory,
	prioritized_sea_territories: [dynamic]^Pro_Place_Territory,
	purchase_options:            ^Pro_Purchase_Option_Map,
) -> bool {
	if pro_resource_tracker_is_empty(self.resource_tracker) {
		return false
	}
	pro_logger_info(
		fmt.tprintf("Purchase sea and amphib units with resources: %v", self.resource_tracker),
	)

	enemy_attack_options := pro_territory_manager_get_enemy_attack_options(
		self.territory_manager,
	)
	bought_units := false
	wanted_to_buy_units_but_could_not_defend_them := false

	can_move_sea_p, can_move_sea_c := pro_matches_territory_can_move_sea_units(
		self.player, false,
	)
	gm := game_data_get_map(self.data)

	for place_territory in prioritized_sea_territories {
		t := pro_place_territory_get_territory(place_territory)
		pro_logger_debug(fmt.tprintf("Checking sea place for %s", territory_get_name(t)))

		// Find all purchase territories for place territory
		selected_purchase_territories := pro_purchase_ai_get_purchase_territories(
			place_territory, purchase_territories,
		)

		// Find local owned units
		neighbors := game_map_get_neighbors_distance_predicate(
			gm, t, 2, can_move_sea_p, can_move_sea_c,
		)
		neighbors[t] = {}
		owned_p, owned_c := matches_unit_is_owned_by(self.player)
		owned_local_units: [dynamic]^Unit
		for nb, _ in neighbors {
			matched := territory_get_matches(nb, owned_p, owned_c)
			for u in matched {
				append(&owned_local_units, u)
			}
			delete(matched)
		}
		delete(neighbors)
		empty_units: [dynamic]^Unit
		unused_carrier_capacity := min(
			i32(0),
			pro_transport_utils_get_unused_carrier_capacity(self.player, t, empty_units),
		)
		unused_local_carrier_capacity :=
			pro_transport_utils_get_unused_local_carrier_capacity(
				self.player, t, empty_units,
			)
		delete(empty_units)
		pro_logger_trace(
			fmt.tprintf(
				"%s, unusedCarrierCapacity=%v, unusedLocalCarrierCapacity=%v",
				territory_to_string(t),
				unused_carrier_capacity,
				unused_local_carrier_capacity,
			),
		)

		// If any enemy attackers then purchase sea defenders until it can
		// be held.
		need_destroyer := false
		max_enemy_attack_territory := pro_other_move_options_get_max(
			enemy_attack_options, t,
		)
		if max_enemy_attack_territory != nil {
			attackers_set := pro_territory_get_max_units(max_enemy_attack_territory)
			attackers: [dynamic]^Unit
			for u, _ in attackers_set {
				append(&attackers, u)
			}
			// Determine if need destroyer
			sub_p, sub_c := matches_unit_has_sub_battle_abilities()
			dest_p, dest_c := matches_unit_is_destroyer()
			any_sub := false
			for u in attackers {
				if sub_p(sub_c, u) {
					any_sub = true
					break
				}
			}
			any_owned_destroyer := false
			for u in territory_get_units(t) {
				if owned_p(owned_c, u) && dest_p(dest_c, u) {
					any_owned_destroyer = true
					break
				}
			}
			if any_sub && !any_owned_destroyer {
				need_destroyer = true
			}
			pro_logger_trace(
				fmt.tprintf(
					"%s, needDestroyer=%v, checking defense since has enemy attackers: %v",
					territory_to_string(t),
					need_destroyer,
					attackers,
				),
			)
			defending_units: [dynamic]^Unit
			for u in pro_place_territory_get_defending_units(place_territory) {
				append(&defending_units, u)
			}
			place_units := pro_purchase_utils_get_place_units(t, purchase_territories)
			for u in place_units {
				append(&defending_units, u)
			}
			delete(place_units)
			bombard_set := pro_territory_get_max_bombard_units(max_enemy_attack_territory)
			bombard_list: [dynamic]^Unit
			for u, _ in bombard_set {
				append(&bombard_list, u)
			}
			result := pro_odds_calculator_calculate_battle_results(
				self.calc, self.pro_data, t, attackers, defending_units, bombard_list,
			)
			units_to_place: [dynamic]^Unit
			for purchase_territory in selected_purchase_territories {
				remaining_unit_production :=
					pro_purchase_territory_get_remaining_unit_production(purchase_territory)
				pro_logger_trace(
					fmt.tprintf(
						"%s, purchaseTerritory=%s, remainingUnitProduction=%v",
						territory_to_string(t),
						territory_to_string(
							pro_purchase_territory_get_territory(purchase_territory),
						),
						remaining_unit_production,
					),
				)
				if remaining_unit_production <= 0 {
					continue
				}

				sea_purchase_options_for_territory :=
					pro_purchase_validation_utils_find_purchase_options_for_territory(
						self.pro_data,
						self.player,
						pro_purchase_option_map_get_sea_defense_options(purchase_options),
						t,
						pro_purchase_territory_get_territory(purchase_territory),
						self.is_bid,
					)
				for ppo in pro_purchase_option_map_get_air_options(purchase_options) {
					append(&sea_purchase_options_for_territory, ppo)
				}

				for {
					evade_p, evade_c := matches_unit_can_evade()
					all_evade := len(defending_units) > 0
					for u in defending_units {
						if !evade_p(evade_c, u) {
							all_evade = false
							break
						}
					}
					any_dest_in_attackers := false
					for u in attackers {
						if dest_p(dest_c, u) {
							any_dest_in_attackers = true
							break
						}
					}
					has_only_retreating_subs :=
						properties_get_sub_retreat_before_battle(
							game_data_get_properties(self.data),
						) &&
						all_evade &&
						!any_dest_in_attackers
					if !has_only_retreating_subs &&
					   (pro_battle_result_get_tuv_swing(result) < -1 ||
							   pro_battle_result_get_win_percentage(result) <
								   (100.0 - pro_data_get_win_percentage(self.pro_data))) {
						break
					}

					pro_purchase_validation_utils_remove_invalid_purchase_options(
						self.pro_data, self.player, self.start_of_turn_data,
						&sea_purchase_options_for_territory, self.resource_tracker,
						remaining_unit_production, units_to_place, purchase_territories,
						0, t,
					)
					defense_efficiencies := make(map[^Pro_Purchase_Option]f64)
					for ppo in sea_purchase_options_for_territory {
						defense_efficiencies[ppo] =
							pro_purchase_option_get_sea_defense_efficiency(
								ppo,
								self.data,
								owned_local_units,
								units_to_place,
								need_destroyer,
								unused_carrier_capacity,
								unused_local_carrier_capacity,
							)
					}
					selected_option := pro_purchase_utils_randomize_purchase_option(
						defense_efficiencies, "Sea Defense",
					)
					delete(defense_efficiencies)
					if selected_option == nil {
						break
					}
					if pro_purchase_option_is_destroyer(selected_option) {
						need_destroyer = false
					}

					pro_resource_tracker_temp_purchase(self.resource_tracker, selected_option)
					remaining_unit_production -=
						pro_purchase_option_get_quantity(selected_option)
					temp_units := pro_purchase_option_create_temp_units(selected_option)
					for u in temp_units {
						append(&units_to_place, u)
					}
					delete(temp_units)
					if pro_purchase_option_is_carrier(selected_option) ||
					   pro_purchase_option_is_air(selected_option) {
						unused_carrier_capacity =
							pro_transport_utils_get_unused_carrier_capacity(
								self.player, t, units_to_place,
							)
						unused_local_carrier_capacity =
							pro_transport_utils_get_unused_local_carrier_capacity(
								self.player, t, units_to_place,
							)
					}
					pro_logger_trace(
						fmt.tprintf(
							"%s, added sea defender for defense: %s, TUVSwing=%v, win%%=%v, unusedCarrierCapacity=%v, unusedLocalCarrierCapacity=%v",
							territory_to_string(t),
							unit_type_get_name(
								pro_purchase_option_get_unit_type(selected_option),
							),
							pro_battle_result_get_tuv_swing(result),
							pro_battle_result_get_win_percentage(result),
							unused_carrier_capacity,
							unused_local_carrier_capacity,
						),
					)

					// Find current battle result
					delete(defending_units)
					defending_units = make([dynamic]^Unit)
					for u in pro_place_territory_get_defending_units(place_territory) {
						append(&defending_units, u)
					}
					place_units2 := pro_purchase_utils_get_place_units(
						t, purchase_territories,
					)
					for u in place_units2 {
						append(&defending_units, u)
					}
					delete(place_units2)
					for u in units_to_place {
						append(&defending_units, u)
					}
					mu_set := pro_territory_get_max_units(max_enemy_attack_territory)
					mu_list: [dynamic]^Unit
					for u, _ in mu_set {
						append(&mu_list, u)
					}
					mb_set := pro_territory_get_max_bombard_units(max_enemy_attack_territory)
					mb_list: [dynamic]^Unit
					for u, _ in mb_set {
						append(&mb_list, u)
					}
					result = pro_odds_calculator_estimate_defend_battle_results(
						self.calc, self.pro_data, t, mu_list, defending_units, mb_list,
					)
				}
				delete(sea_purchase_options_for_territory)
			}

			// Check to see if its worth trying to defend the territory
			if pro_battle_result_get_tuv_swing(result) < 0 ||
			   pro_battle_result_get_win_percentage(result) <
				   (100.0 - pro_data_get_win_percentage(self.pro_data)) {
				pro_resource_tracker_confirm_temp_purchases(self.resource_tracker)
				pro_logger_trace(
					fmt.tprintf(
						"%s, placedUnits=%v, TUVSwing=%v, win%%=%v",
						territory_to_string(t),
						units_to_place,
						pro_battle_result_get_tuv_swing(result),
						pro_battle_result_get_win_percentage(result),
					),
				)
				pro_purchase_ai_add_units_to_place_territory(
					self, place_territory, &units_to_place, purchase_territories,
				)
				bought_units = true
			} else {
				pro_resource_tracker_clear_temp_purchases(self.resource_tracker)
				pro_purchase_ai_set_cant_hold_place_territory(
					self, place_territory, purchase_territories,
				)
				pro_logger_trace(
					fmt.tprintf(
						"%s, can't defend TUVSwing=%v, win%%=%v, tried to placeDefenders=%s, enemyAttackers=%s, defendingUnits=%s",
						territory_to_string(t),
						pro_battle_result_get_tuv_swing(result),
						pro_battle_result_get_win_percentage(result),
						pro_utils_summarize_units(units_to_place),
						pro_utils_summarize_units(attackers),
						pro_utils_summarize_units(defending_units),
					),
				)
				wanted_to_buy_units_but_could_not_defend_them = true
				delete(units_to_place)
				delete(defending_units)
				delete(attackers)
				delete(bombard_list)
				delete(owned_local_units)
				delete(selected_purchase_territories)
				continue
			}
			delete(units_to_place)
			delete(defending_units)
			delete(attackers)
			delete(bombard_list)
		}

		// Check to see if local naval superiority
		land_distance := pro_utils_get_closest_enemy_land_territory_distance_over_water(
			&self.data.game_state, self.player, t,
		)
		if land_distance <= 0 {
			land_distance = 10
		}
		enemy_distance := land_distance + 1
		if enemy_distance < 3 {
			enemy_distance = 3
		}
		can_move_air_p, can_move_air_c := pro_matches_territory_can_move_air_units(
			self.data, self.player, false,
		)
		nearby_territories := game_map_get_neighbors_distance_predicate(
			gm, t, enemy_distance, can_move_air_p, can_move_air_c,
		)
		nearby_land_territories: [dynamic]^Territory
		land_p, land_c := matches_territory_is_land()
		for n, _ in nearby_territories {
			if land_p(land_c, n) {
				append(&nearby_land_territories, n)
			}
		}
		delete(nearby_territories)
		water_only_p, water_only_c := matches_territory_is_water()
		nearby_enemy_sea_territories := game_map_get_neighbors_distance_predicate(
			gm, t, enemy_distance, water_only_p, water_only_c,
		)
		nearby_enemy_sea_territories[t] = {}
		allied_distance := (enemy_distance + 1) / 2
		nearby_allied_sea_territories := game_map_get_neighbors_distance_predicate(
			gm, t, allied_distance, water_only_p, water_only_c,
		)
		nearby_allied_sea_territories[t] = {}
		enemy_units_in_land_territories: [dynamic]^Unit
		enemy_air_p, enemy_air_c := pro_matches_unit_is_enemy_air(self.player)
		for nlt in nearby_land_territories {
			matched := territory_get_matches(nlt, enemy_air_p, enemy_air_c)
			for u in matched {
				append(&enemy_units_in_land_territories, u)
			}
			delete(matched)
		}
		enemy_non_land_p, enemy_non_land_c := pro_matches_unit_is_enemy_not_land(
			self.player,
		)
		enemy_units_in_sea_territories: [dynamic]^Unit
		for nst, _ in nearby_enemy_sea_territories {
			enemy_sea_units := territory_get_matches(nst, enemy_non_land_p, enemy_non_land_c)
			if len(enemy_sea_units) == 0 {
				delete(enemy_sea_units)
				continue
			}
			route := game_map_get_route_for_units(
				gm,
				t,
				nst,
				territory_is_water,
				enemy_sea_units,
				unit_get_owner(enemy_sea_units[0]),
			)
			if route == nil {
				delete(enemy_sea_units)
				continue
			}
			route_length := route_number_of_steps(route)
			if route_length <= enemy_distance {
				for u in enemy_sea_units {
					append(&enemy_units_in_sea_territories, u)
				}
			}
			delete(enemy_sea_units)
		}
		my_units_in_sea_territories: [dynamic]^Unit
		owned_not_land_p, owned_not_land_c := pro_matches_unit_is_owned_not_land(
			self.player,
		)
		for nst, _ in nearby_allied_sea_territories {
			matched := territory_get_matches(nst, owned_not_land_p, owned_not_land_c)
			for u in matched {
				append(&my_units_in_sea_territories, u)
			}
			delete(matched)
			place_units2 := pro_purchase_utils_get_place_units(nst, purchase_territories)
			for u in place_units2 {
				append(&my_units_in_sea_territories, u)
			}
			delete(place_units2)
		}
		delete(nearby_enemy_sea_territories)
		delete(nearby_allied_sea_territories)
		delete(nearby_land_territories)

		// Check if destroyer is needed
		sub_p2, sub_c2 := matches_unit_has_sub_battle_abilities()
		dest_p2, dest_c2 := matches_unit_is_destroyer()
		num_enemy_subs: i32 = 0
		for u in enemy_units_in_sea_territories {
			if sub_p2(sub_c2, u) {
				num_enemy_subs += 1
			}
		}
		num_my_destroyers: i32 = 0
		for u in my_units_in_sea_territories {
			if dest_p2(dest_c2, u) {
				num_my_destroyers += 1
			}
		}
		if num_enemy_subs > 2 * num_my_destroyers {
			need_destroyer = true
		}
		pro_logger_trace(
			fmt.tprintf(
				"%s, enemyDistance=%v, alliedDistance=%v, enemyAirUnits=%s, enemySeaUnits=%s, mySeaUnits=%s, needDestroyer=%v",
				territory_to_string(t),
				enemy_distance,
				allied_distance,
				pro_utils_summarize_units(enemy_units_in_land_territories),
				pro_utils_summarize_units(enemy_units_in_sea_territories),
				pro_utils_summarize_units(my_units_in_sea_territories),
				need_destroyer,
			),
		)
		delete(enemy_units_in_land_territories)
		delete(enemy_units_in_sea_territories)
		delete(my_units_in_sea_territories)

		// Purchase naval defenders until I have local naval superiority
		units_to_place: [dynamic]^Unit
		for purchase_territory in selected_purchase_territories {
			remaining_unit_production :=
				pro_purchase_territory_get_remaining_unit_production(purchase_territory)
			pro_logger_trace(
				fmt.tprintf(
					"%s, purchaseTerritory=%s, remainingUnitProduction=%v",
					territory_to_string(t),
					territory_to_string(
						pro_purchase_territory_get_territory(purchase_territory),
					),
					remaining_unit_production,
				),
			)
			if remaining_unit_production <= 0 {
				continue
			}
			sea_purchase_options_for_territory :=
				pro_purchase_validation_utils_find_purchase_options_for_territory(
					self.pro_data,
					self.player,
					pro_purchase_option_map_get_sea_defense_options(purchase_options),
					t,
					pro_purchase_territory_get_territory(purchase_territory),
					self.is_bid,
				)
			for ppo in pro_purchase_option_map_get_air_options(purchase_options) {
				append(&sea_purchase_options_for_territory, ppo)
			}
			for {
				if pro_battle_utils_territory_has_local_naval_superiority(
					self.pro_data, self.calc, t, self.player, purchase_territories,
					units_to_place,
				) {
					break
				}
				pro_purchase_validation_utils_remove_invalid_purchase_options(
					self.pro_data, self.player, self.start_of_turn_data,
					&sea_purchase_options_for_territory, self.resource_tracker,
					remaining_unit_production, units_to_place, purchase_territories,
					0, t,
				)
				defense_efficiencies := make(map[^Pro_Purchase_Option]f64)
				for ppo in sea_purchase_options_for_territory {
					defense_efficiencies[ppo] =
						pro_purchase_option_get_sea_defense_efficiency(
							ppo,
							self.data,
							owned_local_units,
							units_to_place,
							need_destroyer,
							unused_carrier_capacity,
							unused_local_carrier_capacity,
						)
				}
				selected_option := pro_purchase_utils_randomize_purchase_option(
					defense_efficiencies, "Sea Defense",
				)
				delete(defense_efficiencies)
				if selected_option == nil {
					break
				}
				if pro_purchase_option_is_destroyer(selected_option) {
					need_destroyer = false
				}

				pro_resource_tracker_purchase(self.resource_tracker, selected_option)
				remaining_unit_production -=
					pro_purchase_option_get_quantity(selected_option)
				temp_units := pro_purchase_option_create_temp_units(selected_option)
				for u in temp_units {
					append(&units_to_place, u)
				}
				delete(temp_units)
				if pro_purchase_option_is_carrier(selected_option) ||
				   pro_purchase_option_is_air(selected_option) {
					unused_carrier_capacity =
						pro_transport_utils_get_unused_carrier_capacity(
							self.player, t, units_to_place,
						)
					unused_local_carrier_capacity =
						pro_transport_utils_get_unused_local_carrier_capacity(
							self.player, t, units_to_place,
						)
				}
				pro_logger_trace(
					fmt.tprintf(
						"%s, added sea defender for naval superiority: %s, unusedCarrierCapacity=%v, unusedLocalCarrierCapacity=%v",
						territory_to_string(t),
						unit_type_get_name(
							pro_purchase_option_get_unit_type(selected_option),
						),
						unused_carrier_capacity,
						unused_local_carrier_capacity,
					),
				)
			}
			delete(sea_purchase_options_for_territory)
		}

		// Add sea defender units to place territory
		if len(units_to_place) > 0 {
			pro_purchase_ai_add_units_to_place_territory(
				self, place_territory, &units_to_place, purchase_territories,
			)
			bought_units = true
		}
		delete(units_to_place)

		// Loop through adjacent purchase territories and purchase
		// transport/amphib units. Compute findMaxMovementForTransports
		// inline (mirrors ProTransportUtils.findMaxMovementForTransports).
		distance: i32 = 0
		for ppo in pro_purchase_option_map_get_sea_transport_options(purchase_options) {
			mv := pro_purchase_option_get_movement(ppo)
			if mv > distance {
				distance = mv
			}
		}
		territories_to_check: map[^Territory]struct {}
		for purchase_territory in selected_purchase_territories {
			land_territory := pro_purchase_territory_get_territory(purchase_territory)
			sea_territories := game_map_get_neighbors_distance_predicate(
				gm, land_territory, distance, can_move_sea_p, can_move_sea_c,
			)
			for sea_territory, _ in sea_territories {
				more := game_map_get_neighbors_distance(gm, sea_territory, distance)
				for n, _ in more {
					territories_to_check[n] = {}
				}
				delete(more)
			}
			delete(sea_territories)
			land_neighbors := game_map_get_neighbors_predicate(
				gm, t, land_p, land_c,
			)
			for n, _ in land_neighbors {
				territories_to_check[n] = {}
			}
			delete(land_neighbors)
		}
		empty_tt: [dynamic]^Territory
		empty_ta: [dynamic]^Territory
		territory_value_map := pro_territory_value_utils_find_territory_values(
			self.pro_data, self.player, empty_tt, empty_ta, territories_to_check,
		)
		delete(empty_tt)
		delete(empty_ta)
		delete(territories_to_check)
		pro_logger_trace(
			fmt.tprintf("%s, transportMovement=%v", territory_to_string(t), distance),
		)
		for purchase_territory in selected_purchase_territories {
			land_territory := pro_purchase_territory_get_territory(purchase_territory)

			remaining_unit_production :=
				pro_purchase_territory_get_remaining_unit_production(purchase_territory)
			pro_logger_trace(
				fmt.tprintf(
					"%s, purchaseTerritory=%s, remainingUnitProduction=%v",
					territory_to_string(t),
					territory_to_string(land_territory),
					remaining_unit_production,
				),
			)
			if remaining_unit_production <= 0 {
				continue
			}

			ownland_p, ownland_c := matches_unit_is_owned_by(self.player)
			owned_local_amphib_units := territory_get_matches(
				land_territory, ownland_p, ownland_c,
			)

			sea_transport_purchase_options_for_territory :=
				pro_purchase_validation_utils_find_purchase_options_for_territory(
					self.pro_data,
					self.player,
					pro_purchase_option_map_get_sea_transport_options(purchase_options),
					t,
					land_territory,
					self.is_bid,
				)
			amphib_purchase_options_for_territory :=
				pro_purchase_validation_utils_find_purchase_options_for_territory_5(
					self.pro_data,
					self.player,
					pro_purchase_option_map_get_land_options(purchase_options),
					land_territory,
					self.is_bid,
				)

			// Find transports that need loaded and units to ignore that
			// are already paired up.
			transports_that_need_units: [dynamic]^Unit
			potential_units_to_load: map[^Unit]struct {}
			sea_territories := game_map_get_neighbors_distance_predicate(
				gm, land_territory, distance, can_move_sea_p, can_move_sea_c,
			)
			owned_xport_p, owned_xport_c := pro_matches_unit_is_owned_transport(
				self.player,
			)
			for sea_territory, _ in sea_territories {
				units_in_territory := pro_purchase_utils_get_place_units(
					sea_territory, purchase_territories,
				)
				for u in territory_get_units(sea_territory) {
					append(&units_in_territory, u)
				}
				transports: [dynamic]^Unit
				for u in units_in_territory {
					if owned_xport_p(owned_xport_c, u) {
						append(&transports, u)
					}
				}
				delete(units_in_territory)
				for transport in transports {
					append(&transports_that_need_units, transport)
					territories_to_load_from := game_map_get_neighbors_distance(
						gm, sea_territory, distance,
					)
					to_remove: [dynamic]^Territory
					for pt, _ in territories_to_load_from {
						val := territory_value_map[pt]
						if territory_is_water(pt) || val > 0.25 {
							append(&to_remove, pt)
						}
					}
					for pt in to_remove {
						delete_key(&territories_to_load_from, pt)
					}
					delete(to_remove)
					ignore_list: [dynamic]^Unit
					for u, _ in potential_units_to_load {
						append(&ignore_list, u)
					}
					units := pro_transport_utils_get_units_to_transport_from_territories_4(
						self.player, transport, territories_to_load_from, ignore_list,
					)
					for u in units {
						potential_units_to_load[u] = {}
					}
					delete(units)
					delete(ignore_list)
					delete(territories_to_load_from)
				}
				delete(transports)
			}
			delete(sea_territories)

			// Determine whether transports, amphib units, or both are
			// needed.
			lhood := game_map_get_neighbors_predicate(gm, t, land_p, land_c)
			combat_xport_p, combat_xport_c :=
				pro_matches_unit_is_owned_combat_transportable_unit(self.player)
			for neighbor, _ in lhood {
				if territory_value_map[neighbor] <= 0.25 {
					units_in_territory: [dynamic]^Unit
					for u in territory_get_units(neighbor) {
						append(&units_in_territory, u)
					}
					more := pro_purchase_utils_get_place_units(neighbor, purchase_territories)
					for u in more {
						append(&units_in_territory, u)
					}
					delete(more)
					for u in units_in_territory {
						if combat_xport_p(combat_xport_c, u) {
							potential_units_to_load[u] = {}
						}
					}
					delete(units_in_territory)
				}
			}
			delete(lhood)
			ptl_list: [dynamic]^Unit
			for u, _ in potential_units_to_load {
				append(&ptl_list, u)
			}
			pro_logger_trace(
				fmt.tprintf(
					"%s, potentialUnitsToLoad=%s, transportsThatNeedUnits=%s",
					territory_to_string(t),
					pro_utils_summarize_units(ptl_list),
					pro_utils_summarize_units(transports_that_need_units),
				),
			)
			delete(ptl_list)

			// Purchase transports and amphib units
			amphib_units_to_place: [dynamic]^Unit
			transport_units_to_place: [dynamic]^Unit
			for {
				if len(transports_that_need_units) > 0 {
					transport := transports_that_need_units[0]
					transport_capacity := unit_attachment_get_transport_capacity(
						unit_get_unit_attachment(transport),
					)

					ptl_arr: [dynamic]^Unit
					for u, _ in potential_units_to_load {
						append(&ptl_arr, u)
					}
					selected_units :=
						pro_transport_utils_select_units_to_transport_from_list(
							transport, ptl_arr,
						)
					delete(ptl_arr)
					if len(selected_units) > 0 {
						for u in selected_units {
							delete_key(&potential_units_to_load, u)
						}
						transport_capacity -= pro_transport_utils_find_units_transport_cost(
							selected_units,
						)
					}
					delete(selected_units)

					for transport_capacity > 0 {
						pro_purchase_validation_utils_remove_invalid_purchase_options(
							self.pro_data, self.player, self.start_of_turn_data,
							&amphib_purchase_options_for_territory, self.resource_tracker,
							remaining_unit_production, amphib_units_to_place,
							purchase_territories, 0, t,
						)
						amphib_efficiencies := make(map[^Pro_Purchase_Option]f64)
						for ppo in amphib_purchase_options_for_territory {
							if pro_purchase_option_get_transport_cost(ppo) <=
							   transport_capacity {
								amphib_efficiencies[ppo] =
									pro_purchase_option_get_amphib_efficiency(
										ppo,
										self.data,
										owned_local_amphib_units,
										amphib_units_to_place,
									)
							}
						}
						amphib_choice := pro_purchase_utils_randomize_purchase_option(
							amphib_efficiencies, "Amphib",
						)
						delete(amphib_efficiencies)
						if amphib_choice == nil {
							break
						}
						temp_units := pro_purchase_option_create_temp_units(amphib_choice)
						for u in temp_units {
							append(&amphib_units_to_place, u)
						}
						delete(temp_units)
						pro_resource_tracker_purchase(self.resource_tracker, amphib_choice)
						remaining_unit_production -=
							pro_purchase_option_get_quantity(amphib_choice)
						transport_capacity -= pro_purchase_option_get_transport_cost(
							amphib_choice,
						)
						pro_logger_trace(
							fmt.tprintf(
								"Selected unit=%s",
								unit_type_get_name(
									pro_purchase_option_get_unit_type(amphib_choice),
								),
							),
						)
					}
					ordered_remove(&transports_that_need_units, 0)
				} else {
					pro_purchase_validation_utils_remove_invalid_purchase_options(
						self.pro_data, self.player, self.start_of_turn_data,
						&sea_transport_purchase_options_for_territory,
						self.resource_tracker, remaining_unit_production,
						transport_units_to_place, purchase_territories, 0, t,
					)
					transport_efficiencies := make(map[^Pro_Purchase_Option]f64)
					for ppo in sea_transport_purchase_options_for_territory {
						transport_efficiencies[ppo] =
							pro_purchase_option_get_transport_efficiency_ratio(ppo)
					}
					transport_choice := pro_purchase_utils_randomize_purchase_option(
						transport_efficiencies, "Sea Transport",
					)
					delete(transport_efficiencies)
					if transport_choice == nil {
						break
					}
					transports := pro_purchase_option_create_temp_units(transport_choice)
					for u in transports {
						append(&transport_units_to_place, u)
						append(&transports_that_need_units, u)
					}
					delete(transports)
					pro_resource_tracker_purchase(self.resource_tracker, transport_choice)
					remaining_unit_production -=
						pro_purchase_option_get_quantity(transport_choice)
					ptl_log: [dynamic]^Unit
					for u, _ in potential_units_to_load {
						append(&ptl_log, u)
					}
					pro_logger_trace(
						fmt.tprintf(
							"Selected unit=%s, potentialUnitsToLoad=%v, transportsThatNeedUnits=%v",
							unit_type_get_name(
								pro_purchase_option_get_unit_type(transport_choice),
							),
							ptl_log,
							transports_that_need_units,
						),
					)
					delete(ptl_log)
				}
			}

			if len(amphib_units_to_place) > 0 || len(transport_units_to_place) > 0 {
				for ppt in pro_purchase_territory_get_can_place_territories(purchase_territory) {
					if land_territory == pro_place_territory_get_territory(ppt) {
						pro_purchase_ai_add_units_to_place(self, ppt, amphib_units_to_place)
					} else if pro_place_territory_equals(place_territory, ppt) {
						pro_purchase_ai_add_units_to_place(self, ppt, transport_units_to_place)
					}
				}
				bought_units = true
			}
			pro_logger_trace(
				fmt.tprintf(
					"%s, purchaseTerritory=%s, transportUnitsToPlace=%v, amphibUnitsToPlace=%v",
					territory_to_string(t),
					territory_to_string(land_territory),
					transport_units_to_place,
					amphib_units_to_place,
				),
			)
			delete(amphib_units_to_place)
			delete(transport_units_to_place)
			delete(transports_that_need_units)
			delete(potential_units_to_load)
			delete(owned_local_amphib_units)
			delete(sea_transport_purchase_options_for_territory)
			delete(amphib_purchase_options_for_territory)
		}
		delete(territory_value_map)
		delete(owned_local_units)
		delete(selected_purchase_territories)
	}

	// If we wanted to buy a fleet, but didn't because it couldn't be
	// defended, check if we should save up for one.
	return !bought_units &&
		   wanted_to_buy_units_but_could_not_defend_them &&
		   pro_purchase_ai_should_save_up_for_a_fleet(
			   self, purchase_options, purchase_territories,
		   )
}
