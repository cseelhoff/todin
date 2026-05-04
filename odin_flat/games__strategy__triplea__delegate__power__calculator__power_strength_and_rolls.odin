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
