package game

User_Action_Attachment :: struct {
	using base: Abstract_User_Action_Attachment,
	activate_trigger: [dynamic]^Tuple(string, string),
}

// Stub: not on WW2v5 AI test path.
user_action_attachment_new :: proc(name: string, attachable: ^Attachable, game_data: ^Game_Data) -> ^User_Action_Attachment {
	return new(User_Action_Attachment)
}
