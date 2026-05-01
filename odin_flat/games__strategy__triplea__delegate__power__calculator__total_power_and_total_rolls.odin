package game

// Java: games.strategy.triplea.delegate.power.calculator.TotalPowerAndTotalRolls (interface)

Total_Power_And_Total_Rolls :: struct {
	calculate_total_power: proc(self: ^Total_Power_And_Total_Rolls) -> i32,
	calculate_total_rolls: proc(self: ^Total_Power_And_Total_Rolls) -> i32,
	get_dice_sides:        proc(self: ^Total_Power_And_Total_Rolls) -> i32,
	get_active_units:      proc(self: ^Total_Power_And_Total_Rolls) -> [dynamic]Unit_Power_Strength_And_Rolls,
}

