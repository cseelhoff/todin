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

