package game

Finished_Battle :: struct {
	using abstract_battle: Abstract_Battle,
	amphibious_attack_from: [dynamic]^Territory,
	attacking_from_map: map[^Territory][dynamic]^Unit,
}

// Java owners covered by this file:
//   - games.strategy.triplea.delegate.battle.FinishedBattle

