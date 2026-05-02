package game

// Java owner: games.strategy.triplea.delegate.dice.calculator.RolledDice
// Utility class (Lombok @UtilityClass) with no instance fields.

Rolled_Dice :: struct {}

rolled_dice_get_dice_hits :: proc(
	dice: []i32,
	active_units: [dynamic]Unit_Power_Strength_And_Rolls,
) -> [dynamic]Die {
	result: [dynamic]Die
	idx := 0
	for upsr in active_units {
		strength := upsr.strength_and_rolls.strength
		rolls := upsr.strength_and_rolls.rolls
		if upsr.choose_best_roll {
			best_roll := upsr.dice_sides
			best_roll_index := 0
			dice_rolls: [dynamic]i32
			defer delete(dice_rolls)
			for i in 0 ..< int(rolls) {
				d := dice[idx]
				idx += 1
				append(&dice_rolls, d)
				if d < best_roll {
					best_roll = d
					best_roll_index = i
				}
			}
			for roll_number in 0 ..< int(rolls) {
				t: Die_Die_Type
				if roll_number == best_roll_index {
					if dice_rolls[roll_number] < strength {
						t = .HIT
					} else {
						t = .MISS
					}
				} else {
					t = .IGNORED
				}
				append(&result, die_new(dice_rolls[roll_number], strength, t))
			}
		} else {
			for _ in 0 ..< int(rolls) {
				d := dice[idx]
				idx += 1
				t: Die_Die_Type
				if d < strength {
					t = .HIT
				} else {
					t = .MISS
				}
				append(&result, die_new(d, strength, t))
			}
		}
	}
	return result
}

rolled_dice_calculate :: proc(
	total_power_and_total_rolls: ^Total_Power_And_Total_Rolls,
	player: ^Game_Player,
	dice_generator: ^Random_Dice_Generator,
	annotation: string,
) -> ^Dice_Roll {
	roll_count := total_power_and_total_rolls.calculate_total_rolls(total_power_and_total_rolls)
	if roll_count == 0 {
		empty := make([dynamic]^Die, 0)
		return dice_roll_new(empty, 0, 0, default_named_get_name(&player.named_attachable.default_named))
	}

	dice_sides := total_power_and_total_rolls.get_dice_sides(total_power_and_total_rolls)
	random := dice_generator.apply(dice_sides, roll_count, player, .COMBAT, annotation)
	active_units := total_power_and_total_rolls.get_active_units(total_power_and_total_rolls)
	dice_values := rolled_dice_get_dice_hits(random[:], active_units)
	defer delete(dice_values)

	dice := make([dynamic]^Die, 0, len(dice_values))
	hit_count: i32 = 0
	for d in dice_values {
		p := new(Die)
		p^ = d
		append(&dice, p)
		if rolled_dice_lambda__calculate__0(p) {
			hit_count += 1
		}
	}

	total_power := total_power_and_total_rolls.calculate_total_power(total_power_and_total_rolls)
	expected_hits := f64(total_power) / f64(dice_sides)

	return dice_roll_new(dice, hit_count, expected_hits, default_named_get_name(&player.named_attachable.default_named))
}

// Lambda: die -> die.getType() == Die.DieType.HIT
rolled_dice_lambda__calculate__0 :: proc(die: ^Die) -> bool {
	return die_get_type(die) == .HIT
}

// Lambda body of getDiceForAllRolls: rollNumber -> new Die(diceQueue.removeFirst(), strength, ...)
rolled_dice_lambda__get_dice_for_all_rolls__3 :: proc(
	dice_queue: ^[dynamic]i32,
	strength: i32,
	roll_number: i32,
) -> Die {
	dice_value := dice_queue[0]
	ordered_remove(dice_queue, 0)
	t: Die_Die_Type = .MISS
	if dice_value < strength {
		t = .HIT
	}
	return die_new(dice_value, strength, t)
}

// Lambda body of getDiceForChooseBestRoll: rollNumber -> new Die(diceRolls.get(rollNumber), strength, ...)
rolled_dice_lambda__get_dice_for_choose_best_roll__2 :: proc(
	dice_rolls: ^[dynamic]i32,
	strength: i32,
	dice_hit_index: i32,
	roll_number: i32,
) -> Die {
	t: Die_Die_Type
	if roll_number == dice_hit_index {
		if dice_rolls[roll_number] < strength {
			t = .HIT
		} else {
			t = .MISS
		}
	} else {
		t = .IGNORED
	}
	return die_new(dice_rolls[roll_number], strength, t)
}

// Static: RolledDice.getDiceForAllRolls(Deque<Integer>, UnitPowerStrengthAndRolls) -> Stream<Die>
rolled_dice_get_dice_for_all_rolls :: proc(
	dice_queue: ^[dynamic]i32,
	unit_power_strength_and_rolls: ^Unit_Power_Strength_And_Rolls,
) -> [dynamic]Die {
	strength := unit_power_strength_and_rolls_get_strength(unit_power_strength_and_rolls)
	rolls := unit_power_strength_and_rolls_get_rolls(unit_power_strength_and_rolls)
	result: [dynamic]Die
	for roll_number in 0 ..< int(rolls) {
		append(&result, rolled_dice_lambda__get_dice_for_all_rolls__3(dice_queue, strength, i32(roll_number)))
	}
	return result
}

// Static: RolledDice.getDiceForChooseBestRoll(Deque<Integer>, UnitPowerStrengthAndRolls) -> Stream<Die>
rolled_dice_get_dice_for_choose_best_roll :: proc(
	dice_queue: ^[dynamic]i32,
	unit_power_strength_and_rolls: ^Unit_Power_Strength_And_Rolls,
) -> [dynamic]Die {
	dice_rolls: [dynamic]i32
	best_roll := unit_power_strength_and_rolls_get_dice_sides(unit_power_strength_and_rolls)
	best_roll_index: i32 = 0
	rolls := unit_power_strength_and_rolls_get_rolls(unit_power_strength_and_rolls)
	for i in 0 ..< int(rolls) {
		die_value := dice_queue[0]
		ordered_remove(dice_queue, 0)
		append(&dice_rolls, die_value)
		if die_value < best_roll {
			best_roll = die_value
			best_roll_index = i32(i)
		}
	}

	dice_hit_index := best_roll_index
	strength := unit_power_strength_and_rolls_get_strength(unit_power_strength_and_rolls)
	result: [dynamic]Die
	for roll_number in 0 ..< int(rolls) {
		append(&result, rolled_dice_lambda__get_dice_for_choose_best_roll__2(&dice_rolls, strength, dice_hit_index, i32(roll_number)))
	}
	delete(dice_rolls)
	return result
}

