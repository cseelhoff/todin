package game

import "core:fmt"

// Java: TechAbilityAttachment.ABILITY_CAN_BLITZ / ABILITY_CAN_BOMBARD.
// Public string constants enumerating the abilities understood by
// `setUnitAbilitiesGained`.
ABILITY_CAN_BLITZ   :: "canBlitz"
ABILITY_CAN_BOMBARD :: "canBombard"

// Java: Constants.TECH_ABILITY_ATTACHMENT_NAME ("techAbilityAttachment").
// Inlined here to avoid pulling in the entire Constants file for a single
// string literal; the canonical Java value is preserved verbatim.
TECH_ABILITY_ATTACHMENT_NAME :: "techAbilityAttachment"

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


// --- get(TechAdvance) ----------------------------------------------------

// Java: public static TechAbilityAttachment get(final TechAdvance type)
// Mirrors the static lookup used throughout the file: when `type` is a
// GenericTechAdvance aliasing a hardcoded advance, return that hardcoded
// advance's TechAbilityAttachment; otherwise return `type`'s own. The
// Java `instanceof GenericTechAdvance` test is preserved through the
// `is_generic` discriminator added on Tech_Advance (no RTTI / reflection).
tech_ability_attachment_get :: proc(type: ^Tech_Advance) -> ^Tech_Ability_Attachment {
	if type == nil {
		return nil
	}
	if type.is_generic {
		generic := cast(^Generic_Tech_Advance)type
		hard_coded_advance := generic_tech_advance_get_advance(generic)
		if hard_coded_advance != nil {
			raw := named_attachable_get_attachment(
				&hard_coded_advance.named_attachable,
				TECH_ABILITY_ATTACHMENT_NAME,
			)
			return cast(^Tech_Ability_Attachment)raw
		}
	}
	raw := named_attachable_get_attachment(&type.named_attachable, TECH_ABILITY_ATTACHMENT_NAME)
	return cast(^Tech_Ability_Attachment)raw
}

// --- splitAndValidate / getIntInRange -----------------------------------

// Java: @VisibleForTesting String[] splitAndValidate(name, value)
// Splits `value` on ':' and panics with the Java GameParseException message
// when the input is empty or has more than two colon-separated fields.
// The caller owns the returned `[dynamic]string` (mirrors the convention
// used by `default_attachment_split_on_colon`).
tech_ability_attachment_split_and_validate :: proc(
	self: ^Tech_Ability_Attachment,
	name: string,
	value: string,
) -> [dynamic]string {
	string_array := default_attachment_split_on_colon(value)
	if len(value) == 0 || len(string_array) > 2 {
		suffix := default_attachment_this_error_msg(&self.default_attachment)
		defer delete(suffix)
		fmt.panicf("%s cannot be empty or have more than two fields%s", name, suffix)
	}
	return string_array
}

// Java: @VisibleForTesting int getIntInRange(name, value, max, allowUndefined)
// Parses `value` as an int and validates it lies in
// [allowUndefined ? -1 : 0, max]; otherwise panics with the Java
// GameParseException message. Mirrors the static-format string verbatim.
tech_ability_attachment_get_int_in_range :: proc(
	self: ^Tech_Ability_Attachment,
	name: string,
	value: string,
	max: i32,
	allow_undefined: bool,
) -> i32 {
	int_value := default_attachment_get_int(&self.default_attachment, value)
	min_value: i32 = 0
	if allow_undefined {
		min_value = -1
	}
	if int_value < min_value || int_value > max {
		suffix := default_attachment_this_error_msg(&self.default_attachment)
		defer delete(suffix)
		undefined_clause := ""
		if allow_undefined {
			undefined_clause = " -1 (no effect), or be"
		}
		fmt.panicf(
			"%s must be%s between 0 and %d, was %s%s",
			name,
			undefined_clause,
			max,
			value,
			suffix,
		)
	}
	return int_value
}

// --- mapToInt lambdas missing from the existing block ------------------

// Java: lambda$getWarBondDiceSides$2 — `t -> t.getWarBondDiceSides()`
// mapToInt callback inside the static getWarBondDiceSides(Collection).
// Operates on a non-null TechAbilityAttachment surfaced by the preceding
// filter(Objects::nonNull) stage.
tech_ability_attachment_lambda_get_war_bond_dice_sides_2 :: proc(
	t: ^Tech_Ability_Attachment,
) -> i32 {
	return tech_ability_attachment_get_war_bond_dice_sides_no_args(t)
}

// Java: lambda$getWarBondDiceNumber$4 — `t -> t.getWarBondDiceNumber()`
// mapToInt callback inside the static getWarBondDiceNumber(Collection).
// Mirror of $2 above for the dice-number stream.
tech_ability_attachment_lambda_get_war_bond_dice_number_4 :: proc(
	t: ^Tech_Ability_Attachment,
) -> i32 {
	return tech_ability_attachment_get_war_bond_dice_number_no_args(t)
}

// --- setRocketDiceNumber(String) ----------------------------------------

// Java: private void setRocketDiceNumber(String value)
// Splits `value` on ':' (must be exactly two segments: count:unitType),
// resolves the unit type, parses the count as int, and stores the entry
// in `rocketDiceNumber`, lazily allocating the IntegerMap.
tech_ability_attachment_set_rocket_dice_number :: proc(
	self: ^Tech_Ability_Attachment,
	value: string,
) {
	s := default_attachment_split_on_colon(value)
	defer delete(s)
	if len(s) != 2 {
		suffix := default_attachment_this_error_msg(&self.default_attachment)
		defer delete(suffix)
		fmt.panicf("rocketDiceNumber must have two fields%s", suffix)
	}
	if self.rocket_dice_number == nil {
		self.rocket_dice_number = integer_map_new()
	}
	ut := default_attachment_get_unit_type_or_throw(&self.default_attachment, s[1])
	count := default_attachment_get_int(&self.default_attachment, s[0])
	integer_map_put(self.rocket_dice_number, rawptr(ut), count)
}

// --- setUnitAbilitiesGained(String) -------------------------------------

// Java: private void setUnitAbilitiesGained(String value)
// Splits on ':' (must have at least two segments: unitType:ability[:ability...]),
// resolves the unit type, lazily allocates `unitAbilitiesGained`, then for
// each ability segment validates it against the supported set
// {ABILITY_CAN_BLITZ, ABILITY_CAN_BOMBARD} and adds it to the unit's
// ability set. Java calls `String.intern()` on the ability before adding;
// Odin has no string-intern table so the value is added as-is.
tech_ability_attachment_set_unit_abilities_gained :: proc(
	self: ^Tech_Ability_Attachment,
	value: string,
) {
	s := default_attachment_split_on_colon(value)
	defer delete(s)
	if len(s) < 2 {
		suffix := default_attachment_this_error_msg(&self.default_attachment)
		defer delete(suffix)
		fmt.panicf(
			"unitAbilitiesGained must list the unit type, then all abilities gained%s",
			suffix,
		)
	}
	unit_type := s[0]
	ut := default_attachment_get_unit_type_or_throw(&self.default_attachment, unit_type)
	if self.unit_abilities_gained == nil {
		self.unit_abilities_gained = make(map[^Unit_Type]map[string]struct {})
	}
	if _, exists := self.unit_abilities_gained[ut]; !exists {
		self.unit_abilities_gained[ut] =
			tech_ability_attachment_lambda_set_unit_abilities_gained_6(ut)
	}
	abilities := &self.unit_abilities_gained[ut]
	for i := 1; i < len(s); i += 1 {
		ability := s[i]
		if !(ability == ABILITY_CAN_BLITZ || ability == ABILITY_CAN_BOMBARD) {
			suffix := default_attachment_this_error_msg(&self.default_attachment)
			defer delete(suffix)
			fmt.panicf(
				"unitAbilitiesGained so far only supports: %s and %s%s",
				ABILITY_CAN_BLITZ,
				ABILITY_CAN_BOMBARD,
				suffix,
			)
		}
		abilities[ability] = struct {}{}
	}
}

// --- constructor ---------------------------------------------------------

// Java: public TechAbilityAttachment(String name, Attachable attachable, GameData gameData)
// Mirrors `super(name, attachable, gameData)` — the same setter chain that
// `default_attachment_new` performs, but allocating the concrete subtype so
// the embedded `Default_Attachment` lives inside the
// `Tech_Ability_Attachment` value (no separate heap allocation for the
// parent). All other fields keep their Odin zero defaults except those the
// Java declarations initialize to non-zero values: the three -1 sentinels
// and `rocket_number_per_territory = 1`.
tech_ability_attachment_new :: proc(
	name: string,
	attachable: ^Attachable,
	game_data: ^Game_Data,
) -> ^Tech_Ability_Attachment {
	self := new(Tech_Ability_Attachment)
	self.game_data_component = make_Game_Data_Component(game_data)
	default_attachment_set_name(&self.default_attachment, name)
	default_attachment_set_attached_to(&self.default_attachment, attachable)
	self.minimum_territory_value_for_production_bonus = -1
	self.repair_discount = -1
	self.war_bond_dice_sides = -1
	self.rocket_number_per_territory = 1
	return self
}

// --- applyCheckedValue ---------------------------------------------------

// Java: @VisibleForTesting void applyCheckedValue(name, value, BiConsumer<UnitType, Integer> putter)
// Splits/validates `value` via splitAndValidate, then forwards the resolved
// (UnitType, Integer) pair to `putter`. The Java `BiConsumer` becomes a
// bare Odin `proc` per the porting brief; current call sites use it for
// non-capturing forwarding (e.g. `attackBonus::put` style method refs that
// the orchestrator will port with the matching capture convention when
// those setters are scheduled).
tech_ability_attachment_apply_checked_value :: proc(
	self: ^Tech_Ability_Attachment,
	name: string,
	value: string,
	putter: proc(unit_type: ^Unit_Type, v: i32),
) {
	s := tech_ability_attachment_split_and_validate(self, name, value)
	defer delete(s)
	ut := default_attachment_get_unit_type_or_throw(&self.default_attachment, s[1])
	v := default_attachment_get_int(&self.default_attachment, s[0])
	putter(ut, v)
}

// --- simple int-range setters -------------------------------------------

// Java: private void setMinimumTerritoryValueForProductionBonus(String value)
// Range [-1, 10000] (allowUndefined=true).
tech_ability_attachment_set_minimum_territory_value_for_production_bonus :: proc(
	self: ^Tech_Ability_Attachment,
	value: string,
) {
	self.minimum_territory_value_for_production_bonus = tech_ability_attachment_get_int_in_range(
		self,
		"minimumTerritoryValueForProductionBonus",
		value,
		10000,
		true,
	)
}

// Java: private void setRepairDiscount(String value)
// Range [-1, 100] (allowUndefined=true). Stored as percent; the static
// getRepairDiscount(Collection) divides by 100.0 at use time.
tech_ability_attachment_set_repair_discount :: proc(
	self: ^Tech_Ability_Attachment,
	value: string,
) {
	self.repair_discount = tech_ability_attachment_get_int_in_range(
		self,
		"repairDiscount",
		value,
		100,
		true,
	)
}

// Java: private void setRocketDistance(String value)
// Range [0, 100] (allowUndefined=false).
tech_ability_attachment_set_rocket_distance :: proc(
	self: ^Tech_Ability_Attachment,
	value: string,
) {
	self.rocket_distance = tech_ability_attachment_get_int_in_range(
		self,
		"rocketDistance",
		value,
		100,
		false,
	)
}

// Java: private void setRocketNumberPerTerritory(String value)
// Range [-1, 200] (allowUndefined=true).
tech_ability_attachment_set_rocket_number_per_territory :: proc(
	self: ^Tech_Ability_Attachment,
	value: string,
) {
	self.rocket_number_per_territory = tech_ability_attachment_get_int_in_range(
		self,
		"rocketNumberPerTerritory",
		value,
		200,
		true,
	)
}

// Java: private void setWarBondDiceNumber(String value)
// Range [0, 100] (allowUndefined=false).
tech_ability_attachment_set_war_bond_dice_number :: proc(
	self: ^Tech_Ability_Attachment,
	value: string,
) {
	self.war_bond_dice_number = tech_ability_attachment_get_int_in_range(
		self,
		"warBondDiceNumber",
		value,
		100,
		false,
	)
}

// Java: private void setWarBondDiceSides(String value)
// Range [-1, 200] (allowUndefined=true).
tech_ability_attachment_set_war_bond_dice_sides :: proc(
	self: ^Tech_Ability_Attachment,
	value: string,
) {
	self.war_bond_dice_sides = tech_ability_attachment_get_int_in_range(
		self,
		"warBondDiceSides",
		value,
		200,
		true,
	)
}

// --- IntegerMap<UnitType> string setters --------------------------------
//
// Each Java setter has the shape:
//   private void setXxxBonus(final String value) throws GameParseException {
//     if (xxxBonus == null) { xxxBonus = new IntegerMap<>(); }
//     applyCheckedValue("xxxBonus", value, xxxBonus::put);
//   }
//
// The Odin port inlines `applyCheckedValue` because Odin's bare proc
// signature on `tech_ability_attachment_apply_checked_value` cannot
// carry the captured `xxxBonus` field reference that
// `xxxBonus::put` represents. Inlining keeps the behavior identical
// (split/validate, resolve unit type, parse int, store) without
// introducing a rawptr-ctx adapter for a single internal call site.

// Java: private void setAttackBonus(final String value)
tech_ability_attachment_set_attack_bonus :: proc(
	self: ^Tech_Ability_Attachment,
	value: string,
) {
	if self.attack_bonus == nil {
		self.attack_bonus = integer_map_new()
	}
	s := tech_ability_attachment_split_and_validate(self, "attackBonus", value)
	defer delete(s)
	ut := default_attachment_get_unit_type_or_throw(&self.default_attachment, s[1])
	v := default_attachment_get_int(&self.default_attachment, s[0])
	integer_map_put(self.attack_bonus, rawptr(ut), v)
}

// Java: private void setDefenseBonus(final String value)
tech_ability_attachment_set_defense_bonus :: proc(
	self: ^Tech_Ability_Attachment,
	value: string,
) {
	if self.defense_bonus == nil {
		self.defense_bonus = integer_map_new()
	}
	s := tech_ability_attachment_split_and_validate(self, "defenseBonus", value)
	defer delete(s)
	ut := default_attachment_get_unit_type_or_throw(&self.default_attachment, s[1])
	v := default_attachment_get_int(&self.default_attachment, s[0])
	integer_map_put(self.defense_bonus, rawptr(ut), v)
}

// Java: private void setMovementBonus(final String value)
tech_ability_attachment_set_movement_bonus :: proc(
	self: ^Tech_Ability_Attachment,
	value: string,
) {
	if self.movement_bonus == nil {
		self.movement_bonus = integer_map_new()
	}
	s := tech_ability_attachment_split_and_validate(self, "movementBonus", value)
	defer delete(s)
	ut := default_attachment_get_unit_type_or_throw(&self.default_attachment, s[1])
	v := default_attachment_get_int(&self.default_attachment, s[0])
	integer_map_put(self.movement_bonus, rawptr(ut), v)
}

// Java: private void setRadarBonus(final String value)
tech_ability_attachment_set_radar_bonus :: proc(
	self: ^Tech_Ability_Attachment,
	value: string,
) {
	if self.radar_bonus == nil {
		self.radar_bonus = integer_map_new()
	}
	s := tech_ability_attachment_split_and_validate(self, "radarBonus", value)
	defer delete(s)
	ut := default_attachment_get_unit_type_or_throw(&self.default_attachment, s[1])
	v := default_attachment_get_int(&self.default_attachment, s[0])
	integer_map_put(self.radar_bonus, rawptr(ut), v)
}

// Java: private void setAirAttackBonus(final String value)
tech_ability_attachment_set_air_attack_bonus :: proc(
	self: ^Tech_Ability_Attachment,
	value: string,
) {
	if self.air_attack_bonus == nil {
		self.air_attack_bonus = integer_map_new()
	}
	s := tech_ability_attachment_split_and_validate(self, "airAttackBonus", value)
	defer delete(s)
	ut := default_attachment_get_unit_type_or_throw(&self.default_attachment, s[1])
	v := default_attachment_get_int(&self.default_attachment, s[0])
	integer_map_put(self.air_attack_bonus, rawptr(ut), v)
}

// Java: private void setAirDefenseBonus(final String value)
tech_ability_attachment_set_air_defense_bonus :: proc(
	self: ^Tech_Ability_Attachment,
	value: string,
) {
	if self.air_defense_bonus == nil {
		self.air_defense_bonus = integer_map_new()
	}
	s := tech_ability_attachment_split_and_validate(self, "airDefenseBonus", value)
	defer delete(s)
	ut := default_attachment_get_unit_type_or_throw(&self.default_attachment, s[1])
	v := default_attachment_get_int(&self.default_attachment, s[0])
	integer_map_put(self.air_defense_bonus, rawptr(ut), v)
}

// Java: private void setProductionBonus(final String value)
tech_ability_attachment_set_production_bonus :: proc(
	self: ^Tech_Ability_Attachment,
	value: string,
) {
	if self.production_bonus == nil {
		self.production_bonus = integer_map_new()
	}
	s := tech_ability_attachment_split_and_validate(self, "productionBonus", value)
	defer delete(s)
	ut := default_attachment_get_unit_type_or_throw(&self.default_attachment, s[1])
	v := default_attachment_get_int(&self.default_attachment, s[0])
	integer_map_put(self.production_bonus, rawptr(ut), v)
}

// Java: private void setAttackRollsBonus(final String value)
tech_ability_attachment_set_attack_rolls_bonus :: proc(
	self: ^Tech_Ability_Attachment,
	value: string,
) {
	if self.attack_rolls_bonus == nil {
		self.attack_rolls_bonus = integer_map_new()
	}
	s := tech_ability_attachment_split_and_validate(self, "attackRollsBonus", value)
	defer delete(s)
	ut := default_attachment_get_unit_type_or_throw(&self.default_attachment, s[1])
	v := default_attachment_get_int(&self.default_attachment, s[0])
	integer_map_put(self.attack_rolls_bonus, rawptr(ut), v)
}

// Java: private void setDefenseRollsBonus(final String value)
tech_ability_attachment_set_defense_rolls_bonus :: proc(
	self: ^Tech_Ability_Attachment,
	value: string,
) {
	if self.defense_rolls_bonus == nil {
		self.defense_rolls_bonus = integer_map_new()
	}
	s := tech_ability_attachment_split_and_validate(self, "defenseRollsBonus", value)
	defer delete(s)
	ut := default_attachment_get_unit_type_or_throw(&self.default_attachment, s[1])
	v := default_attachment_get_int(&self.default_attachment, s[0])
	integer_map_put(self.defense_rolls_bonus, rawptr(ut), v)
}

// Java: private void setBombingBonus(final String value)
tech_ability_attachment_set_bombing_bonus :: proc(
	self: ^Tech_Ability_Attachment,
	value: string,
) {
	if self.bombing_bonus == nil {
		self.bombing_bonus = integer_map_new()
	}
	s := tech_ability_attachment_split_and_validate(self, "bombingBonus", value)
	defer delete(s)
	ut := default_attachment_get_unit_type_or_throw(&self.default_attachment, s[1])
	v := default_attachment_get_int(&self.default_attachment, s[0])
	integer_map_put(self.bombing_bonus, rawptr(ut), v)
}

// --- setDefaultTechnologyAttachments(GameData) --------------------------

// Java: public static void setDefaultTechnologyAttachments(GameData data)
//          throws GameParseException
//
// Walks every TechAdvance in the master technology frontier and, for each
// predefined "hard-coded" tech that lacks a TechAbilityAttachment, allocates
// the attachment, wires it into the advance via `addAttachment`, and
// populates it with the canonical defaults baked into the Java method.
// Generic tech advances are unwrapped to their underlying advance (or
// skipped when null), and any property string outside the supported
// switch cases is intentionally ignored — Java's `default` branch is a
// no-op preserving the comment block listing the techs that are handled
// elsewhere (shipyards, industrialTechnology, improvedArtillerySupport,
// paratroopers, mechanizedInfantry).
//
// Predicate composition note: Java's
// `Matches.unitTypeIsAir().and(Matches.unitTypeIsStrategicBomber().negate())`
// for the JET_POWER case is inlined as a single boolean expression because
// the project's matches return `(proc(rawptr,^Unit_Type)->bool, rawptr)`
// pairs that do not currently expose `.and`/`.negate` combinators.
tech_ability_attachment_set_default_technology_attachments :: proc(data: ^Game_Data) {
	advances := tech_advance_get_tech_advances_no_player(game_data_get_technology_frontier(data))
	defer delete(advances)
	for advance in advances {
		ta: ^Tech_Advance
		if advance.is_generic {
			adv := generic_tech_advance_get_advance(cast(^Generic_Tech_Advance)advance)
			if adv != nil {
				ta = adv
			} else {
				continue
			}
		} else {
			ta = advance
		}
		property_string := tech_advance_get_property(ta)
		taa := tech_ability_attachment_get(ta)
		if taa != nil {
			continue
		}
		switch property_string {
		case TECH_PROPERTY_LONG_RANGE_AIRCRAFT:
			taa = tech_ability_attachment_new(TECH_ABILITY_ATTACHMENT_NAME, cast(^Attachable)ta, data)
			named_attachable_add_attachment(
				&ta.named_attachable,
				TECH_ABILITY_ATTACHMENT_NAME,
				cast(^I_Attachment)taa,
			)
			all := unit_type_list_get_all_unit_types(game_data_get_unit_type_list(data))
			defer delete(all)
			pred, ctx := matches_unit_type_is_air()
			for air in all {
				if pred(ctx, air) {
					s := fmt.aprintf("2:%s", air.named.base.name)
					tech_ability_attachment_set_movement_bonus(taa, s)
					delete(s)
				}
			}
		case TECH_PROPERTY_AA_RADAR:
			taa = tech_ability_attachment_new(TECH_ABILITY_ATTACHMENT_NAME, cast(^Attachable)ta, data)
			named_attachable_add_attachment(
				&ta.named_attachable,
				TECH_ABILITY_ATTACHMENT_NAME,
				cast(^I_Attachment)taa,
			)
			all := unit_type_list_get_all_unit_types(game_data_get_unit_type_list(data))
			defer delete(all)
			pred, ctx := matches_unit_type_is_aa_for_anything()
			for aa in all {
				if pred(ctx, aa) {
					s := fmt.aprintf("1:%s", aa.named.base.name)
					tech_ability_attachment_set_radar_bonus(taa, s)
					delete(s)
				}
			}
		case TECH_PROPERTY_SUPER_SUBS:
			taa = tech_ability_attachment_new(TECH_ABILITY_ATTACHMENT_NAME, cast(^Attachable)ta, data)
			named_attachable_add_attachment(
				&ta.named_attachable,
				TECH_ABILITY_ATTACHMENT_NAME,
				cast(^I_Attachment)taa,
			)
			all := unit_type_list_get_all_unit_types(game_data_get_unit_type_list(data))
			defer delete(all)
			pred, ctx := matches_unit_type_is_first_strike()
			for sub in all {
				if pred(ctx, sub) {
					s := fmt.aprintf("1:%s", sub.named.base.name)
					tech_ability_attachment_set_attack_bonus(taa, s)
					delete(s)
				}
			}
		case TECH_PROPERTY_JET_POWER:
			taa = tech_ability_attachment_new(TECH_ABILITY_ATTACHMENT_NAME, cast(^Attachable)ta, data)
			named_attachable_add_attachment(
				&ta.named_attachable,
				TECH_ABILITY_ATTACHMENT_NAME,
				cast(^I_Attachment)taa,
			)
			all := unit_type_list_get_all_unit_types(game_data_get_unit_type_list(data))
			defer delete(all)
			air_pred, air_ctx := matches_unit_type_is_air()
			bomber_pred, bomber_ctx := matches_unit_type_is_strategic_bomber()
			ww2v3_tech_model := properties_get_ww2_v3_tech_model(game_data_get_properties(data))
			for jet in all {
				if air_pred(air_ctx, jet) && !bomber_pred(bomber_ctx, jet) {
					s := fmt.aprintf("1:%s", jet.named.base.name)
					if ww2v3_tech_model {
						tech_ability_attachment_set_attack_bonus(taa, s)
						tech_ability_attachment_set_air_attack_bonus(taa, s)
					} else {
						tech_ability_attachment_set_defense_bonus(taa, s)
						tech_ability_attachment_set_air_defense_bonus(taa, s)
					}
					delete(s)
				}
			}
		case TECH_PROPERTY_INCREASED_FACTORY_PRODUCTION:
			taa = tech_ability_attachment_new(TECH_ABILITY_ATTACHMENT_NAME, cast(^Attachable)ta, data)
			named_attachable_add_attachment(
				&ta.named_attachable,
				TECH_ABILITY_ATTACHMENT_NAME,
				cast(^I_Attachment)taa,
			)
			all := unit_type_list_get_all_unit_types(game_data_get_unit_type_list(data))
			defer delete(all)
			pred, ctx := matches_unit_type_can_produce_units()
			for factory in all {
				if pred(ctx, factory) {
					s := fmt.aprintf("2:%s", factory.named.base.name)
					tech_ability_attachment_set_production_bonus(taa, s)
					delete(s)
					tech_ability_attachment_set_minimum_territory_value_for_production_bonus(taa, "3")
					// means a 50% discount, which is half price
					tech_ability_attachment_set_repair_discount(taa, "50")
				}
			}
		case TECH_PROPERTY_WAR_BONDS:
			taa = tech_ability_attachment_new(TECH_ABILITY_ATTACHMENT_NAME, cast(^Attachable)ta, data)
			named_attachable_add_attachment(
				&ta.named_attachable,
				TECH_ABILITY_ATTACHMENT_NAME,
				cast(^I_Attachment)taa,
			)
			sides := fmt.aprintf("%d", game_data_get_dice_sides(data))
			defer delete(sides)
			tech_ability_attachment_set_war_bond_dice_sides(taa, sides)
			tech_ability_attachment_set_war_bond_dice_number(taa, "1")
		case TECH_PROPERTY_ROCKETS:
			taa = tech_ability_attachment_new(TECH_ABILITY_ATTACHMENT_NAME, cast(^Attachable)ta, data)
			named_attachable_add_attachment(
				&ta.named_attachable,
				TECH_ABILITY_ATTACHMENT_NAME,
				cast(^I_Attachment)taa,
			)
			all := unit_type_list_get_all_unit_types(game_data_get_unit_type_list(data))
			defer delete(all)
			pred, ctx := matches_unit_type_is_rocket()
			for rocket in all {
				if pred(ctx, rocket) {
					s := fmt.aprintf("1:%s", rocket.named.base.name)
					tech_ability_attachment_set_rocket_dice_number(taa, s)
					delete(s)
				}
			}
			tech_ability_attachment_set_rocket_distance(taa, "3")
			tech_ability_attachment_set_rocket_number_per_territory(taa, "1")
		case TECH_PROPERTY_DESTROYER_BOMBARD:
			taa = tech_ability_attachment_new(TECH_ABILITY_ATTACHMENT_NAME, cast(^Attachable)ta, data)
			named_attachable_add_attachment(
				&ta.named_attachable,
				TECH_ABILITY_ATTACHMENT_NAME,
				cast(^I_Attachment)taa,
			)
			all := unit_type_list_get_all_unit_types(game_data_get_unit_type_list(data))
			defer delete(all)
			destroyer_pred, destroyer_ctx := matches_unit_type_is_destroyer()
			sea_pred, sea_ctx := matches_unit_type_is_sea()
			for destroyer in all {
				if destroyer_pred(destroyer_ctx, destroyer) && sea_pred(sea_ctx, destroyer) {
					s := fmt.aprintf("%s:%s", destroyer.named.base.name, ABILITY_CAN_BOMBARD)
					tech_ability_attachment_set_unit_abilities_gained(taa, s)
					delete(s)
				}
			}
		case TECH_PROPERTY_HEAVY_BOMBER:
			taa = tech_ability_attachment_new(TECH_ABILITY_ATTACHMENT_NAME, cast(^Attachable)ta, data)
			named_attachable_add_attachment(
				&ta.named_attachable,
				TECH_ABILITY_ATTACHMENT_NAME,
				cast(^I_Attachment)taa,
			)
			all := unit_type_list_get_all_unit_types(game_data_get_unit_type_list(data))
			defer delete(all)
			pred, ctx := matches_unit_type_is_strategic_bomber()
			heavy_bomber_dice_rolls_total := properties_get_heavy_bomber_dice_rolls(
				game_data_get_properties(data),
			)
			heavy_bombers_lhtr := properties_get_lhtr_heavy_bombers(game_data_get_properties(data))
			null_player := player_list_get_null_player(game_data_get_player_list(data))
			for bomber in all {
				if !pred(ctx, bomber) {
					continue
				}
				// TODO: The bomber dice rolls get set when the xml is parsed.
				// we subtract the base rolls to get the bonus
				heavy_bomber_dice_rolls_bonus :=
					heavy_bomber_dice_rolls_total -
					unit_attachment_get_attack_rolls_with_player(
						unit_type_get_unit_attachment(bomber),
						null_player,
					)
				s := fmt.aprintf("%d:%s", heavy_bomber_dice_rolls_bonus, bomber.named.base.name)
				tech_ability_attachment_set_attack_rolls_bonus(taa, s)
				if heavy_bombers_lhtr {
					// TODO: this all happens WHEN the xml is parsed. Which means if
					// the user changes the game options, this does not get changed.
					// (meaning, turning on LHTR bombers will not result in this bonus
					// damage, etc. It would have to start on, in the xml.)
					tech_ability_attachment_set_defense_rolls_bonus(taa, s)
					// LHTR adds 1 to base roll
					b := fmt.aprintf("1:%s", bomber.named.base.name)
					tech_ability_attachment_set_bombing_bonus(taa, b)
					delete(b)
				}
				delete(s)
			}
		case:
			// shipyards / industrialTechnology / improvedArtillerySupport /
			// paratroopers / mechanizedInfantry — handled elsewhere; no-op here.
		}
	}
}
