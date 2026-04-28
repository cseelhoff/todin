package game

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

