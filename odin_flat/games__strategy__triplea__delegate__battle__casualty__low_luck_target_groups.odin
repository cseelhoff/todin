package game

import "core:math"

Low_Luck_Target_Groups :: struct {
	guaranteed_hit_groups: [dynamic][dynamic]^Unit,
	remainder_units:       [dynamic]^Unit,
}

low_luck_target_groups_get_guaranteed_hit_groups :: proc(self: ^Low_Luck_Target_Groups) -> [dynamic][dynamic]^Unit {
	return self.guaranteed_hit_groups
}

low_luck_target_groups_get_remainder_units :: proc(self: ^Low_Luck_Target_Groups) -> [dynamic]^Unit {
	return self.remainder_units
}

low_luck_target_groups_calculate_guarantee_low_luck_hit_group_size :: proc(
	available_targets: [dynamic]^Unit,
	dice_roll: ^Dice_Roll,
	unit_power_and_rolls_map: ^Aa_Power_Strength_And_Rolls,
) -> i32 {
	best_strength := aa_power_strength_and_rolls_get_best_strength(unit_power_and_rolls_map)
	chosen_dice_size := aa_power_strength_and_rolls_get_dice_sides(unit_power_and_rolls_map)

	if !aa_power_strength_and_rolls_is_same_strength(unit_power_and_rolls_map) {
		return 0
	}
	if best_strength == 0 {
		return 0
	}
	hits := dice_roll_get_hits(dice_roll)
	max_possible := math.ceil(f64(best_strength) * f64(len(available_targets)) / f64(chosen_dice_size))
	if f64(hits) > max_possible {
		return 0
	}
	if chosen_dice_size % best_strength != 0 {
		return 0
	}
	return chosen_dice_size / best_strength
}

low_luck_target_groups_has_guaranteed_groups :: proc(self: ^Low_Luck_Target_Groups) -> bool {
	return len(self.guaranteed_hit_groups) > 0
}

low_luck_target_groups_get_guaranteed_hits :: proc(self: ^Low_Luck_Target_Groups) -> [dynamic]^Unit {
	result: [dynamic]^Unit
	for hit_group in self.guaranteed_hit_groups {
		if len(hit_group) > 0 {
			append(&result, hit_group[0])
		}
	}
	return result
}
