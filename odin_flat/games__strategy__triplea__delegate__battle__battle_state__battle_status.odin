package game

Battle_State_Battle_Status :: struct {
	round:         i32,
	max_rounds:    i32,
	is_over:       bool,
	is_amphibious: bool,
	is_headless:   bool,
}

battle_status_new :: proc(
	round: i32,
	max_rounds: i32,
	is_over: bool,
	is_amphibious: bool,
	is_headless: bool,
) -> ^Battle_State_Battle_Status {
	self := new(Battle_State_Battle_Status)
	self.round = round
	self.max_rounds = max_rounds
	self.is_over = is_over
	self.is_amphibious = is_amphibious
	self.is_headless = is_headless
	return self
}

// Lombok @Value(staticConstructor = "of") factory.
battle_state__battle_status_of :: proc(
	round: i32,
	max_rounds: i32,
	is_over: bool,
	is_amphibious: bool,
	is_headless: bool,
) -> ^Battle_State_Battle_Status {
	return battle_status_new(round, max_rounds, is_over, is_amphibious, is_headless)
}

battle_status_get_round :: proc(self: ^Battle_State_Battle_Status) -> i32 {
	return self.round
}

battle_status_is_amphibious :: proc(self: ^Battle_State_Battle_Status) -> bool {
	return self.is_amphibious
}

battle_status_is_first_round :: proc(self: ^Battle_State_Battle_Status) -> bool {
	return self.round == 1
}

battle_status_is_headless :: proc(self: ^Battle_State_Battle_Status) -> bool {
	return self.is_headless
}

battle_status_is_last_round :: proc(self: ^Battle_State_Battle_Status) -> bool {
	return self.max_rounds > 0 && self.max_rounds <= self.round
}

battle_status_is_over :: proc(self: ^Battle_State_Battle_Status) -> bool {
	return self.is_over
}
