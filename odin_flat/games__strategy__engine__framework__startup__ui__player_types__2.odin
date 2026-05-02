package game

Player_Types_2 :: struct {
        using player_types_type: Player_Types_Type,
}

// Java anonymous subclass `PlayerTypes$2` (FAST_AI). Its synthetic
// `<init>(String)` simply invokes the abstract parent constructor
// `Type(String)`, which delegates to `Type(String, boolean=true)`.
// Mirror that by constructing the embedded `Player_Types_Type` via
// the existing single-arg base constructor and copying it into the
// freshly allocated subtype.
player_types_2_new :: proc(label: string) -> ^Player_Types_2 {
	self := new(Player_Types_2)
	base := player_types_type_new(label)
	self.player_types_type = base^
	free(base)
	return self
}
