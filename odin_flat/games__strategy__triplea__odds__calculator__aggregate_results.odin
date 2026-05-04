package game

import "core:math"

Aggregate_Results :: struct {
	results: [dynamic]^Battle_Results,
	time:    i64,
}

aggregate_results_new_int :: proc(expected_count: i32) -> ^Aggregate_Results {
	self := new(Aggregate_Results)
	self.results = make([dynamic]^Battle_Results, 0, int(expected_count))
	self.time = 0
	return self
}

aggregate_results_new_list :: proc(results: [dynamic]^Battle_Results) -> ^Aggregate_Results {
	self := new(Aggregate_Results)
	self.results = make([dynamic]^Battle_Results, 0, len(results))
	for r in results {
		append(&self.results, r)
	}
	self.time = 0
	return self
}

aggregate_results_add_result :: proc(self: ^Aggregate_Results, result: ^Battle_Results) {
	append(&self.results, result)
}

aggregate_results_set_time :: proc(self: ^Aggregate_Results, time: i64) {
	self.time = time
}

@(private = "file")
aggregate_results_battle_draw :: proc(r: ^Battle_Results) -> bool {
	if r.who_won != .ATTACKER && r.who_won != .DEFENDER {
		return true
	}
	return len(r.remaining_attacking_units) == 0 && len(r.remaining_defending_units) == 0
}

@(private = "file")
aggregate_results_attacker_won :: proc(r: ^Battle_Results) -> bool {
	return !aggregate_results_battle_draw(r) && r.who_won == .ATTACKER
}

aggregate_results_get_attacker_win_percent :: proc(self: ^Aggregate_Results) -> f64 {
	if len(self.results) == 0 {
		return math.nan_f64()
	}
	sum: f64 = 0
	for r in self.results {
		if aggregate_results_attacker_won(r) {
			sum += 1
		}
	}
	return sum / f64(len(self.results))
}

aggregate_results_get_average_attacking_units_left :: proc(self: ^Aggregate_Results) -> f64 {
	if len(self.results) == 0 {
		return math.nan_f64()
	}
	sum: f64 = 0
	for r in self.results {
		sum += f64(len(battle_results_get_remaining_attacking_units(r)))
	}
	return sum / f64(len(self.results))
}

aggregate_results_get_average_defending_units_left :: proc(self: ^Aggregate_Results) -> f64 {
	if len(self.results) == 0 {
		return math.nan_f64()
	}
	sum: f64 = 0
	for r in self.results {
		sum += f64(len(battle_results_get_remaining_defending_units(r)))
	}
	return sum / f64(len(self.results))
}

aggregate_results_get_average_battle_rounds_fought :: proc(self: ^Aggregate_Results) -> f64 {
	if len(self.results) == 0 {
		return math.nan_f64()
	}
	sum: f64 = 0
	for r in self.results {
		sum += f64(r.battle_rounds_fought)
	}
	return sum / f64(len(self.results))
}

aggregate_results_get_battle_results_closest_to_average :: proc(self: ^Aggregate_Results) -> ^Battle_Results {
	if len(self.results) == 0 {
		return nil
	}
	best: ^Battle_Results = nil
	best_score: f64 = 0
	for r in self.results {
		score := aggregate_results_lambda_get_battle_results_closest_to_average_0(self, r)
		if best == nil || score < best_score {
			best = r
			best_score = score
		}
	}
	return best
}

aggregate_results_lambda_get_battle_results_closest_to_average_0 :: proc(self: ^Aggregate_Results, result: ^Battle_Results) -> f64 {
	return abs(f64(len(battle_results_get_remaining_attacking_units(result))) - aggregate_results_get_average_attacking_units_left(self)) +
		abs(f64(len(battle_results_get_remaining_defending_units(result))) - aggregate_results_get_average_defending_units_left(self))
}

aggregate_results_get_average_attacking_units_remaining :: proc(self: ^Aggregate_Results) -> [dynamic]^Unit {
	closest := aggregate_results_get_battle_results_closest_to_average(self)
	if closest == nil {
		return make([dynamic]^Unit, 0)
	}
	return battle_results_get_remaining_attacking_units(closest)
}

aggregate_results_get_average_defending_units_remaining :: proc(self: ^Aggregate_Results) -> [dynamic]^Unit {
	closest := aggregate_results_get_battle_results_closest_to_average(self)
	if closest == nil {
		return make([dynamic]^Unit, 0)
	}
	return battle_results_get_remaining_defending_units(closest)
}

// Java: getAverageTuvOfUnitsLeftOver(IntegerMap<UnitType>, IntegerMap<UnitType>) -> Tuple<Double, Double>
aggregate_results_get_average_tuv_of_units_left_over :: proc(
	self: ^Aggregate_Results,
	attacker_costs_for_tuv: ^Integer_Map_Unit_Type,
	defender_costs_for_tuv: ^Integer_Map_Unit_Type,
) -> ^Tuple(f64, f64) {
	attacker_sum: f64 = 0
	defender_sum: f64 = 0
	count := len(self.results)
	for r in self.results {
		attacker_sum += f64(tuv_utils_get_tuv(battle_results_get_remaining_attacking_units(r), attacker_costs_for_tuv))
		defender_sum += f64(tuv_utils_get_tuv(battle_results_get_remaining_defending_units(r), defender_costs_for_tuv))
	}
	a_mean: f64 = math.nan_f64()
	d_mean: f64 = math.nan_f64()
	if count > 0 {
		a_mean = attacker_sum / f64(count)
		d_mean = defender_sum / f64(count)
	}
	return tuple_new(f64, f64, a_mean, d_mean)
}

// Java: getAverageTuvSwing(GamePlayer, Collection<Unit>, GamePlayer, Collection<Unit>, GameData) -> double
aggregate_results_get_average_tuv_swing :: proc(
	self: ^Aggregate_Results,
	attacker: ^Game_Player,
	attackers: [dynamic]^Unit,
	defender: ^Game_Player,
	defenders: [dynamic]^Unit,
	data: ^Game_Data,
) -> f64 {
	tuv_calculator := tuv_costs_calculator_new()
	attacker_costs_map := tuv_costs_calculator_get_costs_for_tuv(tuv_calculator, attacker)
	defender_costs_map := tuv_costs_calculator_get_costs_for_tuv(tuv_calculator, defender)
	attacker_costs_for_tuv := new(Integer_Map_Unit_Type)
	attacker_costs_for_tuv.entries = attacker_costs_map
	defender_costs_for_tuv := new(Integer_Map_Unit_Type)
	defender_costs_for_tuv.entries = defender_costs_map
	attacker_starting_tuv := tuv_utils_get_tuv(attackers, attacker_costs_for_tuv)
	defender_starting_tuv := tuv_utils_get_tuv(defenders, defender_costs_for_tuv)
	count := len(self.results)
	if count == 0 {
		return f64(defender_starting_tuv) - f64(attacker_starting_tuv) + math.nan_f64()
	}
	sum: f64 = 0
	for r in self.results {
		sum += aggregate_results_lambda_get_average_tuv_swing_1(attacker_costs_for_tuv, defender_costs_for_tuv, r)
	}
	mean := sum / f64(count)
	return f64(defender_starting_tuv) - f64(attacker_starting_tuv) + mean
}

// Java: lambda$getAverageTuvSwing$1(IntegerMap, IntegerMap, BattleResults)
aggregate_results_lambda_get_average_tuv_swing_1 :: proc(
	attacker_costs_for_tuv: ^Integer_Map_Unit_Type,
	defender_costs_for_tuv: ^Integer_Map_Unit_Type,
	result: ^Battle_Results,
) -> f64 {
	return f64(tuv_utils_get_tuv(battle_results_get_remaining_attacking_units(result), attacker_costs_for_tuv)) -
		f64(tuv_utils_get_tuv(battle_results_get_remaining_defending_units(result), defender_costs_for_tuv))
}

// Java: lambda$getDrawPercent$4(BattleResults) -> result.draw() ? 1 : 0
aggregate_results_lambda_get_draw_percent_4 :: proc(result: ^Battle_Results) -> f64 {
	if battle_results_draw(result) {
		return 1
	}
	return 0
}

// Java: lambda$getAttackerWinPercent$2(BattleResults) -> result.attackerWon() ? 1 : 0
aggregate_results_lambda_get_attacker_win_percent_2 :: proc(result: ^Battle_Results) -> f64 {
	if battle_results_attacker_won(result) {
		return 1
	}
	return 0
}

// Java: lambda$getDefenderWinPercent$3(BattleResults) -> result.defenderWon() ? 1 : 0
aggregate_results_lambda_get_defender_win_percent_3 :: proc(result: ^Battle_Results) -> f64 {
	if battle_results_defender_won(result) {
		return 1
	}
	return 0
}
