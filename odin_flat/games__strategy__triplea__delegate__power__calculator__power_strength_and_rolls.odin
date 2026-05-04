package game

// Port of games.strategy.triplea.delegate.power.calculator.PowerStrengthAndRolls.
// Computes total power, strength, and roll for a collection of units.
Power_Strength_And_Rolls :: struct {
	calculator:                             Combat_Value,
	dice_sides:                             i32,
	total_strength_and_total_rolls_by_unit: map[^Unit]Unit_Power_Strength_And_Rolls,
	sorted_strength_and_rolls:              [dynamic]Unit_Power_Strength_And_Rolls,
	unit_support_power_map:                 map[^Unit]Integer_Map,
	unit_support_rolls_map:                 map[^Unit]Integer_Map,
}

power_strength_and_rolls_get_active_units :: proc(
	self: ^Power_Strength_And_Rolls,
) -> [dynamic]Unit_Power_Strength_And_Rolls {
	return self.sorted_strength_and_rolls
}

power_strength_and_rolls_calculate_total_power :: proc(
	self: ^Power_Strength_And_Rolls,
) -> i32 {
	sum: i32 = 0
	for _, v in self.total_strength_and_total_rolls_by_unit {
		sum += v.power
	}
	return sum
}

power_strength_and_rolls_calculate_total_rolls :: proc(
	self: ^Power_Strength_And_Rolls,
) -> i32 {
	sum: i32 = 0
	for _, v in self.total_strength_and_total_rolls_by_unit {
		if v.strength_and_rolls != nil {
			sum += v.strength_and_rolls.rolls
		}
	}
	return sum
}

power_strength_and_rolls_get_total_strength_and_total_rolls_by_unit :: proc(
	self: ^Power_Strength_And_Rolls,
) -> map[^Unit]Unit_Power_Strength_And_Rolls {
	return self.total_strength_and_total_rolls_by_unit
}

power_strength_and_rolls_get_unit_support_power_map :: proc(
	self: ^Power_Strength_And_Rolls,
) -> map[^Unit]Integer_Map {
	return self.unit_support_power_map
}

power_strength_and_rolls_get_unit_support_rolls_map :: proc(
	self: ^Power_Strength_And_Rolls,
) -> map[^Unit]Integer_Map {
	return self.unit_support_rolls_map
}

power_strength_and_rolls_has_strength_or_rolls :: proc(
	self: ^Power_Strength_And_Rolls,
) -> bool {
	return power_strength_and_rolls_calculate_total_rolls(self) != 0 &&
		power_strength_and_rolls_calculate_total_power(self) != 0
}

// Lambda from addUnits: (newSupport) -> new IntegerMap<>() used by
// unitSupportPowerMap.computeIfAbsent.
power_strength_and_rolls_lambda_add_units_0 :: proc(new_support: ^Unit) -> Integer_Map {
	return Integer_Map{map_values = make(map[rawptr]i32)}
}

// Lambda from addUnits: (newSupport) -> new IntegerMap<>() used by
// unitSupportRollsMap.computeIfAbsent.
power_strength_and_rolls_lambda_add_units_2 :: proc(new_support: ^Unit) -> Integer_Map {
	return Integer_Map{map_values = make(map[rawptr]i32)}
}

// Lambda from addUnits: (supporter, supportedUnits) ->
//   unitSupportPowerMap.computeIfAbsent(supporter, $0).add(supportedUnits).
// Captures the enclosing Power_Strength_And_Rolls instance.
power_strength_and_rolls_lambda_add_units_1 :: proc(
	self: ^Power_Strength_And_Rolls,
	supporter: ^Unit,
	supported_units: ^Integer_Map,
) {
	if !(supporter in self.unit_support_power_map) {
		self.unit_support_power_map[supporter] =
			power_strength_and_rolls_lambda_add_units_0(supporter)
	}
	existing := self.unit_support_power_map[supporter]
	integer_map_add_map(&existing, supported_units)
}

// Lambda from addUnits: (supporter, supportedUnits) ->
//   unitSupportRollsMap.computeIfAbsent(supporter, $2).add(supportedUnits).
// Captures the enclosing Power_Strength_And_Rolls instance.
power_strength_and_rolls_lambda_add_units_3 :: proc(
	self: ^Power_Strength_And_Rolls,
	supporter: ^Unit,
	supported_units: ^Integer_Map,
) {
	if !(supporter in self.unit_support_rolls_map) {
		self.unit_support_rolls_map[supporter] =
			power_strength_and_rolls_lambda_add_units_2(supporter)
	}
	existing := self.unit_support_rolls_map[supporter]
	integer_map_add_map(&existing, supported_units)
}

// Java: private void addUnits(final Collection<Unit> units)
//   final StrengthCalculator strengthCalculator = calculator.getStrength();
//   final RollCalculator rollCalculator = calculator.getRoll();
//   final PowerCalculator powerCalculator = calculator.getPower();
//   for (final Unit unit : units) {
//     final UnitPowerStrengthAndRolls data = UnitPowerStrengthAndRolls.builder()
//         .unit(unit)
//         .strengthAndRolls(StrengthAndRolls.of(
//             strengthCalculator.getStrength(unit), rollCalculator.getRoll(unit)))
//         .power(powerCalculator.getValue(unit))
//         .powerCalculator(powerCalculator)
//         .diceSides(calculator.getDiceSides(unit))
//         .chooseBestRoll(calculator.chooseBestRoll(unit))
//         .build();
//     totalStrengthAndTotalRollsByUnit.put(unit, data);
//     sortedStrengthAndRolls.add(data);
//   }
//   strengthCalculator.getSupportGiven().forEach(...unitSupportPowerMap...);
//   rollCalculator.getSupportGiven().forEach(...unitSupportRollsMap...);
power_strength_and_rolls_add_units :: proc(
	self: ^Power_Strength_And_Rolls,
	units: [dynamic]^Unit,
) {
	strength_calculator := combat_value_get_strength(&self.calculator)
	roll_calculator := combat_value_get_roll(&self.calculator)
	power_calculator := combat_value_get_power(&self.calculator)
	for unit in units {
		b := unit_power_strength_and_rolls_builder()
		b = unit_power_strength_and_rolls_unit_power_strength_and_rolls_builder_unit(b, unit)
		b = unit_power_strength_and_rolls_unit_power_strength_and_rolls_builder_strength_and_rolls(
			b,
			strength_and_rolls_new(
				strength_calculator_get_strength(strength_calculator, unit),
				roll_calculator_get_roll(roll_calculator, unit),
			),
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
			combat_value_get_dice_sides(&self.calculator, unit),
		)
		b = unit_power_strength_and_rolls_unit_power_strength_and_rolls_builder_choose_best_roll(
			b,
			combat_value_choose_best_roll(&self.calculator, unit),
		)
		data := unit_power_strength_and_rolls_unit_power_strength_and_rolls_builder_build(b)
		self.total_strength_and_total_rolls_by_unit[unit] = data^
		append(&self.sorted_strength_and_rolls, data^)
	}

	for supporter, supported_units in strength_calculator_get_support_given(strength_calculator) {
		power_strength_and_rolls_lambda_add_units_1(self, supporter, supported_units)
	}
	for supporter, supported_units in roll_calculator_get_support_given(roll_calculator) {
		power_strength_and_rolls_lambda_add_units_3(self, supporter, supported_units)
	}
}

// Java: private PowerStrengthAndRolls(final Collection<Unit> units, final CombatValue calculator)
//   this.calculator = calculator;
//   this.diceSides = units.isEmpty() ? 0 : calculator.getDiceSides(CollectionUtils.getAny(units));
//   addUnits(units);
power_strength_and_rolls_new :: proc(
	units: [dynamic]^Unit,
	calculator: ^Combat_Value,
) -> ^Power_Strength_And_Rolls {
	self := new(Power_Strength_And_Rolls)
	self.calculator = calculator^
	self.total_strength_and_total_rolls_by_unit = make(map[^Unit]Unit_Power_Strength_And_Rolls)
	self.sorted_strength_and_rolls = make([dynamic]Unit_Power_Strength_And_Rolls)
	self.unit_support_power_map = make(map[^Unit]Integer_Map)
	self.unit_support_rolls_map = make(map[^Unit]Integer_Map)
	if len(units) == 0 {
		self.dice_sides = 0
	} else {
		self.dice_sides = combat_value_get_dice_sides(&self.calculator, units[0])
	}
	power_strength_and_rolls_add_units(self, units)
	return self
}
