package game

Moderator_Message :: struct {
	action:      string,
	player_name: string,
}

make_Moderator_Message :: proc(action: string, player_name: string) -> Moderator_Message {
	return Moderator_Message{action = action, player_name = player_name}
}

moderator_message_get_action :: proc(self: ^Moderator_Message) -> string {
	return self.action
}
// Java owners covered by this file:
//   - games.strategy.engine.framework.startup.mc.messages.ModeratorMessage

