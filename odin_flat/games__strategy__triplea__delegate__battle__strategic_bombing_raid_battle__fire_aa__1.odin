package game

Fire_Aa_1 :: struct {
	using i_executable: I_Executable,
	outer:               ^Fire_Aa,
	current_possible_aa: [dynamic]^Unit,
	current_type_aa:     string,
}

// Java owners covered by this file:
//   - games.strategy.triplea.delegate.battle.StrategicBombingRaidBattle$FireAa$1

fire_aa_1_new :: proc(
	outer: ^Fire_Aa,
	current_possible_aa: [dynamic]^Unit,
	current_type_aa: string,
) -> ^Fire_Aa_1 {
	self := new(Fire_Aa_1)
	self.outer = outer
	self.current_possible_aa = current_possible_aa
	self.current_type_aa = current_type_aa
	return self
}

