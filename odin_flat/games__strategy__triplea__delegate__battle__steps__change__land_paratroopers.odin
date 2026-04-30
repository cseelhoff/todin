package game

Land_Paratroopers :: struct {
	using battle_step: Battle_Step,
	battle_state:   ^Battle_State,
	battle_actions: ^Battle_Actions,
}

land_paratroopers_new :: proc(battle_state: ^Battle_State, battle_actions: ^Battle_Actions) -> ^Land_Paratroopers {
	self := new(Land_Paratroopers)
	self.battle_state = battle_state
	self.battle_actions = battle_actions
	return self
}

land_paratroopers_get_order :: proc(self: ^Land_Paratroopers) -> Battle_Step_Order {
	return .LAND_PARATROOPERS
}
