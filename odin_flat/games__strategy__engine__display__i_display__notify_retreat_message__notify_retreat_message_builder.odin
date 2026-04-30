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
