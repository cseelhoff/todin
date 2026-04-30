package game

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
