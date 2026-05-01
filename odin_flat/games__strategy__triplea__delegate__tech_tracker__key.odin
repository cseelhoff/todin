package game

Tech_Tracker_Key :: struct {
	player:    ^Game_Player,
	unit_type: ^Unit_Type,
	property:  string,
}

tech_tracker_key_init :: proc(
	self: ^Tech_Tracker_Key,
	player: ^Game_Player,
	unit_type: ^Unit_Type,
	property: string,
) {
	self.player = player
	self.unit_type = unit_type
	self.property = property
}

