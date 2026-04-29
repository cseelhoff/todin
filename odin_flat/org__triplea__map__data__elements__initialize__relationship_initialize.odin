package game

Relationship_Initialize :: struct {
	relationships: [dynamic]^Relationship_Initialize_Relationship,
}

Relationship_Initialize_Relationship :: struct {
	type:        string,
	round_value: i32,
	player1:     string,
	player2:     string,
}

