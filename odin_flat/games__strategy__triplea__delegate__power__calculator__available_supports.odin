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

// Lambda from getSupport(): `e -> new SupportDetails(e.getValue())`.
// Used in Collectors.toMap to convert each Map.Entry<UnitSupportAttachment,
// IntegerMap<Unit>> value into a SupportDetails wrapper. Java's Map.Entry
// is decomposed into (key, value) parameters in Odin.
available_supports_lambda_get_support_1 :: proc(
	key: ^Unit_Support_Attachment,
	value: ^Integer_Map_Unit,
) -> ^Available_Supports_Support_Details {
	return available_supports_support_details_new(value^)
}

// static AvailableSupports getSupport(SupportCalculator supportCalculator)
//   Streams supportCalculator.getSupportUnits().entrySet() into a new map
//   whose values are SupportDetails wrappers, then builds an AvailableSupports
//   carrying that map plus supportCalculator.getSupportRules().
available_supports_get_support :: proc(support_calculator: ^Support_Calculator) -> ^Available_Supports {
	src_support_units := support_calculator_get_support_units(support_calculator)
	transformed_support_units := make(map[^Unit_Support_Attachment]^Available_Supports_Support_Details)
	for k, v in src_support_units {
		transformed_support_units[k] = available_supports_lambda_get_support_1(k, v)
	}
	builder := available_supports_builder()
	builder = available_supports_available_supports_builder_support_rules(
		builder,
		support_calculator_get_support_rules(support_calculator),
	)
	builder = available_supports_available_supports_builder_support_units(
		builder,
		transformed_support_units,
	)
	return available_supports_available_supports_builder_build(builder)
}

// int giveSupportToUnit(Unit unit)
//   Walks each bonus-type bucket in supportRules, applies as many supports
//   from each rule as are available (bounded by the bonus type's per-unit
//   count), records the supporter -> supportee bonus mapping in
//   unitsGivingSupport, and returns the total bonus given.
available_supports_give_support_to_unit :: proc(self: ^Available_Supports, unit: ^Unit) -> i32 {
	amount_of_support_given: i32 = 0
	for _, rules_by_bonus_type in self.support_rules {
		if len(rules_by_bonus_type) == 0 {
			continue
		}
		first_rule := rules_by_bonus_type[0]
		max_per_bonus_type := unit_support_attachment_bonus_type_get_count(
			unit_support_attachment_get_bonus_type(first_rule),
		)
		for rule in rules_by_bonus_type {
			unit_types := unit_support_attachment_get_unit_type(rule)
			if _, has := unit_types[unit_get_type(unit)]; !has {
				continue
			}
			num_support_available_to_apply := available_supports_get_support_available(self, rule)
			for i: i32 = 0; i < num_support_available_to_apply; i += 1 {
				supporter := available_supports_get_next_available_supporter(self, rule)
				bonus := unit_support_attachment_get_bonus(rule)
				amount_of_support_given += bonus
				im, present := self.units_giving_support[supporter]
				if !present {
					im = available_supports_lambda_give_support_to_unit_3(supporter)
					self.units_giving_support[supporter] = im
				}
				integer_map_add(im, rawptr(unit), bonus)
			}
			max_per_bonus_type -= num_support_available_to_apply
			if max_per_bonus_type <= 0 {
				break
			}
		}
	}
	return amount_of_support_given
}

// static AvailableSupports getSortedSupport(SupportCalculator supportCalculator)
//   Builds the AvailableSupports via getSupport, then sorts each bonus
//   bucket of rules using a SupportRuleSort comparator configured from the
//   calculator's side / allied flag plus UnitSupportAttachment::getRoll and
//   ::getStrength method references.
available_supports_get_sorted_support :: proc(support_calculator: ^Support_Calculator) -> ^Available_Supports {
	support_calculation_result := available_supports_get_support(support_calculator)

	builder := support_rule_sort_builder()
	builder = support_rule_sort_support_rule_sort_builder_side(
		builder,
		support_calculator_get_side(support_calculator),
	)
	builder = support_rule_sort_support_rule_sort_builder_friendly(
		builder,
		support_calculator_is_allies(support_calculator),
	)
	builder = support_rule_sort_support_rule_sort_builder_roll(
		builder,
		unit_support_attachment_get_roll,
	)
	builder = support_rule_sort_support_rule_sort_builder_strength(
		builder,
		unit_support_attachment_get_strength,
	)
	support_rule_sort := support_rule_sort_support_rule_sort_builder_build(builder)

	rules_map := available_supports_get_support_rules(support_calculation_result)
	for bonus_type, unit_support_attachment in rules_map {
		available_supports_lambda_get_sorted_support_0(support_rule_sort, bonus_type, unit_support_attachment)
	}
	return support_calculation_result
}

// AvailableSupports filter(Predicate<UnitSupportAttachment> ruleFilter)
//   Builds a new AvailableSupports retaining only rules/support-units for
//   which ruleFilter.test(usa) is true. Empty rule lists are dropped, and
//   surviving SupportDetails values are deep-copied via the copy ctor.
available_supports_filter :: proc(
	self: ^Available_Supports,
	rule_filter: proc(rawptr, ^Unit_Support_Attachment) -> bool,
	rule_filter_ctx: rawptr,
) -> ^Available_Supports {
	support_rules := make(map[^Unit_Support_Attachment_Bonus_Type][dynamic]^Unit_Support_Attachment)
	for bonus_type, rules in self.support_rules {
		filtered_support_rules: [dynamic]^Unit_Support_Attachment
		for rule in rules {
			if rule_filter(rule_filter_ctx, rule) {
				append(&filtered_support_rules, rule)
			}
		}
		if len(filtered_support_rules) > 0 {
			support_rules[bonus_type] = filtered_support_rules
		}
	}

	support_units := make(map[^Unit_Support_Attachment]^Available_Supports_Support_Details)
	for usa, details in self.support_units {
		if rule_filter(rule_filter_ctx, usa) {
			support_units[usa] = available_supports_support_details_new_copy(details)
		}
	}

	builder := available_supports_builder()
	builder = available_supports_available_supports_builder_support_rules(builder, support_rules)
	builder = available_supports_available_supports_builder_support_units(builder, support_units)
	return available_supports_available_supports_builder_build(builder)
}

// Adapter for copy(): rawptr-form predicate that ignores its arg and returns
// true, matching available_supports_filter's predicate signature.
available_supports_copy_always_true :: proc(ctx: rawptr, usa: ^Unit_Support_Attachment) -> bool {
	return true
}

// AvailableSupports copy()
//   Constructs a copied version of this via filter(support -> true).
available_supports_copy :: proc(self: ^Available_Supports) -> ^Available_Supports {
	return available_supports_filter(self, available_supports_copy_always_true, nil)
}

