package game

import "core:math"

// Java owners covered by this file:
//   - games.strategy.triplea.util.TuvCostsCalculator

Tuv_Costs_Calculator :: struct {
	costs_all:        map[^Unit_Type]i32,
	costs_per_player: map[^Game_Player]map[^Unit_Type]i32,
}

tuv_costs_calculator_new :: proc() -> ^Tuv_Costs_Calculator {
	self := new(Tuv_Costs_Calculator)
	self.costs_per_player = make(map[^Game_Player]map[^Unit_Type]i32)
	// costs_all is left as nil map (Java: @Nullable, lazily set)
	return self
}

// Lambda: differentCosts.computeIfAbsent(ut, key -> new ArrayList<>())
tuv_costs_calculator_lambda_get_costs_for_tuv_for_all_players_merged_and_averaged_0 :: proc(
	key: ^Unit_Type,
) -> [dynamic]i32 {
	return make([dynamic]i32)
}

// Java: getCostsForTuv(GamePlayer player)
//   return costsPerPlayer.computeIfAbsent(player, this::computeCostsForTuv);
tuv_costs_calculator_get_costs_for_tuv :: proc(
	self: ^Tuv_Costs_Calculator,
	player: ^Game_Player,
) -> map[^Unit_Type]i32 {
	if cached, ok := self.costs_per_player[player]; ok {
		return cached
	}
	computed := tuv_costs_calculator_compute_costs_for_tuv(self, player)
	self.costs_per_player[player] = computed
	return computed
}

// Java: private static int getTotalTuv(
//           final UnitType unitType,
//           final IntegerMap<UnitType> costs,
//           final Set<UnitType> alreadyAdded)
tuv_costs_calculator_get_total_tuv :: proc(
	unit_type: ^Unit_Type,
	costs: map[^Unit_Type]i32,
	already_added: map[^Unit_Type]struct {},
) -> i32 {
	ua := unit_type_get_unit_attachment(unit_type)
	if unit_attachment_get_tuv(ua) > -1 {
		return unit_attachment_get_tuv(ua)
	}
	tuv := costs[unit_type]
	consumes := unit_attachment_get_consumes_units(ua)
	if _, seen := already_added[unit_type]; len(consumes) == 0 || seen {
		return tuv
	}
	already_added_mut := already_added
	already_added_mut[unit_type] = {}
	for ut, count in consumes {
		tuv += count * tuv_costs_calculator_get_total_tuv(ut, costs, already_added_mut)
	}
	delete_key(&already_added_mut, unit_type)
	return tuv
}

// Java: private IntegerMap<UnitType> computeBaseCostsForPlayer(GamePlayer player)
//   final Resource pus = player.getData().getResourceList().getResourceOrThrow(Constants.PUS);
//   final IntegerMap<UnitType> costs = new IntegerMap<>();
//   final ProductionFrontier frontier = player.getProductionFrontier();
//   if (frontier != null) {
//     for (final ProductionRule rule : frontier.getRules()) {
//       final NamedAttachable resourceOrUnit = rule.getAnyResultKey();
//       if (!(resourceOrUnit instanceof UnitType)) continue;
//       ...
//     }
//   }
//   return costs;
//
// Constants.PUS resolves to the literal "PUs" (matches the convention used
// throughout odin_flat/, e.g. resource_collection.odin / ai_utils.odin).
// `instanceof UnitType` is the `Named_Kind.Unit_Type` discriminator on the
// embedded Named tag; UnitType pointers and their NamedAttachable base share
// the same address because Named_Attachable is the first embedded field of
// Unit_Type, so `cast(^Unit_Type)` of the rawptr key is layout-safe.
tuv_costs_calculator_compute_base_costs_for_player :: proc(
	self: ^Tuv_Costs_Calculator,
	player: ^Game_Player,
) -> map[^Unit_Type]i32 {
	data := game_player_get_data(player)
	pus := resource_list_get_resource_or_throw(game_data_get_resource_list(data), "PUs")
	costs := make(map[^Unit_Type]i32)
	frontier := player.production_frontier
	if frontier != nil {
		rules := production_frontier_get_rules(frontier)
		for rule in rules {
			named: ^Named_Attachable = nil
			for k, _ in rule.results.map_values {
				named = cast(^Named_Attachable)k
				break
			}
			if named == nil || named.default_named.named.kind != .Unit_Type {
				continue
			}
			type := cast(^Unit_Type)named
			cost_per_group := rule.costs.map_values[rawptr(pus)]
			number_produced := rule.results.map_values[rawptr(type)]
			// we average the cost for a single unit, rounding up
			rounded_cost_per_single := i32(
				math.ceil(f64(cost_per_group) / f64(number_produced)),
			)
			costs[type] = rounded_cost_per_single
		}
	}
	return costs
}

// Java: private static IntegerMap<UnitType>
//   getCostsForTuvForAllPlayersMergedAndAveraged(GameData data)
// Computes a per-UnitType TUV averaged across every production rule that
// produces it, then overlays any UnitAttachment.tuv override > -1 from the
// XML. See TuvCostsCalculator.java for the full algorithm.
tuv_costs_calculator_get_costs_for_tuv_for_all_players_merged_and_averaged :: proc(
	data: ^Game_Data,
) -> map[^Unit_Type]i32 {
	pus := resource_list_get_resource_or_throw(game_data_get_resource_list(data), "PUs")
	costs := make(map[^Unit_Type]i32)
	different_costs := make(map[^Unit_Type][dynamic]i32)
	defer {
		for _, list in different_costs {
			delete(list)
		}
		delete(different_costs)
	}
	rules := production_rule_list_get_production_rules(
		game_data_get_production_rule_list(data),
	)
	defer delete(rules)
	for rule in rules {
		// only works for the first result, so we are assuming each
		// purchase frontier only gives one type of unit
		named: ^Named_Attachable = nil
		for k, _ in rule.results.map_values {
			named = cast(^Named_Attachable)k
			break
		}
		if named == nil || named.default_named.named.kind != .Unit_Type {
			continue
		}
		ut := cast(^Unit_Type)named
		number_produced := rule.results.map_values[rawptr(ut)]
		cost_per_group := rule.costs.map_values[rawptr(pus)]
		// we round up the cost
		rounded_cost_per_single := i32(
			math.ceil(f64(cost_per_group) / f64(number_produced)),
		)
		list, exists := different_costs[ut]
		if !exists {
			list = tuv_costs_calculator_lambda_get_costs_for_tuv_for_all_players_merged_and_averaged_0(
				ut,
			)
		}
		append(&list, rounded_cost_per_single)
		different_costs[ut] = list
	}
	for ut, costs_for_type in different_costs {
		total_costs: i32 = 0
		for cost in costs_for_type {
			total_costs += cost
		}
		averaged_cost := i32(
			math.round(f64(total_costs) / f64(len(costs_for_type))),
		)
		costs[ut] = averaged_cost
	}
	// Add any units that have XML TUV even if they aren't purchasable
	utl := game_data_get_unit_type_list(data)
	all_unit_types := unit_type_list_iterator(utl)
	defer delete(all_unit_types)
	for unit_type in all_unit_types {
		ua := unit_type_get_unit_attachment(unit_type)
		if unit_attachment_get_tuv(ua) > -1 {
			costs[unit_type] = unit_attachment_get_tuv(ua)
		}
	}
	return costs
}

