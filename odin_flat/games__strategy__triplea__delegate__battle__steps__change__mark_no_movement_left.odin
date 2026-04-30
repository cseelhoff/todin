package game

Mark_No_Movement_Left :: struct {
	using battle_step: Battle_Step,
	battle_state:   ^Battle_State,
	battle_actions: ^Battle_Actions,
}

mark_no_movement_left_new :: proc(battle_state: ^Battle_State, battle_actions: ^Battle_Actions) -> ^Mark_No_Movement_Left {
	self := new(Mark_No_Movement_Left)
	self.battle_state = battle_state
	self.battle_actions = battle_actions
	return self
}

mark_no_movement_left_get_all_step_details :: proc(self: ^Mark_No_Movement_Left) -> [dynamic]^Battle_Step_Step_Details {
	return make([dynamic]^Battle_Step_Step_Details)
}

mark_no_movement_left_get_order :: proc(self: ^Mark_No_Movement_Left) -> Battle_Step_Order {
	return .MARK_NO_MOVEMENT_LEFT
}

