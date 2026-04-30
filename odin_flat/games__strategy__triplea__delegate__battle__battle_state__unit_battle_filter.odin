package game

Battle_State_Unit_Battle_Filter :: struct {
	filter: map[Battle_State_Unit_Battle_Status]struct {},
}

battle_state_unit_battle_filter_new :: proc(status: ..Battle_State_Unit_Battle_Status) -> ^Battle_State_Unit_Battle_Filter {
	self := new(Battle_State_Unit_Battle_Filter)
	self.filter = make(map[Battle_State_Unit_Battle_Status]struct {})
	for s in status {
		self.filter[s] = struct {}{}
	}
	return self
}

battle_state_unit_battle_filter_get_filter :: proc(self: ^Battle_State_Unit_Battle_Filter) -> map[Battle_State_Unit_Battle_Status]struct {} {
	return self.filter
}

