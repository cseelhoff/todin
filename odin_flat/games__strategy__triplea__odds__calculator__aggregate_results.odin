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
