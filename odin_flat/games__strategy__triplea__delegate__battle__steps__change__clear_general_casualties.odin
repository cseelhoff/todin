package game

Clear_General_Casualties :: struct {
	using battle_step: Battle_Step,
	battle_state:   ^Battle_State,
	battle_actions: ^Battle_Actions,
}

clear_general_casualties_new :: proc(battle_state: ^Battle_State, battle_actions: ^Battle_Actions) -> ^Clear_General_Casualties {
	self := new(Clear_General_Casualties)
	self.battle_state = battle_state
	self.battle_actions = battle_actions
	return self
}

clear_general_casualties_get_order :: proc(self: ^Clear_General_Casualties) -> Battle_Step_Order {
	return .GENERAL_REMOVE_CASUALTIES
}
