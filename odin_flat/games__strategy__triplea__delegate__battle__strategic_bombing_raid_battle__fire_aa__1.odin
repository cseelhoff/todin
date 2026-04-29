package game

Fire_Aa_1 :: struct {
	using parent:        I_Executable,
	outer:               ^Fire_Aa,
	current_possible_aa: [dynamic]^Unit,
	current_type_aa:     string,
}

// Java owners covered by this file:
//   - games.strategy.triplea.delegate.battle.StrategicBombingRaidBattle$FireAa$1

