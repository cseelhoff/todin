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

casualty_order_of_losses_parameters_parameters_builder_new :: proc() -> ^Casualty_Order_Of_Losses_Parameters_Parameters_Builder {
	self := new(Casualty_Order_Of_Losses_Parameters_Parameters_Builder)
	return self
}

casualty_order_of_losses_parameters_parameters_builder_targets_to_pick_from :: proc(
	self: ^Casualty_Order_Of_Losses_Parameters_Parameters_Builder,
	targets_to_pick_from: [dynamic]^Unit,
) -> ^Casualty_Order_Of_Losses_Parameters_Parameters_Builder {
	self.targets_to_pick_from = targets_to_pick_from
	return self
}

casualty_order_of_losses_parameters_parameters_builder_player :: proc(
	self: ^Casualty_Order_Of_Losses_Parameters_Parameters_Builder,
	player: ^Game_Player,
) -> ^Casualty_Order_Of_Losses_Parameters_Parameters_Builder {
	self.player = player
	return self
}

casualty_order_of_losses_parameters_parameters_builder_combat_value :: proc(
	self: ^Casualty_Order_Of_Losses_Parameters_Parameters_Builder,
	combat_value: ^Combat_Value,
) -> ^Casualty_Order_Of_Losses_Parameters_Parameters_Builder {
	self.combat_value = combat_value
	return self
}

casualty_order_of_losses_parameters_parameters_builder_battlesite :: proc(
	self: ^Casualty_Order_Of_Losses_Parameters_Parameters_Builder,
	battlesite: ^Territory,
) -> ^Casualty_Order_Of_Losses_Parameters_Parameters_Builder {
	self.battlesite = battlesite
	return self
}

casualty_order_of_losses_parameters_parameters_builder_costs :: proc(
	self: ^Casualty_Order_Of_Losses_Parameters_Parameters_Builder,
	costs: ^Integer_Map_Unit_Type,
) -> ^Casualty_Order_Of_Losses_Parameters_Parameters_Builder {
	self.costs = costs
	return self
}

casualty_order_of_losses_parameters_parameters_builder_data :: proc(
	self: ^Casualty_Order_Of_Losses_Parameters_Parameters_Builder,
	data: ^Game_State,
) -> ^Casualty_Order_Of_Losses_Parameters_Parameters_Builder {
	self.data = data
	return self
}

