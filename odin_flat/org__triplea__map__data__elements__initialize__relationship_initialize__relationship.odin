package game

Initialize_Relationship_Initialize_Relationship :: struct {
	type:        string,
	round_value: i32,
	player1:     string,
	player2:     string,
}

initialize_relationship_initialize_relationship_get_player1 :: proc(self: ^Initialize_Relationship_Initialize_Relationship) -> string {
	return self.player1
}

initialize_relationship_initialize_relationship_get_player2 :: proc(self: ^Initialize_Relationship_Initialize_Relationship) -> string {
	return self.player2
}

initialize_relationship_initialize_relationship_get_round_value :: proc(self: ^Initialize_Relationship_Initialize_Relationship) -> i32 {
	return self.round_value
}

initialize_relationship_initialize_relationship_get_type :: proc(self: ^Initialize_Relationship_Initialize_Relationship) -> string {
	return self.type
}
