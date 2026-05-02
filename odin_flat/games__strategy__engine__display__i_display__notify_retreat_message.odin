package game

Notify_Retreat_Message :: struct {
	short_message:          string,
	message:                string,
	step:                   string,
	retreating_player_name: string,
}

make_I_Display_Notify_Retreat_Message :: proc(
	short_message: string,
	message: string,
	step: string,
	retreating_player_name: string,
) -> Notify_Retreat_Message {
	return Notify_Retreat_Message{
		short_message = short_message,
		message = message,
		step = step,
		retreating_player_name = retreating_player_name,
	}
}
// Lombok @Builder generated static factory: NotifyRetreatMessage.builder()
notify_retreat_message_builder :: proc() -> ^I_Display_Notify_Retreat_Message_Notify_Retreat_Message_Builder {
	b := new(I_Display_Notify_Retreat_Message_Notify_Retreat_Message_Builder)
	b^ = I_Display_Notify_Retreat_Message_Notify_Retreat_Message_Builder{}
	return b
}

i_display_notify_retreat_message_accept :: proc(self: ^Notify_Retreat_Message, display: ^I_Display, playerlist: ^Player_List) {
	i_display_notify_retreat(
		display,
		self.short_message,
		self.message,
		self.step,
		player_list_get_player_id(playerlist, self.retreating_player_name),
	)
}
