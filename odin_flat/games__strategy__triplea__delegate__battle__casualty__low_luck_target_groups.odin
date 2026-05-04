package game

import "core:math"

Low_Luck_Target_Groups :: struct {
	guaranteed_hit_groups: [dynamic][dynamic]^Unit,
	remainder_units:       [dynamic]^Unit,
}

low_luck_target_groups_new :: proc(
	targets: [dynamic]^Unit,
	dice_roll: ^Dice_Roll,
	unit_power_and_rolls_map: ^Aa_Power_Strength_And_Rolls,
) -> ^Low_Luck_Target_Groups {
	self := new(Low_Luck_Target_Groups)
	self.guaranteed_hit_groups = make([dynamic][dynamic]^Unit)
	self.remainder_units = make([dynamic]^Unit)

	guarantee_hit_group_size := low_luck_target_groups_calculate_guarantee_low_luck_hit_group_size(
		targets,
		dice_roll,
		unit_power_and_rolls_map,
	)
	if guarantee_hit_group_size == 0 {
		for u in targets {
			append(&self.remainder_units, u)
		}
		return self
	}

	builder := unit_separator_separator_categories_separator_categories_builder_new()
	unit_separator_separator_categories_separator_categories_builder_transport_cost(builder, true)
	separator_categories := unit_separator_separator_categories_separator_categories_builder_build(builder)
	grouped_targets := unit_separator_categorize(targets, separator_categories)

	for uc in grouped_targets {
		uc_units := unit_category_get_units(uc)
		uc_count := i32(len(uc_units))
		if uc_count == 0 {
			continue
		}
		// Lists.partition: split into consecutive sub-lists of size guarantee_hit_group_size,
		// the final partition may be smaller.
		guaranteed_groups := make([dynamic][dynamic]^Unit)
		i: i32 = 0
		for i < uc_count {
			end := i + guarantee_hit_group_size
			if end > uc_count {
				end = uc_count
			}
			part := make([dynamic]^Unit)
			for j := i; j < end; j += 1 {
				append(&part, uc_units[j])
			}
			append(&guaranteed_groups, part)
			i = end
		}
		if len(guaranteed_groups) == 0 {
			continue
		}
		last_group := guaranteed_groups[len(guaranteed_groups) - 1]
		if i32(len(last_group)) != guarantee_hit_group_size {
			group_of_remainder_units := guaranteed_groups[len(guaranteed_groups) - 1]
			ordered_remove(&guaranteed_groups, len(guaranteed_groups) - 1)
			for u in group_of_remainder_units {
				append(&self.remainder_units, u)
			}
		}
		for g in guaranteed_groups {
			append(&self.guaranteed_hit_groups, g)
		}
	}
	return self
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
