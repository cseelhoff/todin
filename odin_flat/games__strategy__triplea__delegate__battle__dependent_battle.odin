package game

Dependent_Battle :: struct {
	using abstract_battle: Abstract_Battle,
	attacking_from_map: map[^Territory][dynamic]^Unit,
	attacking_from: map[^Territory]bool,
	amphibious_attack_from: [dynamic]^Territory,
}

// Java owners covered by this file:
//   - games.strategy.triplea.delegate.battle.DependentBattle

