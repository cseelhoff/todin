package game

import "core:fmt"

// Java owners covered by this file:
//   - games.strategy.triplea.delegate.power.calculator.SupportCalculator

Support_Calculator :: struct {
	support_rules:       map[^Unit_Support_Attachment_Bonus_Type][dynamic]^Unit_Support_Attachment,
	support_units:       map[^Unit_Support_Attachment]^Integer_Map_Unit,
	side:                Battle_State_Side,
	allies:              bool,
	// LinkedHashMap insertion-order for `support_rules`. Java declares
	// the field as LinkedHashMap (AvailableSupports.java:31, 60, 98)
	// and AvailableSupports.giveSupportToUnit iterates .values().
	support_rules_order: [dynamic]^Unit_Support_Attachment_Bonus_Type,
	// LinkedHashMap insertion-order for `support_units` (Java line 32, 108).
	support_units_order: [dynamic]^Unit_Support_Attachment,
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

support_calculator_get_support_rules_order :: proc(self: ^Support_Calculator) -> [dynamic]^Unit_Support_Attachment_Bonus_Type {
	return self.support_rules_order
}

support_calculator_get_support_units_order :: proc(self: ^Support_Calculator) -> [dynamic]^Unit_Support_Attachment {
	return self.support_units_order
}

support_calculator_is_allies :: proc(self: ^Support_Calculator) -> bool {
	return self.allies
}

// Java: Collection<List<UnitSupportAttachment>> getUnitSupportAttachments()
// returns supportRules.values(); collect map values into a dynamic array
// in LinkedHashMap insertion order so downstream consumers see Java order.
support_calculator_get_unit_support_attachments :: proc(self: ^Support_Calculator) -> [dynamic][dynamic]^Unit_Support_Attachment {
	result: [dynamic][dynamic]^Unit_Support_Attachment
	if len(self.support_rules_order) > 0 {
		for k in self.support_rules_order {
			if v, ok := self.support_rules[k]; ok {
				append(&result, v)
			}
		}
	} else {
		for _, v in self.support_rules {
			append(&result, v)
		}
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
	self.support_rules_order = make([dynamic]^Unit_Support_Attachment_Bonus_Type)
	self.support_units_order = make([dynamic]^Unit_Support_Attachment)

	if len(units_giving_the_support) == 0 {
		when #config(SUP_PROBE, false) {
			fmt.printf("SUP_NEW empty side=%v allies=%v\n", side, allies)
		}
		return self
	}
	when #config(SUP_PROBE, false) {
		_inf_count := 0
		_art_count := 0
		for u in units_giving_the_support {
			if u.type == nil { continue }
			if u.type.named_attachable.default_named.name == "infantry" { _inf_count += 1 }
			if u.type.named_attachable.default_named.name == "artillery" { _art_count += 1 }
		}
		fmt.printf("SUP_NEW units=%d inf=%d art=%d side=%v allies=%v rules=%d\n", len(units_giving_the_support), _inf_count, _art_count, side, allies, len(rules))
	}

	for rule in rules {
		types := unit_support_attachment_get_unit_type(rule)
		_attached := cast(^Unit_Type)rule.attached_to
		_aname := "?"
		when #config(SUP_PROBE, false) {
			if _attached != nil { _aname = _attached.named_attachable.default_named.name }
		}
		if len(unit_support_attachment_get_players(rule)) == 0 || types == nil || len(types) == 0 {
			when #config(SUP_PROBE, false) {
				if _aname == "artillery" {
					_tlen := -1
					if types != nil { _tlen = len(types) }
					fmt.printf("SUP_SKIP1 attached=%s players=%d types=%d\n", _aname, len(unit_support_attachment_get_players(rule)), _tlen)
				}
			}
			continue
		}
		if !((side == .DEFENSE && unit_support_attachment_get_defence(rule)) ||
			(side == .OFFENSE && unit_support_attachment_get_offence(rule))) {
			when #config(SUP_PROBE, false) {
				if _aname == "artillery" { fmt.printf("SUP_SKIP2_side attached=%s side=%v def=%v off=%v\n", _aname, side, unit_support_attachment_get_defence(rule), unit_support_attachment_get_offence(rule)) }
			}
			continue
		}
		if !((allies && unit_support_attachment_get_allied(rule)) ||
			(!allies && unit_support_attachment_get_enemy(rule))) {
			when #config(SUP_PROBE, false) {
				if _aname == "artillery" { fmt.printf("SUP_SKIP3_allies attached=%s allies=%v r_allied=%v r_enemy=%v\n", _aname, allies, unit_support_attachment_get_allied(rule), unit_support_attachment_get_enemy(rule)) }
			}
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
			integer_map_unit_put(units_for_rule, unit, number)

			imp_art_hit: bool
			if has_imp_art {
				imp_art_hit = imp_art_p(imp_art_c, unit)
			} else {
				imp_art_hit = support_calculator_lambda_new_0(self, unit)
			}
			if imp_art_hit {
				integer_map_unit_put(units_for_rule, unit, units_for_rule.entries[unit] + number)
			}
		}
		if len(units_for_rule.entries) > 0 {
			when #config(SUP_PROBE, false) {
				attached_name := "?"
				if attached_ut != nil { attached_name = attached_ut.named_attachable.default_named.name }
				fmt.printf("SUP_RULE_ADD attached=%s side=%v allies=%v supporters=%d\n", attached_name, side, allies, len(units_for_rule.entries))
			}
			if _, already := self.support_units[rule]; !already {
				append(&self.support_units_order, rule)
			}
			self.support_units[rule] = units_for_rule
			bt := unit_support_attachment_get_bonus_type(rule)
			list, ok := self.support_rules[bt]
			if !ok {
				list = support_calculator_lambda_new_1(self, bt)
				append(&self.support_rules_order, bt)
			}
			append(&list, rule)
			self.support_rules[bt] = list
		} else {
			when #config(SUP_PROBE, false) {
				attached_name := "?"
				if attached_ut != nil { attached_name = attached_ut.named_attachable.default_named.name }
				if attached_name == "artillery" {
					_units_count_match := 0
					for u in units_giving_the_support {
						if is_of_type_p(is_of_type_c, u) { _units_count_match += 1 }
					}
					_owned_match := 0
					for u in units_giving_the_support {
						if is_of_type_p(is_of_type_c, u) && owned_p(owned_c, u) { _owned_match += 1 }
					}
					_players := unit_support_attachment_get_players(rule)
					_first_owner := "?"
					for u in units_giving_the_support {
						if is_of_type_p(is_of_type_c, u) && u.owner != nil {
							_first_owner = u.owner.named_attachable.default_named.name
							break
						}
					}
					_players_str := ""
					for p in _players {
						if p == nil { continue }
						_players_str = _players_str
						_players_str = fmt.aprintf("%s,%s", _players_str, p.named_attachable.default_named.name)
					}
					fmt.printf("SUP_RULE_EMPTY attached=%s side=%v allies=%v type_match=%d owned_match=%d first_owner=%s players=[%s]\n", attached_name, side, allies, _units_count_match, _owned_match, _first_owner, _players_str)
				}
			}
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
	// Walk LinkedHashMap insertion order on both sides so downstream
	// consumers (PowerStrengthAndRolls.addUnits) build their
	// unit_support_*_map in the same supporter order Java does.
	friends_units := available_supports_get_units_giving_support(support_from_friends)
	for k in available_supports_get_units_giving_support_order(support_from_friends) {
		v := friends_units[k]
		entry, ok := support[k]
		if !ok {
			entry = support_calculator_lambda_get_combined_support_given_2(k)
			support[k] = entry
		}
		integer_map_add_map(entry, v)
	}
	enemies_units := available_supports_get_units_giving_support(support_from_enemies)
	for k in available_supports_get_units_giving_support_order(support_from_enemies) {
		v := enemies_units[k]
		entry, ok := support[k]
		if !ok {
			entry = support_calculator_lambda_get_combined_support_given_3(k)
			support[k] = entry
		}
		integer_map_add_map(entry, v)
	}
	return support
}
