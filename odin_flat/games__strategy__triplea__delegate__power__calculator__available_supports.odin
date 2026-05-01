package game

// Tracks the available support that a collection of units can give to other units.
// Once a support is used, it will no longer be available for other units to use.
Available_Supports :: struct {
	support_rules:        map[^Unit_Support_Attachment_Bonus_Type][dynamic]^Unit_Support_Attachment,
	support_units:        map[^Unit_Support_Attachment]^Available_Supports_Support_Details,
	units_giving_support: map[^Unit]^Integer_Map,
}

// Constructor: AvailableSupports(Map supportRules, Map supportUnits)
available_supports_new :: proc(
	support_rules: map[^Unit_Support_Attachment_Bonus_Type][dynamic]^Unit_Support_Attachment,
	support_units: map[^Unit_Support_Attachment]^Available_Supports_Support_Details,
) -> ^Available_Supports {
	self := new(Available_Supports)
	self.support_rules = support_rules
	self.support_units = support_units
	self.units_giving_support = make(map[^Unit]^Integer_Map)
	return self
}

// int getSupportLeft(UnitSupportAttachment support)
available_supports_get_support_left :: proc(self: ^Available_Supports, support: ^Unit_Support_Attachment) -> i32 {
	details, ok := self.support_units[support]
	if ok && details != nil {
		return details.total_support
	}
	return 0
}

// Map<UnitSupportAttachment.BonusType, List<UnitSupportAttachment>> getSupportRules()
available_supports_get_support_rules :: proc(self: ^Available_Supports) -> map[^Unit_Support_Attachment_Bonus_Type][dynamic]^Unit_Support_Attachment {
	return self.support_rules
}

// Map<Unit, IntegerMap<Unit>> getUnitsGivingSupport()
available_supports_get_units_giving_support :: proc(self: ^Available_Supports) -> map[^Unit]^Integer_Map {
	return self.units_giving_support
}

// Lambda from copy(): `support -> true`.
available_supports_lambda_copy_2 :: proc(support: ^Unit_Support_Attachment) -> bool {
	return true
}

// Lambda from getSortedSupport():
//   (bonusType, unitSupportAttachment) -> unitSupportAttachment.sort(supportRuleSort)
// Captured: supportRuleSort. Second forEach value is the List<UnitSupportAttachment>
// of rules for the given bonus type; List.sort(Comparator) is applied using
// SupportRuleSort as the comparator.
available_supports_lambda_get_sorted_support_0 :: proc(
	support_rule_sort: ^Support_Rule_Sort,
	bonus_type: ^Unit_Support_Attachment_Bonus_Type,
	rules: [dynamic]^Unit_Support_Attachment,
) {
	support_rule_sort_sort(support_rule_sort, rules)
}

