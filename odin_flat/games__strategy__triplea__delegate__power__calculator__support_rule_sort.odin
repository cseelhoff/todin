package game

import "core:slice"

// Java owners covered by this file:
//   - games.strategy.triplea.delegate.power.calculator.SupportRuleSort

Support_Rule_Sort :: struct {
	side:     Battle_State_Side,
	friendly: bool,
	roll:     proc(u: ^Unit_Support_Attachment) -> bool,
	strength: proc(u: ^Unit_Support_Attachment) -> bool,
}

support_rule_sort_builder :: proc() -> ^Support_Rule_Sort_Support_Rule_Sort_Builder {
	return support_rule_sort_support_rule_sort_builder_new()
}

support_rule_sort_new :: proc(
	side: Battle_State_Side,
	friendly: bool,
	roll: proc(u: ^Unit_Support_Attachment) -> bool,
	strength: proc(u: ^Unit_Support_Attachment) -> bool,
) -> ^Support_Rule_Sort {
	s := new(Support_Rule_Sort)
	s.side = side
	s.friendly = friendly
	s.roll = roll
	s.strength = strength
	return s
}

// Java: public int compare(final UnitSupportAttachment u1, final UnitSupportAttachment u2)
//   See SupportRuleSort.java lines 22-117. Orders rules so that:
//   - friendly: stronger rolls first, then stronger strength bonuses;
//   - enemy:    worst rolls first, then worst strength bonuses;
//   - then by smaller getUnitType() set size (more specific rules first);
//   - then by greater unit power (rolls * value) of the attached UnitType.
support_rule_sort_compare :: proc(self: ^Support_Rule_Sort, u1, u2: ^Unit_Support_Attachment) -> i32 {
	compare_to: i32

	u1_can_bonus := unit_support_attachment_get_defence(u1) if self.side == .DEFENSE else unit_support_attachment_get_offence(u1)
	u2_can_bonus := unit_support_attachment_get_defence(u2) if self.side == .DEFENSE else unit_support_attachment_get_offence(u2)

	if self.friendly {
		if self.roll(u1) || self.roll(u2) {
			u1_bonus: i32 = unit_support_attachment_get_bonus(u1) if self.roll(u1) && u1_can_bonus else 0
			u2_bonus: i32 = unit_support_attachment_get_bonus(u2) if self.roll(u2) && u2_can_bonus else 0
			compare_to = 0
			if u2_bonus < u1_bonus do compare_to = -1
			else if u2_bonus > u1_bonus do compare_to = 1
			if compare_to != 0 do return compare_to
		}
		if self.strength(u1) || self.strength(u2) {
			u1_bonus: i32 = unit_support_attachment_get_bonus(u1) if self.strength(u1) && u1_can_bonus else 0
			u2_bonus: i32 = unit_support_attachment_get_bonus(u2) if self.strength(u2) && u2_can_bonus else 0
			compare_to = 0
			if u2_bonus < u1_bonus do compare_to = -1
			else if u2_bonus > u1_bonus do compare_to = 1
			if compare_to != 0 do return compare_to
		}
	} else {
		if self.roll(u1) || self.roll(u2) {
			u1_bonus: i32 = unit_support_attachment_get_bonus(u1) if self.roll(u1) && u1_can_bonus else 0
			u2_bonus: i32 = unit_support_attachment_get_bonus(u2) if self.roll(u2) && u2_can_bonus else 0
			compare_to = 0
			if u1_bonus < u2_bonus do compare_to = -1
			else if u1_bonus > u2_bonus do compare_to = 1
			if compare_to != 0 do return compare_to
		}
		if self.strength(u1) || self.strength(u2) {
			u1_bonus: i32 = unit_support_attachment_get_bonus(u1) if self.strength(u1) && u1_can_bonus else 0
			u2_bonus: i32 = unit_support_attachment_get_bonus(u2) if self.strength(u2) && u2_can_bonus else 0
			compare_to = 0
			if u1_bonus < u2_bonus do compare_to = -1
			else if u1_bonus > u2_bonus do compare_to = 1
			if compare_to != 0 do return compare_to
		}
	}

	// Smaller getUnitType() size first (more specific support rules apply earlier).
	types1 := unit_support_attachment_get_unit_type(u1)
	types2 := unit_support_attachment_get_unit_type(u2)
	s1 := i32(len(types1))
	s2 := i32(len(types2))
	compare_to = 0
	if s1 < s2 do compare_to = -1
	else if s1 > s2 do compare_to = 1
	if compare_to != 0 do return compare_to

	// More powerful supporters first: rolls * value of the attached UnitType.
	unit_type1 := cast(^Unit_Type)u1.attached_to
	unit_type2 := cast(^Unit_Type)u2.attached_to
	ua1 := unit_type_get_unit_attachment(unit_type1)
	ua2 := unit_type_get_unit_attachment(unit_type2)
	data := game_data_component_get_data(&u1.game_data_component)
	null_player := player_list_get_null_player(game_data_get_player_list(data))

	unit_power1, unit_power2: i32
	if unit_support_attachment_get_defence(u1) {
		unit_power1 = unit_attachment_get_defense_rolls_with_player(ua1, null_player) * unit_attachment_get_defense(ua1, null_player)
		unit_power2 = unit_attachment_get_defense_rolls_with_player(ua2, null_player) * unit_attachment_get_defense(ua2, null_player)
	} else {
		unit_power1 = unit_attachment_get_attack_rolls_with_player(ua1, null_player) * unit_attachment_get_attack(ua1, null_player)
		unit_power2 = unit_attachment_get_attack_rolls_with_player(ua2, null_player) * unit_attachment_get_attack(ua2, null_player)
	}

	if unit_power2 < unit_power1 do return -1
	if unit_power2 > unit_power1 do return 1
	return 0
}

// In-place sort wrapper for `List.sort(Comparator)` callers. Odin proc literals
// can't capture, so we stash the active comparator in a package-private slot
// and route through a non-capturing thunk — same pattern used by other
// in-place sort wrappers in odin_flat/ (e.g. aa_power_strength_and_rolls).
@(private = "file")
support_rule_sort_active_self_: ^Support_Rule_Sort

@(private = "file")
support_rule_sort_thunk_ :: proc(a, b: ^Unit_Support_Attachment) -> bool {
	return support_rule_sort_compare(support_rule_sort_active_self_, a, b) < 0
}

support_rule_sort_sort :: proc(self: ^Support_Rule_Sort, rules: [dynamic]^Unit_Support_Attachment) {
	prev := support_rule_sort_active_self_
	support_rule_sort_active_self_ = self
	slice.sort_by(rules[:], support_rule_sort_thunk_)
	support_rule_sort_active_self_ = prev
}

