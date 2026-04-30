package game

// Port of games.strategy.triplea.attachments.TechAbilityAttachment.
Tech_Ability_Attachment :: struct {
	using default_attachment: Default_Attachment,

	attack_bonus:                                 ^Integer_Map,
	defense_bonus:                                ^Integer_Map,
	movement_bonus:                               ^Integer_Map,
	radar_bonus:                                  ^Integer_Map,
	air_attack_bonus:                             ^Integer_Map,
	air_defense_bonus:                            ^Integer_Map,
	production_bonus:                             ^Integer_Map,
	minimum_territory_value_for_production_bonus: i32,
	repair_discount:                              i32,
	war_bond_dice_sides:                          i32,
	war_bond_dice_number:                         i32,
	rocket_dice_number:                           ^Integer_Map,
	rocket_distance:                              i32,
	rocket_number_per_territory:                  i32,
	unit_abilities_gained:                        map[^Unit_Type]map[string]struct {},
	airborne_forces:                              bool,
	airborne_capacity:                            ^Integer_Map,
	airborne_types:                               map[^Unit_Type]struct {},
	airborne_distance:                            i32,
	airborne_bases:                               map[^Unit_Type]struct {},
	airborne_targeted_by_aa:                      map[string]map[^Unit_Type]struct {},
	attack_rolls_bonus:                           ^Integer_Map,
	defense_rolls_bonus:                          ^Integer_Map,
	bombing_bonus:                                ^Integer_Map,
}

// =====================================================================
// Method ports — TechAbilityAttachment instance/static accessors.
//
// Naming convention for Java overloads on this struct:
//   - The instance-receiver getter (Java's `int getRepairDiscount()`,
//     `int getWarBondDiceSides()`, `int getWarBondDiceNumber()`,
//     `Map<String,Set<UnitType>> getAirborneTargettedByAa()`) keeps the
//     plain `tech_ability_attachment_<name>` form and is suffixed
//     `_no_args` to disambiguate from the static collection variant.
//   - The static collection variant (Java's
//     `getRepairDiscount(Collection<TechAdvance>)`, etc.) is suffixed
//     `_with_techs`.
// This matches the suffix scheme called out in the porting brief.
// Lambdas extracted by javac (`lambda$<method>$<n>`) become top-level
// helper procs `tech_ability_attachment_lambda_<method>_<n>` and are
// invoked at the same call sites where Java used the lambda; this keeps
// the stream pipeline shape one-to-one with the Java source.
// =====================================================================

// --- getRepairDiscount ---------------------------------------------------

// Java: private int getRepairDiscount() { return repairDiscount; }
tech_ability_attachment_get_repair_discount_no_args :: proc(
	self: ^Tech_Ability_Attachment,
) -> i32 {
	return self.repair_discount
}

// Java: lambda$getRepairDiscount$0 — `i -> i != -1` filter on the
// IntStream of repairDiscount values inside getRepairDiscount(Collection).
tech_ability_attachment_lambda_get_repair_discount_0 :: proc(i: i32) -> bool {
	return i != -1
}

// Java: lambda$getRepairDiscount$1 — `d -> d / 100.0` mapToDouble in
// getRepairDiscount(Collection). Java auto-widens int → double.
tech_ability_attachment_lambda_get_repair_discount_1 :: proc(d: i32) -> f64 {
	return f64(d) / 100.0
}

// Java: public static double getRepairDiscount(Collection<TechAdvance>)
// Returns max(0, 1.0 - sum(discount/100.0 for each non-null TAA whose
// repairDiscount is not -1)).
tech_ability_attachment_get_repair_discount_with_techs :: proc(
	tech_advances: [dynamic]^Tech_Advance,
) -> f64 {
	sum: f64 = 0
	for ta in tech_advances {
		taa := tech_ability_attachment_get(ta)
		if taa == nil {
			continue
		}
		v := tech_ability_attachment_get_repair_discount_no_args(taa)
		if !tech_ability_attachment_lambda_get_repair_discount_0(v) {
			continue
		}
		sum += tech_ability_attachment_lambda_get_repair_discount_1(v)
	}
	result := 1.0 - sum
	if result < 0 {
		result = 0
	}
	return result
}

// --- getWarBondDiceSides -------------------------------------------------

// Java: private int getWarBondDiceSides() { return warBondDiceSides; }
tech_ability_attachment_get_war_bond_dice_sides_no_args :: proc(
	self: ^Tech_Ability_Attachment,
) -> i32 {
	return self.war_bond_dice_sides
}

// Java: lambda$getWarBondDiceSides$3 — `t -> t > 0` filter inside
// getWarBondDiceSides(Collection). Operates on the int returned by the
// preceding mapToInt(t -> t.getWarBondDiceSides()).
tech_ability_attachment_lambda_get_war_bond_dice_sides_3 :: proc(t: i32) -> bool {
	return t > 0
}

// Java: public static int getWarBondDiceSides(Collection<TechAdvance>)
// Returns the first positive warBondDiceSides among the non-null TAAs,
// or 0 if none is positive (Java: findAny().orElse(0)).
tech_ability_attachment_get_war_bond_dice_sides_with_techs :: proc(
	tech_advances: [dynamic]^Tech_Advance,
) -> i32 {
	for ta in tech_advances {
		taa := tech_ability_attachment_get(ta)
		if taa == nil {
			continue
		}
		v := tech_ability_attachment_get_war_bond_dice_sides_no_args(taa)
		if tech_ability_attachment_lambda_get_war_bond_dice_sides_3(v) {
			return v
		}
	}
	return 0
}

// --- getWarBondDiceNumber ------------------------------------------------

// Java: private int getWarBondDiceNumber() { return warBondDiceNumber; }
tech_ability_attachment_get_war_bond_dice_number_no_args :: proc(
	self: ^Tech_Ability_Attachment,
) -> i32 {
	return self.war_bond_dice_number
}

// Java: lambda$getWarBondDiceNumber$5 — `t -> t > 0` filter inside
// getWarBondDiceNumber(Collection).
tech_ability_attachment_lambda_get_war_bond_dice_number_5 :: proc(t: i32) -> bool {
	return t > 0
}

// Java: public static int getWarBondDiceNumber(Collection<TechAdvance>)
// Returns the sum of positive warBondDiceNumber values across the
// non-null TAAs in the collection.
tech_ability_attachment_get_war_bond_dice_number_with_techs :: proc(
	tech_advances: [dynamic]^Tech_Advance,
) -> i32 {
	total: i32 = 0
	for ta in tech_advances {
		taa := tech_ability_attachment_get(ta)
		if taa == nil {
			continue
		}
		v := tech_ability_attachment_get_war_bond_dice_number_no_args(taa)
		if tech_ability_attachment_lambda_get_war_bond_dice_number_5(v) {
			total += v
		}
	}
	return total
}

// --- getAirborneTargettedByAa --------------------------------------------

// Java: lambda$getAirborneTargettedByAa$7 — `key -> new HashSet<>()`
// supplier passed to computeIfAbsent inside getAirborneTargettedByAa(
// Collection). Returns a freshly allocated empty unit-type set keyed by
// the AA-fire string. The `key` argument mirrors the Java lambda
// parameter even though it is unused.
tech_ability_attachment_lambda_get_airborne_targetted_by_aa_7 :: proc(
	key: string,
) -> map[^Unit_Type]struct {} {
	_ = key
	return make(map[^Unit_Type]struct {})
}

// Java: private Map<String, Set<UnitType>> getAirborneTargettedByAa()
// Mirrors `return getMapProperty(airborneTargetedByAa);`.
tech_ability_attachment_get_airborne_targetted_by_aa_no_args :: proc(
	self: ^Tech_Ability_Attachment,
) -> map[string]map[^Unit_Type]struct {} {
	return default_attachment_get_map_property(self.airborne_targeted_by_aa)
}

// Java: public static Map<String, Set<UnitType>> getAirborneTargettedByAa(
//           Collection<TechAdvance>)
// Merges all per-tech AA-fire-to-unit-type maps into a fresh map by
// unioning the unit-type sets per AA-fire key. Skips null TAAs and
// empty maps, matching the Java guard `mapAa != null && !mapAa.isEmpty()`.
tech_ability_attachment_get_airborne_targetted_by_aa_with_techs :: proc(
	tech_advances: [dynamic]^Tech_Advance,
) -> map[string]map[^Unit_Type]struct {} {
	airborne_targetted_by_aa := make(map[string]map[^Unit_Type]struct {})
	for ta in tech_advances {
		taa := tech_ability_attachment_get(ta)
		if taa == nil {
			continue
		}
		map_aa := tech_ability_attachment_get_airborne_targetted_by_aa_no_args(taa)
		if len(map_aa) == 0 {
			continue
		}
		for key, units in map_aa {
			if _, exists := airborne_targetted_by_aa[key]; !exists {
				airborne_targetted_by_aa[key] =
					tech_ability_attachment_lambda_get_airborne_targetted_by_aa_7(key)
			}
			inner := &airborne_targetted_by_aa[key]
			for ut, _ in units {
				inner[ut] = struct {}{}
			}
		}
	}
	return airborne_targetted_by_aa
}

// --- setUnitAbilitiesGained lambda ---------------------------------------

// Java: lambda$setUnitAbilitiesGained$6 — `key -> new HashSet<>()`
// supplier passed to `unitAbilitiesGained.computeIfAbsent(ut, ...)`
// inside setUnitAbilitiesGained(String). Returns a freshly allocated
// empty ability-name set; the UnitType key mirrors the Java lambda
// parameter even though it is unused.
tech_ability_attachment_lambda_set_unit_abilities_gained_6 :: proc(
	key: ^Unit_Type,
) -> map[string]struct {} {
	_ = key
	return make(map[string]struct {})
}

