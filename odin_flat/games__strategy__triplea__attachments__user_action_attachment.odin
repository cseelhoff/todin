package game

User_Action_Attachment :: struct {
	using base: Abstract_User_Action_Attachment,
	activate_trigger: [dynamic]^Tuple(string, string),
}
