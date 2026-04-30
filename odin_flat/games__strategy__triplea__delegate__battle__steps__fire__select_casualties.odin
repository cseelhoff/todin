package game

Select_Casualties :: struct {
	battle_state:     ^Battle_State,
	side:             Battle_State_Side,
	firing_group:     ^Firing_Group,
	fire_round_state: ^Fire_Round_State,
	select_casualties: proc(bridge: ^I_Delegate_Bridge, step: ^Select_Casualties) -> ^Casualty_Details,
}

select_casualties_new :: proc(
	battle_state: ^Battle_State,
	side: Battle_State_Side,
	firing_group: ^Firing_Group,
	fire_round_state: ^Fire_Round_State,
	select_casualties: proc(bridge: ^I_Delegate_Bridge, step: ^Select_Casualties) -> ^Casualty_Details,
) -> ^Select_Casualties {
	self := new(Select_Casualties)
	self.battle_state = battle_state
	self.side = side
	self.firing_group = firing_group
	self.fire_round_state = fire_round_state
	self.select_casualties = select_casualties
	return self
}

select_casualties_get_battle_state :: proc(self: ^Select_Casualties) -> ^Battle_State {
	return self.battle_state
}

select_casualties_get_side :: proc(self: ^Select_Casualties) -> Battle_State_Side {
	return self.side
}

select_casualties_get_firing_group :: proc(self: ^Select_Casualties) -> ^Firing_Group {
	return self.firing_group
}

select_casualties_get_fire_round_state :: proc(self: ^Select_Casualties) -> ^Fire_Round_State {
	return self.fire_round_state
}

