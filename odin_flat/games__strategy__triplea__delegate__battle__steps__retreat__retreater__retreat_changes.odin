package game

Retreater_Retreat_Changes :: struct {
	change:       ^Change,
	history_text: [dynamic]^Retreater_Retreat_History_Child,
}

retreat_changes_new :: proc(
	change: ^Change,
	history_text: [dynamic]^Retreater_Retreat_History_Child,
) -> ^Retreater_Retreat_Changes {
	self := new(Retreater_Retreat_Changes)
	self.change = change
	self.history_text = history_text
	return self
}

retreat_changes_get_change :: proc(self: ^Retreater_Retreat_Changes) -> ^Change {
	return self.change
}

retreat_changes_get_history_text :: proc(
	self: ^Retreater_Retreat_Changes,
) -> [dynamic]^Retreater_Retreat_History_Child {
	return self.history_text
}

retreat_changes_of :: proc(
	change: ^Change,
	history_text: [dynamic]^Retreater_Retreat_History_Child,
) -> ^Retreater_Retreat_Changes {
	return retreat_changes_new(change, history_text)
}

