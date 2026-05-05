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
	self.i_executable.execute = fire_aa_2_execute
	return self
}

// games.strategy.triplea.delegate.battle.StrategicBombingRaidBattle$FireAa$2#execute(
//     ExecutionStack, IDelegateBridge)
//
// Java body (the "calculateCasualties" anonymous IExecutable inside FireAa.execute):
//   if (!validAttackingUnitsForThisRoll.isEmpty()) {
//     final CasualtyDetails details =
//         calculateCasualties(
//             validAttackingUnitsForThisRoll, currentPossibleAa, bridge,
//             dice, currentTypeAa);
//     markDamaged(details.getDamaged(), bridge);
//     casualties = details;
//     casualtiesSoFar.addAll(details.getKilled());
//   }
fire_aa_2_execute :: proc(
	self_base: ^I_Executable,
	stack: ^Execution_Stack,
	bridge: ^I_Delegate_Bridge,
) {
	_ = stack
	self := cast(^Fire_Aa_2)self_base
	fa := self.this_0
	sbr := fa.this_0

	if len(fa.valid_attacking_units_for_this_roll) == 0 {
		return
	}

	details := strategic_bombing_raid_battle_calculate_casualties(
		sbr,
		fa.valid_attacking_units_for_this_roll,
		self.val_current_possible_aa,
		bridge,
		fa.dice,
		self.val_current_type_aa,
	)

	damaged := casualty_list_get_damaged(&details.casualty_list)
	abstract_battle_mark_damaged(&sbr.abstract_battle, damaged, bridge)

	fa.casualties = details

	killed := casualty_list_get_killed(&details.casualty_list)
	for u in killed {
		append(&fa.casualties_so_far, u)
	}
}

