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

