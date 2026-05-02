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

// static AvailableSupportsBuilder builder() — Lombok @Builder factory.
available_supports_builder :: proc() -> ^Available_Supports_Available_Supports_Builder {
	return available_supports_available_supports_builder_new()
}

// private int getSupportAvailable(UnitSupportAttachment support)
//   Math.max(0, Math.min(support.getBonusType().getCount(), getSupportLeft(support)))
available_supports_get_support_available :: proc(self: ^Available_Supports, support: ^Unit_Support_Attachment) -> i32 {
	bt := unit_support_attachment_get_bonus_type(support)
	cap_count := unit_support_attachment_bonus_type_get_count(bt)
	left := available_supports_get_support_left(self, support)
	return max(i32(0), min(cap_count, left))
}

// private Unit getNextAvailableSupporter(UnitSupportAttachment support)
//   Pulls one unit out of the support pool for `support`, decrementing its
//   per-unit count and the cached total. Removes the unit when its remaining
//   count drops to zero. Mirrors IntegerMap<Unit>.add(u, -1) + removeKey.
available_supports_get_next_available_supporter :: proc(self: ^Available_Supports, support: ^Unit_Support_Attachment) -> ^Unit {
	details := self.support_units[support]
	int_map := &details.support_units
	u: ^Unit
	for k, _ in int_map.entries {
		u = k
		break
	}
	new_val := int_map.entries[u] - 1
	int_map.entries[u] = new_val
	details.total_support -= 1
	if new_val <= 0 {
		delete_key(&int_map.entries, u)
	}
	return u
}

// Lambda from giveSupportToUnit(): `(newSupport) -> new IntegerMap<>()`.
// Used as the mappingFunction for unitsGivingSupport.computeIfAbsent — the
// Java parameter is the missing key (a Unit) and the result is a fresh
// IntegerMap<Unit> to insert.
available_supports_lambda_give_support_to_unit_3 :: proc(new_support: ^Unit) -> ^Integer_Map {
	return integer_map_new()
}

