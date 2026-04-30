package game

// games.strategy.engine.display.IDisplay$NotifyRetreatMessage$NotifyRetreatMessageBuilder
// Lombok @Builder generated builder for NotifyRetreatMessage.

I_Display_Notify_Retreat_Message_Notify_Retreat_Message_Builder :: struct {
	short_message:          string,
	message:                string,
	step:                   string,
	retreating_player_name: string,
}

make_I_Display_Notify_Retreat_Message_Notify_Retreat_Message_Builder :: proc() -> I_Display_Notify_Retreat_Message_Notify_Retreat_Message_Builder {
	return I_Display_Notify_Retreat_Message_Notify_Retreat_Message_Builder{}
}

i_display_notify_retreat_message_notify_retreat_message_builder_message :: proc(self: ^I_Display_Notify_Retreat_Message_Notify_Retreat_Message_Builder, message: string) -> ^I_Display_Notify_Retreat_Message_Notify_Retreat_Message_Builder {
	self.message = message
	return self
}

i_display_notify_retreat_message_notify_retreat_message_builder_retreating_player_name :: proc(self: ^I_Display_Notify_Retreat_Message_Notify_Retreat_Message_Builder, retreating_player_name: string) -> ^I_Display_Notify_Retreat_Message_Notify_Retreat_Message_Builder {
	self.retreating_player_name = retreating_player_name
	return self
}

i_display_notify_retreat_message_notify_retreat_message_builder_short_message :: proc(self: ^I_Display_Notify_Retreat_Message_Notify_Retreat_Message_Builder, short_message: string) -> ^I_Display_Notify_Retreat_Message_Notify_Retreat_Message_Builder {
	self.short_message = short_message
	return self
}

i_display_notify_retreat_message_notify_retreat_message_builder_step :: proc(self: ^I_Display_Notify_Retreat_Message_Notify_Retreat_Message_Builder, step: string) -> ^I_Display_Notify_Retreat_Message_Notify_Retreat_Message_Builder {
	self.step = step
	return self
}
