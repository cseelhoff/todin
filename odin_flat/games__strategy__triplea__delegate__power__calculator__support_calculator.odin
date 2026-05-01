package game

// Java owners covered by this file:
//   - games.strategy.triplea.delegate.power.calculator.SupportCalculator

Support_Calculator :: struct {
	support_rules: map[^Unit_Support_Attachment_Bonus_Type][dynamic]^Unit_Support_Attachment,
	support_units: map[^Unit_Support_Attachment]^Integer_Map_Unit,
	side:          Battle_State_Side,
	allies:        bool,
}

support_calculator_get_side :: proc(self: ^Support_Calculator) -> Battle_State_Side {
	return self.side
}

support_calculator_get_support_rules :: proc(self: ^Support_Calculator) -> map[^Unit_Support_Attachment_Bonus_Type][dynamic]^Unit_Support_Attachment {
	return self.support_rules
}

support_calculator_get_support_units :: proc(self: ^Support_Calculator) -> map[^Unit_Support_Attachment]^Integer_Map_Unit {
	return self.support_units
}

support_calculator_is_allies :: proc(self: ^Support_Calculator) -> bool {
	return self.allies
}

// Java: Collection<List<UnitSupportAttachment>> getUnitSupportAttachments()
// returns supportRules.values(); collect map values into a dynamic array.
support_calculator_get_unit_support_attachments :: proc(self: ^Support_Calculator) -> [dynamic][dynamic]^Unit_Support_Attachment {
	result: [dynamic][dynamic]^Unit_Support_Attachment
	for _, v in self.support_rules {
		append(&result, v)
	}
	return result
}

// Java synthetic lambda: `u -> false` from the ternary in the
// SupportCalculator constructor (impArtTech fallback predicate).
support_calculator_lambda_new_0 :: proc(self: ^Support_Calculator, unit: ^Unit) -> bool {
	return false
}

// Java synthetic lambda: `(bt) -> new ArrayList<>()` passed to
// supportRules.computeIfAbsent in the SupportCalculator constructor.
support_calculator_lambda_new_1 :: proc(self: ^Support_Calculator, bonus_type: ^Unit_Support_Attachment_Bonus_Type) -> [dynamic]^Unit_Support_Attachment {
	result: [dynamic]^Unit_Support_Attachment
	return result
}
