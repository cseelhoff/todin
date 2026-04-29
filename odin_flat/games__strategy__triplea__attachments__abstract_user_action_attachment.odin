package game

Abstract_User_Action_Attachment :: struct {
	using abstract_conditions_attachment: Abstract_Conditions_Attachment,
	text: string,
	cost_pu: i32,
	cost_resources: Integer_Map_Resource,
	attempts_per_turn: i32,
	attempts_left_this_turn: i32,
	action_accept: [dynamic]^Game_Player,
}

