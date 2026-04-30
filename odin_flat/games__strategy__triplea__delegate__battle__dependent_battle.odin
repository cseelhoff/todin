package game

Dependent_Battle :: struct {
	using abstract_battle: Abstract_Battle,
	attacking_from_map: map[^Territory][dynamic]^Unit,
	attacking_from: map[^Territory]bool,
	amphibious_attack_from: [dynamic]^Territory,
}

// Java owners covered by this file:
//   - games.strategy.triplea.delegate.battle.DependentBattle

// Return attacking from Collection.
dependent_battle_get_attacking_from :: proc(self: ^Dependent_Battle) -> [dynamic]^Territory {
	result: [dynamic]^Territory
	for k, _ in self.attacking_from_map {
		append(&result, k)
	}
	return result
}

// Returns territories where there are amphibious attacks.
dependent_battle_get_amphibious_attack_territories :: proc(self: ^Dependent_Battle) -> [dynamic]^Territory {
	return self.amphibious_attack_from
}

