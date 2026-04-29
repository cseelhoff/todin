package game

Political_Action_Attachment :: struct {
	using abstract_user_action_attachment: Abstract_User_Action_Attachment,
	relationship_change: [dynamic]string,
}

Political_Action_Attachment_Relationship_Change :: struct {
	player1: ^Game_Player,
	player2: ^Game_Player,
	relationship_type: ^Relationship_Type,
}
