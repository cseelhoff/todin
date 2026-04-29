package game

Battle_Calculator :: struct {
	using i_battle_calculator: I_Battle_Calculator,
	game_data: ^Game_Data,
	tuv_calculator: ^Tuv_Costs_Calculator,
	keep_one_attacking_land_unit: bool,
	amphibious: bool,
	retreat_after_round: i32,
	retreat_after_x_units_left: i32,
	attacker_order_of_losses: string,
	defender_order_of_losses: string,
	cancelled: bool,
	is_running: bool,
}
// Java owners covered by this file:
//   - games.strategy.triplea.odds.calculator.BattleCalculator

