package game

Relationship_Change :: struct {
	using change: Change,
	player1_name: string,
	player2_name: string,
	old_relationship_type_name: string,
	new_relationship_type_name: string,
}
