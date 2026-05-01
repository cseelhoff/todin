package game

Support_Rule_Sort_Support_Rule_Sort_Builder :: struct {
	side:     Battle_State_Side,
	friendly: bool,
	roll:     proc(u: ^Unit_Support_Attachment) -> bool,
	strength: proc(u: ^Unit_Support_Attachment) -> bool,
}

support_rule_sort_support_rule_sort_builder_new :: proc() -> ^Support_Rule_Sort_Support_Rule_Sort_Builder {
	self := new(Support_Rule_Sort_Support_Rule_Sort_Builder)
	return self
}

support_rule_sort_support_rule_sort_builder_side :: proc(self: ^Support_Rule_Sort_Support_Rule_Sort_Builder, side: Battle_State_Side) -> ^Support_Rule_Sort_Support_Rule_Sort_Builder {
	self.side = side
	return self
}

support_rule_sort_support_rule_sort_builder_friendly :: proc(self: ^Support_Rule_Sort_Support_Rule_Sort_Builder, friendly: bool) -> ^Support_Rule_Sort_Support_Rule_Sort_Builder {
	self.friendly = friendly
	return self
}

support_rule_sort_support_rule_sort_builder_roll :: proc(self: ^Support_Rule_Sort_Support_Rule_Sort_Builder, roll: proc(u: ^Unit_Support_Attachment) -> bool) -> ^Support_Rule_Sort_Support_Rule_Sort_Builder {
	self.roll = roll
	return self
}

support_rule_sort_support_rule_sort_builder_strength :: proc(self: ^Support_Rule_Sort_Support_Rule_Sort_Builder, strength: proc(u: ^Unit_Support_Attachment) -> bool) -> ^Support_Rule_Sort_Support_Rule_Sort_Builder {
	self.strength = strength
	return self
}
