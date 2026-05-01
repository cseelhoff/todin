package game

// Java owners covered by this file:
//   - games.strategy.triplea.delegate.battle.StrategicBombingRaidBattle$FireAa$2
//
// Second anonymous IExecutable inside FireAa.execute (calculateCasualties step).
// Captures the enclosing FireAa instance plus the loop-local currentTypeAa
// and currentPossibleAa.

Fire_Aa_2 :: struct {
	using i_executable:      I_Executable,
	this_0:                  ^Fire_Aa,
	val_current_type_aa:     string,
	val_current_possible_aa: [dynamic]^Unit,
}

fire_aa_2_new :: proc(
	this_0: ^Fire_Aa,
	val_current_possible_aa: [dynamic]^Unit,
	val_current_type_aa: string,
) -> ^Fire_Aa_2 {
	self := new(Fire_Aa_2)
	self.this_0 = this_0
	self.val_current_possible_aa = val_current_possible_aa
	self.val_current_type_aa = val_current_type_aa
	return self
}

