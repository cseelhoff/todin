package game

// Java: games.strategy.triplea.delegate.power.calculator.CombatValue (interface)
// Modelled as a vtable struct with proc-typed fields. Each implementer (e.g.
// Bombardment_Combat_Value) builds a Combat_Value adapter via its
// `<impl>_to_combat_value` proc that points `concrete` at the impl and wires
// the dispatch fields. The default-method procs below (getPower, unitComparator)
// dispatch through these fields.

Combat_Value :: struct {
        concrete:                    rawptr,
        get_strength:                proc(self: ^Combat_Value) -> ^Strength_Calculator,
        get_roll:                    proc(self: ^Combat_Value) -> ^Roll_Calculator,
        choose_best_roll:            proc(self: ^Combat_Value, unit: ^Unit) -> bool,
        get_dice_sides:              proc(self: ^Combat_Value, unit: ^Unit) -> i32,
        get_battle_side:             proc(self: ^Combat_Value) -> Battle_State_Side,
        get_friend_units:            proc(self: ^Combat_Value) -> [dynamic]^Unit,
        get_enemy_units:             proc(self: ^Combat_Value) -> [dynamic]^Unit,
        build_with_no_unit_supports: proc(self: ^Combat_Value) -> ^Combat_Value,
        build_opposite_combat_value: proc(self: ^Combat_Value) -> ^Combat_Value,
}

combat_value_get_strength :: proc(self: ^Combat_Value) -> ^Strength_Calculator {
        return self.get_strength(self)
}

combat_value_get_roll :: proc(self: ^Combat_Value) -> ^Roll_Calculator {
        return self.get_roll(self)
}

combat_value_choose_best_roll :: proc(self: ^Combat_Value, unit: ^Unit) -> bool {
        return self.choose_best_roll(self, unit)
}

combat_value_get_dice_sides :: proc(self: ^Combat_Value, unit: ^Unit) -> i32 {
        return self.get_dice_sides(self, unit)
}

combat_value_get_battle_side :: proc(self: ^Combat_Value) -> Battle_State_Side {
        return self.get_battle_side(self)
}

combat_value_get_friend_units :: proc(self: ^Combat_Value) -> [dynamic]^Unit {
        return self.get_friend_units(self)
}

combat_value_get_enemy_units :: proc(self: ^Combat_Value) -> [dynamic]^Unit {
        return self.get_enemy_units(self)
}

combat_value_build_with_no_unit_supports :: proc(self: ^Combat_Value) -> ^Combat_Value {
        return self.build_with_no_unit_supports(self)
}

combat_value_build_opposite_combat_value :: proc(self: ^Combat_Value) -> ^Combat_Value {
        return self.build_opposite_combat_value(self)
}

// default Comparator<Unit> unitComparator() default-method context shared with the
// returned comparator closure. Holds the captured strength_calculator + dice-side
// dispatch so the comparator can be a plain `proc(a, b: ^Unit) -> int` value.
Combat_Value_Unit_Comparator_Ctx :: struct {
        strength_calculator: ^Strength_Calculator,
        cache:               map[^Unit]i32,
        owner:               ^Combat_Value,
}

// default PowerCalculator getPower() {
//   return new PowerCalculator(getStrength(), getRoll(), this::chooseBestRoll, this::getDiceSides);
// }
combat_value_get_power :: proc(self: ^Combat_Value) -> ^Power_Calculator {
        // PowerCalculator's choose_best_roll / get_dice_sides take only `unit`
        // (no self). Wrap the dispatch via small forwarder closures via context
        // pointers — but Odin proc literals aren't true closures, so we forward
        // through globals indexed by the Combat_Value pointer.
        combat_value_register_dispatch_(self)
        return power_calculator_new(
                self.get_strength(self),
                self.get_roll(self),
                combat_value_choose_best_roll_thunk_,
                combat_value_get_dice_sides_thunk_,
        )
}

// Goofy-but-correct: PowerCalculator stores `proc(unit) -> bool/i32` (no self).
// Java captures `this` via method references; in Odin we keep a tiny package-
// private slot pointing at the most-recently-registered Combat_Value. Single-
// threaded snapshot harness, so this is safe.
@(private="file")
combat_value_active_dispatch_: ^Combat_Value

@(private="file")
combat_value_register_dispatch_ :: proc(self: ^Combat_Value) {
        combat_value_active_dispatch_ = self
}

@(private="file")
combat_value_choose_best_roll_thunk_ :: proc(unit: ^Unit) -> bool {
        cv := combat_value_active_dispatch_
        return cv.choose_best_roll(cv, unit)
}

@(private="file")
combat_value_get_dice_sides_thunk_ :: proc(unit: ^Unit) -> i32 {
        cv := combat_value_active_dispatch_
        return cv.get_dice_sides(cv, unit)
}

// default Comparator<Unit> unitComparator()
combat_value_unit_comparator :: proc(self: ^Combat_Value) -> proc(^Unit, ^Unit) -> i32 {
        // unit support is stateful which would mess up the sort calculations so
        // remove unit supports
        no_supports := self.build_with_no_unit_supports(self)
        sc := no_supports.get_strength(no_supports)

        ctx := new(Combat_Value_Unit_Comparator_Ctx)
        ctx.strength_calculator = sc
        ctx.cache = make(map[^Unit]i32)
        ctx.owner = self
        combat_value_unit_comparator_active_ctx_ = ctx
        return combat_value_unit_comparator_thunk_
}

@(private="file")
combat_value_unit_comparator_active_ctx_: ^Combat_Value_Unit_Comparator_Ctx

@(private="file")
combat_value_unit_comparator_strength_for_ :: proc(
        ctx: ^Combat_Value_Unit_Comparator_Ctx,
        unit: ^Unit,
) -> i32 {
        if v, ok := ctx.cache[unit]; ok {
                return v
        }
        sv := ctx.strength_calculator.get_strength(ctx.strength_calculator, unit)
        v := strength_value_get_value(sv)
        ctx.cache[unit] = v
        return v
}

@(private="file")
combat_value_unit_comparator_thunk_ :: proc(a: ^Unit, b: ^Unit) -> i32 {
        ctx := combat_value_unit_comparator_active_ctx_

        // First key: (strength == 0) ascending — false (0) before true (1)
        // means non-zero-strength units come first.
        a_zero := combat_value_unit_comparator_strength_for_(ctx, a) == 0
        b_zero := combat_value_unit_comparator_strength_for_(ctx, b) == 0
        if a_zero != b_zero {
                if !a_zero { return -1 }
                return 1
        }

        // Second key: -strength / diceSides ascending (i.e. higher
        // strength/diceSides ratio first).
        owner := ctx.owner
        a_str := f64(combat_value_unit_comparator_strength_for_(ctx, a))
        b_str := f64(combat_value_unit_comparator_strength_for_(ctx, b))
        a_sides := f64(owner.get_dice_sides(owner, a))
        b_sides := f64(owner.get_dice_sides(owner, b))
        a_key := -a_str / a_sides
        b_key := -b_str / b_sides
        if a_key < b_key { return -1 }
        if a_key > b_key { return 1 }
        return 0
}

// lambda$unitComparator$0 — `unit -> cache.computeIfAbsent(unit, getStrength) == 0`
// where getStrength = u -> strengthCalculator.getStrength(u).getValue()
combat_value_lambda_unit_comparator_0 :: proc(
        strength_calculator: ^Strength_Calculator,
        unit: ^Unit,
) -> bool {
        sv := strength_calculator.get_strength(strength_calculator, unit)
        return strength_value_get_value(sv) == 0
}

// lambda$unitComparator$1 — pre-existing helper, kept intact.
combat_value_lambda_unit_comparator_1 :: proc(
        cache: ^map[rawptr]int,
        get_strength: proc(rawptr) -> int,
        unit: rawptr,
) -> bool {
        val, ok := cache[unit]
        if !ok {
                val = get_strength(unit)
                cache[unit] = val
        }
        return val == 0
}

// lambda$unitComparator$2 — `unit -> -cache.computeIfAbsent(unit, getStrength) / (float) getDiceSides(unit)`
// Captures: the per-call HashMap cache, the getStrength Function, and `this`
// (for getDiceSides). Returns Java `double` which we model as f64.
combat_value_lambda_unit_comparator_2 :: proc(
        cache: ^map[^Unit]i32,
        get_strength: proc(unit: ^Unit) -> i32,
        owner: ^Combat_Value,
        unit: ^Unit,
) -> f64 {
        v, ok := cache[unit]
        if !ok {
                v = get_strength(unit)
                cache[unit] = v
        }
        sides := owner.get_dice_sides(owner, unit)
        return -f64(v) / f64(sides)
}

