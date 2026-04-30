package game

Retreater_Retreat_History_Child :: struct {
	text:  string,
	units: [dynamic]^Unit,
}

retreat_history_child_new :: proc(text: string, units: [dynamic]^Unit) -> ^Retreater_Retreat_History_Child {
	self := new(Retreater_Retreat_History_Child)
	self.text = text
	self.units = units
	return self
}

retreat_history_child_get_text :: proc(self: ^Retreater_Retreat_History_Child) -> string {
	return self.text
}

retreat_history_child_get_units :: proc(self: ^Retreater_Retreat_History_Child) -> [dynamic]^Unit {
	return self.units
}

