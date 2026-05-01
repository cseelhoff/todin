package game

Relationship_Change :: struct {
	using change: Change,
	player1_name: string,
	player2_name: string,
	old_relationship_type_name: string,
	new_relationship_type_name: string,
}

relationship_change_new :: proc(
	player1: ^Game_Player,
	player2: ^Game_Player,
	old_relationship_type: ^Relationship_Type,
	new_relationship_type: ^Relationship_Type,
) -> ^Relationship_Change {
	rc := new(Relationship_Change)
	rc.player1_name = player1.named.base.name
	rc.player2_name = player2.named.base.name
	rc.old_relationship_type_name = old_relationship_type.named.base.name
	rc.new_relationship_type_name = new_relationship_type.named.base.name
	return rc
}
