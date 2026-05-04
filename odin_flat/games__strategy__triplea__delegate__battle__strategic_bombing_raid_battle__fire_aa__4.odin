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
	self.execute = fire_aa_4_execute
	return self
}

// games.strategy.triplea.delegate.battle.StrategicBombingRaidBattle$FireAa$4#execute
//
// Java body:
//   if (!validAttackingUnitsForThisRoll.isEmpty()) {
//       removeAaHits(bridge, casualties, currentTypeAa);
//   }
// validAttackingUnitsForThisRoll and casualties are fields of the enclosing
// FireAa instance; removeAaHits is a method on the outer StrategicBombingRaidBattle.
fire_aa_4_execute :: proc(self_base: ^I_Executable, stack: ^Execution_Stack, bridge: ^I_Delegate_Bridge) {
	_ = stack
	self := cast(^Fire_Aa_4)self_base
	outer := self.this_0
	if len(outer.valid_attacking_units_for_this_roll) > 0 {
		strategic_bombing_raid_battle_remove_aa_hits(
			outer.this_0,
			bridge,
			outer.casualties,
			self.val_current_type_aa,
		)
	}
}

