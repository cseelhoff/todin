package game

import "core:fmt"

Battle_Calculator :: struct {
	using i_battle_calculator: I_Battle_Calculator,
	game_data: ^Game_Data,
	tuv_calculator: ^Tuv_Costs_Calculator,
	keep_one_attacking_land_unit: bool,
	amphibious: bool,
	retreat_after_round: i32,
	retreat_after_x_units_left: i32,
	attacker_order_of_losses: string,
	defender_order_of_losses: string,
	cancelled: bool,
	is_running: bool,
}
// Java owners covered by this file:
//   - games.strategy.triplea.odds.calculator.BattleCalculator

battle_calculator_cancel :: proc(self: ^Battle_Calculator) {
	self.cancelled = true
}

// Mirrors Java's `mergeUnitCollections`: returns the union of two
// unit collections and panics (IllegalStateException analogue) if
// the two inputs share any element. Pointer identity matches Java
// HashSet semantics for Unit (which inherits Object equality via
// its UUID-keyed identity used elsewhere in the engine).
battle_calculator_merge_unit_collections :: proc(
	self: ^Battle_Calculator,
	c1: [dynamic]^Unit,
	c2: [dynamic]^Unit,
) -> [dynamic]^Unit {
	seen: map[^Unit]struct{}
	defer delete(seen)
	combined := make([dynamic]^Unit)
	for u in c1 {
		if _, exists := seen[u]; !exists {
			seen[u] = {}
			append(&combined, u)
		}
	}
	for u in c2 {
		if _, exists := seen[u]; !exists {
			seen[u] = {}
			append(&combined, u)
		}
	}
	if len(combined) != len(c1) + len(c2) {
		fmt.panicf(
			"Attackers and defenders collections must be distinct with no duplicates. " +
			"This helps catch logic errors in AI code that would otherwise be hard to debug.",
		)
	}
	return combined
}

