package game

Player_Types :: struct {
	player_types: [dynamic]^Player_Types_Type,
}

make_Player_Types :: proc(types: [dynamic]^Player_Types_Type) -> Player_Types {
	return Player_Types{player_types = types}
}

player_types_from_label :: proc(self: ^Player_Types, label: string) -> ^Player_Types_Type {
	for t in self.player_types {
		if t.label == label {
			return t
		}
	}
	panic("could not find PlayerType")
}
