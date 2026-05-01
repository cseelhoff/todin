package game

Casualty_List :: struct {
	killed:  [dynamic]^Unit,
	damaged: [dynamic]^Unit,
}

casualty_list_init :: proc(self: ^Casualty_List, killed: []^Unit, damaged: []^Unit) {
	self.killed = make([dynamic]^Unit, 0, len(killed))
	self.damaged = make([dynamic]^Unit, 0, len(damaged))
	for u in killed do append(&self.killed, u)
	for u in damaged do append(&self.damaged, u)
}

casualty_list_add_to_killed :: proc(self: ^Casualty_List, dead_unit: ^Unit) {
	append(&self.killed, dead_unit)
}

casualty_list_add_to_damaged_one :: proc(self: ^Casualty_List, damaged_unit: ^Unit) {
	append(&self.damaged, damaged_unit)
}

casualty_list_add_to_damaged_many :: proc(self: ^Casualty_List, damaged_units: []^Unit) {
	for u in damaged_units do append(&self.damaged, u)
}

casualty_list_get_killed :: proc(self: ^Casualty_List) -> [dynamic]^Unit {
	return self.killed
}

casualty_list_get_damaged :: proc(self: ^Casualty_List) -> [dynamic]^Unit {
	return self.damaged
}

casualty_list_size :: proc(self: ^Casualty_List) -> int {
	return len(self.killed) + len(self.damaged)
}

