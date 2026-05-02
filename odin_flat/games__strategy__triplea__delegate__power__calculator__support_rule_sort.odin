package game

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

