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

// Java constructor:
//   public SupportCalculator(
//       Collection<Unit> unitsGivingTheSupport,
//       Collection<UnitSupportAttachment> rules,
//       BattleState.Side side,
//       boolean allies)
support_calculator_new :: proc(
	units_giving_the_support: [dynamic]^Unit,
	rules: [dynamic]^Unit_Support_Attachment,
	side: Battle_State_Side,
	allies: bool,
) -> ^Support_Calculator {
	self := new(Support_Calculator)
	self.side = side
	self.allies = allies
	self.support_rules = make(map[^Unit_Support_Attachment_Bonus_Type][dynamic]^Unit_Support_Attachment)
	self.support_units = make(map[^Unit_Support_Attachment]^Integer_Map_Unit)

	if len(units_giving_the_support) == 0 {
		return self
	}

	for rule in rules {
		types := unit_support_attachment_get_unit_type(rule)
		if len(unit_support_attachment_get_players(rule)) == 0 || types == nil || len(types) == 0 {
			continue
		}
		if !((side == .DEFENSE && unit_support_attachment_get_defence(rule)) ||
			(side == .OFFENSE && unit_support_attachment_get_offence(rule))) {
			continue
		}
		if !((allies && unit_support_attachment_get_allied(rule)) ||
			(!allies && unit_support_attachment_get_enemy(rule))) {
			continue
		}

		// canSupport = unitIsOfType((UnitType) rule.getAttachedTo())
		//                .and(unitIsOwnedByAnyOf(rule.getPlayers()))
		attached_ut := cast(^Unit_Type)rule.attached_to
		is_of_type_p, is_of_type_c := matches_unit_is_of_type(attached_ut)
		owned_p, owned_c := matches_unit_is_owned_by_any_of(unit_support_attachment_get_players(rule))

		// impArtTech = rule.getImpArtTech()
		//                ? Matches.unitOwnerHasImprovedArtillerySupportTech()
		//                : u -> false;
		has_imp_art := unit_support_attachment_get_imp_art_tech(rule)
		imp_art_p: proc(rawptr, ^Unit) -> bool
		imp_art_c: rawptr
		if has_imp_art {
			imp_art_p, imp_art_c = matches_unit_owner_has_improved_artillery_support_tech()
		}

		units_for_rule := new(Integer_Map_Unit)
		units_for_rule.entries = make(map[^Unit]i32)
		number := unit_support_attachment_get_number(rule)
		for unit in units_giving_the_support {
			if !is_of_type_p(is_of_type_c, unit) {
				continue
			}
			if !owned_p(owned_c, unit) {
				continue
			}
			units_for_rule.entries[unit] = number

			imp_art_hit: bool
			if has_imp_art {
				imp_art_hit = imp_art_p(imp_art_c, unit)
			} else {
				imp_art_hit = support_calculator_lambda_new_0(self, unit)
			}
			if imp_art_hit {
				units_for_rule.entries[unit] += number
			}
		}
		if len(units_for_rule.entries) > 0 {
			self.support_units[rule] = units_for_rule
			bt := unit_support_attachment_get_bonus_type(rule)
			list, ok := self.support_rules[bt]
			if !ok {
				list = support_calculator_lambda_new_1(self, bt)
			}
			append(&list, rule)
			self.support_rules[bt] = list
		}
	}
	return self
}

// Java synthetic lambda: `u -> new IntegerMap<>()` passed to
// support.computeIfAbsent inside getCombinedSupportGiven (first call,
// supportFromFriends branch).
support_calculator_lambda_get_combined_support_given_2 :: proc(u: ^Unit) -> ^Integer_Map {
	return integer_map_new()
}

// Java synthetic lambda: `u -> new IntegerMap<>()` passed to
// support.computeIfAbsent inside getCombinedSupportGiven (second call,
// supportFromEnemies branch).
support_calculator_lambda_get_combined_support_given_3 :: proc(u: ^Unit) -> ^Integer_Map {
	return integer_map_new()
}

// Java: public int getSupport(UnitSupportAttachment rule)
//   return supportUnits.getOrDefault(rule, IntegerMap.of()).totalValues();
support_calculator_get_support :: proc(self: ^Support_Calculator, rule: ^Unit_Support_Attachment) -> i32 {
	units, ok := self.support_units[rule]
	if !ok {
		return 0
	}
	total: i32 = 0
	for _, v in units.entries {
		total += v
	}
	return total
}

// Java: public static Map<Unit, IntegerMap<Unit>> getCombinedSupportGiven(
//     AvailableSupports supportFromFriends, AvailableSupports supportFromEnemies)
support_calculator_get_combined_support_given :: proc(
	support_from_friends: ^Available_Supports,
	support_from_enemies: ^Available_Supports,
) -> map[^Unit]^Integer_Map {
	support := make(map[^Unit]^Integer_Map)
	for k, v in available_supports_get_units_giving_support(support_from_friends) {
		entry, ok := support[k]
		if !ok {
			entry = support_calculator_lambda_get_combined_support_given_2(k)
			support[k] = entry
		}
		integer_map_add_map(entry, v)
	}
	for k, v in available_supports_get_units_giving_support(support_from_enemies) {
		entry, ok := support[k]
		if !ok {
			entry = support_calculator_lambda_get_combined_support_given_3(k)
			support[k] = entry
		}
		integer_map_add_map(entry, v)
	}
	return support
}
