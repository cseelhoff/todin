package game

Aa_Casualty_Selector :: struct {}

aa_casualty_selector_lambda_build_casualty_details_0 :: proc(
	casualty_details: ^Casualty_Details,
	unit: ^Unit,
	unit_key: ^Unit,
	hp: i64,
) -> i64 {
	if hp > 1 {
		casualty_list_add_to_damaged_one(&casualty_details.casualty_list, unit)
	} else {
		casualty_list_add_to_killed(&casualty_details.casualty_list, unit)
	}
	return hp - 1
}

// games.strategy.triplea.delegate.battle.casualty.AaCasualtySelector#calculateAvailableTargets(java.util.Collection,boolean)
aa_casualty_selector_calculate_available_targets :: proc(
	targets: [dynamic]^Unit,
	allow_multiple_hits_per_unit: bool,
) -> [dynamic]^Unit {
	targets_list := make([dynamic]^Unit, 0)
	for target in targets {
		raw_hp := unit_attachment_get_hit_points(unit_get_unit_attachment(target)) - unit_get_hits(target)
		hp_left: i32
		if allow_multiple_hits_per_unit {
			hp_left = raw_hp
		} else {
			hp_left = raw_hp
			if hp_left > 1 {
				hp_left = 1
			}
		}
		for hp: i32 = 0; hp < hp_left; hp += 1 {
			// if allow_multiple_hits_per_unit, then the target needs to be added for each hp
			append(&targets_list, target)
		}
	}
	return targets_list
}

// games.strategy.triplea.delegate.battle.casualty.AaCasualtySelector#buildCasualtyDetails(java.util.List,java.util.Collection)
aa_casualty_selector_build_casualty_details :: proc(
	available_targets: [dynamic]^Unit,
	hit_targets: [dynamic]^Unit,
) -> ^Casualty_Details {
	// availableTargets.stream().collect(groupingBy(identity, counting()))
	unit_hp := make(map[^Unit]i64)
	defer delete(unit_hp)
	for u in available_targets {
		unit_hp[u] = unit_hp[u] + 1
	}

	casualty_details := casualty_details_new()
	for hit_target in hit_targets {
		// availableTargets.get(availableTargets.indexOf(hitTarget))
		// — the canonical instance is the first occurrence in availableTargets
		// that equals hitTarget. Pointer equality matches Java reference equality.
		var_unit: ^Unit = nil
		for u in available_targets {
			if u == hit_target {
				var_unit = u
				break
			}
		}
		if var_unit == nil {
			continue
		}
		hp, present := unit_hp[var_unit]
		if !present {
			continue
		}
		new_hp := aa_casualty_selector_lambda_build_casualty_details_0(
			casualty_details,
			var_unit,
			var_unit,
			hp,
		)
		unit_hp[var_unit] = new_hp
	}
	return casualty_details
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

// games.strategy.triplea.delegate.battle.casualty.AaCasualtySelector#calculateRolledAaCasualties(java.util.List,games.strategy.triplea.delegate.power.calculator.AaPowerStrengthAndRolls,games.strategy.triplea.delegate.DiceRoll,games.strategy.engine.delegate.IDelegateBridge)
aa_casualty_selector_calculate_rolled_aa_casualties :: proc(
	available_targets: [dynamic]^Unit,
	unit_power_and_rolls_map: ^Aa_Power_Strength_And_Rolls,
	dice: ^Dice_Roll,
	bridge: ^I_Delegate_Bridge,
) -> [dynamic]^Unit {
	if aa_power_strength_and_rolls_calculate_total_rolls(unit_power_and_rolls_map) ==
			i32(len(available_targets)) &&
		dice_roll_get_hits(dice) < i32(len(available_targets)) {
		// there is a roll for every target but not enough hits to kill all the targets
		// so no need to get a random set of units since all units will either have a hit
		// or miss roll
		return aa_casualty_selector_find_rolled_targets(available_targets, dice)
	} else {
		// randomly choose targets (or all targets if there's enough hits)
		return aa_casualty_selector_find_random_targets(
			available_targets,
			bridge,
			dice_roll_get_hits(dice),
		)
	}
}

// games.strategy.triplea.delegate.battle.casualty.AaCasualtySelector#getLowLuckAaCasualties(java.util.List,games.strategy.triplea.delegate.power.calculator.AaPowerStrengthAndRolls,games.strategy.triplea.delegate.DiceRoll,games.strategy.engine.delegate.IDelegateBridge)
aa_casualty_selector_get_low_luck_aa_casualties :: proc(
	available_targets: [dynamic]^Unit,
	unit_power_and_rolls_map: ^Aa_Power_Strength_And_Rolls,
	dice: ^Dice_Roll,
	bridge: ^I_Delegate_Bridge,
) -> [dynamic]^Unit {
	target_groups := low_luck_target_groups_new(available_targets, dice, unit_power_and_rolls_map)

	if !low_luck_target_groups_has_guaranteed_groups(target_groups) {
		// it is not possible to separate the targets into guaranteed hit groups so randomly
		// choose the targets instead
		return aa_casualty_selector_find_random_targets(
			available_targets,
			bridge,
			dice_roll_get_hits(dice),
		)
	}

	if dice_roll_get_hits(dice) >= i32(len(low_luck_target_groups_get_guaranteed_hit_groups(target_groups))) {
		// there are enough hits to hit all the guaranteed hits
		hit_units := low_luck_target_groups_get_guaranteed_hits(target_groups)

		// if there are more hits than groups, the extra hits come out of the remainderUnits
		remainder_hits := dice_roll_get_hits(dice) - i32(len(hit_units))
		if remainder_hits > 0 {
			// randomly pull out units from the remainder group
			extras := aa_casualty_selector_find_random_targets(
				low_luck_target_groups_get_remainder_units(target_groups),
				bridge,
				remainder_hits,
			)
			for u in extras {
				append(&hit_units, u)
			}
		}
		return hit_units
	} else {
		// There is somehow more guaranteed hit groups than hits. This currently only happens
		// with multi hp targets and damageable AA shots.

		// Randomly pick out of the guaranteed hits
		return aa_casualty_selector_find_random_targets(
			low_luck_target_groups_get_guaranteed_hits(target_groups),
			bridge,
			dice_roll_get_hits(dice),
		)
	}
}

