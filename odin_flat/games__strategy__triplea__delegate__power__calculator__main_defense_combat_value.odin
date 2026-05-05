package game

Main_Defense_Combat_Value :: struct {
	game_sequence:                 ^Game_Sequence,
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

main_defense_combat_value_default_friend_units :: proc() -> [dynamic]^Unit {
	return make([dynamic]^Unit)
}

main_defense_combat_value_default_enemy_units :: proc() -> [dynamic]^Unit {
	return make([dynamic]^Unit)
}

main_defense_combat_value_new :: proc(
	game_sequence: ^Game_Sequence,
	game_dice_sides: i32,
	lhtr_heavy_bombers: bool,
	strength_support_from_friends: ^Available_Supports,
	strength_support_from_enemies: ^Available_Supports,
	roll_support_from_friends: ^Available_Supports,
	roll_support_from_enemies: ^Available_Supports,
	territory_effects: [dynamic]^Territory_Effect,
	friend_units: [dynamic]^Unit,
	enemy_units: [dynamic]^Unit,
) -> ^Main_Defense_Combat_Value {
	self := new(Main_Defense_Combat_Value)
	self.game_sequence = game_sequence
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

main_defense_combat_value_get_battle_side :: proc(self: ^Main_Defense_Combat_Value) -> Battle_State_Side {
	return .DEFENSE
}

main_defense_combat_value_get_dice_sides :: proc(self: ^Main_Defense_Combat_Value, unit: ^Unit) -> i32 {
	return self.game_dice_sides
}

main_defense_combat_value_builder :: proc(
) -> ^Main_Defense_Combat_Value_Main_Defense_Combat_Value_Builder {
	return main_defense_combat_value_main_defense_combat_value_builder_new()
}

// Ported from MainDefenseCombatValue#buildWithNoUnitSupports().
// Returns a copy of this combat value with all support pools replaced by
// AvailableSupports.EMPTY_RESULT and friend/enemy unit lists replaced by
// empty lists. Territory effects are preserved.
main_defense_combat_value_build_with_no_unit_supports :: proc(self: ^Main_Defense_Combat_Value) -> ^Main_Defense_Combat_Value {
	empty_roll_friends := available_supports_new(
		make(map[^Unit_Support_Attachment_Bonus_Type][dynamic]^Unit_Support_Attachment),
		make(map[^Unit_Support_Attachment]^Available_Supports_Support_Details),
	)
	empty_roll_enemies := available_supports_new(
		make(map[^Unit_Support_Attachment_Bonus_Type][dynamic]^Unit_Support_Attachment),
		make(map[^Unit_Support_Attachment]^Available_Supports_Support_Details),
	)
	empty_strength_friends := available_supports_new(
		make(map[^Unit_Support_Attachment_Bonus_Type][dynamic]^Unit_Support_Attachment),
		make(map[^Unit_Support_Attachment]^Available_Supports_Support_Details),
	)
	empty_strength_enemies := available_supports_new(
		make(map[^Unit_Support_Attachment_Bonus_Type][dynamic]^Unit_Support_Attachment),
		make(map[^Unit_Support_Attachment]^Available_Supports_Support_Details),
	)
	b := main_defense_combat_value_builder()
	b = main_defense_combat_value_main_defense_combat_value_builder_game_sequence(b, self.game_sequence)
	b = main_defense_combat_value_main_defense_combat_value_builder_game_dice_sides(b, self.game_dice_sides)
	b = main_defense_combat_value_main_defense_combat_value_builder_lhtr_heavy_bombers(b, self.lhtr_heavy_bombers)
	b = main_defense_combat_value_main_defense_combat_value_builder_roll_support_from_friends(b, empty_roll_friends)
	b = main_defense_combat_value_main_defense_combat_value_builder_roll_support_from_enemies(b, empty_roll_enemies)
	b = main_defense_combat_value_main_defense_combat_value_builder_strength_support_from_friends(b, empty_strength_friends)
	b = main_defense_combat_value_main_defense_combat_value_builder_strength_support_from_enemies(b, empty_strength_enemies)
	b = main_defense_combat_value_main_defense_combat_value_builder_friend_units(b, make([dynamic]^Unit))
	b = main_defense_combat_value_main_defense_combat_value_builder_enemy_units(b, make([dynamic]^Unit))
	b = main_defense_combat_value_main_defense_combat_value_builder_territory_effects(b, self.territory_effects)
	return main_defense_combat_value_main_defense_combat_value_builder_build(b)
}

// Ported from MainDefenseCombatValue#buildOppositeCombatValue().
// Returns the offensive counterpart with friend/enemy support and unit
// collections swapped. Territory effects, dice sides, sequence, and
// LHTR-heavy-bombers flag are preserved.
main_defense_combat_value_build_opposite_combat_value :: proc(self: ^Main_Defense_Combat_Value) -> ^Main_Offense_Combat_Value {
	b := main_offense_combat_value_builder()
	b = main_offense_combat_value_main_offense_combat_value_builder_game_sequence(b, self.game_sequence)
	b = main_offense_combat_value_main_offense_combat_value_builder_game_dice_sides(b, self.game_dice_sides)
	b = main_offense_combat_value_main_offense_combat_value_builder_lhtr_heavy_bombers(b, self.lhtr_heavy_bombers)
	b = main_offense_combat_value_main_offense_combat_value_builder_roll_support_from_friends(b, self.roll_support_from_enemies)
	b = main_offense_combat_value_main_offense_combat_value_builder_roll_support_from_enemies(b, self.roll_support_from_friends)
	b = main_offense_combat_value_main_offense_combat_value_builder_strength_support_from_friends(b, self.strength_support_from_enemies)
	b = main_offense_combat_value_main_offense_combat_value_builder_strength_support_from_enemies(b, self.strength_support_from_friends)
	b = main_offense_combat_value_main_offense_combat_value_builder_friend_units(b, self.enemy_units)
	b = main_offense_combat_value_main_offense_combat_value_builder_enemy_units(b, self.friend_units)
	b = main_offense_combat_value_main_offense_combat_value_builder_territory_effects(b, self.territory_effects)
	return main_offense_combat_value_main_offense_combat_value_builder_build(b)
}

// Ported from MainDefenseCombatValue#chooseBestRoll(Unit).
// Returns true if LHTR heavy bombers is enabled or if the unit's attachment
// has chooseBestRoll set.
main_defense_combat_value_choose_best_roll :: proc(self: ^Main_Defense_Combat_Value, unit: ^Unit) -> bool {
	return self.lhtr_heavy_bombers || unit_attachment_get_choose_best_roll(unit_get_unit_attachment(unit))
}

// Java: public RollCalculator getRoll() {
//   return new MainDefenseRoll(rollSupportFromFriends.copy(), rollSupportFromEnemies.copy());
// }
main_defense_combat_value_get_roll :: proc(
	self: ^Main_Defense_Combat_Value,
) -> ^Main_Defense_Combat_Value_Main_Defense_Roll {
	return main_defense_combat_value_main_defense_roll_new(
		available_supports_copy(self.roll_support_from_friends),
		available_supports_copy(self.roll_support_from_enemies),
	)
}

// Java: public StrengthCalculator getStrength() {
//   return new MainDefenseStrength(
//       gameSequence, gameDiceSides, territoryEffects,
//       strengthSupportFromFriends.copy(), strengthSupportFromEnemies.copy());
// }
main_defense_combat_value_get_strength :: proc(
	self: ^Main_Defense_Combat_Value,
) -> ^Main_Defense_Combat_Value_Main_Defense_Strength {
	return main_defense_combat_value_main_defense_strength_new(
		self.game_sequence,
		self.game_dice_sides,
		self.territory_effects,
		available_supports_copy(self.strength_support_from_friends),
		available_supports_copy(self.strength_support_from_enemies),
	)
}

// ============================================================
// Combat_Value / Strength_Calculator / Roll_Calculator adapters
// (Odin-only vtable glue — no Java equivalent)
// ============================================================

@(private="file")
mdcv_get_strength_ :: proc(cv: ^Combat_Value) -> ^Strength_Calculator {
        impl := cast(^Main_Defense_Combat_Value)cv.concrete
        return main_defense_combat_value_main_defense_strength_to_strength_calculator(
                main_defense_combat_value_get_strength(impl),
        )
}

@(private="file")
mdcv_get_roll_ :: proc(cv: ^Combat_Value) -> ^Roll_Calculator {
        impl := cast(^Main_Defense_Combat_Value)cv.concrete
        return main_defense_combat_value_main_defense_roll_to_roll_calculator(
                main_defense_combat_value_get_roll(impl),
        )
}

@(private="file")
mdcv_choose_best_roll_ :: proc(cv: ^Combat_Value, unit: ^Unit) -> bool {
        impl := cast(^Main_Defense_Combat_Value)cv.concrete
        return main_defense_combat_value_choose_best_roll(impl, unit)
}

@(private="file")
mdcv_get_dice_sides_ :: proc(cv: ^Combat_Value, unit: ^Unit) -> i32 {
        impl := cast(^Main_Defense_Combat_Value)cv.concrete
        return main_defense_combat_value_get_dice_sides(impl, unit)
}

@(private="file")
mdcv_get_battle_side_ :: proc(cv: ^Combat_Value) -> Battle_State_Side {
        impl := cast(^Main_Defense_Combat_Value)cv.concrete
        return main_defense_combat_value_get_battle_side(impl)
}

@(private="file")
mdcv_get_friend_units_ :: proc(cv: ^Combat_Value) -> [dynamic]^Unit {
        impl := cast(^Main_Defense_Combat_Value)cv.concrete
        return impl.friend_units
}

@(private="file")
mdcv_get_enemy_units_ :: proc(cv: ^Combat_Value) -> [dynamic]^Unit {
        impl := cast(^Main_Defense_Combat_Value)cv.concrete
        return impl.enemy_units
}

@(private="file")
mdcv_build_with_no_unit_supports_ :: proc(cv: ^Combat_Value) -> ^Combat_Value {
        impl := cast(^Main_Defense_Combat_Value)cv.concrete
        return main_defense_combat_value_to_combat_value(
                main_defense_combat_value_build_with_no_unit_supports(impl),
        )
}

@(private="file")
mdcv_build_opposite_combat_value_ :: proc(cv: ^Combat_Value) -> ^Combat_Value {
        impl := cast(^Main_Defense_Combat_Value)cv.concrete
        return main_offense_combat_value_to_combat_value(
                main_defense_combat_value_build_opposite_combat_value(impl),
        )
}

main_defense_combat_value_to_combat_value :: proc(self: ^Main_Defense_Combat_Value) -> ^Combat_Value {
        cv := new(Combat_Value)
        cv.concrete                    = self
        cv.get_strength                = mdcv_get_strength_
        cv.get_roll                    = mdcv_get_roll_
        cv.choose_best_roll            = mdcv_choose_best_roll_
        cv.get_dice_sides              = mdcv_get_dice_sides_
        cv.get_battle_side             = mdcv_get_battle_side_
        cv.get_friend_units            = mdcv_get_friend_units_
        cv.get_enemy_units             = mdcv_get_enemy_units_
        cv.build_with_no_unit_supports = mdcv_build_with_no_unit_supports_
        cv.build_opposite_combat_value = mdcv_build_opposite_combat_value_
        return cv
}

@(private="file")
mds_get_strength_ :: proc(sc: ^Strength_Calculator, unit: ^Unit) -> ^Strength_Value {
        impl := cast(^Main_Defense_Combat_Value_Main_Defense_Strength)sc.concrete
        return main_defense_combat_value_main_defense_strength_get_strength(impl, unit)
}

@(private="file")
mds_get_support_given_ :: proc(sc: ^Strength_Calculator) -> map[^Unit]^Integer_Map {
        impl := cast(^Main_Defense_Combat_Value_Main_Defense_Strength)sc.concrete
        return main_defense_combat_value_main_defense_strength_get_support_given(impl)
}

main_defense_combat_value_main_defense_strength_to_strength_calculator :: proc(self: ^Main_Defense_Combat_Value_Main_Defense_Strength) -> ^Strength_Calculator {
        sc := new(Strength_Calculator)
        sc.concrete          = self
        sc.get_strength      = mds_get_strength_
        sc.get_support_given = mds_get_support_given_
        return sc
}

@(private="file")
mdr_get_roll_ :: proc(rc: ^Roll_Calculator, unit: ^Unit) -> ^Roll_Value {
        impl := cast(^Main_Defense_Combat_Value_Main_Defense_Roll)rc.concrete
        return main_defense_combat_value_main_defense_roll_get_roll(impl, unit)
}

@(private="file")
mdr_get_support_given_ :: proc(rc: ^Roll_Calculator) -> map[^Unit]^Integer_Map {
        impl := cast(^Main_Defense_Combat_Value_Main_Defense_Roll)rc.concrete
        return main_defense_combat_value_main_defense_roll_get_support_given(impl)
}

main_defense_combat_value_main_defense_roll_to_roll_calculator :: proc(self: ^Main_Defense_Combat_Value_Main_Defense_Roll) -> ^Roll_Calculator {
        rc := new(Roll_Calculator)
        rc.concrete          = self
        rc.get_roll          = mdr_get_roll_
        rc.get_support_given = mdr_get_support_given_
        return rc
}
