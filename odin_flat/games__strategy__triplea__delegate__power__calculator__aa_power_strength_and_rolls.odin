package game

import "core:slice"

Aa_Power_Strength_And_Rolls :: struct {
	best_strength:                          int,
	dice_sides:                             int,
	calculator:                             ^Combat_Value,
	total_strength_and_total_rolls_by_unit: map[^Unit]Unit_Power_Strength_And_Rolls,
	target_count:                           int,
	active_strength_and_rolls:              [dynamic]Unit_Power_Strength_And_Rolls,
}

aa_power_strength_and_rolls_get_active_units :: proc(
	self: ^Aa_Power_Strength_And_Rolls,
) -> [dynamic]Unit_Power_Strength_And_Rolls {
	return self.active_strength_and_rolls
}

aa_power_strength_and_rolls_calculate_total_power :: proc(
	self: ^Aa_Power_Strength_And_Rolls,
) -> i32 {
	sum: i32 = 0
	for entry in self.active_strength_and_rolls {
		sum += entry.power
	}
	return sum
}

aa_power_strength_and_rolls_calculate_total_rolls :: proc(
	self: ^Aa_Power_Strength_And_Rolls,
) -> i32 {
	sum: i32 = 0
	for entry in self.active_strength_and_rolls {
		if entry.strength_and_rolls != nil {
			sum += entry.strength_and_rolls.rolls
		}
	}
	return sum
}

aa_power_strength_and_rolls_get_best_strength :: proc(
	self: ^Aa_Power_Strength_And_Rolls,
) -> i32 {
	return i32(self.best_strength)
}

aa_power_strength_and_rolls_get_dice_sides :: proc(
	self: ^Aa_Power_Strength_And_Rolls,
) -> i32 {
	return i32(self.dice_sides)
}

aa_power_strength_and_rolls_is_same_strength :: proc(
	self: ^Aa_Power_Strength_And_Rolls,
) -> bool {
	seen: map[i32]struct {}
	defer delete(seen)
	for entry in self.active_strength_and_rolls {
		s: i32 = 0
		if entry.strength_and_rolls != nil {
			s = entry.strength_and_rolls.strength
		}
		seen[s] = {}
	}
	return len(seen) == 1
}

// Java synthetic lambda from calculateActiveStrengthAndRolls (filter for the
// best-infinite search): `unit -> calculator.getDiceSides(unit) == diceSides`.
// Each unit's dice sides were cached into `total_strength_and_total_rolls_by_unit`
// at construction (via `addUnits`, using `calculator.getDiceSides(unit)`), so the
// per-unit cached value equals what the lambda would compute on the calculator.
aa_power_strength_and_rolls_lambda_calculate_active_strength_and_rolls_0 :: proc(
	self: ^Aa_Power_Strength_And_Rolls,
	unit: ^Unit,
) -> bool {
	entry := self.total_strength_and_total_rolls_by_unit[unit]
	return int(entry.dice_sides) == self.dice_sides
}

// Java synthetic lambda from calculateActiveStrengthAndRolls
// (key extractor for `Comparator.comparingInt`):
// `unit -> totalStrengthAndTotalRollsByUnit.get(unit).getStrength()`.
aa_power_strength_and_rolls_lambda_calculate_active_strength_and_rolls_1 :: proc(
	self: ^Aa_Power_Strength_And_Rolls,
	unit: ^Unit,
) -> i32 {
	entry := self.total_strength_and_total_rolls_by_unit[unit]
	if entry.strength_and_rolls != nil {
		return entry.strength_and_rolls.strength
	}
	return 0
}

// Java synthetic lambda from calculateActiveStrengthAndRolls
// (mapper for `Optional.map` extracting the best infinite unit's strength):
// `unit -> totalStrengthAndTotalRollsByUnit.get(unit).getStrength()`.
aa_power_strength_and_rolls_lambda_calculate_active_strength_and_rolls_2 :: proc(
	self: ^Aa_Power_Strength_And_Rolls,
	unit: ^Unit,
) -> i32 {
	entry := self.total_strength_and_total_rolls_by_unit[unit]
	if entry.strength_and_rolls != nil {
		return entry.strength_and_rolls.strength
	}
	return 0
}

// Java: AaPowerStrengthAndRolls#addUnits(Collection<Unit>) — populates
// `totalStrengthAndTotalRollsByUnit` with a UnitPowerStrengthAndRolls entry per
// unit, computed via the calculator's strength/roll/power calculators.
aa_power_strength_and_rolls_add_units :: proc(
	self: ^Aa_Power_Strength_And_Rolls,
	units: [dynamic]^Unit,
) {
	if self.total_strength_and_total_rolls_by_unit == nil {
		self.total_strength_and_total_rolls_by_unit = make(
			map[^Unit]Unit_Power_Strength_And_Rolls,
		)
	}
	strength_calculator := combat_value_get_strength(self.calculator)
	roll_calculator := combat_value_get_roll(self.calculator)
	power_calculator := combat_value_get_power(self.calculator)
	for unit in units {
		b := unit_power_strength_and_rolls_builder()
		b = unit_power_strength_and_rolls_unit_power_strength_and_rolls_builder_unit(b, unit)
		sar := strength_and_rolls_new(
			strength_calculator_get_strength(strength_calculator, unit),
			roll_calculator_get_roll(roll_calculator, unit),
		)
		b =
			unit_power_strength_and_rolls_unit_power_strength_and_rolls_builder_strength_and_rolls(
				b,
				sar,
			)
		b = unit_power_strength_and_rolls_unit_power_strength_and_rolls_builder_power(
			b,
			power_calculator_get_value_unit(power_calculator, unit),
		)
		b = unit_power_strength_and_rolls_unit_power_strength_and_rolls_builder_power_calculator(
			b,
			power_calculator,
		)
		b = unit_power_strength_and_rolls_unit_power_strength_and_rolls_builder_dice_sides(
			b,
			combat_value_get_dice_sides(self.calculator, unit),
		)
		b = unit_power_strength_and_rolls_unit_power_strength_and_rolls_builder_choose_best_roll(
			b,
			combat_value_choose_best_roll(self.calculator, unit),
		)
		built := unit_power_strength_and_rolls_unit_power_strength_and_rolls_builder_build(b)
		self.total_strength_and_total_rolls_by_unit[unit] = built^
	}
}

// File-private slot used to bridge the dynamic comparator produced by
// `combat_value_unit_comparator` (which itself relies on a globally-stashed
// ctx) into `slice.sort_by`, which requires a non-capturing `proc(a,b) -> bool`.
@(private = "file")
aa_power_strength_and_rolls_active_cmp_: proc(^Unit, ^Unit) -> i32

@(private = "file")
aa_power_strength_and_rolls_active_less_ :: proc(a: ^Unit, b: ^Unit) -> bool {
	return aa_power_strength_and_rolls_active_cmp_(a, b) < 0
}

@(private = "file")
aa_power_strength_and_rolls_units_contains_ :: proc(units: ^[dynamic]^Unit, u: ^Unit) -> bool {
	for x in units {
		if x == u {
			return true
		}
	}
	return false
}

// Java synthetic lambda from calculateActiveStrengthAndRolls
// (the body of `bestInfiniteUnit.ifPresent(unit -> { ... })`):
//   captures `targetCount - totalBasicRollsFinal`, `infinitePowerStrengthAndRolls`,
//   `activeUnits`. Records the infinite unit's updated rolls into the per-unit
//   map, appends the updated entry to the local infinite list, and adds the
//   unit to the running active-units collection.
aa_power_strength_and_rolls_lambda_calculate_active_strength_and_rolls_3 :: proc(
	self: ^Aa_Power_Strength_And_Rolls,
	remaining_targets: i32,
	infinite_power_strength_and_rolls: ^[dynamic]Unit_Power_Strength_And_Rolls,
	active_units: ^[dynamic]^Unit,
	unit: ^Unit,
) {
	original := self.total_strength_and_total_rolls_by_unit[unit]
	infinite_unit_data := unit_power_strength_and_rolls_update_rolls(&original, remaining_targets)
	append(infinite_power_strength_and_rolls, infinite_unit_data^)
	self.total_strength_and_total_rolls_by_unit[unit] = infinite_unit_data^
	append(active_units, unit)
}

// Java: AaPowerStrengthAndRolls#calculateActiveStrengthAndRolls()
// Determines which AA units actually roll, applies the per-group ordering
// (basic non-infinite stronger than the best infinite first, capped by
// targetCount; then the best infinite to fill remaining targets; then any
// overstack units appended afterwards) and zeroes every unit not selected.
aa_power_strength_and_rolls_calculate_active_strength_and_rolls :: proc(
	self: ^Aa_Power_Strength_And_Rolls,
) -> [dynamic]Unit_Power_Strength_And_Rolls {
	// Make sure the higher powers fire first
	aa_to_roll: [dynamic]^Unit
	for unit, _ in self.total_strength_and_total_rolls_by_unit {
		append(&aa_to_roll, unit)
	}
	cmp := combat_value_unit_comparator(self.calculator)
	aa_power_strength_and_rolls_active_cmp_ = cmp
	slice.sort_by(aa_to_roll[:], aa_power_strength_and_rolls_active_less_)

	// Setup all 3 groups of aa guns
	basic_aa: [dynamic]^Unit
	for u in aa_to_roll {
		append(&basic_aa, u)
	}

	infinite_pred, infinite_ctx := matches_unit_max_aa_attacks_is_infinite()
	overstack_pred, overstack_ctx := matches_unit_may_over_stack_aa()

	infinite_aa: [dynamic]^Unit
	for u in aa_to_roll {
		if infinite_pred(infinite_ctx, u) {
			append(&infinite_aa, u)
		}
	}
	overstack_aa: [dynamic]^Unit
	for u in aa_to_roll {
		if overstack_pred(overstack_ctx, u) {
			append(&overstack_aa, u)
		}
	}

	// overstackAa.removeAll(infiniteAa)
	{
		filtered: [dynamic]^Unit
		for u in overstack_aa {
			if !aa_power_strength_and_rolls_units_contains_(&infinite_aa, u) {
				append(&filtered, u)
			}
		}
		delete(overstack_aa)
		overstack_aa = filtered
	}
	// basicAa.removeAll(infiniteAa)
	{
		filtered: [dynamic]^Unit
		for u in basic_aa {
			if !aa_power_strength_and_rolls_units_contains_(&infinite_aa, u) {
				append(&filtered, u)
			}
		}
		delete(basic_aa)
		basic_aa = filtered
	}
	// basicAa.removeAll(overstackAa)
	{
		filtered: [dynamic]^Unit
		for u in basic_aa {
			if !aa_power_strength_and_rolls_units_contains_(&overstack_aa, u) {
				append(&filtered, u)
			}
		}
		delete(basic_aa)
		basic_aa = filtered
	}

	// Determine highest strength for infinite group, restricted to AA whose
	// dice sides match the chosen `dice_sides`.
	have_best := false
	best_infinite: ^Unit = nil
	best_infinite_strength: i32 = 0
	for u in infinite_aa {
		if !aa_power_strength_and_rolls_lambda_calculate_active_strength_and_rolls_0(self, u) {
			continue
		}
		s := aa_power_strength_and_rolls_lambda_calculate_active_strength_and_rolls_1(self, u)
		if !have_best || s > best_infinite_strength {
			have_best = true
			best_infinite_strength = s
			best_infinite = u
		}
	}

	strength_of_best_infinite_unit: i32 = 0
	if have_best {
		strength_of_best_infinite_unit =
			aa_power_strength_and_rolls_lambda_calculate_active_strength_and_rolls_2(
				self,
				best_infinite,
			)
	}

	active_strength_and_rolls: [dynamic]Unit_Power_Strength_And_Rolls
	// keep track of the units that will roll so we can set all the others to 0 roll/strength
	active_units: [dynamic]^Unit

	// Add the non infinite units that are stronger than the infinite units.
	// If there are more non infinite rolls than targets, then ensure that the
	// last unit only fires enough to hit the remaining targets.
	total_basic_rolls: i32 = 0
	target_count_i32 := i32(self.target_count)
	for unit in basic_aa {
		original_unit_data := self.total_strength_and_total_rolls_by_unit[unit]
		original_strength: i32 = 0
		if original_unit_data.strength_and_rolls != nil {
			original_strength = original_unit_data.strength_and_rolls.strength
		}
		if original_strength <= strength_of_best_infinite_unit {
			continue
		}
		append(&active_units, unit)
		roll: i32 = 0
		if original_unit_data.strength_and_rolls != nil {
			roll = original_unit_data.strength_and_rolls.rolls
		}
		if total_basic_rolls + roll >= target_count_i32 {
			weakest_basic_aa_rolls := target_count_i32 - total_basic_rolls
			total_basic_rolls += weakest_basic_aa_rolls
			weakest_basic_unit_data := unit_power_strength_and_rolls_update_rolls(
				&original_unit_data,
				weakest_basic_aa_rolls,
			)
			append(&active_strength_and_rolls, weakest_basic_unit_data^)
			// update the weakest rolling basic unit with the actual number of rolls it has
			self.total_strength_and_total_rolls_by_unit[unit] = weakest_basic_unit_data^
			break
		}
		append(
			&active_strength_and_rolls,
			self.total_strength_and_total_rolls_by_unit[unit],
		)
		total_basic_rolls += roll
	}

	// Add infinite AA if there are targets left for it
	total_basic_rolls_final := total_basic_rolls
	if target_count_i32 - total_basic_rolls_final > 0 {
		infinite_power_strength_and_rolls: [dynamic]Unit_Power_Strength_And_Rolls
		if have_best {
			aa_power_strength_and_rolls_lambda_calculate_active_strength_and_rolls_3(
				self,
				target_count_i32 - total_basic_rolls_final,
				&infinite_power_strength_and_rolls,
				&active_units,
				best_infinite,
			)
		}
		for entry in infinite_power_strength_and_rolls {
			append(&active_strength_and_rolls, entry)
		}
		delete(infinite_power_strength_and_rolls)
	}

	// Add all the overstack units
	for u in overstack_aa {
		append(&active_units, u)
	}
	for u in overstack_aa {
		append(
			&active_strength_and_rolls,
			self.total_strength_and_total_rolls_by_unit[u],
		)
	}

	// mark all of the non-active units with 0 rolls/strength
	keys: [dynamic]^Unit
	for k, _ in self.total_strength_and_total_rolls_by_unit {
		append(&keys, k)
	}
	for k in keys {
		if aa_power_strength_and_rolls_units_contains_(&active_units, k) {
			continue
		}
		current := self.total_strength_and_total_rolls_by_unit[k]
		zeroed := unit_power_strength_and_rolls_to_zero(&current)
		self.total_strength_and_total_rolls_by_unit[k] = zeroed^
	}
	delete(keys)

	delete(aa_to_roll)
	delete(basic_aa)
	delete(infinite_aa)
	delete(overstack_aa)
	delete(active_units)

	return active_strength_and_rolls
}
