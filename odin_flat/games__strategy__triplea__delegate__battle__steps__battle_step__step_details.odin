package game

Battle_Step_Step_Details :: struct {
	name: string,
	step: ^Battle_Step,
}

battle_step_step_details_new :: proc(name: string, step: ^Battle_Step) -> ^Battle_Step_Step_Details {
	self := new(Battle_Step_Step_Details)
	self.name = name
	self.step = step
	return self
}

battle_step_step_details_get_name :: proc(self: ^Battle_Step_Step_Details) -> string {
	return self.name
}

battle_step_step_details_get_step :: proc(self: ^Battle_Step_Step_Details) -> ^Battle_Step {
	return self.step
}
