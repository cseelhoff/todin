package game

Aa_Casualty_Selector :: struct {}

aa_casualty_selector_lambda_build_casualty_details_0 :: proc(
	casualty_details: ^Casualty_Details,
	unit: ^Unit,
	unit_key: ^Unit,
	hp: i64,
) -> i64 {
	if hp > 1 {
		casualty_list_add_to_damaged(&casualty_details.casualty_list, unit)
	} else {
		casualty_list_add_to_killed(&casualty_details.casualty_list, unit)
	}
	return hp - 1
}

// games.strategy.triplea.delegate.battle.casualty.AaCasualtySelector#findRandomTargets(java.util.List,games.strategy.engine.delegate.IDelegateBridge,int)
aa_casualty_selector_find_random_targets :: proc(
	available_targets: [dynamic]^Unit,
	bridge: ^I_Delegate_Bridge,
	hits: i32,
) -> [dynamic]^Unit {
	// No need for random if all targets will be hit. The logic below would
	// infinite loop otherwise if hits are greater.
	if hits >= i32(len(available_targets)) {
		return available_targets
	}
	hit_random := i_delegate_bridge_get_random(
		bridge,
		i32(len(available_targets)),
		hits,
		nil,
		I_Random_Stats_Dice_Type.ENGINE,
		"Deciding which planes should die due to AA fire",
	)
	// turn the random numbers into a unique set of targets
	hit_targets := make(map[i32]struct {})
	index: i32 = 0
	for random_index in hit_random {
		index = (index + random_index) % i32(len(available_targets))
		for {
			_, present := hit_targets[index]
			if !present {
				break
			}
			index = (index + 1) % i32(len(available_targets))
		}
		hit_targets[index] = {}
	}
	result := make([dynamic]^Unit, 0)
	for idx in hit_targets {
		append(&result, available_targets[idx])
	}
	return result
}

// games.strategy.triplea.delegate.battle.casualty.AaCasualtySelector#findRolledTargets(java.util.List,games.strategy.triplea.delegate.DiceRoll)
aa_casualty_selector_find_rolled_targets :: proc(
	available_targets: [dynamic]^Unit,
	dice: ^Dice_Roll,
) -> [dynamic]^Unit {
	assert(
		len(available_targets) == len(dice.rolls),
		"findRolledTargets needs one roll per target",
	)
	result := make([dynamic]^Unit, 0)
	for roll_idx in 0 ..< i32(len(dice.rolls)) {
		if aa_casualty_selector_lambda__find_rolled_targets__1(dice, roll_idx) {
			append(&result, available_targets[roll_idx])
		}
	}
	return result
}

// games.strategy.triplea.delegate.battle.casualty.AaCasualtySelector#lambda$findRolledTargets$1(games.strategy.triplea.delegate.DiceRoll,int)
aa_casualty_selector_lambda__find_rolled_targets__1 :: proc(
	dice: ^Dice_Roll,
	roll_idx: i32,
) -> bool {
	return dice.rolls[roll_idx].type == Die_Die_Type.HIT
}

