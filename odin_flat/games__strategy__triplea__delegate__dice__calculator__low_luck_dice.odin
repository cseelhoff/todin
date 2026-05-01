package game

Low_Luck_Dice :: struct {}

low_luck_dice_calculate :: proc(
	total_power_and_total_rolls: ^Total_Power_And_Total_Rolls,
	player: ^Game_Player,
	dice_generator: ^Random_Dice_Generator,
	annotation: string,
) -> ^Dice_Roll {
	power := total_power_and_total_rolls.calculate_total_power(total_power_and_total_rolls)
	if power == 0 {
		empty := make([dynamic]^Die, 0)
		return dice_roll_new(empty, 0, 0, default_named_get_name(&player.named_attachable.default_named))
	}

	dice_sides := total_power_and_total_rolls.get_dice_sides(total_power_and_total_rolls)
	hit_count := power / dice_sides
	dice := make([dynamic]^Die, 0)
	roll_for := power % dice_sides
	if roll_for > 0 {
		random := dice_generator.apply(dice_sides, 1, player, .COMBAT, annotation)
		hit := roll_for > random[0]
		if hit {
			hit_count += 1
		}
		die_type: Die_Die_Type = .MISS
		if hit {
			die_type = .HIT
		}
		d := new(Die)
		d^ = die_new(random[0], roll_for, die_type)
		append(&dice, d)
	}

	expected_hits := f64(power) / f64(dice_sides)
	return dice_roll_new(dice, hit_count, expected_hits, default_named_get_name(&player.named_attachable.default_named))
}

