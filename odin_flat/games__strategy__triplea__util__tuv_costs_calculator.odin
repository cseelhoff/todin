package game

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

