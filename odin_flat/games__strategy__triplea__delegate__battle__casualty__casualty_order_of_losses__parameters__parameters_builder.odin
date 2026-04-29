package game

Casualty_Order_Of_Losses_Parameters_Parameters_Builder :: struct {
	targets_to_pick_from: [dynamic]^Unit,
	player:               ^Game_Player,
	combat_value:         ^Combat_Value,
	battlesite:           ^Territory,
	costs:                ^Integer_Map_Unit_Type,
	data:                 ^Game_State,
}
// Java owners covered by this file:
//   - games.strategy.triplea.delegate.battle.casualty.CasualtyOrderOfLosses$Parameters$ParametersBuilder

