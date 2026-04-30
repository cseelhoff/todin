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

abstract_user_action_attachment_can_perform :: proc(
	self: ^Abstract_User_Action_Attachment,
	tested_conditions: map[^I_Condition]bool,
) -> bool {
	return self.conditions == nil ||
		abstract_conditions_attachment_is_satisfied(&self.abstract_conditions_attachment, tested_conditions)
}

abstract_user_action_attachment_has_attempts_left :: proc(
	self: ^Abstract_User_Action_Attachment,
) -> bool {
	return self.attempts_left_this_turn > 0
}

