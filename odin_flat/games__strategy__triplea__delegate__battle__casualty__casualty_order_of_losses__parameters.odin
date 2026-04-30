package game

Casualty_Order_Of_Losses_Parameters :: struct {
	targets_to_pick_from: [dynamic]^Unit,
	player:               ^Game_Player,
	combat_value:         ^Combat_Value,
	battlesite:           ^Territory,
	costs:                ^Integer_Map_Unit_Type,
	data:                 ^Game_State,
}
// Java owners covered by this file:
//   - games.strategy.triplea.delegate.battle.casualty.CasualtyOrderOfLosses$Parameters

casualty_order_of_losses_parameters_new :: proc(
	targets_to_pick_from: [dynamic]^Unit,
	player: ^Game_Player,
	combat_value: ^Combat_Value,
	battlesite: ^Territory,
	costs: ^Integer_Map_Unit_Type,
	data: ^Game_State,
) -> ^Casualty_Order_Of_Losses_Parameters {
	self := new(Casualty_Order_Of_Losses_Parameters)
	self.targets_to_pick_from = targets_to_pick_from
	self.player = player
	self.combat_value = combat_value
	self.battlesite = battlesite
	self.costs = costs
	self.data = data
	return self
}

