package game

import "core:slice"

Chat :: struct {
	chat_transmitter:        ^Chat_Transmitter,
	chat_message_listeners:  [dynamic]^Chat_Message_Listener,
	chat_player_listeners:   [dynamic]^Chat_Player_Listener,
	sent_messages_history:   ^Sent_Messages_History,
	chatters:                map[^Chat_Participant]struct{},
	chat_history:            [dynamic]^Chat_Message,
	ignore_list:             map[^User_Name]struct{},
	local_user_name:         ^User_Name,
	status_update_listeners: [dynamic]proc(^User_Name, string),
}

chat_is_ignored :: proc(self: ^Chat, user_name: ^User_Name) -> bool {
	_, ok := self.ignore_list[user_name]
	return ok
}

chat_lambda_status_updated_10 :: proc(user_name: ^User_Name, status: string, l: proc(^User_Name, string)) {
	l(user_name, status)
}

chat_update_connections :: proc(self: ^Chat) {
	player_names := make([dynamic]^Chat_Participant, 0, len(self.chatters))
	defer delete(player_names)
	for c in self.chatters {
		append(&player_names, c)
	}
	slice.sort_by(player_names[:], proc(a, b: ^Chat_Participant) -> bool {
		return a.user_name < b.user_name
	})
	for listener in self.chat_player_listeners {
		_ = listener
	}
}

