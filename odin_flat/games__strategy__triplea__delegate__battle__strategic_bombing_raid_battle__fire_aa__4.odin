package game

// Java owners covered by this file:
//   - games.strategy.triplea.delegate.battle.StrategicBombingRaidBattle$FireAa$4
//
// Fourth anonymous IExecutable inside FireAa.execute (removeHits step).
// Captures the enclosing FireAa instance plus the loop-local currentTypeAa.

Fire_Aa_4 :: struct {
	using i_executable:  I_Executable,
	this_0:              ^Fire_Aa,
	val_current_type_aa: string,
}

fire_aa_4_new :: proc(this_0: ^Fire_Aa, val_current_type_aa: string) -> ^Fire_Aa_4 {
	self := new(Fire_Aa_4)
	self.this_0 = this_0
	self.val_current_type_aa = val_current_type_aa
	return self
}

