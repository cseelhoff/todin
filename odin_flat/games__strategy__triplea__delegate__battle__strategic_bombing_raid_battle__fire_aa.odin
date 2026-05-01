package game

// Fire_Aa — IExecutable inner class of StrategicBombingRaidBattle.
// Mirrors Java fields:
//   DiceRoll dice;
//   CasualtyDetails casualties;
//   final Collection<Unit> casualtiesSoFar = new ArrayList<>();
//   Collection<Unit> validAttackingUnitsForThisRoll;
//   final boolean determineAttackers;
Fire_Aa :: struct {
	using i_executable:                  I_Executable,
	this_0:                              ^Strategic_Bombing_Raid_Battle,
	dice:                                ^Dice_Roll,
	casualties:                          ^Casualty_Details,
	casualties_so_far:                   [dynamic]^Unit,
	valid_attacking_units_for_this_roll: [dynamic]^Unit,
	determine_attackers:                 bool,
}

// FireAa(final Collection<Unit> attackers)
fire_aa_new_with_attackers :: proc(
	this_0: ^Strategic_Bombing_Raid_Battle,
	attackers: [dynamic]^Unit,
) -> ^Fire_Aa {
	self := new(Fire_Aa)
	self.this_0 = this_0
	self.casualties_so_far = make([dynamic]^Unit)
	self.valid_attacking_units_for_this_roll = attackers
	self.determine_attackers = false
	return self
}

// FireAa()
fire_aa_new :: proc(this_0: ^Strategic_Bombing_Raid_Battle) -> ^Fire_Aa {
	self := new(Fire_Aa)
	self.this_0 = this_0
	self.casualties_so_far = make([dynamic]^Unit)
	self.valid_attacking_units_for_this_roll = make([dynamic]^Unit)
	self.determine_attackers = true
	return self
}
