package game

// Java `PlayerTypes.Type` is abstract with `newPlayerWithName(String)`.
// Odin models virtual dispatch via a function-pointer field that each
// concrete subtype (PlayerTypes$1/$2/$3) wires up in its constructor.
// The base dispatcher `player_types_type_new_player_with_name` just
// forwards to the field.
Player_Types_Type :: struct {
	label:                 string,
	visible:               bool,
	new_player_with_name:  proc(self: ^Player_Types_Type, name: string) -> ^Player,
}

player_types_type_new_player_with_name :: proc(self: ^Player_Types_Type, name: string) -> ^Player {
	return self.new_player_with_name(self, name)
}

