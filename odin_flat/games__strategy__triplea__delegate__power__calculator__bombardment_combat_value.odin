package game

// Calculates offense strength and roll for non-AA dice (bombardment).
// Takes into account marine, bombarding, territory effects, friendly support, and enemy support.
Bombardment_Combat_Value :: struct {
	game_dice_sides:               i32,
	lhtr_heavy_bombers:            bool,
	strength_support_from_friends: ^Available_Supports,
	strength_support_from_enemies: ^Available_Supports,
	roll_support_from_friends:     ^Available_Supports,
	roll_support_from_enemies:     ^Available_Supports,
	territory_effects:             [dynamic]^Territory_Effect,
	friend_units:                  [dynamic]^Unit,
	enemy_units:                   [dynamic]^Unit,
}

bombardment_combat_value_default_friend_units :: proc() -> [dynamic]^Unit {
	return make([dynamic]^Unit)
}

bombardment_combat_value_default_enemy_units :: proc() -> [dynamic]^Unit {
	return make([dynamic]^Unit)
}

// Java: public int getDiceSides(final Unit unit) { return gameDiceSides; }
bombardment_combat_value_get_dice_sides :: proc(
	self: ^Bombardment_Combat_Value,
	unit: ^Unit,
) -> i32 {
	return self.game_dice_sides
}

// Java: public BattleState.Side getBattleSide() { return BattleState.Side.OFFENSE; }
bombardment_combat_value_get_battle_side :: proc(
	self: ^Bombardment_Combat_Value,
) -> Battle_State_Side {
	return .OFFENSE
}

// Java: public boolean chooseBestRoll(final Unit unit) {
//   return lhtrHeavyBombers || unit.getUnitAttachment().getChooseBestRoll();
// }
bombardment_combat_value_choose_best_roll :: proc(
	self: ^Bombardment_Combat_Value,
	unit: ^Unit,
) -> bool {
	return self.lhtr_heavy_bombers || unit_attachment_get_choose_best_roll(unit_get_unit_attachment(unit))
}

bombardment_combat_value_new :: proc(
	game_dice_sides: i32,
	lhtr_heavy_bombers: bool,
	strength_support_from_friends: ^Available_Supports,
	strength_support_from_enemies: ^Available_Supports,
	roll_support_from_friends: ^Available_Supports,
	roll_support_from_enemies: ^Available_Supports,
	territory_effects: [dynamic]^Territory_Effect,
	friend_units: [dynamic]^Unit,
	enemy_units: [dynamic]^Unit,
) -> ^Bombardment_Combat_Value {
	self := new(Bombardment_Combat_Value)
	self.game_dice_sides = game_dice_sides
	self.lhtr_heavy_bombers = lhtr_heavy_bombers
	self.strength_support_from_friends = strength_support_from_friends
	self.strength_support_from_enemies = strength_support_from_enemies
	self.roll_support_from_friends = roll_support_from_friends
	self.roll_support_from_enemies = roll_support_from_enemies
	self.territory_effects = territory_effects
	self.friend_units = friend_units
	self.enemy_units = enemy_units
	return self
}

// Java: public static BombardmentCombatValueBuilder builder() (Lombok-generated).
bombardment_combat_value_builder :: proc(
) -> ^Bombardment_Combat_Value_Bombardment_Combat_Value_Builder {
	return make_Bombardment_Combat_Value_Bombardment_Combat_Value_Builder()
}

// Mirrors AvailableSupports.EMPTY_RESULT — a fresh AvailableSupports built
// from empty supportRules and supportUnits maps. Java holds a single static
// instance; we return a freshly-allocated equivalent each call (the contents
// are immutable for the consumers below).
@(private = "file")
bombardment_combat_value_empty_supports :: proc() -> ^Available_Supports {
	rules := make(map[^Unit_Support_Attachment_Bonus_Type][dynamic]^Unit_Support_Attachment)
	units := make(map[^Unit_Support_Attachment]^Available_Supports_Support_Details)
	return available_supports_new(rules, units)
}

// Java: public CombatValue buildWithNoUnitSupports().
// Rebuilds this BombardmentCombatValue with all four support slots replaced by
// AvailableSupports.EMPTY_RESULT and friend/enemy unit lists cleared, while
// preserving gameDiceSides, lhtrHeavyBombers, and territoryEffects.
bombardment_combat_value_build_with_no_unit_supports :: proc(
	self: ^Bombardment_Combat_Value,
) -> ^Bombardment_Combat_Value {
	b := bombardment_combat_value_builder()
	b = bombardment_combat_value_bombardment_combat_value_builder_game_dice_sides(b, int(self.game_dice_sides))
	b = bombardment_combat_value_bombardment_combat_value_builder_lhtr_heavy_bombers(b, self.lhtr_heavy_bombers)
	b = bombardment_combat_value_bombardment_combat_value_builder_roll_support_from_friends(b, bombardment_combat_value_empty_supports())
	b = bombardment_combat_value_bombardment_combat_value_builder_roll_support_from_enemies(b, bombardment_combat_value_empty_supports())
	b = bombardment_combat_value_bombardment_combat_value_builder_strength_support_from_friends(b, bombardment_combat_value_empty_supports())
	b = bombardment_combat_value_bombardment_combat_value_builder_strength_support_from_enemies(b, bombardment_combat_value_empty_supports())
	b = bombardment_combat_value_bombardment_combat_value_builder_friend_units(b, make([dynamic]^Unit))
	b = bombardment_combat_value_bombardment_combat_value_builder_enemy_units(b, make([dynamic]^Unit))
	b = bombardment_combat_value_bombardment_combat_value_builder_territory_effects(b, self.territory_effects)
	return bombardment_combat_value_bombardment_combat_value_builder_build(b)
}

// Java: public CombatValue buildOppositeCombatValue().
// Swaps friend/enemy unit lists and the rollSupport pair; sets the strength
// support pair from the (original) rollSupport pair (mirrors the Java code
// exactly — note Java assigns rollSupport to BOTH roll and strength sides on
// the rebuilt value). territoryEffects, gameDiceSides, lhtrHeavyBombers carry
// over unchanged.
bombardment_combat_value_build_opposite_combat_value :: proc(
	self: ^Bombardment_Combat_Value,
) -> ^Bombardment_Combat_Value {
	b := bombardment_combat_value_builder()
	b = bombardment_combat_value_bombardment_combat_value_builder_game_dice_sides(b, int(self.game_dice_sides))
	b = bombardment_combat_value_bombardment_combat_value_builder_lhtr_heavy_bombers(b, self.lhtr_heavy_bombers)
	b = bombardment_combat_value_bombardment_combat_value_builder_roll_support_from_friends(b, self.roll_support_from_enemies)
	b = bombardment_combat_value_bombardment_combat_value_builder_roll_support_from_enemies(b, self.roll_support_from_friends)
	b = bombardment_combat_value_bombardment_combat_value_builder_strength_support_from_friends(b, self.roll_support_from_enemies)
	b = bombardment_combat_value_bombardment_combat_value_builder_strength_support_from_enemies(b, self.roll_support_from_friends)
	b = bombardment_combat_value_bombardment_combat_value_builder_friend_units(b, self.enemy_units)
	b = bombardment_combat_value_bombardment_combat_value_builder_enemy_units(b, self.friend_units)
	b = bombardment_combat_value_bombardment_combat_value_builder_territory_effects(b, self.territory_effects)
	return bombardment_combat_value_bombardment_combat_value_builder_build(b)
}

// Java: public RollCalculator getRoll() {
//   return new MainOffenseCombatValue.MainOffenseRoll(
//       rollSupportFromFriends.copy(), rollSupportFromEnemies.copy());
// }
bombardment_combat_value_get_roll :: proc(
	self: ^Bombardment_Combat_Value,
) -> ^Main_Offense_Combat_Value_Main_Offense_Roll {
	return main_offense_combat_value_main_offense_roll_new(
		available_supports_copy(self.roll_support_from_friends),
		available_supports_copy(self.roll_support_from_enemies),
	)
}

// Java: public StrengthCalculator getStrength() {
//   return new BombardmentStrength(
//       gameDiceSides, territoryEffects,
//       strengthSupportFromFriends.copy(), strengthSupportFromEnemies.copy());
// }
bombardment_combat_value_get_strength :: proc(
	self: ^Bombardment_Combat_Value,
) -> ^Bombardment_Combat_Value_Bombardment_Strength {
	return bombardment_strength_new(
		int(self.game_dice_sides),
		self.territory_effects,
		available_supports_copy(self.strength_support_from_friends),
		available_supports_copy(self.strength_support_from_enemies),
	)
}


// ============================================================
// Combat_Value / Strength_Calculator adapters for Bombardment
// ============================================================

@(private="file")
bcv_get_strength_ :: proc(cv: ^Combat_Value) -> ^Strength_Calculator {
        impl := cast(^Bombardment_Combat_Value)cv.concrete
        return bombardment_strength_to_strength_calculator(
                bombardment_combat_value_get_strength(impl),
        )
}

@(private="file")
bcv_get_roll_ :: proc(cv: ^Combat_Value) -> ^Roll_Calculator {
        impl := cast(^Bombardment_Combat_Value)cv.concrete
        return main_offense_combat_value_main_offense_roll_to_roll_calculator(
                bombardment_combat_value_get_roll(impl),
        )
}

@(private="file")
bcv_choose_best_roll_ :: proc(cv: ^Combat_Value, unit: ^Unit) -> bool {
        impl := cast(^Bombardment_Combat_Value)cv.concrete
        return bombardment_combat_value_choose_best_roll(impl, unit)
}

@(private="file")
bcv_get_dice_sides_ :: proc(cv: ^Combat_Value, unit: ^Unit) -> i32 {
        impl := cast(^Bombardment_Combat_Value)cv.concrete
        return bombardment_combat_value_get_dice_sides(impl, unit)
}

@(private="file")
bcv_get_battle_side_ :: proc(cv: ^Combat_Value) -> Battle_State_Side {
        impl := cast(^Bombardment_Combat_Value)cv.concrete
        return bombardment_combat_value_get_battle_side(impl)
}

@(private="file")
bcv_get_friend_units_ :: proc(cv: ^Combat_Value) -> [dynamic]^Unit {
        impl := cast(^Bombardment_Combat_Value)cv.concrete
        return impl.friend_units
}

@(private="file")
bcv_get_enemy_units_ :: proc(cv: ^Combat_Value) -> [dynamic]^Unit {
        impl := cast(^Bombardment_Combat_Value)cv.concrete
        return impl.enemy_units
}

@(private="file")
bcv_build_with_no_unit_supports_ :: proc(cv: ^Combat_Value) -> ^Combat_Value {
        impl := cast(^Bombardment_Combat_Value)cv.concrete
        return bombardment_combat_value_to_combat_value(
                bombardment_combat_value_build_with_no_unit_supports(impl),
        )
}

@(private="file")
bcv_build_opposite_combat_value_ :: proc(cv: ^Combat_Value) -> ^Combat_Value {
        impl := cast(^Bombardment_Combat_Value)cv.concrete
        return bombardment_combat_value_to_combat_value(
                bombardment_combat_value_build_opposite_combat_value(impl),
        )
}

bombardment_combat_value_to_combat_value :: proc(self: ^Bombardment_Combat_Value) -> ^Combat_Value {
        cv := new(Combat_Value)
        cv.concrete                    = self
        cv.get_strength                = bcv_get_strength_
        cv.get_roll                    = bcv_get_roll_
        cv.choose_best_roll            = bcv_choose_best_roll_
        cv.get_dice_sides              = bcv_get_dice_sides_
        cv.get_battle_side             = bcv_get_battle_side_
        cv.get_friend_units            = bcv_get_friend_units_
        cv.get_enemy_units             = bcv_get_enemy_units_
        cv.build_with_no_unit_supports = bcv_build_with_no_unit_supports_
        cv.build_opposite_combat_value = bcv_build_opposite_combat_value_
        return cv
}

@(private="file")
bs_get_strength_ :: proc(sc: ^Strength_Calculator, unit: ^Unit) -> ^Strength_Value {
        impl := cast(^Bombardment_Combat_Value_Bombardment_Strength)sc.concrete
        return bombardment_strength_get_strength(impl, unit)
}

@(private="file")
bs_get_support_given_ :: proc(sc: ^Strength_Calculator) -> map[^Unit]^Integer_Map {
        impl := cast(^Bombardment_Combat_Value_Bombardment_Strength)sc.concrete
        return bombardment_strength_get_support_given(impl)
}

bombardment_strength_to_strength_calculator :: proc(self: ^Bombardment_Combat_Value_Bombardment_Strength) -> ^Strength_Calculator {
        sc := new(Strength_Calculator)
        sc.concrete          = self
        sc.get_strength      = bs_get_strength_
        sc.get_support_given = bs_get_support_given_
        return sc
}
