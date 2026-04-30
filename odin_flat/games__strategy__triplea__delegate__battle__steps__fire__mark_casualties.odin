package game

Mark_Casualties :: struct {
	using battle_step: Battle_Step,
	battle_state:      ^Battle_State,
	battle_actions:    ^Battle_Actions,
	side:              Battle_State_Side,
	firing_group:      ^Firing_Group,
	fire_round_state:  ^Fire_Round_State,
	return_fire:       Must_Fight_Battle_Return_Fire,
}

mark_casualties_new :: proc(
	battle_state: ^Battle_State,
	battle_actions: ^Battle_Actions,
	side: Battle_State_Side,
	firing_group: ^Firing_Group,
	fire_round_state: ^Fire_Round_State,
	return_fire: Must_Fight_Battle_Return_Fire,
) -> ^Mark_Casualties {
	self := new(Mark_Casualties)
	self.battle_state = battle_state
	self.battle_actions = battle_actions
	self.side = side
	self.firing_group = firing_group
	self.fire_round_state = fire_round_state
	self.return_fire = return_fire
	return self
}

