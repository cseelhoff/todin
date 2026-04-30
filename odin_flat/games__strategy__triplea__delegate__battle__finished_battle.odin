package game

Finished_Battle :: struct {
	using abstract_battle: Abstract_Battle,
	amphibious_attack_from: [dynamic]^Territory,
	attacking_from_map: map[^Territory][dynamic]^Unit,
}

// Java owners covered by this file:
//   - games.strategy.triplea.delegate.battle.FinishedBattle

finished_battle_get_attacking_from_map :: proc(self: ^Finished_Battle) -> map[^Territory][dynamic]^Unit {
	return self.attacking_from_map
}

finished_battle_is_empty :: proc(self: ^Finished_Battle) -> bool {
	return len(self.attacking_units) == 0
}

finished_battle_lambda_add_attack_change_0 :: proc(k: ^Territory) -> [dynamic]^Unit {
	return make([dynamic]^Unit)
}

