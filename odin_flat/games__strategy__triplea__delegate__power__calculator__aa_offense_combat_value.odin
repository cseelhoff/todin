package game

Aa_Offense_Combat_Value :: struct {
	strength_support_from_friends: ^Available_Supports,
	strength_support_from_enemies: ^Available_Supports,
	roll_support_from_friends:     ^Available_Supports,
	roll_support_from_enemies:     ^Available_Supports,
	friend_units:                  [dynamic]^Unit,
	enemy_units:                   [dynamic]^Unit,
}

aa_offense_combat_value_default_friend_units :: proc() -> [dynamic]^Unit {
	return make([dynamic]^Unit)
}

aa_offense_combat_value_default_enemy_units :: proc() -> [dynamic]^Unit {
	return make([dynamic]^Unit)
}

aa_offense_combat_value_builder :: proc() -> ^Aa_Offense_Combat_Value_Aa_Offense_Combat_Value_Builder {
	return aa_offense_combat_value_aa_offense_combat_value_builder_new()
}

aa_offense_combat_value_new :: proc(
	strength_support_from_friends: ^Available_Supports,
	strength_support_from_enemies: ^Available_Supports,
	roll_support_from_friends: ^Available_Supports,
	roll_support_from_enemies: ^Available_Supports,
	friend_units: [dynamic]^Unit,
	enemy_units: [dynamic]^Unit,
) -> ^Aa_Offense_Combat_Value {
	self := new(Aa_Offense_Combat_Value)
	self.strength_support_from_friends = strength_support_from_friends
	self.strength_support_from_enemies = strength_support_from_enemies
	self.roll_support_from_friends = roll_support_from_friends
	self.roll_support_from_enemies = roll_support_from_enemies
	self.friend_units = friend_units
	self.enemy_units = enemy_units
	return self
}


// ============================================================
// Combat_Value / Strength_Calculator adapters for AA Offense
// (Underlying impl methods are largely unported; thunks return
// stub values where the impl proc does not yet exist.)
// ============================================================

@(private="file")
aocv_get_strength_ :: proc(cv: ^Combat_Value) -> ^Strength_Calculator {
        // aa_offense_combat_value_get_strength not yet ported — return nil.
        return nil
}

@(private="file")
aocv_get_roll_ :: proc(cv: ^Combat_Value) -> ^Roll_Calculator {
        // aa_offense_combat_value_get_roll not yet ported — return nil.
        return nil
}

@(private="file")
aocv_choose_best_roll_ :: proc(cv: ^Combat_Value, unit: ^Unit) -> bool {
        // Java: AaOffenseCombatValue#chooseBestRoll(unit) = false.
        return false
}

@(private="file")
aocv_get_dice_sides_ :: proc(cv: ^Combat_Value, unit: ^Unit) -> i32 {
        // Java: AaOffenseCombatValue#getDiceSides(unit) =
        //   unit.getUnitAttachment().getOffensiveAttackAaMaxDieSides() (per
        //   AA convention; mirror of AaDefense uses attackAaMaxDieSides).
        return unit_attachment_get_attack_aa_max_die_sides(unit_get_unit_attachment(unit))
}

@(private="file")
aocv_get_battle_side_ :: proc(cv: ^Combat_Value) -> Battle_State_Side {
        return .OFFENSE
}

@(private="file")
aocv_get_friend_units_ :: proc(cv: ^Combat_Value) -> [dynamic]^Unit {
        impl := cast(^Aa_Offense_Combat_Value)cv.concrete
        return impl.friend_units
}

@(private="file")
aocv_get_enemy_units_ :: proc(cv: ^Combat_Value) -> [dynamic]^Unit {
        impl := cast(^Aa_Offense_Combat_Value)cv.concrete
        return impl.enemy_units
}

@(private="file")
aocv_build_with_no_unit_supports_ :: proc(cv: ^Combat_Value) -> ^Combat_Value {
        // Not yet ported.
        return nil
}

@(private="file")
aocv_build_opposite_combat_value_ :: proc(cv: ^Combat_Value) -> ^Combat_Value {
        // Not yet ported.
        return nil
}

aa_offense_combat_value_to_combat_value :: proc(self: ^Aa_Offense_Combat_Value) -> ^Combat_Value {
        cv := new(Combat_Value)
        cv.concrete                    = self
        cv.get_strength                = aocv_get_strength_
        cv.get_roll                    = aocv_get_roll_
        cv.choose_best_roll            = aocv_choose_best_roll_
        cv.get_dice_sides              = aocv_get_dice_sides_
        cv.get_battle_side             = aocv_get_battle_side_
        cv.get_friend_units            = aocv_get_friend_units_
        cv.get_enemy_units             = aocv_get_enemy_units_
        cv.build_with_no_unit_supports = aocv_build_with_no_unit_supports_
        cv.build_opposite_combat_value = aocv_build_opposite_combat_value_
        return cv
}

@(private="file")
aos_get_strength_ :: proc(sc: ^Strength_Calculator, unit: ^Unit) -> ^Strength_Value {
        // Aa_Offense_Strength impl not yet ported — stub.
        return nil
}

@(private="file")
aos_get_support_given_ :: proc(sc: ^Strength_Calculator) -> map[^Unit]^Integer_Map {
        return make(map[^Unit]^Integer_Map)
}

aa_offense_strength_to_strength_calculator :: proc(self: ^Aa_Offense_Combat_Value_Aa_Offense_Strength) -> ^Strength_Calculator {
        sc := new(Strength_Calculator)
        sc.concrete          = self
        sc.get_strength      = aos_get_strength_
        sc.get_support_given = aos_get_support_given_
        return sc
}
